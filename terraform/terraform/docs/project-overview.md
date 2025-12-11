# Project Overview — Azure AGW + k3s + Custom App

This project demonstrates an enterprise-like Azure architecture deployed entirely using free-tier resources:

- Landing zone structure  
- Application Gateway v2 + WAF  
- Lightweight Kubernetes cluster (k3s)  
- Custom nginx workload  
- NodePort exposure  
- ConfigMap-based HTML injection  

The project shows how to run container workloads without using AKS and still achieve global ingress via AGW.
