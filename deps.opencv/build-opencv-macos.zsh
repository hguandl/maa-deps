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

function build_architecture() {
    ARCH=$1
    echo "Building OpenCV ${OPENCV_VER} for ${ARCH}"

    cmake -S "${SRC_PATH}" -B "${BUILD_PATH}/${ARCH}" -GNinja \
        -DBUILD_JAVA=OFF \
        -DBUILD_ITT=OFF \
        -DBUILD_opencv_apps=OFF \
        -DBUILD_opencv_python3=OFF \
        -DBUILD_SHARED_LIBS=OFF \
        -DBUILD_ZLIB=OFF \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="${BUILD_PATH}/opencv-install/${ARCH}" \
        -DCMAKE_OSX_ARCHITECTURES="${ARCH}" \
        -DCMAKE_OSX_DEPLOYMENT_TARGET=11.0 \
        -DOPENCV_FORCE_3RDPARTY_BUILD=ON \
        -DWITH_FFMPEG=OFF \
        -DWITH_IPP=OFF \
        -DWITH_PROTOBUF=OFF

    cmake --build "${BUILD_PATH}/${ARCH}"
    cmake --install "${BUILD_PATH}/${ARCH}"
}

build_architecture "arm64"
build_architecture "x86_64"

echo "Creating universal binary"
pushd "${BUILD_PATH}/opencv-install/arm64"
find . -type f -name "*.a" | while read i; do
    lipo -create -output $i $i ../x86_64/$i
done
popd

# ----------  INSTALL  ----------

rsync -a "${BUILD_PATH}/opencv-install/arm64/" "${INSTALL_PATH}/"

echo "OpenCV build complete."
