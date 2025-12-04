# Architecture Explanation

### 1. Governance
Management Groups + Resource Groups create isolation and structure.

### 2. Networking
A VNet splits into:
- appgw-subnet → Application Gateway
- vm-subnet → Virtual Machine + k3s

### 3. k3s Kubernetes
k3s deploys a single-node cluster running:
- kubelet
- kube-apiserver
- scheduler
- containerd

### 4. Custom Web App
ConfigMap is injected into nginx pod → no Docker required.

### 5. NodePort
The service exposes port 30731 externally.

### 6. Application Gateway
Routing:
```
Internet → AGW Listener → Routing Rule → Backend Pool (VM) → NodePort (k8s)
```
