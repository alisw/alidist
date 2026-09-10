cmake_minimum_required(VERSION 3.16)
project(onnxruntime_inference_test LANGUAGES CXX)

find_package(onnxruntime CONFIG REQUIRED)

add_executable(onnxruntime-ep-inference onnxruntime_ep_inference.cxx)
target_compile_features(onnxruntime-ep-inference PRIVATE cxx_std_17)
target_link_libraries(onnxruntime-ep-inference PRIVATE onnxruntime::onnxruntime)

install(TARGETS onnxruntime-ep-inference RUNTIME DESTINATION bin)
install(PROGRAMS
  run-onnxruntime-all-eps.sh
  run-onnxruntime-cpu.sh
  run-onnxruntime-cuda.sh
  run-onnxruntime-migraphx.sh
  run-onnxruntime-tensorrt.sh
  run-local-onnxruntime-inference-test.sh
  DESTINATION bin)
install(FILES net.onnx DESTINATION test/onnxruntime-inference)
