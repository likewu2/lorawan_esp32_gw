################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../main/AppMain.c \
../main/ESP32WifiConnector.c \
../main/LoraNodeManager.c \
../main/LoraRealtimeSender.c \
../main/LoraRealtimeSenderItf.c \
../main/LoraServerManager.c \
../main/LoraTransceiverItf.c \
../main/NetworkServerProtocolItf.c \
../main/SX1276.c \
../main/SemtechProtocolEngine.c \
../main/ServerConnectorItf.c \
../main/ServerManagerItf.c \
../main/TransceiverManagerItf.c \
../main/Utilities.c 

OBJS += \
./main/AppMain.o \
./main/ESP32WifiConnector.o \
./main/LoraNodeManager.o \
./main/LoraRealtimeSender.o \
./main/LoraRealtimeSenderItf.o \
./main/LoraServerManager.o \
./main/LoraTransceiverItf.o \
./main/NetworkServerProtocolItf.o \
./main/SX1276.o \
./main/SemtechProtocolEngine.o \
./main/ServerConnectorItf.o \
./main/ServerManagerItf.o \
./main/TransceiverManagerItf.o \
./main/Utilities.o 

C_DEPS += \
./main/AppMain.d \
./main/ESP32WifiConnector.d \
./main/LoraNodeManager.d \
./main/LoraRealtimeSender.d \
./main/LoraRealtimeSenderItf.d \
./main/LoraServerManager.d \
./main/LoraTransceiverItf.d \
./main/NetworkServerProtocolItf.d \
./main/SX1276.d \
./main/SemtechProtocolEngine.d \
./main/ServerConnectorItf.d \
./main/ServerManagerItf.d \
./main/TransceiverManagerItf.d \
./main/Utilities.d 


# Each subdirectory must supply rules for building sources it contributes
main/%.o: ../main/%.c main/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: GNU Arm Cross C Compiler'
	arm-none-eabi-gcc -mcpu=cortex-m3 -mthumb -O0 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections  -g3 -std=gnu11 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


