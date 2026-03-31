#!/bin/bash
# set -euo pipefail
# reference: https://stackoverflow.com/a/246128/31927360
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PROXMOX_VERSION="9.1-1"
OUT_DIR="$SCRIPT_DIR/out"
cd "$SCRIPT_DIR/../../cloud-init/scripts/instantiate_template"
TEMPLATE_FILE="../../../proxmox/hive01_answerfile.toml.gotmpl"
ANSWER_FILE="${TEMPLATE_FILE%.gotmpl}"
echo "Instantiating template $(realpath $TEMPLATE_FILE) .."
go run instantiate_template.go "$TEMPLATE_FILE"
cp "$ANSWER_FILE" "$OUT_DIR"

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
docker run --rm --mount "type=bind,src=$OUT_DIR,dst=$DATA_PATH" apiary/proxmox-auto-install-assistant:0.1.0 \
    prepare-iso "$DATA_PATH/$PROXMOX_FILENAME" \
    --fetch-from iso \
    --answer-file "$DATA_PATH/$(basename "$ANSWER_FILE")"
