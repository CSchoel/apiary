# Known issues

## Cookies and stream

The cookies-and-stream VM will only be able to output audio via HDMI on the first startup.
If it is ever restarted, it will loose the HDMI audio output in the system settings.
proxmox hdmi audio
### Reason

It seems that the HD audio PCI device [does not support resetting](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Passing_through_a_device_that_does_not_support_resetting).
There are a [few](https://www.reddit.com/r/Proxmox/comments/1hbag7u/successfull_audio_and_video_passthrough_on_n100/) [posts](https://www.reddit.com/r/Proxmox/comments/19bxw3k/pci_passthrough_hdmi_audio_disappears_after_vm/) out there that describe the exact same problem.

### Workaround

There is a workaround [posted on GitHub](https://github.com/xiongyw/docs/blob/master/pve-8.4-1_hp-elitedesk-800-g4-dm.md) that involves removing the PCI device and then performing a scan to get them back.
However, I could not get this to work for my setup and it also messes with the IOMMU groups of the devices.

For now, I therefore only pause the VM and never actually reboot it.
Another option could be a hardware solution:
Since the audio jack output of the machine still works after reboot, I could just connect that to the line-in of the TV. 🤷
