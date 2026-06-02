#!/bin/bash
set -e

# Target paths
NAS_DEST="/media/neo/NAS1/Android_Toolchain"
SDK_SRC="/home/neo/Android/Sdk"
GRADLE_SRC="/home/neo/.gradle"

echo "============================================="
echo "  Android Toolchain Migration to NAS1       "
echo "============================================="
echo "SDK Source:     ${SDK_SRC}"
echo "Gradle Source:  ${GRADLE_SRC}"
echo "NAS Destination: ${NAS_DEST}"
echo "============================================="

# Ensure target directory exists on NAS
mkdir -p "${NAS_DEST}"

# 1. Sync Android SDK
if [ -d "${SDK_SRC}" ] && [ ! -L "${SDK_SRC}" ]; then
    echo "1. Syncing Android SDK to NAS..."
    rsync -a --info=progress2 "${SDK_SRC}/" "${NAS_DEST}/Sdk/"
else
    echo "ℹ️ SDK already symlinked or does not exist, skipping sync."
fi

# 2. Sync Gradle Cache
if [ -d "${GRADLE_SRC}" ] && [ ! -L "${GRADLE_SRC}" ]; then
    echo "2. Syncing Gradle Cache to NAS..."
    rsync -a --info=progress2 "${GRADLE_SRC}/" "${NAS_DEST}/.gradle/"
else
    echo "ℹ️ Gradle Cache already symlinked or does not exist, skipping sync."
fi

# 3. Create backup names and symlink
echo "3. Creating symbolic links..."

if [ -d "${SDK_SRC}" ] && [ ! -L "${SDK_SRC}" ]; then
    echo "Renaming Sdk -> Sdk_old"
    mv "${SDK_SRC}" "${SDK_SRC}_old"
    echo "Creating symlink for Sdk"
    ln -s "${NAS_DEST}/Sdk" "${SDK_SRC}"
fi

if [ -d "${GRADLE_SRC}" ] && [ ! -L "${GRADLE_SRC}" ]; then
    echo "Renaming .gradle -> .gradle_old"
    mv "${GRADLE_SRC}" "${GRADLE_SRC}_old"
    echo "Creating symlink for .gradle"
    ln -s "${NAS_DEST}/.gradle" "${GRADLE_SRC}"
fi

echo "============================================="
echo "✅ Toolchain migration completed successfully!"
echo "Please verify your Android build compiles."
echo "Once verified, you can reclaim space by running:"
echo "  rm -rf ${SDK_SRC}_old"
echo "  rm -rf ${GRADLE_SRC}_old"
echo "============================================="
