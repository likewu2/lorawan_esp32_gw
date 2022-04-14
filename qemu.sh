#!/bin/sh

# You might need to change this...
ESP_QEMU_PATH=/mnt/hgfs/app/qemu-esp-develop-20220203/qemu/bin
BUILD=debug

TARGET=xtensa-esp32-espidf # Don't change this. Only the ESP32 chip is supported in QEMU for now

#D:\tools\esptool-v3.3-win64\esptool
#gcc build/main/libmain.a freertos -o main.out
#esptool.py --chip esp32 elf2image build/main/main.out
#esptool.py --chip esp32 image_info build/lorawan_esp32_gw.bin
esptool.py --chip esp32 merge_bin --output build/esp32-main-qemu.bin --fill-flash-size 4MB 0x1000 ../rust-esp32-std-demo/qemu_bins/bootloader.bin  0x8000 ../rust-esp32-std-demo/qemu_bins/partitions.bin  0x10000 build/lorawan_esp32_gw.bin --flash_mode dio --flash_freq 40m --flash_size 4MB
$ESP_QEMU_PATH/qemu-system-xtensa -nographic -machine esp32 -nic user,model=open_eth,id=lo0,hostfwd=tcp:127.0.0.1:7888-:80 -drive file=build/esp32-main-qemu.bin,if=mtd,format=raw
#