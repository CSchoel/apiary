# references:
# - https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm
# - https://www.youtube.com/watch?v=8D2lN7MEavM
# - https://www.youtube.com/watch?v=sJlnXwZDdso
# - https://registry.terraform.io/providers/bpg/proxmox/latest/docs/guides/cloud-image
resource "proxmox_virtual_environment_vm" "cookies-and-stream" {
  name        = "cookies-and-stream"
  description = "Debian VM for TV connection"
  node_name   = "hive"
  tags        = ["terraform", "debian"]
  agent {
    # qemu-guest-agent is installed via cloudinit-template
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
    user_data_file_id = proxmox_virtual_environment_file.cloudinit_user_data.id
  }
}

resource "proxmox_virtual_environment_file" "cloudinit_user_data" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "hive"
  source_file {
    path = "../cloud-init/cookies-and-stream/user-data.yml"
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
