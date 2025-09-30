#!/bin/bash

echo "Waiting for emulator to be ready..."

# Wait for device to be connected
adb wait-for-device

# Wait for boot completion
while [ "$(adb shell getprop sys.boot_completed | tr -d '\r')" != "1" ]; do
    echo "Boot not completed yet..."
    sleep 10
done

echo "Emulator is ready!"