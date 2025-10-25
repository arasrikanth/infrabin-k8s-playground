# Infrabin Kubernetes Playground

This guide helps you set up a local Kubernetes environment with Infrabin, Istio, and Prometheus monitoring.

## Prerequisites

- [Minikube](https://minikube.sigs.k8s.io/docs/start/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/)

## Setup Instructions

### 1. Start Minikube
```bash
minikube start 
```

### 2. Add Required Helm Repositories
```bash
# pulling latest versions
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

### 3. Install Istio
```bash
# Create and configure istio-system namespace, pulling latest versions
kubectl create namespace istio-system --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install istio-base istio/base -n istio-system
helm upgrade --install istiod istio/istiod -n istio-system
helm upgrade --install istio-gateway istio/gateway -n istio-system
```

### 4. Install Prometheus Stack
```bash
# pulling latest versions
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
# Enable grafana at /grafana sub path 
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --set grafana.grafana.ini.server.root_url="http://localhost/grafana" \
  --set grafana.grafana.ini.server.serve_from_sub_path=true
```

### 5. Configure Namespaces
```bash
# Create and label infrabin namespace
kubectl create namespace infrabin --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace infrabin istio-injection=enabled --overwrite

# Label system namespaces
kubectl label namespace istio-system name=istio-system --overwrite
kubectl label namespace monitoring name=monitoring --overwrite
```

### 6. Deploy Infrabin
```bash
# Validate the deployment with dry-run first
helm upgrade --install infrabin ./charts/infrabin -n infrabin --create-namespace --dry-run

# Proceed with actual installation
helm upgrade --install infrabin ./charts/infrabin -n infrabin --create-namespace

# Wait for deployment
kubectl wait --for=condition=available --timeout=180s deployment -n infrabin infrabin
```

## Validation

### 1. Check System Status
```bash
# View all pods across namespaces
kubectl get pods -A

# Check Horizontal Pod Autoscaler
kubectl get hpa -n infrabin

# View ServiceMonitors
kubectl get servicemonitor -A
```

### 2. Enable External Access
```bash
# Run in a separate terminal window
minikube tunnel
```

### 3. Access the Application
The application will be available at:
- Main endpoint: `http://localhost/`
- Network information: `http://localhost/networks`

### 4. Access Grafana

```bash
# For Mac/Linux
printf "Username: %s\nPassword: %s\n" \
"$(kubectl get secret -n monitoring kube-prometheus-stack-grafana -o jsonpath='{.data.admin-user}' | base64 --decode)" \
"$(kubectl get secret -n monitoring kube-prometheus-stack-grafana -o jsonpath='{.data.admin-password}' | base64 --decode)"

# For Windows PowerShell
Write-Host "Username: $((kubectl get secret -n monitoring kube-prometheus-stack-grafana -o jsonpath='{.data.admin-user}' | base64 -d))"
Write-Host "Password: $((kubectl get secret -n monitoring kube-prometheus-stack-grafana -o jsonpath='{.data.admin-password}' | base64 -d))"
```

- Go to URL: `localhost/grafana`
- Enter username and password
- Click skip if you do not wish to change password

### 5. Import Dashboard

1. Go to **Dashboards → Import**
2. Choose "Upload JSON file" and select the file `infrabin-grafana-dashboard.json`
3. Replace `YOUR_PROMETHEUS_UID` with your actual Prometheus data source UID (found under Settings → Data Sources → Prometheus → UID)
4. Click Import

## Troubleshooting

If you encounter issues:
1. Ensure all pods are running: `kubectl get pods -A`
2. Check pod logs: `kubectl logs -n infrabin <pod-name>`
3. Verify Istio injection: `kubectl get namespace infrabin --show-labels`

## Cleanup

To remove the setup:
```bash
helm uninstall infrabin -n infrabin
helm uninstall kube-prometheus-stack -n monitoring
helm uninstall istio-gateway istiod istio-base -n istio-system
```
````
This is the code block that represents the suggested code change:
```markdown
+-----------------+
                                     |    Grafana     |
                                     |   Dashboard    |
                                     +--------^--------+
                                              |
                                     +--------+--------+
                                     |   Prometheus   |
                                     +--------^--------+
                                              |
+----------+     +------------+     +---------+--------+     +-------------+
|          |     |            |     |  ServiceMonitor  |     |             |
| External |     |   Istio    |     |                 |     |     HPA     |
| Client   +---->|  Gateway   +---->|    Infrabin     |<----+             |
|          |     |            |     |     Service     |     | Auto-scales |
+----------+     +------------+     |                 |     |             |
                                   |   Pod1   Pod2    |     |             |
                                   +-----------------++     +-------------+
                                              ^
                                              |
                                   +----------+---------+
                                   |   NetworkPolicy   |
                                   |    (Optional)     |
                                   +------------------+
```






