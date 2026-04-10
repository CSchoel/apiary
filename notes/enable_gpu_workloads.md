# How to enable (NVIDIA) GPU workloads on k3s

Reference: https://kubernetes.io/docs/tasks/manage-gpus/scheduling-gpus/

* Install `nvidia-container-toolkit`
* `sudo nvidia-ctk runtime configure --runtime=containerd`
* `sudo systemctl restart containerd`
* Deploy `nvidia-device-plugin` (see [configs/kubernetes/local-k8s/base/ollama/nvidia-k8s-device-plugin.yaml](../configs/kubernetes/local-k8s/base/ollama/nvidia-k8s-device-plugin.yaml))
