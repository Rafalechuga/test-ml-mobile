#!/bin/bash

echo "Starting Android Emulator..."

# Start emulator with optimized settings
${ANDROID_HOME}/emulator/emulator -avd pixel_android_33 \
  -memory 2048 \
  -cores 2 \
  -gpu swiftshader_indirect \
  -no-audio \
  -no-snapshot \
  -accel on \
  -qemu -enable-kvm &

# Wait for emulator to be ready
./scripts/wait-for-emulator.sh

echo "Starting Appium Server..."

# Start Appium server
appium --log-level info \
  --allow-insecure=adb_shell \
  --relaxed-security \
  --base-path /wd/hub \
  --port 4723