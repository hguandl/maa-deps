#!/usr/bin/env zsh

set -e -o pipefail

# ----------  SETUP  ----------

OPENCV_VER="4.6.0"

PROJECT_PATH="$(dirname $0)/.."
pushd $PROJECT_PATH
PROJECT_PATH=$PWD
popd

SRC_ROOT="${PROJECT_PATH}/macos_src"
SRC_PATH="${SRC_ROOT}/opencv-${OPENCV_VER}"
BUILD_PATH="${PROJECT_PATH}/macos_build/opencv-${OPENCV_VER}"
INSTALL_PATH="${PROJECT_PATH}/maa-deps-macos"

# ----------  DOWNLOAD  ----------

if [ ! -f "${SRC_PATH}/CMakeLists.txt" ]; then
    echo "Downloading OpenCV ${OPENCV_VER}"
    mkdir -p ${SRC_ROOT}
    curl -fSL -o- https://github.com/opencv/opencv/archive/${OPENCV_VER}.tar.gz | tar -C ${SRC_ROOT} -zxf -
fi

# ----------  BUILD  ----------

echo "Building OpenCV ${OPENCV_VER}"

cmake -S "${SRC_PATH}" -B "${BUILD_PATH}" -GNinja \
    -DBUILD_opencv_apps=OFF \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_ZLIB=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_PATH}" \
    -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=11.0 \
    -DWITH_FFMPEG=OFF \
    -DWITH_OPENEXR=OFF \
    -DWITH_PROTOBUF=OFF
cmake --build "${BUILD_PATH}"
cmake --install "${BUILD_PATH}"

echo "OpenCV build complete."
