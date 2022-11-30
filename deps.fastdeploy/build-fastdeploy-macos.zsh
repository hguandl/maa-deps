#!/usr/bin/env zsh

set -e -o pipefail

# ----------  SETUP  ----------

FASTDEPLOY_VER="1.0.0"

PROJECT_PATH="$(dirname $0)/.."
pushd $PROJECT_PATH
PROJECT_PATH=$PWD
popd

SRC_ROOT="${PROJECT_PATH}/macos_src"
SRC_PATH="${SRC_ROOT}/FastDeploy-release-${FASTDEPLOY_VER}"
BUILD_PATH="${PROJECT_PATH}/macos_build/FastDeploy-release-${FASTDEPLOY_VER}"
INSTALL_PATH="${PROJECT_PATH}/maa-deps-macos"

# ----------  DOWNLOAD  ----------

if [ ! -f "${SRC_PATH}/CMakeLists.txt" ]; then
    echo "Downloading FastDeploy ${FASTDEPLOY_VER}"
    mkdir -p ${SRC_ROOT}
    curl -fSL -o- https://github.com/PaddlePaddle/FastDeploy/archive/refs/tags/release/${FASTDEPLOY_VER}.tar.gz | tar -C ${SRC_ROOT} -zxf -
fi

# ----------  BUILD  ----------

function build_architecture() {
    ARCH=$1
    echo "Building FastDeploy ${OPENCV_VER} for ${ARCH}"

    cmake -S "${SRC_PATH}" -B "${BUILD_PATH}/${ARCH}" -GNinja \
        -DCMAKE_INSTALL_PREFIX="${BUILD_PATH}/${ARCH}/compiled_fastdeploy_sdk" \
        -DCMAKE_OSX_ARCHITECTURES="${ARCH}" \
        -DCMAKE_OSX_DEPLOYMENT_TARGET=11.0 \
        -DENABLE_ORT_BACKEND=ON \
        -DENABLE_VISION=ON \
        -DOPENCV_DIRECTORY="${INSTALL_PATH}"
    cmake --build "${BUILD_PATH}/${ARCH}"
    cmake --install "${BUILD_PATH}/${ARCH}"
}

build_architecture "arm64"
build_architecture "x86_64"

echo "Creating universal binary"
pushd ${BUILD_PATH}
cp -R arm64/compiled_fastdeploy_sdk .
pushd compiled_fastdeploy_sdk
find . -type f -name "*.dylib" | while read i; do
    lipo -create -output $i $i ../x86_64/compiled_fastdeploy_sdk/$i
done
popd
popd

# ----------  INSTALL  ----------

rsync -a "${BUILD_PATH}/compiled_fastdeploy_sdk/" "${INSTALL_PATH}/"

echo "FastDeploy build complete."
