# Apiary

This project contains the code I use to set up and maintain my private cloud for self-hosting.
It employs the following principles:

* 🏗️ Infrastructure as code: Everything should be stored in machine-readable files.
* 🕵️ No hidden steps: Even if my house were to burn down, I want to be able to get back to a running system within a few hours without having to Google anything.
* 🔒 No credentials: Should be obvious, but I don't even want to put encrypted passwords in this repo. If that means I have to write custom code to render go templates, I will.

The setup is specific to my hardware, so it might not be all that interesting to anyone else, but I'm keeping it here to show off my cool stuff and as a potential learning resource for people that also want to set up a local cluster.

## Hardware

I'm just using what I have available, so we have a bit of a hodgepodge situation regarding hardware:

* `hive`: Beelink Mini S12 Pro.
* `mellifera`: An old Raspberry Pi 3 B.

## VMs

Since I want to use `hive` for watching YouTube videos on my TV, I want it to be isolated from my Kubernetes cluster.
Therefore, I'm using Proxmox to provide a VM with iGPU passthrough for powering the TV and another one to run workloads on the Kubernetes cluster.
`mellifera` is super small, so I'm just using that bare metal.

## Workloads

Currently I have the following workloads planned:

* LanguageTool server.
* Private GitLab instance (if that works out resource-wise).

## Setup instructions

* Download the latest iso for Proxmox, create a bootable USB and install it on `hive`.
  * Default settings are fine.
  * Note down root password.
* Store Ansible vault secret in GNOME keyring with `configs/ansible/scripts/store_vault_secret_in_keyring.sh`.
* Set up a terraform user and create an API token with `configs/ansible/scripts/create_terraform_proxmox_user.sh`.
  * 🚧 TODO: This will be turned into an Ansible playbook later.
* Store the following two credentials in a file `configs/ansible/vars/credentials.yml` using `configs/ansible/scripts/encrypt_string.sh`.
  * `proxmox_api_token_secret`: The secret of the API token you generated in the last command.
  * `proxmox_ansible_password`: The root password of the Proxmox instance on `hive`.
* Run `configs/ansible/scripts/ansroot.sh configs/ansible/playbooks/allow_ssh_as_root.yml` to allow SSH-ing into the Proxmox root user with your SSH key.
* [Install terraform](https://developer.hashicorp.com/terraform/install) on your development machine.
* Add the following variables to `configs/terraform/credentials.auto.tfvars`:
  * `proxmox_endpoint` the endpoint where to find your proxmox server.
  * `proxmox_api_token` the full API token for Proxmox with username and secret.
* Run `terraform init` in `configs/terraform`
* Follow the instructions in [notes/igpu_passthrough.md](notes/igpu_passthrough.md) to prepare iGPU passthrough on the Proxmox host side.
  * 🚧 TODO: This will be turned into an Ansible playbook later.
* Follow the instructions in [notes/enable_snippets.md](notes/enable_snippets.md) to allow uploading snippets to Proxmox.
* [Install go](https://go.dev/doc/install) on your development machine.
* Run `go run configs/cloud-init/cookies-and-stream/instantiate_templates.go configs/cloud-init/cookies-and-stream/user-data.yml.gotmpl` to provide a password to the cloud-init user data file.
  * 🚧 TODO: This will be replaced by putting the cloud-init config directly into the Terraform config and using tfvars.
* Run `terraform apply`. This should already set up all VMs on Proxmox, including the iGPU passthrough.
