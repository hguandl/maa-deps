#!/usr/bin/env zsh

set -e -o pipefail

# ----------  SETUP  ----------

P2O_VER="d5f88459d00717c8584aae74fddb4251608d7c54"

PROJECT_PATH="$(dirname $0)/.."
pushd $PROJECT_PATH
PROJECT_PATH=$PWD
popd

SRC_ROOT="${PROJECT_PATH}/macos_src"
SRC_PATH="${SRC_ROOT}/paddle2onnx-${P2O_VER}"
BUILD_PATH="${PROJECT_PATH}/macos_build/paddle2onnx-${P2O_VER}"
INSTALL_PATH="${PROJECT_PATH}/maa-deps-macos"

# ----------  DOWNLOAD  ----------

if [ ! -f "${SRC_PATH}/CMakeLists.txt" ]; then
    echo "Downloading Paddle2ONNX ${P2O_VER}"
    mkdir -p ${SRC_ROOT}
    git clone https://github.com/PaddlePaddle/Paddle2ONNX.git ${SRC_PATH}
    pushd ${SRC_PATH}
    git checkout ${P2O_VER}
    git submodule update --init --recursive
    popd
fi

# ----------  BUILD  ----------

echo "Building Paddle2ONNX ${P2O_VER}"

PATH="${INSTALL_PATH}/bin:${PATH}"

cmake -S "${SRC_PATH}" -B "${BUILD_PATH}" -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER_LAUNCHER=ccache \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_PATH} \
    -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=11.0

cmake --build "${BUILD_PATH}/${ARCH}"
cmake --install "${BUILD_PATH}/${ARCH}"

echo "Paddle2ONNX build complete."
