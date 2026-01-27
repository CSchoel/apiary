## Grub

* `nano /etc/default/grub`
    ```plain
    GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt pcie_acs_override=downstream,multifunction initcall_blacklist=sysfb_init video=simplefb:off video=vesafb:off video=efifb:off video=vesa:off disable_vga=1 vfio_iommu_type1.allow_unsafe_interrupts=1 kvm.ignore_msrs=1 modprobe.blacklist=radeon,nouveau,nvidia,nvidiafb,nvidia-gpu,snd_hda_intel,snd_hda_codec_hdmi,i915"
    ```
* `update-grub`

## Modules

* `nano /etc/modules`
    ```plain
    # Modules required for PCI passthrough
    vfio
    vfio_iommu_type1
    vfio_pci
    vfio_virqfd
    ```
* `update-initramfs -u -k all`
* Reboot proxmox
* `dmesg | grep -e DMAR -e IOMMU` should show `[0.067203] DMAR: IOMMU enabled`

## VM

* On proxmox: `lspci -nnv | grep VGA`, check start of line (e.g. `00:02.0`)
* Add Hardware to VM:
  * PCI Device
  * Raw device
  * Select `0000.something` where `something` is the output of the `lspci` command.
* In VM:
  * `sudo lspci -nnv | grep VGA`
  * `cd /dev/dri && ls -la | grep render`
