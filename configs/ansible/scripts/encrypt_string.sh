#!/bin/bash
# Encrypt a string in the main ansible vault
# Usage: ./encrypt_string.sh
# reference: https://stackoverflow.com/a/246128/31927360
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ansible-vault encrypt_string --vault-id "main@${SCRIPT_DIR}/gnome-keyring-client.sh" -p
