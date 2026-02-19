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
  * Ensure the machine has ethernet access to router before booting.
  * Use the following settings:
    * Management interface: nic0 (needs to be ethernet, not wifi)
    * Hostname (FQDN): `hive.local`
    * IP Address (CIDR): `192.168.178.67/24`
      * This may be pre-filled.
      * It's important to use a valid IP in the subnet of your router here. So if you are unsure, you can just look up the IPv4 address that your router assigns to the machine.
      * The last part `/24` defines the subnet mask. It declares that the first 24 bits are fixed, so the last 8 ones will make up the subnet that the cluster operates in.
    * Gateway: `192.168.178.1` (ip address of your router)
    * DNS Server: `192.168.178.1` (ip address of your router, if it provides a DNS server)
  * Note down root password.
* Access your router configuration and ensure that `hive` always gets assigned the same IP.
* Store Ansible vault secret in GNOME keyring with `configs/ansible/scripts/store_vault_secret_in_keyring.sh`.
* Store the following credentials in a file `❗❗` using `configs/ansible/scripts/encrypt_string.sh`.
  * `proxmox_ansible_password`: The root password of the Proxmox instance on `hive`.
  * `proxmox_api_token_secret`: Just add a dummy value here for now.
* Run the following Ansible configs:
  * `configs/ansible/scripts/ansroot.sh configs/ansible/playbooks/create_ansible_user.yml`
  * `configs/ansible/scripts/ansuser.sh configs/ansible/scripts/create_terraform_proxmox_user.sh`
    * ❗ Save the token that is displayed at the end of this playbook as `proxmox_api_token_secret` in `configs/ansible/vars/credentials.yml` as you will not be able to view it again.
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
* Copy `bottom-board:/etc/rancher/k3s/k3s.yaml` to `~/.kube/config` on your development machine and install `kubectl`.
  * If you have a `k3s` install on your development machine that includes `kubectl`, you also need to add `export KUBECONFIG="${HOME}/.kube/config"` to your `~/.bashrc`. The `kubectl` installed by `k3s` ignores configs in `~/.kube/config` by default.

## Kubernetes cluster

My Kubernetes cluster is currently mostly managed via Helm, using configurations from the [brood chamber repo](https://github.com/CSchoel/brood-chamber).
