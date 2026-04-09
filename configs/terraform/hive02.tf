resource "proxmox_virtual_environment_download_file" "h02_debian_cloud_image" {
  provider     = proxmox.hive02
  content_type = "import"
  datastore_id = "local"
  node_name    = "hive02"
  url          = "https://cloud.debian.org/images/cloud/trixie/20260112-2355/debian-13-generic-amd64-20260112-2355.qcow2"
  overwrite    = false # don't check if the image still exists in case it has already been downloaded
}

resource "proxmox_virtual_environment_vm" "h02-bottom-board" {
  provider    = proxmox.hive02
  name        = "h02-bottom-board"
  description = "The bottom board of the beehive - The Kubernetes master node"
  node_name   = "hive02"
  tags        = ["terraform", "debian", "kubernetes"]
  lifecycle {
    prevent_destroy = true
  }
  agent {
    # qemu-guest-agent is installed via cloudinit-template
    enabled = true
  }
  cpu {
    cores = 1
    type  = "host"
  }
  memory {
    dedicated = 4096
  }
  network_device {
    bridge = "vmbr0"
  }

  disk {
    datastore_id = "local-lvm"
    import_from  = proxmox_virtual_environment_download_file.h02_debian_cloud_image.id
    interface    = "scsi0"
    discard      = "on"
    size         = 100
  }

  # attached disks from data VM
  disk {
    datastore_id      = proxmox_virtual_environment_vm.h02-data.disk[0].datastore_id
    path_in_datastore = proxmox_virtual_environment_vm.h02-data.disk[0].path_in_datastore
    file_format       = proxmox_virtual_environment_vm.h02-data.disk[0].file_format
    size              = proxmox_virtual_environment_vm.h02-data.disk[0].size
    discard           = proxmox_virtual_environment_vm.h02-data.disk[0].discard
    interface         = "scsi1"
  }

  operating_system {
    type = "l26"
  }

  initialization {
    ip_config {
      ipv4 {
        # Ensure that this is outside the range of IPs that your router distributes with DHCP
        address = "192.168.178.203/24"
        gateway = "192.168.178.1"
      }
    }
    user_data_file_id = proxmox_virtual_environment_file.h02_bottom_board_user_data.id
  }
}

resource "proxmox_virtual_environment_vm" "h02-frame01" {
  provider    = proxmox.hive02
  name        = "h02-frame01"
  description = "A frame in the beehive - a Kubernetes worker node"
  node_name   = "hive02"
  tags        = ["terraform", "debian", "kubernetes"]
  lifecycle {
    prevent_destroy = true
  }
  agent {
    # qemu-guest-agent is installed via cloudinit-template
    enabled = true
  }
  cpu {
    cores = 3
    type  = "host"
  }
  memory {
    dedicated = 11264
  }
  network_device {
    bridge = "vmbr0"
  }

  disk {
    datastore_id = "local-lvm"
    import_from  = proxmox_virtual_environment_download_file.h02_debian_cloud_image.id
    interface    = "scsi0"
    discard      = "on"
    size         = 100
  }

  # attached disks from data VM
  disk {
    datastore_id      = proxmox_virtual_environment_vm.h02-data.disk[1].datastore_id
    path_in_datastore = proxmox_virtual_environment_vm.h02-data.disk[1].path_in_datastore
    file_format       = proxmox_virtual_environment_vm.h02-data.disk[1].file_format
    size              = proxmox_virtual_environment_vm.h02-data.disk[1].size
    discard           = proxmox_virtual_environment_vm.h02-data.disk[1].discard
    interface         = "scsi1"
  }

  operating_system {
    type = "l26"
  }

  initialization {
    ip_config {
      ipv4 {
        # Ensure that this is outside the range of IPs that your router distributes with DHCP
        address = "192.168.178.204/24"
        gateway = "192.168.178.1"
      }
    }
    user_data_file_id = proxmox_virtual_environment_file.h02_frame01_user_data.id
  }

  # need to initialize the master node before the worker
  depends_on = [proxmox_virtual_environment_vm.h02-bottom-board]
}

# variable "beekeeper_ssh_pubkey" {
#   type = string
# }

# variable "beekeeper_password" {
#   type      = string
#   sensitive = true
# }

# variable "k3s_node_token" {
#   type      = string
#   sensitive = true
# }

# This is just a dummy VM to hold the data disks that should persist
# even after their VM was deleted.
resource "proxmox_virtual_environment_vm" "h02-data" {
  provider  = proxmox.hive02
  node_name = "hive02"
  started   = false
  on_boot   = false

  lifecycle {
    prevent_destroy = true
  }

  # Data disk for bottom-board
  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    discard      = "on"
    size         = 100
    file_format  = "raw"
  }

  # Data disk for frame01
  disk {
    datastore_id = "local-lvm"
    interface    = "scsi1"
    discard      = "on"
    size         = 100
    file_format  = "raw"
  }
}

resource "proxmox_virtual_environment_storage_lvmthin" "h02_frame01_kube_data" {
  provider = proxmox.hive02
  id       = "h02-f01-lvmthin"
  nodes    = ["h02-frame01"]

  volume_group = "pve" # can be found with `vgs`
  thin_pool    = "kube-data-h02-f01"

  content = ["rootdir"]
}

variable "hive02_root_password" {
  type      = string
  sensitive = true
}

resource "proxmox_virtual_environment_file" "h02_bottom_board_user_data" {
  provider     = proxmox.hive02
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "hive02"

  source_raw {
    data = <<-EOF
    #cloud-config
    hostname: h02-bottom-board
    keyboard:
      layout: de
    users:
      - name: beekeeper
        passwd: '${var.beekeeper_password}'
        lock_passwd: false
        ssh_authorized_keys: ['${var.beekeeper_ssh_pubkey}']
        sudo: "ALL=(ALL) ALL"
        shell: /bin/bash
    locale: en_US
    ssh_pwauth: False
    package_update: true # apt update
    packages:
      - qemu-guest-agent
      - open-iscsi  # required for longhorn
    package_reboot_if_required: true
    runcmd: # install k3s
      - "systemctl start qemu-guest-agent"
      - "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${var.k3s_version} K3S_TOKEN=${var.k3s_node_token} sh -"
    EOF

    file_name = "h02_bottom_board_user_data.yaml"
  }
}

resource "proxmox_virtual_environment_file" "h02_frame01_user_data" {
  provider     = proxmox.hive02
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "hive02"

  source_raw {
    data = <<-EOF
    #cloud-config
    hostname: h02-frame01
    keyboard:
      layout: de
    users:
      - name: beekeeper
        passwd: '${var.beekeeper_password}'
        lock_passwd: false
        ssh_authorized_keys: ['${var.beekeeper_ssh_pubkey}']
        sudo: "ALL=(ALL) ALL"
        shell: /bin/bash
    locale: en_US
    ssh_pwauth: False
    package_update: true # apt update
    packages:
      - qemu-guest-agent
      - open-iscsi  # required for longhorn
    package_reboot_if_required: true
    runcmd: # install k3s
      - "systemctl start qemu-guest-agent"
      - "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${var.k3s_version} K3S_URL=https://h02-bottom-board:6443 K3S_TOKEN=${var.k3s_node_token} sh -"
    EOF

    file_name = "h02_frame01_user_data.yaml"
  }
}
