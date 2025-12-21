#!/bin/bash

# Exit on any error
set -e

# Define paths
ANDROID_SDK_DIR="$HOME/android-sdk"
CMD_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
ZSH_RC="$HOME/.zshrc"
BASH_RC="$HOME/.bashrc"

echo "Starting setup for Expo Android tools on Arch Linux..."

# Install dependencies using yay
echo "Installing required packages (unzip, wget)..."
yay -S --noconfirm unzip wget

# Create Android SDK directory
echo "Setting up Android SDK in $ANDROID_SDK_DIR..."
mkdir -p "$ANDROID_SDK_DIR"
cd "$ANDROID_SDK_DIR"

# Download and extract Android command-line tools
echo "Downloading Android command-line tools..."
wget -q "$CMD_TOOLS_URL" -O cmdline-tools.zip
unzip -q cmdline-tools.zip
# Handle the extracted directory structure properly
if [ -d "cmdline-tools/cmdline-tools" ]; then
    # If there's a nested cmdline-tools directory
    mkdir -p cmdline-tools/latest
    mv cmdline-tools/cmdline-tools/* cmdline-tools/latest/
    rm -rf cmdline-tools/cmdline-tools
elif [ -d "cmdline-tools" ] && [ -f "cmdline-tools/bin/sdkmanager" ]; then
    # If the tools are directly in cmdline-tools
    temp_dir=$(mktemp -d)
    mv cmdline-tools/* "$temp_dir"/
    mkdir -p cmdline-tools/latest
    mv "$temp_dir"/* cmdline-tools/latest/
    rm -rf "$temp_dir"
else
    # If the extraction created a different structure, find and move the tools
    echo "Detecting extracted directory structure..."
    sdkmanager_path=$(find . -name "sdkmanager" -type f | head -1)
    if [ -n "$sdkmanager_path" ]; then
        tools_dir=$(dirname "$sdkmanager_path")
        mkdir -p cmdline-tools/latest
        mv "$tools_dir"/* cmdline-tools/latest/
        rm -rf "$tools_dir"
    else
        echo "Error: Could not find sdkmanager in extracted files"
        exit 1
    fi
fi
rm cmdline-tools.zip

# Set environment variables
echo "Configuring environment variables..."
if [ -f "$ZSH_RC" ]; then
  PROFILE="$ZSH_RC"
elif [ -f "$BASH_RC" ]; then
  PROFILE="$BASH_RC"
else
  PROFILE="$HOME/.profile"
  touch "$PROFILE"
fi

# Add environment variables if not already present
if ! grep -q "ANDROID_HOME" "$PROFILE"; then
  echo -e "\n# Android SDK for Expo" >>"$PROFILE"
  echo "export ANDROID_HOME=$ANDROID_SDK_DIR" >>"$PROFILE"
  echo "export PATH=\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin" >>"$PROFILE"
  echo "export PATH=\$PATH:\$ANDROID_HOME/platform-tools" >>"$PROFILE"
fi

# Source the profile to apply changes in the current session
source "$PROFILE"

# Export environment variables for current session as well
export ANDROID_HOME="$ANDROID_SDK_DIR"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"

# Install Android SDK components
echo "Installing Android SDK components (platform-tools, android-33, build-tools)..."
"$ANDROID_SDK_DIR/cmdline-tools/latest/bin/sdkmanager" "platform-tools" "platforms;android-33" "build-tools;33.0.2"

# Accept SDK licenses
echo "Accepting Android SDK licenses..."
yes | "$ANDROID_SDK_DIR/cmdline-tools/latest/bin/sdkmanager" --licenses

# Verify installations
echo "Verifying installations..."
if command -v java &> /dev/null; then
    java -version
else
    echo "Warning: Java not found. You may need to install it: sudo pacman -S jdk-openjdk"
fi

if command -v node &> /dev/null; then
    node -v
else
    echo "Warning: Node.js not found. You may need to install it: sudo pacman -S nodejs npm"
fi

if command -v adb &> /dev/null; then
    adb --version
else
    echo "Warning: ADB not available yet. It should be available after restarting your shell."
fi

echo "Setup complete! You can now create an Expo project with:"
echo "npx create-expo-app MyExpoApp"
echo "Then navigate to the project and run 'npx expo run:android' to build and run on an Android device or emulator."
echo "Note: If you need an emulator, manually install it with sdkmanager (e.g., 'system-images;android-33;google_apis;x86_64')."
