# Debug terraform errors

## Get API calls

In case you need to debug a terraform error that is not immediately obvious, you can run the following command:

```bash
TF_LOG=DEBUG tofu apply
```

## Debugging Proxmox API requests

Setting `TF_LOG=DEBUG` will, among other things, give you details about the HTTP calls issued by the Proxmox provider, resulting in a fairly cryptic string like this:

```plain
2026-02-23T19:30:41.209+0100 [DEBUG] provider.terraform-provider-proxmox_v0.93.0: Sending HTTP Request: Authorization="PVEAPIToken=terraform@pve!terraform-token=********************" User-Agent=Go-http-client/1.1 tf_http_req_method=POST tf_http_trans_id=24efc0a1-f7e4-9cda-5b28-e695fd663e04 tf_resource_type=proxmox_virtual_environment_vm Accept=application/json Content-Type=application/x-www-form-urlencoded tf_http_req_body="acpi=1&agent=enabled%3D1%2Cfstrim_cloned_disks%3D0%2Ctype%3Dvirtio&balloon=0&bios=seabios&boot=order%3Dscsi0%3Bnet0&cicustom=user%3Dlocal%3Asnippets%2Fh02_frame01_user_data.yaml&cores=3&cpu=host&description=A+frame+in+the+beehive+-+a+Kubernetes+worker+node&ide2=file%3Dlocal-lvm%3Acloudinit%2C&ipconfig0=ip%3Ddhcp&keyboard=en-us&memory=11264&name=h02-frame01&net0=model%3Dvirtio%2Cbridge%3Dvmbr0%2Cfirewall%3D0&numa=0&onboot=1&ostype=l26&protection=0&scsi0=file%3Dlocal-lvm%3A0%2Cimport-from%3Dlocal%3Aimport%2Fdebian-13-generic-amd64-20260112-2355.qcow2%2Csize%3D268435456000%2Caio%3Dio_uring%2Cbackup%3D1%2Ciothread%3D0%2Cssd%3D0%2Cdiscard%3Don%2Ccache%3Dnone%2Creplicate%3D1&scsihw=virtio-scsi-pci&sockets=1&tablet=1&tags=debian%3Bkubernetes%3Bterraform&template=0&vmid=101" tf_http_req_uri=/api2/json/nodes/hive02/qemu tf_http_req_version=HTTP/1.1 tf_mux_provider=tf5to6server.v5tov6Server tf_provider_addr=registry.terraform.io/bpg/proxmox @module=proxmox Host=hive02:8006 tf_http_op_type=request @caller=/home/runner/go/pkg/mod/github.com/hashicorp/terraform-plugin-sdk/v2@v2.38.1/helper/logging/logging_http_transport.go:162 Accept-Encoding=gzip Content-Length=776 tf_req_id=d3bf53cc-d14b-6b10-3abd-f9b3b7fbf173 tf_rpc=ApplyResourceChange timestamp="2026-02-23T19:30:41.209+0100"
```

Using some human diligence or LLM magic, you can turn this info into a proper `curl` call:

```bash
export TERRAFORM_TOKEN=your-token-here
curl -X POST "http://hive02:8006/api2/json/nodes/hive02/qemu" \
  -H "Authorization: PVEAPIToken=terraform@pve!terraform-token=$TERRAFORM_TOKEN" \
  -H "User-Agent: Go-http-client/1.1" \
  -H "Accept: application/json" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -L \
  -d "acpi=1" \
  -d "agent=enabled=1,fstrim_cloned_disks=0,type=virtio" \
  -d "balloon=0" \
  -d "bios=seabios" \
  -d "boot=order=scsi0;net0" \
  -d "cicustom=user=local:snippets/h02_frame01_user_data.yaml" \
  -d "cores=3" \
  -d "cpu=host" \
  -d "description=A frame in the beehive - a Kubernetes worker node" \
  -d "ide2=file=local-lvm:cloudinit," \
  -d "ipconfig0=ip=dhcp" \
  -d "keyboard=en-us" \
  -d "memory=11264" \
  -d "name=h02-frame01" \
  -d "net0=model=virtio,bridge=vmbr0,firewall=0" \
  -d "numa=0" \
  -d "onboot=1" \
  -d "ostype=l26" \
  -d "protection=0" \
  -d "scsi0=file=local-lvm:0,import-from=local:import/debian-13-generic-amd64-20260112-2355.qcow2,size=268435456000,aio=io_uring,backup=1,iothread=0,ssd=0,discard=on,cache=none,replicate=1" \
  -d "scsihw=virtio-scsi-pci" \
  -d "sockets=1" \
  -d "tablet=1" \
  -d "tags=debian;kubernetes;terraform" \
  -d "template=0" \
  -d "vmid=101"
```
