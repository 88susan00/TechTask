# TechTask

A project for deploying a Kubernetes-based monitoring infrastructure using a GitOps approach with ArgoCD.

## Overview

The project automates the deployment of a local Minikube-based Kubernetes cluster with the following components:
- ArgoCD for GitOps application management
- VictoriaMetrics for metrics collection and storage
- Grafana for metrics visualization
- Spam2000 as a test application that generates metrics

## Architecture

```
┌────────────────────────────────────────────────────────┐
│                    Minikube Cluster                    │
├────────────────────────────────────────────────────────┤
│                                                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │           argocd namespace                       │  │
│  │  ┌────────────────────────────────────────────┐  │  │
│  │  │  ArgoCD Server                             │  │  │
│  │  │  - Git synchronization                     │  │  │
│  │  │  - Automated deployment                    │  │  │
│  │  └────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────┘  │
│                                                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │         monitoring namespace                     │  │
│  │  ┌──────────────────┐  ┌──────────────────┐      │  │
│  │  │ VictoriaMetrics  │  │     Grafana      │      │  │
│  │  │ - Metrics scrape │  │ - Visualization  │      │  │
│  │  │ - Storage        │  │ - Dashboards     │      │  │
│  │  └──────────────────┘  └──────────────────┘      │  │
│  └──────────────────────────────────────────────────┘  │
│                                                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │          spam2000 namespace                      │  │
│  │  ┌────────────────────────────────────────────┐  │  │
│  │  │  Spam2000 Deployment                       │  │  │
│  │  │  - Metrics generator                       │  │  │
│  │  │  - Prometheus endpoint /metrics            │  │  │
│  │  └────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────┘  │
│                                                        │
└────────────────────────────────────────────────────────┘
```

## Dependencies

### System requirements

- Operating system: macOS, Linux or Windows with WSL2
- Minimum resources:
    - CPU: 4 cores
    - RAM: 4 GB
    - Disk: 20 GB of free space

### Required software

1. **Minikube** version 1.30.0 or newer
    - Installation: https://minikube.sigs.k8s.io/docs/start/

2. **kubectl** version 1.28.0 or newer
    - Installation: https://kubernetes.io/docs/tasks/tools/

3. **Docker** or another driver supported by Minikube
    - macOS: Docker Desktop
    - Linux: Docker Engine
    - Installation: https://docs.docker.com/get-docker/

4. **Helm** version 3.12.0 or newer (optional, for local testing)
    - Installation: https://helm.sh/docs/intro/install/

5. **Bash** version 4.0 or newer

### Checking dependencies

Run the following commands to check that the required tools are installed:

```bash
minikube version
kubectl version --client
docker --version
helm version
bash --version
```

## Project structure

```
TechTask/
├── apps/
│   ├── monitoring/
│   │   ├── Chart.yaml                     # Helm chart metadata
│   │   ├── values.yaml                    # VictoriaMetrics and Grafana configuration
│   │   ├── Chart.lock                     # Locked dependency versions
│   │   ├── charts/                        # Local copies of Helm charts
│   │   ├── dashboards/                    # Grafana JSON dashboards
│   │   │   ├── cluster.json
│   │   │   └── spam2000.json
│   │   └── templates/                     # Helm templates
│   │       ├── dashboards-configmap.yaml
│   │       └── datasources-configmap.yaml
│   └── spam2000/
│       ├── Chart.yaml                     # Helm chart metadata
│       ├── values.yaml                    # Application configuration
│       └── templates/
│           ├── deployment.yaml
│           └── service.yaml
├── argocd/
│   ├── monitoring.yaml                    # ArgoCD Application for monitoring
│   └── spam2000.yaml                      # ArgoCD Application for spam2000
└── bootstrap/
    ├── main.sh                            # Main deployment script
    ├── install.sh                         # Installs Minikube and ArgoCD
    ├── wait-for-argocd.sh                 # Waits for ArgoCD to be ready
    ├── get-argocd-password.sh             # Retrieves the ArgoCD password
    └── apply-apps.sh                      # Applies ArgoCD Applications
```

In addition to what is shown above, Ingress manifests were added for ArgoCD, Grafana, VictoriaMetrics and spam2000.

## System components

### ArgoCD

ArgoCD is a GitOps controller that automatically keeps the cluster state in sync with the configuration in the Git repository. It is configured with automated sync, self-healing and automatic pruning of resources.

**Configuration:**
- Namespace: `argocd`
- Automated sync: enabled
- Self-heal: enabled
- Prune: enabled
- Source: GitHub repository `88susan00/TechTask`, branch `master`

### VictoriaMetrics

VictoriaMetrics collects, stores and serves metrics in a Prometheus-compatible format.

**Configuration:**
- Helm chart: `victoria-metrics-single` version 0.11.0
- Service type: ClusterIP
- Scrape interval: 10 seconds
- Kubernetes Service Discovery: enabled for automatic discovery of services with Prometheus annotations

**Scrape jobs:**
- `vmagent` - internal VictoriaMetrics metrics
- `kubernetes-apiservers` - Kubernetes API server metrics
- `kubernetes-nodes` - cluster node metrics
- `kubernetes-nodes-cadvisor` - container metrics via cAdvisor
- `kubernetes-service-endpoints` - metrics of services annotated with `prometheus.io/scrape: "true"`
- `kubernetes-service-endpoints-slow` - metrics scraped every 5 minutes
- `kubernetes-services` - blackbox probes of services
- `kubernetes-pods` - metrics of annotated pods
- `spam2000` - dedicated job for the spam2000 namespace
- `monitoring` - dedicated job for the monitoring namespace

