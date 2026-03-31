# references:
# - https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm
# - https://www.youtube.com/watch?v=8D2lN7MEavM
# - https://www.youtube.com/watch?v=sJlnXwZDdso
# - https://registry.terraform.io/providers/bpg/proxmox/latest/docs/guides/cloud-image
# - https://blog.konpat.me/dev/2019/03/11/setting-up-lxc-for-intel-gpu-proxmox.html
resource "proxmox_virtual_environment_container" "cookies-and-stream" {
  provider     = proxmox.hive01
  description  = "Debian VM for TV connection"
  node_name    = "hive01"
  tags         = ["terraform", "debian"]
  unprivileged = true
  cpu {
    cores = 2
  }
  memory {
    dedicated = 8192
  }
  network_interface {
    name   = "veth0"
    bridge = "vmbr0"
  }
  disk {
    datastore_id = "local-lvm"
    size         = 100
  }
  operating_system {
    template_file_id = proxmox_virtual_environment_download_file.h01_debian_cloud_image_lxc.id
    type             = "debian"
  }

  # device_passthrough {
  #   # TODO
  # }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    hostname = "cookies-and-stream"
    user_account {
      keys = [var.beekeeper_ssh_pubkey]
    }
  }
}

resource "proxmox_virtual_environment_download_file" "h01_debian_cloud_image_lxc" {
  provider     = proxmox.hive01
  content_type = "vztmpl"
  datastore_id = "local"
  node_name    = "hive01"
  url          = "https://fra1lxdmirror01.do.letsbuildthe.cloud/images/debian/trixie/amd64/default/20260318_05:24/rootfs.tar.xz"
}
