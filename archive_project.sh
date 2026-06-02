#!/bin/bash

# Configuration
NAS_ROOT="/media/neo/NAS1"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GODOT_DIR="${PROJECT_DIR}/horde-of-horrors-godot"

SNAPSHOTS_DIR="${NAS_ROOT}/Snapshots"
BUILDS_DIR="${NAS_ROOT}/HordeOfHorrors_Builds"
ASSETS_DIR="${NAS_ROOT}/HordeOfHorrors_SourceAssets"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo "============================================="
echo "  Horde of Horrors Project Archive Utility   "
echo "============================================="
echo "Project Path: ${PROJECT_DIR}"
echo "NAS Path:     ${NAS_ROOT}"
echo "============================================="

# Ensure target directories exist
mkdir -p "${SNAPSHOTS_DIR}" "${BUILDS_DIR}" "${ASSETS_DIR}"

function show_menu() {
    echo "1) Create timestamped project snapshot (Zip)"
    echo "2) Scan and archive new Android builds (.apk)"
    echo "3) Clean up old snapshots (Keep last 5)"
    echo "4) Run all (Snapshot + Archive APKs + Clean)"
    echo "5) Exit"
    echo -n "Choose an option: "
}

function create_snapshot() {
    echo "Creating timestamped project snapshot..."
    ZIP_NAME="horde_of_horrors_snapshot_${TIMESTAMP}.zip"
    ZIP_PATH="${SNAPSHOTS_DIR}/${ZIP_NAME}"
    
    # Zip the project excluding temporary cache directories (.godot, .venv, etc.)
    cd "${PROJECT_DIR}"
    zip -r "${ZIP_PATH}" . -x "*.godot/*" -x "*.venv/*" -x "*.git/*" -x "*/.import/*" -x "*.apk" -x "*.idsig" > /dev/null
    
    if [ $? -eq 0 ]; then
        echo "✅ Snapshot created: ${ZIP_NAME} ($(du -sh "${ZIP_PATH}" | cut -f1))"
    else
        echo "❌ Failed to create snapshot!"
    fi
}

function archive_apks() {
    echo "Scanning for new APK files..."
    found_apks=0
    
    # Find all APK files in the Godot project directory
    while IFS= read -r apk_path; do
        if [ -f "$apk_path" ]; then
            filename=$(basename "$apk_path")
            # Rename with timestamp to prevent overwriting older builds
            new_filename="${TIMESTAMP}_${filename}"
            echo "Archiving: ${filename} -> ${new_filename}"
            mv "$apk_path" "${BUILDS_DIR}/${new_filename}"
            
            # Also move corresponding .idsig files if they exist
            sig_path="${apk_path}.idsig"
            if [ -f "$sig_path" ]; then
                mv "$sig_path" "${BUILDS_DIR}/${new_filename}.idsig"
            fi
            
            found_apks=$((found_apks + 1))
        fi
    done < <(find "${GODOT_DIR}" -maxdepth 2 -name "*.apk")
    
    if [ $found_apks -gt 0 ]; then
        echo "✅ Successfully archived ${found_apks} build(s) to ${BUILDS_DIR}."
    else
        echo "ℹ️ No new APK builds found in ${GODOT_DIR}."
    fi
}

function clean_old_snapshots() {
    echo "Checking for old snapshots in ${SNAPSHOTS_DIR}..."
    # List snapshots sorted by time, skip the first 5 (newest), and delete the rest
    cd "${SNAPSHOTS_DIR}"
    count=$(ls -1 horde_of_horrors_snapshot_*.zip 2>/dev/null | wc -l)
    
    if [ "$count" -gt 5 ]; then
        echo "Found ${count} snapshots. Keeping the 5 most recent..."
        ls -t horde_of_horrors_snapshot_*.zip | tail -n +6 | while read -r old_zip; do
            echo "Deleting old snapshot: ${old_zip}"
            rm "${old_zip}"
        done
        echo "✅ Cleanup complete."
    else
        echo "ℹ️ Only ${count} snapshots found. No cleanup needed."
    fi
}

# Non-interactive mode if argument is passed, otherwise show menu
if [ ! -z "$1" ]; then
    case "$1" in
        "snapshot") create_snapshot ;;
        "apks") archive_apks ;;
        "clean") clean_old_snapshots ;;
        "all") create_snapshot; archive_apks; clean_old_snapshots ;;
        *) echo "Usage: $0 [snapshot|apks|clean|all]" ;;
    esac
    exit 0
fi

while true; do
    show_menu
    read -r opt
    case $opt in
        1) create_snapshot ;;
        2) archive_apks ;;
        3) clean_old_snapshots ;;
        4) create_snapshot; archive_apks; clean_old_snapshots ;;
        5) echo "Goodbye!"; exit 0 ;;
        *) echo "Invalid option." ;;
    esac
    echo ""
done
