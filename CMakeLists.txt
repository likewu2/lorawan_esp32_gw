cmake_minimum_required(VERSION 3.5)

#set(INCLUDE_DIRECTORIES ./main/include/)
#include_directories(includes_folder)
#include_directories(E:/app/julia/rust-esp32-std-demo/.embuild/espressif/esp-idf-master/components/freertos/FreeRTOS-Kernel/include/)

include($ENV{IDF_PATH}/tools/cmake/project.cmake)
project(lorawan_esp32_gw)