### Grafana

Grafana provides a web interface for visualizing metrics from VictoriaMetrics.

**Configuration:**
- Helm chart: `grafana` version 7.3.0
- Service type: ClusterIP
- Admin credentials: `admin` / `admin`
- Sidecar for automatic import of dashboards and datasources

**Dashboards:**
- `cluster.json` - cluster and node metrics
- `spam2000.json` - spam2000 application metrics

**Datasource:**
- VictoriaMetrics at: `http://monitoring-victoria-metrics-single-server.monitoring.svc.cluster.local:8428`

### Spam2000

Spam2000 is a test application that generates metrics in the Prometheus format.

**Configuration:**
- Image: `andriiuni/spam2000:1.1394.355`
- Replicas: 1
- Service type: ClusterIP
- Port: 3000
- Metrics endpoint: `/metrics`
- Prometheus annotations: configured for automatic discovery by VictoriaMetrics

## Installation and launch

### Automated deployment

Run the main bootstrap script to deploy the whole infrastructure automatically:

```bash
cd bootstrap
bash main.sh
```

The script performs the following steps:
1. Starts the Minikube cluster
2. Installs ArgoCD in the `argocd` namespace
3. Waits for the ArgoCD server to be ready
4. Prints the password for ArgoCD access
5. Applies the ArgoCD Application resources for automated application deployment

### Manual deployment

If you need to run the steps separately:

#### Step 1: Start Minikube and install ArgoCD

```bash
bash bootstrap/install.sh
```

#### Step 2: Wait for ArgoCD to be ready

```bash
bash bootstrap/wait-for-argocd.sh
```

#### Step 3: Get the ArgoCD password

```bash
bash bootstrap/get-argocd-password.sh
```

#### Step 4: Apply the ArgoCD Applications

```bash
bash bootstrap/apply-apps.sh
```

### Apple Silicon support

The `install.sh` script automatically detects the system architecture and configures Minikube for Apple Silicon (arm64).

## Verifying the deployment

### Checking the cluster state

Check the state of the cluster nodes:

```bash
kubectl get nodes
```

Expected result: one node in the `Ready` state.

### Checking ArgoCD

Check the state of the ArgoCD pods:

```bash
kubectl get pods -n argocd
```

All pods should be in the `Running` state.

Check the ArgoCD Applications:

```bash
kubectl get applications -n argocd
```

Expected result: two Application resources (`monitoring` and `spam2000`) with the status `Synced` and `Healthy`.

### Checking the monitoring stack

Check the pods in the monitoring namespace:

```bash
kubectl get pods -n monitoring
```

Expected result:
- VictoriaMetrics pods in the `Running` state
- Grafana pods in the `Running` state

Check the services:

```bash
kubectl get svc -n monitoring
```

### Checking Spam2000

Check the spam2000 pod:

```bash
kubectl get pods -n spam2000
```

Check the service:

```bash
kubectl get svc -n spam2000
```

Check that metrics are available:

```bash
kubectl port-forward -n spam2000 svc/spam2000 3000:3000
curl http://localhost:3000/metrics
```

### Accessing the web interfaces

#### ArgoCD UI

Set up port-forwarding:

```bash
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

Open in your browser: `https://localhost:8080`

Credentials:
- Username: `admin`
- Password: get it with `bash bootstrap/get-argocd-password.sh`

#### Grafana UI

Set up port-forwarding:

```bash
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80
```

Open in your browser: `http://localhost:3000`

Credentials:
- Username: `admin`
- Password: `admin`

#### VictoriaMetrics UI

Set up port-forwarding:

```bash
kubectl port-forward -n monitoring svc/monitoring-victoria-metrics-single-server 8428:8428
```

Open in your browser: `http://localhost:8428`

### Checking metrics collection

Check that spam2000 metrics are present in VictoriaMetrics:

```bash
kubectl port-forward -n monitoring svc/monitoring-victoria-metrics-single-server 8428:8428
curl "http://localhost:8428/api/v1/query?query=up{job=\"spam2000\"}"
```

Expected result: a metric with the value `1` for the active endpoint.

## Removal

To remove the whole infrastructure:

```bash
minikube delete
```

Or to remove individual components:

```bash
kubectl delete application -n argocd --all
kubectl delete namespace monitoring spam2000
```

## Troubleshooting

### Minikube issues

If Minikube does not start, check:

```bash
minikube status
minikube logs
```

### ArgoCD sync issues

Check the ArgoCD logs:

```bash
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

Check the Application state:

```bash
kubectl describe application -n argocd monitoring
kubectl describe application -n argocd spam2000
```

### Metrics collection issues

Check the VictoriaMetrics scrape configuration:

```bash
kubectl get configmap -n monitoring monitoring-victoria-metrics-single-server-scrape -o yaml
```

Check the spam2000 service annotations:

```bash
kubectl get svc -n spam2000 spam2000 -o yaml
```

Check the VictoriaMetrics logs:

```bash
kubectl logs -n monitoring -l app.kubernetes.io/name=victoria-metrics-single-server
```

## Additional information

### Configuring scrape intervals

Scrape intervals are configured in `apps/monitoring/values.yaml` under `victoria-metrics-single.server.scrape.config.global.scrape_interval`.

### Adding new dashboards

Add dashboard JSON files to the `apps/monitoring/dashboards/` directory. They will be imported automatically through the ConfigMap and the Grafana sidecar.

### Changing the configuration

All configuration changes are made through Git. After you commit and push to the repository, ArgoCD automatically syncs the changes to the cluster.
