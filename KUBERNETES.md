# ScarletDME Kubernetes Deployment Guide

This guide explains how to build and deploy ScarletDME on Kubernetes using the provided Dockerfile and Helm chart.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Building the Docker Image](#building-the-docker-image)
- [Pushing to a Container Registry](#pushing-to-a-container-registry)
- [Deploying with Helm](#deploying-with-helm)
- [Accessing ScarletDME](#accessing-scarletdme)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)

## Prerequisites

- Docker or compatible container runtime
- Kubernetes cluster (1.19+)
- Helm 3.2.0+
- kubectl configured to access your cluster

## Building the Docker Image

The Dockerfile uses a multi-stage build with Alpine Linux for a minimal, production-ready image.

### Build the image

```bash
docker build -t scarletdme/scarletdme:latest .
```

### Build with a specific tag

```bash
docker build -t scarletdme/scarletdme:1.0.0 .
```

### Test the image locally

```bash
docker run -d -p 4242:4242 -p 4243:4243 --name scarletdme-test scarletdme/scarletdme:latest
```

Check if it's running:

```bash
docker ps
docker logs scarletdme-test
```

Stop and remove the test container:

```bash
docker stop scarletdme-test
docker rm scarletdme-test
```

## Pushing to a Container Registry

### Docker Hub

```bash
# Tag the image
docker tag scarletdme/scarletdme:latest your-dockerhub-username/scarletdme:latest

# Login to Docker Hub
docker login

# Push the image
docker push your-dockerhub-username/scarletdme:latest
```

### GitHub Container Registry (ghcr.io)

```bash
# Tag the image
docker tag scarletdme/scarletdme:latest ghcr.io/your-github-username/scarletdme:latest

# Login to GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u your-github-username --password-stdin

# Push the image
docker push ghcr.io/your-github-username/scarletdme:latest
```

### Private Registry

```bash
# Tag the image
docker tag scarletdme/scarletdme:latest registry.example.com/scarletdme:latest

# Login to your registry
docker login registry.example.com

# Push the image
docker push registry.example.com/scarletdme:latest
```

## Deploying with Helm

### Quick Start

Deploy with default settings:

```bash
helm install scarletdme ./helm/scarletdme
```

### Deploy with Custom Values

Create a `values.yaml` file:

```yaml
image:
  repository: your-registry/scarletdme
  tag: "1.0.0"
  pullPolicy: Always

service:
  type: LoadBalancer

persistence:
  enabled: true
  size: 20Gi
  storageClassName: standard

resources:
  limits:
    cpu: 2000m
    memory: 2Gi
  requests:
    cpu: 500m
    memory: 512Mi

scarletdme:
  numUsers: 50
  sortMem: 8192
```

Deploy:

```bash
helm install scarletdme ./helm/scarletdme -f values.yaml
```

### Deploy to a Specific Namespace

```bash
# Create namespace
kubectl create namespace scarletdme

# Deploy
helm install scarletdme ./helm/scarletdme \
  --namespace scarletdme \
  --create-namespace
```

### Deploy with NodePort Service

```bash
helm install scarletdme ./helm/scarletdme \
  --set service.type=NodePort
```

## Accessing ScarletDME

### Using Port-Forward (Development)

Forward both ports to your local machine:

```bash
kubectl port-forward service/scarletdme 4242:4242 4243:4243
```

Now you can connect to:
- **QMServer (Telnet)**: `localhost:4242`
- **QMClient (API)**: `localhost:4243`

### Using NodePort

Get the node port and node IP:

```bash
# Get NodePort
kubectl get svc scarletdme -o jsonpath='{.spec.ports[?(@.name=="qmclient")].nodePort}'

# Get Node IP
kubectl get nodes -o wide
```

Connect to: `<NODE_IP>:<NODE_PORT>`

### Using LoadBalancer

Get the external IP:

```bash
kubectl get svc scarletdme
```

Wait for the EXTERNAL-IP to be assigned, then connect to:
- **QMClient (API)**: `<EXTERNAL-IP>:4243`
- **QMServer (Telnet)**: `<EXTERNAL-IP>:4242`

### Using Ingress

Enable ingress in your values file:

```yaml
ingress:
  enabled: true
  className: nginx
  hosts:
    - host: scarletdme.example.com
      paths:
        - path: /
          pathType: Prefix
```

## Configuration

### Ports

- **4242**: QMServer (Telnet connections)
- **4243**: QMClient (API connections)

### Persistence

By default, persistence is enabled and data is stored in a 10Gi PVC mounted at `/usr/qmsys`.

To disable persistence (not recommended for production):

```bash
helm install scarletdme ./helm/scarletdme --set persistence.enabled=false
```

### ScarletDME Configuration

The configuration is managed via ConfigMap. Key parameters:

- `QMSYS`: Installation path (default: `/usr/qmsys`)
- `GRPSIZE`: Group size (default: `2`)
- `NUMUSERS`: Number of users (default: `10`)
- `SORTMEM`: Sort memory in KB (default: `4096`)

Example custom configuration:

```yaml
scarletdme:
  numUsers: 100
  sortMem: 8192
  extraConfig:
    MAXIDLEN: "32"
    DEADLOCK: "5"
```

### Resource Limits

Adjust based on your workload:

```yaml
resources:
  limits:
    cpu: 4000m
    memory: 4Gi
  requests:
    cpu: 1000m
    memory: 1Gi
```

### High Availability

For production deployments with multiple replicas:

```yaml
replicaCount: 3

podDisruptionBudget:
  enabled: true
  minAvailable: 2

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
```

## Upgrading

Update your deployment:

```bash
helm upgrade scarletdme ./helm/scarletdme -f values.yaml
```

Upgrade with a new image version:

```bash
helm upgrade scarletdme ./helm/scarletdme \
  --set image.tag=1.1.0 \
  --reuse-values
```

## Rollback

If something goes wrong, rollback to the previous release:

```bash
helm rollback scarletdme
```

Rollback to a specific revision:

```bash
helm rollback scarletdme 2
```

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -l app.kubernetes.io/name=scarletdme
```

### View Pod Logs

```bash
kubectl logs -l app.kubernetes.io/name=scarletdme --tail=100 -f
```

### Describe Pod

```bash
kubectl describe pod <pod-name>
```

### Execute Commands in Pod

```bash
# Get a shell
kubectl exec -it <pod-name> -- /bin/bash

# Check ScarletDME status
kubectl exec -it <pod-name> -- /usr/qmsys/bin/qm -status
```

### Check ConfigMap

```bash
kubectl get configmap scarletdme -o yaml
```

### Check PVC

```bash
kubectl get pvc
kubectl describe pvc scarletdme
```

### Common Issues

#### Pod in CrashLoopBackOff

Check logs for errors:
```bash
kubectl logs <pod-name> --previous
```

#### PVC Not Binding

Check if a StorageClass is available:
```bash
kubectl get storageclass
```

Set a specific StorageClass:
```bash
helm upgrade scarletdme ./helm/scarletdme \
  --set persistence.storageClassName=standard
```

#### Can't Connect to Service

Check if the service is running:
```bash
kubectl get svc scarletdme
kubectl get endpoints scarletdme
```

## Uninstalling

Remove the Helm release:

```bash
helm uninstall scarletdme
```

Delete the namespace (if created):

```bash
kubectl delete namespace scarletdme
```

**Note**: PVCs are not automatically deleted. To delete them:

```bash
kubectl delete pvc <pvc-name>
```

## Production Checklist

- [ ] Use a specific image tag (not `latest`)
- [ ] Enable persistence with adequate storage
- [ ] Configure appropriate resource limits
- [ ] Set up monitoring and logging
- [ ] Configure backups for persistent data
- [ ] Use secrets for sensitive data
- [ ] Enable Pod Disruption Budget for HA
- [ ] Configure network policies if needed
- [ ] Use a LoadBalancer or Ingress for external access
- [ ] Test disaster recovery procedures

## Additional Resources

- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [ScarletDME Documentation](https://scarlet.deltasoft.com)
- [ScarletDME GitHub](https://github.com/geneb/ScarletDME)











