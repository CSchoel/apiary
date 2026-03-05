#!/bin/bash
set -euo pipefail
# reference: https://stackoverflow.com/a/246128/31927360
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
echo "Instantiating templates..."
cd "$SCRIPT_DIR/instantiate_template"
go get .
go run instantiate_template.go ../../mini-hive/user-data.yml.gotmpl
go run instantiate_template.go ../../mini-hive/network-config.yml.gotmpl
cd -
CONFIG_DIR="$SCRIPT_DIR/../mini-hive"
IMAGE_URL="https://downloads.raspberrypi.com/raspios_lite_arm64/images/raspios_lite_arm64-2025-12-04/2025-12-04-raspios-trixie-arm64-lite.img.xz"
DEVICE=/dev/sdd
MOUNT_POINT=$(lsblk -lo name,size,mountpoints | grep sdd)
echo "WARNING: This wil delete all data on $DEVICE, which has the following partitions:"
echo "$MOUNT_POINT"
read -p "Do you want to overwrite $DEVICE? [y/n]: " response
if [[ $response =~ ^[Yy]$ ]]; then
    echo "Overwriting $DEVICE with the image."
else
    echo "Exiting."
    exit 1
fi

rpi-imager \
    --cli \
    --cloudinit-userdata "$CONFIG_DIR/user-data.yml" \
    --cloudinit-networkconfig "$CONFIG_DIR/network-config.yml" \
    $IMAGE_URL \
    $DEVICE
