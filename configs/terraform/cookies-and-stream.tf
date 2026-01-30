resource "proxmox_vm_qemu" "cookies-and-stream" {
  name        = "cookies-and-stream"
  description = "Debian VM for TV connection"
  node_name   = "hive"
  tags        = ["terraform", "debian"]
  clone {
    vm_id = 900
    full  = true
  }
  agent {
    enabled = true
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
  disk {
    interface    = "scsi0"
    size         = "100G"
    file_format  = "raw"
    datastore_id = "local-lvm"
  }

  operation_system {
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

output "vm_ip_address" {
  description = "IP address of the created VM"
  value       = proxmox_virtual_environment_vm.cookies-and-stream.ipv4_addresses
}
