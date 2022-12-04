#!/usr/bin/env zsh

set -e -o pipefail

./deps.opencv/build-opencv-macos.zsh
./deps.protobuf/build-protobuf-macos.zsh
./deps.onnxruntime/build-onnxruntime-macos.zsh
./deps.paddle2onnx/build-paddle2onnx-macos.zsh
./deps.fastdeploy/build-fastdeploy-macos.zsh

echo "Packaging dependencies"
tar Jcf maa-deps-macos.tar.xz maa-deps-macos
echo "Done."
