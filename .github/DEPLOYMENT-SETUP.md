# ScarletDME GitHub Actions Deployment Setup Guide

This guide explains how to set up GitHub Actions to automatically deploy ScarletDME to DigitalOcean Kubernetes.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [GitHub Secrets Configuration](#github-secrets-configuration)
3. [DigitalOcean Setup](#digitalocean-setup)
4. [Helm Values Configuration](#helm-values-configuration)
5. [Triggering Deployments](#triggering-deployments)
6. [Monitoring & Troubleshooting](#monitoring--troubleshooting)

## Prerequisites

- DigitalOcean account with active Kubernetes cluster
- GitHub repository with admin access
- `doctl` CLI configured locally (for testing)
- `kubectl` configured to access your DigitalOcean cluster
- Helm 3.x installed

## GitHub Secrets Configuration

You need to configure the following secrets in your GitHub repository settings.

### 1. DigitalOcean Access Token

**Secret Name**: `DIGITALOCEAN_ACCESS_TOKEN`

Steps to create:
1. Log in to DigitalOcean
2. Go to **API** → **Tokens/Keys**
3. Click **Generate New Token**
4. Name it: `github-actions-scarletdme`
5. Grant **read** and **write** permissions
6. Copy the token value
7. In GitHub Repository → **Settings** → **Secrets and Variables** → **Actions**
8. Click **New repository secret**
9. Name: `DIGITALOCEAN_ACCESS_TOKEN`
10. Value: (paste the token)

**Scope Required**:
- `registry:access_token`
- `kubernetes:access_token`

### 2. Registry Credentials (Optional - for manual image management)

If you need to push images manually:

**Secret Names**:
- `DIGITALOCEAN_REGISTRY_USERNAME` (usually your email)
- `DIGITALOCEAN_REGISTRY_PASSWORD` (your API token)

## DigitalOcean Setup

### 1. Container Registry Setup

Create a DigitalOcean Container Registry:

```bash
# List existing registries
doctl registry get

# Create new registry
doctl registry create binarystar --region nyc3
```

The registry URL will be: `registry.digitalocean.com/binarystar`

### 2. Kubernetes Cluster

Ensure you have a Kubernetes cluster ready:

```bash
# List clusters
doctl kubernetes cluster list

# Get cluster details
doctl kubernetes cluster get k8s-binarystar-do

# Merge kubeconfig locally
doctl kubernetes cluster kubeconfig save k8s-binarystar-do
```

**Note**: Update the `CLUSTER_NAME` environment variable in the workflow if your cluster name differs.

### 3. Storage Class Verification

Verify available storage classes for persistence:

```bash
kubectl get storageclass
```

## Helm Values Configuration

### Staging Environment

Create or update `helm/scarletdme/values-staging.yaml`:

```yaml
# Staging Configuration
replicaCount: 1

image:
  repository: registry.digitalocean.com/binarystar/scarletdme
  tag: staging-latest
  pullPolicy: Always

service:
  type: ClusterIP
  port: 4243
  targetPort: 4243
  telnetPort: 4242

persistence:
  enabled: true
  storageClassName: do-block-storage
  size: 10Gi
  mountPath: /usr/qmsys

resources:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: 2000m
    memory: 2Gi

scarletdme:
  numUsers: 10
  sortMem: 4096

ingress:
  enabled: false
  # Can enable with your ingress controller

autoscaling:
  enabled: false
```

### Production Environment

Create or update `helm/scarletdme/values.yaml`:

```yaml
# Production Configuration
replicaCount: 3

image:
  repository: registry.digitalocean.com/binarystar/scarletdme
  tag: latest
  pullPolicy: IfNotPresent

service:
  type: LoadBalancer
  port: 4243
  targetPort: 4243
  telnetPort: 4242
  annotations:
    service.spec.externalTrafficPolicy: "Local"

persistence:
  enabled: true
  storageClassName: do-block-storage
  size: 50Gi
  mountPath: /usr/qmsys

resources:
  requests:
    cpu: 1000m
    memory: 1Gi
  limits:
    cpu: 4000m
    memory: 4Gi

scarletdme:
  numUsers: 100
  sortMem: 8192

podDisruptionBudget:
  enabled: true
  minAvailable: 1

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 5
  targetCPUUtilizationPercentage: 70

ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: scarletdme.binarystarlabs.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: scarletdme-tls
      hosts:
        - scarletdme.binarystarlabs.com
```

## Triggering Deployments

### 1. Manual Workflow Dispatch

In GitHub, go to **Actions** → **Deploy to DigitalOcean** → **Run workflow**

Options:
- **environment**: Choose `staging` or `production`
- **skip_tests**: Enable to skip health checks

### 2. Automatic Deployment via Push

- Pushes to `main` or `master` → Deploys to **staging**
- Pushes to `staging` branch → Deploys to **staging**
- Tags matching `v*.*.*` → Deploys to **production**

Example:
```bash
# Deploy to staging
git push origin main

# Deploy to production
git tag v1.0.0
git push origin v1.0.0
```

### 3. Release Deployments

Publishing a GitHub release automatically triggers production deployment.

## Monitoring & Troubleshooting

### View Deployment Status

```bash
# Check pods
kubectl get pods -n scarletdme

# View deployment logs
kubectl logs -n scarletdme -l app.kubernetes.io/name=scarletdme -f

# Check service status
kubectl get svc -n scarletdme

# Get external IP (LoadBalancer)
kubectl get svc scarletdme -n scarletdme -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

### Common Issues

#### Deployment Stuck in Pending

```bash
# Check pod events
kubectl describe pod <pod-name> -n scarletdme

# Check PVC status
kubectl get pvc -n scarletdme
kubectl describe pvc <pvc-name> -n scarletdme
```

**Solution**: May need to wait for storage provisioning or check node availability.

#### Image Pull Errors

```bash
# Verify registry credentials
kubectl get secret -n scarletdme
kubectl describe secret regcred -n scarletdme
```

**Solution**: Check if DigitalOcean Container Registry credentials are correct.

#### Health Check Failures

The workflow includes automatic health checks. If they fail:

1. SSH into a pod:
   ```bash
   kubectl exec -it <pod-name> -n scarletdme -- /bin/bash
   ```

2. Verify ScarletDME is running:
   ```bash
   pgrep -x qm
   /usr/qmsys/bin/qm -status
   ```

### Viewing Workflow Logs

In GitHub:
1. Go to **Actions** tab
2. Select the workflow run
3. Click on the job to see detailed logs
4. Check specific steps for errors

## Rollback

Automatic rollback on failure is included in the workflow. Manual rollback:

```bash
# List releases
helm history scarletdme -n scarletdme

# Rollback to previous
helm rollback scarletdme -n scarletdme

# Rollback to specific revision
helm rollback scarletdme 2 -n scarletdme
```

## Environment Variables in Workflow

The workflow automatically configures:

| Environment | Namespace | Domain | Release Name |
|---|---|---|---|
| Staging | `scarletdme-staging` | `scarletdme-staging.binarystarlabs.com` | `scarletdme-staging` |
| Production | `scarletdme` | `scarletdme.binarystarlabs.com` | `scarletdme` |

## Security Best Practices

1. **Rotate tokens regularly**
   ```bash
   doctl auth revoke <old-token>
   ```

2. **Use least privilege**
   - Only grant necessary permissions to API tokens
   - Limit RBAC roles in Kubernetes

3. **Monitor deployments**
   - Enable audit logging in DigitalOcean
   - Set up notifications for failed deployments

4. **Secure registry**
   - Make registry private (default)
   - Use image scanning/vulnerability detection

## Next Steps

1. Configure the Helm values files for your environment
2. Set up the GitHub secrets
3. Verify DigitalOcean cluster access
4. Test a manual deployment
5. Monitor the first automated deployment

## Support

For issues:
1. Check workflow logs in GitHub Actions
2. Review DigitalOcean dashboard for cluster health
3. Verify kubectl connectivity
4. Check Helm chart configuration

---

**Last Updated**: 2025
**Tested With**: Helm 3.13.0, kubectl 1.28.0, doctl 1.110.0
