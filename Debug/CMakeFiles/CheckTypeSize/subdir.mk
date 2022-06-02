################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../CMakeFiles/CheckTypeSize/TIME_T_SIZE.c 

OBJS += \
./CMakeFiles/CheckTypeSize/TIME_T_SIZE.o 

C_DEPS += \
./CMakeFiles/CheckTypeSize/TIME_T_SIZE.d 


# Each subdirectory must supply rules for building sources it contributes
CMakeFiles/CheckTypeSize/%.o: ../CMakeFiles/CheckTypeSize/%.c CMakeFiles/CheckTypeSize/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: GNU Arm Cross C Compiler'
	arm-none-eabi-gcc -mcpu=cortex-m3 -mthumb -O0 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections  -g3 -std=gnu11 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


