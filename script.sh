#!/usr/bin/env bash
set -e

###############################################################################
# Krivana App - Full Environment Setup & APK Build Script
# Run this after restarting the codespace: bash script.sh
###############################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log()   { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
err()   { echo -e "${RED}[✗]${NC} $1"; exit 1; }

APP_DIR="/workspaces/krivana-app"
FLUTTER_DIR="/home/codespace/flutter-sdk"
ANDROID_SDK_DIR="/home/codespace/android-sdk"
JAVA_HOME_DIR="/usr/lib/jvm/java-17-openjdk-amd64"

cd "$APP_DIR"

# ─── 1. Java 17 ─────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  Step 1/8: Java 17"
echo "══════════════════════════════════════════════════════════════"

if [ -d "$JAVA_HOME_DIR" ] && "$JAVA_HOME_DIR/bin/java" -version 2>&1 | grep -q "17"; then
    log "Java 17 already installed"
else
    warn "Installing Java 17..."
    sudo apt-get update -qq && sudo apt-get install -y -qq openjdk-17-jdk > /dev/null 2>&1
    log "Java 17 installed"
fi

export JAVA_HOME="$JAVA_HOME_DIR"
export PATH="$JAVA_HOME/bin:$PATH"
log "JAVA_HOME=$JAVA_HOME"

# ─── 2. Flutter SDK ─────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  Step 2/8: Flutter SDK"
echo "══════════════════════════════════════════════════════════════"

if [ -f "$FLUTTER_DIR/bin/flutter" ]; then
    log "Flutter SDK found at $FLUTTER_DIR"
else
    warn "Cloning Flutter SDK (stable)..."
    git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
    log "Flutter SDK cloned"
fi

export FLUTTER_ROOT="$FLUTTER_DIR"
export PATH="$FLUTTER_DIR/bin:$PATH"

# Precache artifacts
flutter precache --android 2>/dev/null || true
log "Flutter $(flutter --version 2>&1 | head -1)"

# ─── 3. Android SDK ─────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  Step 3/8: Android SDK"
echo "══════════════════════════════════════════════════════════════"

export ANDROID_HOME="$ANDROID_SDK_DIR"
export ANDROID_SDK_ROOT="$ANDROID_SDK_DIR"
export PATH="$ANDROID_SDK_DIR/cmdline-tools/latest/bin:$ANDROID_SDK_DIR/platform-tools:$PATH"

if [ -f "$ANDROID_SDK_DIR/cmdline-tools/latest/bin/sdkmanager" ]; then
    log "Android SDK cmdline-tools found"
else
    warn "Downloading Android cmdline-tools..."
    mkdir -p "$ANDROID_SDK_DIR/cmdline-tools"
    CMDLINE_ZIP="/tmp/cmdline-tools.zip"
    curl -sL "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip" -o "$CMDLINE_ZIP"
    unzip -qo "$CMDLINE_ZIP" -d "$ANDROID_SDK_DIR/cmdline-tools"
    mv "$ANDROID_SDK_DIR/cmdline-tools/cmdline-tools" "$ANDROID_SDK_DIR/cmdline-tools/latest" 2>/dev/null || true
    rm -f "$CMDLINE_ZIP"
    log "Android cmdline-tools installed"
fi

# Accept licenses
yes | sdkmanager --licenses > /dev/null 2>&1 || true

# Install required SDK components
COMPONENTS=(
    "platforms;android-34"
    "platforms;android-35"
    "platforms;android-36"
    "build-tools;35.0.0"
    "platform-tools"
    "ndk;27.0.12077973"
)

for comp in "${COMPONENTS[@]}"; do
    if [ -d "$ANDROID_SDK_DIR/$(echo "$comp" | tr ';' '/')" ]; then
        log "$comp already installed"
    else
        warn "Installing $comp..."
        sdkmanager --install "$comp" > /dev/null 2>&1
        log "$comp installed"
    fi
done

# ─── 4. Configure Flutter ───────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  Step 4/8: Configure Flutter"
echo "══════════════════════════════════════════════════════════════"

flutter config --android-sdk "$ANDROID_SDK_DIR" 2>/dev/null
flutter config --jdk-dir "$JAVA_HOME_DIR" 2>/dev/null
log "Flutter configured (Android SDK + JDK)"

# ─── 5. Persist env to .bashrc ──────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  Step 5/8: Persist environment variables"
echo "══════════════════════════════════════════════════════════════"

BASHRC="$HOME/.bashrc"
add_to_bashrc() {
    grep -qxF "$1" "$BASHRC" 2>/dev/null || echo "$1" >> "$BASHRC"
}

add_to_bashrc "export JAVA_HOME=$JAVA_HOME_DIR"
add_to_bashrc "export ANDROID_HOME=$ANDROID_SDK_DIR"
add_to_bashrc "export ANDROID_SDK_ROOT=$ANDROID_SDK_DIR"
add_to_bashrc "export FLUTTER_ROOT=$FLUTTER_DIR"
add_to_bashrc 'export PATH="$FLUTTER_ROOT/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$JAVA_HOME/bin:$PATH"'
log "Environment variables persisted to ~/.bashrc"

# ─── 6. Flutter pub get ─────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  Step 6/8: Flutter packages"
echo "══════════════════════════════════════════════════════════════"

cd "$APP_DIR"
flutter pub get
log "Packages resolved"

# ─── 7. Launcher icons ──────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  Step 7/8: Generate launcher icons"
echo "══════════════════════════════════════════════════════════════"

dart run flutter_launcher_icons 2>/dev/null && log "Launcher icons generated" || warn "Launcher icons skipped (already generated or error)"

# ─── 8. Build APK ───────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  Step 8/8: Build Release APK"
echo "══════════════════════════════════════════════════════════════"

cd "$APP_DIR"
flutter build apk --release

echo ""
echo "══════════════════════════════════════════════════════════════"
echo -e "  ${GREEN}BUILD COMPLETE!${NC}"
echo "══════════════════════════════════════════════════════════════"
echo ""
APK_PATH="$APP_DIR/build/app/outputs/flutter-apk/app-release.apk"
if [ -f "$APK_PATH" ]; then
    SIZE=$(du -h "$APK_PATH" | cut -f1)
    log "APK: $APK_PATH ($SIZE)"
else
    err "APK not found at expected path!"
fi
