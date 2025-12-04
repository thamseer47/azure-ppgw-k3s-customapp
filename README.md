🌐 Azure Application Gateway + WAF + k3s Kubernetes + Custom Web App  
This project demonstrates a complete cloud-native application deployment using:

- Azure Virtual Networks  
- Application Gateway v2 + WAF  
- Ubuntu VM running k3s Kubernetes  
- Custom nginx web application using ConfigMap  
- NodePort service  
- Basic landing zone governance  
- IAM + optional PIM documentation  

The entire solution works fully on **Azure Free Trial**.

---

 Architecture Overview

``
Client Browser
     ↓
Azure Application Gateway (Public IP)
     ↓   (WAF Inspection + Routing + Health Probes)
Backend Pool → VM Public IP
     ↓
Ubuntu VM
     ↓
k3s Lightweight Kubernetes
     ↓
NodePort Service (30731)
     ↓
nginx Pod
     ↓
Custom HTML Web App
```

---

 Repository Structure

```
k8s/               → Kubernetes manifests
scripts/           → CLI helper scripts
docs/              → Architecture, screenshots, explanations
architecture-diagram.txt → ASCII architecture diagram
README.md          → This file
```

---

# 🧩 Components Used

| Component | Purpose |
|----------|---------|
| Management Groups | Governance & landing zone setup |
| Resource Groups (rg-platform, rg-app) | Resource separation |
| VNet + Subnets | Networking + isolation |
| Ubuntu VM | Hosts k3s cluster |
| k3s Kubernetes | Lightweight container orchestrator |
| ConfigMap | Custom HTML file |
| Deployment | nginx workload |
| Service (NodePort) | External access to Kubernetes |
| Application Gateway | Public routing + WAF |
| IAM | Role-based access |
| PIM (Documented Optional) | Governance design |

---

# 🛠 Step 1 — Deploy VM Using CLI

Script: `scripts/create-vm-cli.sh`

```bash
#!/bin/bash
RG="rg-app"
VM="vm-k3s"
LOC="centralindia"
ADMIN="azureuser"
SIZE="Standard_B1s"

az group create -n $RG -l $LOC

az vm create \
  --resource-group $RG \
  --name $VM \
  --image UbuntuLTS \
  --size $SIZE \
  --admin-username $ADMIN \
  --ssh-key-values ~/.ssh/id_rsa.pub
```

---

# 🛠 Step 2 — Install k3s

Script: `scripts/deploy-k3s.sh`

```bash
#!/bin/bash
curl -sfL https://get.k3s.io | sh -
sudo kubectl get nodes
```

---

# 🛠 Step 3 — Deploy Custom Web App

### Create ConfigMap
File: `k8s/configmap-index-html.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: custom-html
data:
  index.html: |
    <h1 style='color:green;'>This is my Custom Web App deployed on Azure + k3s + AGW!</h1>
```

### Create Deployment
File: `k8s/custom-nginx.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: custom-nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: custom-nginx
  template:
    metadata:
      labels:
        app: custom-nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        volumeMounts:
        - name: html
          mountPath: /usr/share/nginx/html/index.html
          subPath: index.html
      volumes:
      - name: html
        configMap:
          name: custom-html
```

### Apply changes

```bash
sudo kubectl apply -f k8s/configmap-index-html.yaml
sudo kubectl apply -f k8s/custom-nginx.yaml
sudo kubectl expose deployment custom-nginx --port=80 --type=NodePort --name=nginx
```

Check NodePort:

```bash
sudo kubectl get svc nginx
```

---

# 🛡 Step 4 — Configure Application Gateway v2 + WAF

### Backend pool  
- Target type: **IP Address**  
- IP: `<VM_PUBLIC_IP>`

### Backend settings  
- Protocol: HTTP  
- Port: **30731**  

### Health probe  
- Port: **30731**  
- Path: `/`

### Listener & Rule  
- Listener → Route → Backend  

---

# 🧪 Step 5 — Testing

### On VM
```bash
curl http://127.0.0.1:30731
```

### Browser test
```
http://<APPLICATION_GATEWAY_PUBLIC_IP>
```

Expected output:

**This is my Custom Web App deployed on Azure + k3s + AGW!**

---

# 📜 Documentation

Detailed docs inside `/docs` folder:

- **project-overview.md** → Interview summary  
- **architecture-explanation.md** → Deep-dive explanation  
- **pim-governance.md** → Optional PIM governance  
- **screenshots-checklist.md** → Things to include in GitHub README  

---

# 🎓 Interview Summary

```
Designed an Azure landing zone with Application Gateway v2 + WAF integrated to a Kubernetes workload running on k3s in a lightweight VM. Deployed a custom nginx-based web app using ConfigMaps, exposed via NodePort, and routed through AGW. Implemented strong IAM governance and documented PIM for JIT role elevation.
```

---

# ⭐ Status: Completed ✔  
Your app is now globally accessible through Application Gateway with WAF protection and running inside Kubernetes.

