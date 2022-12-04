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

## ----------  PATCH  ----------
pushd ${SRC_PATH}
patch -p1 --forward -i ${PROJECT_PATH}/deps.fastdeploy/static-libs.patch || true
popd

# ----------  BUILD  ----------

echo "Building FastDeploy ${FASTDEPLOY_VER}"

cmake -S "${SRC_PATH}" -B "${BUILD_PATH}" -GNinja \
    -DCMAKE_C_COMPILER_LAUNCHER=ccache \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_PATH}" \
    -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=11.0 \
    -DENABLE_ORT_BACKEND=ON \
    -DENABLE_VISION=ON \
    -DOPENCV_DIRECTORY="${INSTALL_PATH}" \
    -DCUSTOM_DIRECTORY="${INSTALL_PATH}"

cmake --build "${BUILD_PATH}"

cp "${BUILD_PATH}/libfastdeploy.a" "${INSTALL_PATH}/lib"

echo "FastDeploy build complete."
