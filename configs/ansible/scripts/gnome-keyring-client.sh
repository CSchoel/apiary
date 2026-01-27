#!/bin/bash
# Client script for Ansible to use the GNOME keyring
if [ "$1" != "--vault-id" ] || [ "$#" -ne 2 ]; then
    echo "Usage: $0 --vault-id vaultID"
    exit 1
fi

/usr/bin/secret-tool lookup application ansible-vault vault-id $2
