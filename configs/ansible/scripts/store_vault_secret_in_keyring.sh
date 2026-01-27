#!/bin/bash
# Stores a secret given via terminal input in the GNOME keyring
secret-tool store --label='Ansible Vault Key' application ansible-vault vault-id main
