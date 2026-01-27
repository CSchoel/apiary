resource "proxmox_vm_qemu" "cookies-and-stream" {
  name        = "cookies-and-stream"
  description = "Debian VM for TV connection"
  target_node = "hive"
  sshkeys     = "TODO"
  agent       = 1
  clone       = "debian-ci"
  cpu {
    cores = 2
  }
  memory = 4096
  vga {
    type = "std"
  }
  disks {
    scsi {
      scsi0 {
        disk {
          size    = "100G"
          storage = "local-lvm"
          discard = false
        }
      }
    }
  }

  network {
    id       = 0
    bridge   = "vmbr0"
    model    = "virtio"
    firewall = false
  }

  ## muss dem Template matchen

  os_type    = "cloud-init"
  ipconfig0  = "ip=dhcp"
  nameserver = "192.168.178.1"
  ciuser     = "tk"
}
