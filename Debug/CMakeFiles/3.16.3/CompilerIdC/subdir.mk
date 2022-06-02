################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../CMakeFiles/3.16.3/CompilerIdC/CMakeCCompilerId.c 

OBJS += \
./CMakeFiles/3.16.3/CompilerIdC/CMakeCCompilerId.o 

C_DEPS += \
./CMakeFiles/3.16.3/CompilerIdC/CMakeCCompilerId.d 


# Each subdirectory must supply rules for building sources it contributes
CMakeFiles/3.16.3/CompilerIdC/%.o: ../CMakeFiles/3.16.3/CompilerIdC/%.c CMakeFiles/3.16.3/CompilerIdC/subdir.mk
	@echo 'Building file: $<'
	@echo 'Invoking: GNU Arm Cross C Compiler'
	arm-none-eabi-gcc -mcpu=cortex-m3 -mthumb -O0 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections  -g3 -std=gnu11 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


