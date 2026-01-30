# references:
# - https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm
# - https://www.youtube.com/watch?v=8D2lN7MEavM
# - https://www.youtube.com/watch?v=sJlnXwZDdso
# - https://registry.terraform.io/providers/bpg/proxmox/latest/docs/guides/cloud-image
resource "proxmox_vm_qemu" "cookies-and-stream" {
  name        = "cookies-and-stream"
  description = "Debian VM for TV connection"
  node_name   = "hive"
  tags        = ["terraform", "debian"]
  # clone existing VM
  # clone {
  #   vm_id = 900
  #   full  = true
  # }
  agent {
    # TODO: Set to true once we have qemu-guest-agent installed in cloudinit-template
    enabled = false
  }
  cpu {
    cores = 2
    type  = "host"
  }
  memory {
    dedicated = 4096
  }
  network_device {
    bridge = "vmbr0"
  }
  # vga {
  #   type = "std"
  # }
  # create a new scsi disk
  # disk {
  #   interface    = "scsi0"
  #   size         = "100G"
  #   file_format  = "raw"
  #   datastore_id = "local-lvm"
  # }
  disk {
    datastore_id = "local-lvm"
    import_from  = proxmox_virtual_environment_download_file.debian_cloud_image.id
    interface    = "scsi0"
    # iothread     = true
    discard = "on"
    size    = 100
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
    user_account {
      keys     = [var.ssh_public_key]
      username = "chris"
      password = var.vm_password
    }
  }
}

resource "proxmox_virtual_environment_download_file" "debian_cloud_image" {
  content_type = "import"
  datastore_id = "local"
  node_name    = "hive"
  url          = "https://cloud.debian.org/images/cloud/trixie/20260112-2355/debian-13-generic-amd64-20260112-2355.qcow2"
}

output "vm_ip_address" {
  description = "IP address of the created VM"
  value       = proxmox_virtual_environment_vm.cookies-and-stream.ipv4_addresses
}
