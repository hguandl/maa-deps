#!/usr/bin/env zsh

set -e -o pipefail

# ----------  SETUP  ----------

PROTOBUF_VER="v3.18.1"

PROJECT_PATH="$(dirname $0)/.."
pushd $PROJECT_PATH
PROJECT_PATH=$PWD
popd

SRC_ROOT="${PROJECT_PATH}/macos_src"
SRC_PATH="${SRC_ROOT}/protobuf-${PROTOBUF_VER}"
BUILD_PATH="${PROJECT_PATH}/macos_build/protobuf-${PROTOBUF_VER}"
INSTALL_PATH="${PROJECT_PATH}/maa-deps-macos"

# ----------  DOWNLOAD  ----------

if [ ! -f "${SRC_PATH}/cmake/CMakeLists.txt" ]; then
    echo "Downloading Protobuf ${PROTOBUF_VER}"
    mkdir -p ${SRC_ROOT}
    git clone https://github.com/protocolbuffers/protobuf.git --branch ${PROTOBUF_VER} --single-branch --recursive ${SRC_PATH}
fi

# ----------  BUILD  ----------

echo "Building Protobuf ${PROTOBUF_VER}"

cmake -S "${SRC_PATH}/cmake" -B "${BUILD_PATH}" -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER_LAUNCHER=ccache \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_PATH}" \
    -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=11.0 \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -Dprotobuf_BUILD_SHARED_LIBS=OFF \
    -Dprotobuf_BUILD_TESTS=OFF

cmake --build "${BUILD_PATH}"
cmake --install "${BUILD_PATH}"

echo "Protobuf build complete."
