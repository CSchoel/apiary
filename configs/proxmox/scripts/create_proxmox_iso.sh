#!/bin/bash
# set -euo pipefail
# reference: https://stackoverflow.com/a/246128/31927360
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PROXMOX_VERSION="9.1-1"
DOWNLOAD_DIR="$(realpath ~/Downloads)"
cd $SCRIPT_DIR/../../cloud-init/scripts/instantiate_template
TEMPLATE_FILE="../../../proxmox/hive01_answerfile.toml.gotmpl"
echo "Instantiating template $(realpath $TEMPLATE_FILE) .."
go run instantiate_template.go $TEMPLATE_FILE

PROXMOX_FILENAME="proxmox-ve_$PROXMOX_VERSION.iso"
PROXMOX_URL="https://enterprise.proxmox.com/iso/$PROXMOX_FILENAME"
PROXMOX_PATH="$DOWNLOAD_DIR/$PROXMOX_FILENAME"

if [ ! -f $PROXMOX_PATH ]; then
    echo "Downloading iso file for Proxmox version $PROXMOX_VERSION .."
    wget -P $DOWNLOAD_DIR $PROXMOX_URL
fi
ANSWER_FILE="${TEMPLATE_FILE%.gotmpl}"
echo "Creating iso with answerfile $(realpath ANSWER_FILE) .."
proxmox-auto-install-assistant prepare-iso $PROXMOX_PATH --fetch-from iso --answer-file $ANSWER_FILE
