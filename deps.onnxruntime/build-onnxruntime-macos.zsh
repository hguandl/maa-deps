#!/usr/bin/env zsh

set -e -o pipefail

# ----------  SETUP  ----------

ORT_VER="v1.12.1"

PROJECT_PATH="$(dirname $0)/.."
pushd $PROJECT_PATH
PROJECT_PATH=$PWD
popd

SRC_ROOT="${PROJECT_PATH}/macos_src"
SRC_PATH="${SRC_ROOT}/onnxruntime-${ORT_VER}"
BUILD_PATH="${PROJECT_PATH}/macos_build/onnxruntime-${ORT_VER}"
INSTALL_PATH="${PROJECT_PATH}/maa-deps-macos"

# ----------  DOWNLOAD  ----------

if [ ! -f "${SRC_PATH}/cmake/CMakeLists.txt" ]; then
    echo "Downloading ONNXRuntime ${ORT_VER}"
    mkdir -p ${SRC_ROOT}
    git clone https://github.com/microsoft/onnxruntime.git --branch ${ORT_VER} --single-branch --recursive ${SRC_PATH}
fi

# ----------  BUILD  ----------

function build_architecture() {
    ARCH=$1
    echo "Building ONNXRuntime ${ORT_VER} for ${ARCH}"

    cmake -S "${SRC_PATH}/cmake" -B "${BUILD_PATH}/${ARCH}" -GNinja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_COMPILER_LAUNCHER=ccache \
        -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
        -DCMAKE_OSX_ARCHITECTURES="${ARCH}" \
        -DCMAKE_OSX_DEPLOYMENT_TARGET=11.0 \
        -DPYTHON_EXECUTABLE="$(brew --prefix python)/bin/python3" \
        -Donnxruntime_RUN_ONNX_TESTS=OFF \
        -Donnxruntime_GENERATE_TEST_REPORTS=OFF

    if [ "${ARCH}" = "arm64" ]; then
        sed -i '' 's/-maes -msse4.1/-march=armv8-a+crypto/g' "${BUILD_PATH}/${ARCH}/build.ninja"
    else
        sed -i '' 's/-march=armv8-a+crypto/-maes -msse4.1/g' "${BUILD_PATH}/${ARCH}/build.ninja"
    fi

    cmake --build "${BUILD_PATH}/${ARCH}"
}

function install_lib() {
    LIB=$1
    lipo -create -output "${INSTALL_PATH}/lib/${LIB}" "${BUILD_PATH}/arm64/${LIB}" "${BUILD_PATH}/x86_64/${LIB}"
}

function install_external_lib() {
    DIR=$1
    LIB=$2
    lipo -create -output "${INSTALL_PATH}/lib/onnxruntime/external/${LIB}" "${BUILD_PATH}/arm64/${DIR}/${LIB}" "${BUILD_PATH}/x86_64/${DIR}/${LIB}"
}

build_architecture "arm64"
build_architecture "x86_64"

mkdir -p "${INSTALL_PATH}/include/onnxruntime"
find "${SRC_PATH}/include/onnxruntime/core/session" -name "*.h" -exec cp {} "${INSTALL_PATH}/include/onnxruntime" \;

install_lib libonnxruntime_common.a
install_lib libonnxruntime_flatbuffers.a
install_lib libonnxruntime_framework.a
install_lib libonnxruntime_graph.a
install_lib libonnxruntime_mlas.a
# install_lib libonnxruntime_mocked_allocator.a
install_lib libonnxruntime_optimizer.a
install_lib libonnxruntime_providers.a
install_lib libonnxruntime_session.a
install_lib libonnxruntime_util.a

mkdir -p "${INSTALL_PATH}/lib/onnxruntime/external"

install_external_lib "external/abseil-cpp/absl/base" "libabsl_throw_delegate.a"
install_external_lib "external/abseil-cpp/absl/base" "libabsl_throw_delegate.a"
install_external_lib "external/abseil-cpp/absl/container" "libabsl_raw_hash_set.a"
install_external_lib "external/abseil-cpp/absl/hash" "libabsl_low_level_hash.a"
install_external_lib "external/abseil-cpp/absl/hash" "libabsl_hash.a"
install_external_lib "external/abseil-cpp/absl/hash" "libabsl_city.a"
install_external_lib "external/nsync" "libnsync_cpp.a"
install_external_lib "external/onnx" "libonnx.a"
install_external_lib "external/onnx" "libonnx_proto.a"
install_external_lib "external/re2" "libre2.a"

echo "ONNXRuntime build complete."
