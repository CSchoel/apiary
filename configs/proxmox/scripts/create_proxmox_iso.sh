#!/bin/bash
# Create an iso file for an unattended installation of proxmox
# Usage: create-proxmox-iso.sh [ANSWERFILE_TEMPLATE]
# Note: You will have to supply the proxmox root password for validation
set -euo pipefail
# reference: https://stackoverflow.com/a/246128/31927360
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PROXMOX_VERSION="9.1-1"
OUT_DIR="$SCRIPT_DIR/out"
DATA_PATH="/etc/proxmox-auto-install-assistant"
if [[ $# -eq 0 ]]; then
    TEMPLATE_FILE="$SCRIPT_DIR/../hive01_answerfile.toml.gotmpl"
else
    TEMPLATE_FILE="$1"
fi
ANSWER_FILE="${TEMPLATE_FILE%.gotmpl}"
echo "Instantiating template $(realpath $TEMPLATE_FILE) .."
cd "$SCRIPT_DIR/../../cloud-init/scripts/instantiate_template" && go run instantiate_template.go "$TEMPLATE_FILE"
pwd
cp "$ANSWER_FILE" "$OUT_DIR"
echo "Validating answerfile $ANSWER_FILE .."
docker run -it --rm --mount "type=bind,src=$OUT_DIR,dst=$DATA_PATH" apiary/proxmox-auto-install-assistant:0.1.0 \
    validate-answer --verify-root-password "$DATA_PATH/$(basename "$ANSWER_FILE")" \
    | tee "$OUT_DIR/validation.txt"
# TODO: This is a bit hacky. It seems that validate-answer doesn't yield proper exit codes, but I need to check that.
if [ $(grep -c "Error" "$OUT_DIR/validation.txt") -gt 0 ]
then
    exit 1
fi

echo "Building container for running proxmox-auto-install-assistant .."
DOCKER_BUILDKIT=1 docker build "$SCRIPT_DIR" -t apiary/proxmox-auto-install-assistant:0.1.0

PROXMOX_FILENAME="proxmox-ve_$PROXMOX_VERSION.iso"
PROXMOX_URL="https://enterprise.proxmox.com/iso/$PROXMOX_FILENAME"
PROXMOX_PATH="$OUT_DIR/$PROXMOX_FILENAME"

if [ ! -f "$PROXMOX_PATH" ]; then
    echo "Downloading iso file for Proxmox version $PROXMOX_VERSION .."
    wget -P "$OUT_DIR" "$PROXMOX_URL"
fi
echo "Creating iso with answerfile $(realpath "$ANSWER_FILE") .."
# docker run --rm --mount "type=bind,src=$OUT_DIR,dst=$DATA_PATH" apiary/proxmox-auto-install-assistant:0.1.0 \
#     prepare-iso "$DATA_PATH/$PROXMOX_FILENAME" \
#     --fetch-from iso \
#     --answer-file "$DATA_PATH/$(basename "$ANSWER_FILE")"
