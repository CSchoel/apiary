#!/usr/bin/env bash
# Source - https://stackoverflow.com/a/246128
# Posted by dogbane, modified by community. See post 'Timeline' for change history
# Retrieved 2026-02-03, License - CC BY-SA 4.0
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

ansible-playbook -i  "$SCRIPT_DIR/../inventory/inventory_root.yml" --vault-id "main@${SCRIPT_DIR}/../scripts/gnome-keyring-client.sh" $@
