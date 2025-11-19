# ScarletDME DigitalOcean Deployment Quick Reference

## Quick Start

### 1. Set up GitHub Secret
```bash
# Create or get your DigitalOcean API token
# Add to GitHub: Settings → Secrets → DIGITALOCEAN_ACCESS_TOKEN
```

### 2. Deploy via GitHub Actions
- **Manual**: Go to Actions → Deploy to DigitalOcean → Run workflow
- **Auto (Staging)**: Push to `main` or `master`
- **Auto (Production)**: Create git tag `v1.0.0` and push

### 3. Monitor Deployment
View in GitHub Actions tab → Click workflow run

---

## Common Commands

### Check Deployment Status
```bash
# Connect to cluster
doctl kubernetes cluster kubeconfig save k8s-binarystar-do

# View pods
kubectl get pods -n scarletdme

# View services
kubectl get svc -n scarletdme

# Get external IP (production LoadBalancer)
kubectl get svc scarletdme -n scarletdme -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

### View Logs
```bash
# Recent logs
kubectl logs -n scarletdme -l app.kubernetes.io/name=scarletdme --tail=50

# Follow logs
kubectl logs -n scarletdme -l app.kubernetes.io/name=scarletdme -f

# Previous pod logs (if crashed)
kubectl logs -n scarletdme <pod-name> --previous
```

### Access Pod
```bash
# Get pod name
POD=$(kubectl get pod -n scarletdme -o jsonpath='{.items[0].metadata.name}')

# SSH into pod
kubectl exec -it $POD -n scarletdme -- /bin/bash

# Check ScarletDME status
kubectl exec -it $POD -n scarletdme -- /usr/qmsys/bin/qm -status

# Verify process
kubectl exec -it $POD -n scarletdme -- pgrep -x qm
```

### Deployment Management
```bash
# View all deployments
kubectl get deployments -n scarletdme

# Scale replicas (production)
kubectl scale deployment scarletdme -n scarletdme --replicas=5

# Update image
kubectl set image deployment/scarletdme \
  scarletdme=registry.digitalocean.com/binarystar/scarletdme:latest \
  -n scarletdme

# Restart deployment
kubectl rollout restart deployment/scarletdme -n scarletdme

# Check rollout status
kubectl rollout status deployment/scarletdme -n scarletdme
```

### Helm Management
```bash
# List releases
helm list -n scarletdme

# View release history
helm history scarletdme -n scarletdme

# Get deployment values
helm get values scarletdme -n scarletdme

# Manual Helm deployment
helm upgrade scarletdme ./helm/scarletdme \
  --namespace scarletdme \
  --install \
  --set image.tag=staging-latest

# Rollback to previous
helm rollback scarletdme -n scarletdme

# Rollback to specific revision
helm rollback scarletdme 2 -n scarletdme
```

### Debugging
```bash
# Describe pod (events and errors)
kubectl describe pod <pod-name> -n scarletdme

# Check persistent volume
kubectl get pvc -n scarletdme
kubectl describe pvc scarletdme -n scarletdme

# Check ConfigMap
kubectl get configmap -n scarletdme
kubectl describe configmap scarletdme -n scarletdme

# Check image pull secrets
kubectl get secrets -n scarletdme

# Events in namespace
kubectl get events -n scarletdme --sort-by='.lastTimestamp'

# Full pod YAML
kubectl get pod <pod-name> -n scarletdme -o yaml
```

---

## Deployment Triggers

| Action | Environment | Condition |
|--------|-------------|-----------|
| Push to `main` | Staging | Automatic |
| Push to `master` | Staging | Automatic |
| Push to `staging` | Staging | Automatic |
| Create tag `v*.*.*` | Production | Automatic |
| Publish release | Production | Automatic |
| Manual dispatch | Selectable | Click "Run workflow" |

---

## Environment Configuration

| Setting | Staging | Production |
|---------|---------|------------|
| Namespace | `scarletdme-staging` | `scarletdme` |
| Replicas | 1 | 3 |
| Service Type | ClusterIP | LoadBalancer |
| Storage Size | 10Gi | 50Gi |
| Memory Limit | 2Gi | 4Gi |
| Domain | staging.binarystarlabs.com | scarletdme.binarystarlabs.com |

---

## Troubleshooting Quick Fixes

### Pod Won't Start (CrashLoopBackOff)
```bash
# Check logs
kubectl logs <pod-name> -n scarletdme --previous

# Describe pod for errors
kubectl describe pod <pod-name> -n scarletdme

# Check image exists
doctl registry list-repositories --format Name

# Verify pull credentials
kubectl get secrets -n scarletdme
```

### Can't Pull Image
```bash
# Ensure registry login works
doctl registry login

# Check image tag exists
doctl registry list-images | grep scarletdme

# Verify credentials in namespace
kubectl get secret regcred -n scarletdme -o yaml
```

### Connection Timeout
```bash
# Wait for LoadBalancer IP (can take 1-2 minutes)
kubectl get svc scarletdme -n scarletdme -w

# Check ingress (if enabled)
kubectl get ingress -n scarletdme
kubectl describe ingress scarletdme -n scarletdme
```

### Storage Issues
```bash
# List persistent volumes
kubectl get pv

# Check PVC binding
kubectl get pvc -n scarletdme

# Describe PVC for errors
kubectl describe pvc scarletdme -n scarletdme

# Available storage classes
kubectl get storageclass
```

---

## Useful Aliases

Add to your shell:

```bash
alias kgs='kubectl get svc'
alias kgp='kubectl get pods'
alias kgd='kubectl get deployment'
alias kl='kubectl logs'
alias ke='kubectl exec -it'
alias kdesc='kubectl describe'

# ScarletDME specific
alias scarlet-status='kubectl get pods -n scarletdme && kubectl get svc -n scarletdme'
alias scarlet-logs='kubectl logs -n scarletdme -l app.kubernetes.io/name=scarletdme -f'
alias scarlet-sh='kubectl exec -it $(kubectl get pod -n scarletdme -o jsonpath={.items[0].metadata.name}) -n scarletdme -- /bin/bash'
```

---

## Important URLs

- **Staging**: https://scarletdme-staging.binarystarlabs.com
- **Production**: https://scarletdme.binarystarlabs.com
- **GitHub Repo**: https://github.com/binarystar-qms/ScarletDME
- **DigitalOcean Console**: https://cloud.digitalocean.com/
- **Kubernetes Dashboard**: (if installed) via port-forward

---

## Next Steps

1. **For First Deploy**: Follow `.github/DEPLOYMENT-SETUP.md`
2. **For Common Tasks**: Use commands above
3. **For Issues**: Check troubleshooting section or GitHub Actions logs
4. **For Production**: Ensure staging deployment succeeds first

---

**Last Updated**: 2025
**Tested With**: kubectl 1.28+, Helm 3.13+, doctl 1.110+
