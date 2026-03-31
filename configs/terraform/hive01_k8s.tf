resource "proxmox_virtual_environment_vm" "h01-bottom-board" {
  provider    = proxmox.hive01
  name        = "h01-bottom-board"
  description = "The bottom board of the beehive - The Kubernetes master node"
  node_name   = "hive01"
  tags        = ["terraform", "debian", "kubernetes"]
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
    import_from  = proxmox_virtual_environment_download_file.debian_cloud_image.id
    interface    = "scsi0"
    discard      = "on"
    size         = 150
  }

  operating_system {
    type = "l26"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    user_data_file_id = proxmox_virtual_environment_file.bottom_board_user_data.id
  }
}

resource "proxmox_virtual_environment_vm" "h01-frame01" {
  provider    = proxmox.hive01
  name        = "h01-frame01"
  description = "A frame in the beehive - a Kubernetes worker node"
  node_name   = "hive01"
  tags        = ["terraform", "debian", "kubernetes"]
  agent {
    # qemu-guest-agent is installed via cloudinit-template
    enabled = true
  }
  cpu {
    cores = 1
    type  = "host"
  }
  memory {
    dedicated = 3072
  }
  network_device {
    bridge = "vmbr0"
  }

  disk {
    datastore_id = "local-lvm"
    import_from  = proxmox_virtual_environment_download_file.debian_cloud_image.id
    interface    = "scsi0"
    discard      = "on"
    size         = 150
  }

  operating_system {
    type = "l26"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    user_data_file_id = proxmox_virtual_environment_file.h01-frame01_user_data.id
  }

  # need to initialize the master node before the worker
  depends_on = [proxmox_virtual_environment_vm.h01-bottom-board]
}

variable "beekeeper_ssh_pubkey" {
  type = string
}

variable "beekeeper_password" {
  type      = string
  sensitive = true
}

variable "k3s_node_token" {
  type      = string
  sensitive = true
}

variable "hive01_root_password" {
  type      = string
  sensitive = true
}

variable "k3s_version" {
  type = string
}

resource "proxmox_virtual_environment_file" "bottom_board_user_data" {
  provider     = proxmox.hive01
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "hive01"

  source_raw {
    data = <<-EOF
    #cloud-config
    hostname: h01-bottom-board
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
    package_reboot_if_required: true
    runcmd: # install k3s
      - "systemctl start qemu-guest-agent"
      - "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${var.k3s_version} K3S_TOKEN=${var.k3s_node_token} sh -"
    EOF

    file_name = "bottom_board_user_data.yaml"
  }
}

resource "proxmox_virtual_environment_file" "h01-frame01_user_data" {
  provider     = proxmox.hive01
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "hive01"

  source_raw {
    data = <<-EOF
    #cloud-config
    hostname: h01-frame01
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
    package_reboot_if_required: true
    runcmd: # install k3s
      - "systemctl start qemu-guest-agent"
      - "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${var.k3s_version} K3S_URL=https://h01-bottom-board:6443 K3S_TOKEN=${var.k3s_node_token} sh -"
    EOF

    file_name = "h01-frame01_user_data.yaml"
  }
}
