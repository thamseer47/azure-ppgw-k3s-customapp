#cloud-config
package_update: true
packages:
  - curl
  - ca-certificates
runcmd:
  - |
    set -euo pipefail
    echo "Installing k3s..."
    curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644
    # Wait for kubelet to be ready
    for i in $(seq 1 30); do
      sudo kubectl get nodes && break || sleep 5
    done
    echo "Creating k8s manifests for custom nginx..."

    cat > /root/custom-configmap.yaml <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: custom-html
data:
  index.html: |
    <h1 style='color:green;'>This is my Custom Web App deployed on Azure + k3s + AGW!</h1>
EOF

    cat > /root/custom-deployment.yaml <<'EOF'
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
EOF

    cat > /root/custom-service.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  selector:
    app: custom-nginx
  type: NodePort
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
      nodePort: ${nodeport}
EOF

    echo "Applying k8s manifests..."
    sudo kubectl apply -f /root/custom-configmap.yaml
    sudo kubectl apply -f /root/custom-deployment.yaml
    sudo kubectl apply -f /root/custom-service.yaml

    echo "Finished k3s install and app deploy."
