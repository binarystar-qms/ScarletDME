# Kubernetes Deployment

## Overview

ScarletDME includes Helm charts for deploying to Kubernetes clusters. This enables cloud-native deployment with orchestration, scaling, and service management.

## Prerequisites

- Kubernetes cluster (1.19+)
- kubectl configured
- Helm 3.x installed
- Docker registry access (for custom images)

## Helm Chart

### Chart Location

```
helm/scarletdme/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   ├── pvc.yaml
│   └── ...
└── README.md
```

### Installing the Chart

#### Basic Installation

```bash
# From chart directory
cd helm/scarletdme
helm install scarletdme .

# Or specify namespace
helm install scarletdme . --namespace scarletdme --create-namespace
```

#### With Custom Values

```bash
helm install scarletdme . \
  --namespace scarletdme \
  --create-namespace \
  --values custom-values.yaml
```

### Upgrading the Release

```bash
helm upgrade scarletdme . \
  --namespace scarletdme \
  --values custom-values.yaml
```

### Uninstalling

```bash
helm uninstall scarletdme --namespace scarletdme
```

## Configuration Options

### values.yaml Structure

```yaml
# Replica configuration
replicaCount: 1

# Image configuration
image:
  repository: scarletdme/scarletdme
  tag: latest
  pullPolicy: IfNotPresent

# Service configuration
service:
  type: LoadBalancer
  qmserver:
    port: 4242
  qmclient:
    port: 4243

# Resource limits
resources:
  limits:
    cpu: 1000m
    memory: 2Gi
  requests:
    cpu: 500m
    memory: 1Gi

# Persistence
persistence:
  enabled: true
  storageClass: ""
  accessMode: ReadWriteOnce
  size: 10Gi

# Health checks
livenessProbe:
  enabled: true
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  enabled: true
  initialDelaySeconds: 20
  periodSeconds: 5
```

### Custom Configuration

Create `custom-values.yaml`:

```yaml
image:
  repository: myregistry.com/scarletdme
  tag: 2.6-6

service:
  type: ClusterIP
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: nlb

resources:
  limits:
    cpu: 2000m
    memory: 4Gi
  requests:
    cpu: 1000m
    memory: 2Gi

persistence:
  enabled: true
  storageClass: "fast-ssd"
  size: 50Gi

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: scarletdme.example.com
      paths:
        - path: /
          pathType: Prefix
```

## Kubernetes Resources

### Deployment

The Helm chart creates a Deployment resource:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: scarletdme
spec:
  replicas: 1
  selector:
    matchLabels:
      app: scarletdme
  template:
    metadata:
      labels:
        app: scarletdme
    spec:
      containers:
      - name: scarletdme
        image: scarletdme:latest
        ports:
        - containerPort: 4242
          name: qmserver
        - containerPort: 4243
          name: qmclient
        volumeMounts:
        - name: data
          mountPath: /usr/qmsys
        livenessProbe:
          exec:
            command:
            - pgrep
            - -x
            - qmlnxd
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          tcpSocket:
            port: 4243
          initialDelaySeconds: 20
          periodSeconds: 5
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: scarletdme-pvc
```

### Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: scarletdme
spec:
  type: LoadBalancer
  ports:
  - port: 4242
    targetPort: 4242
    protocol: TCP
    name: qmserver
  - port: 4243
    targetPort: 4243
    protocol: TCP
    name: qmclient
  selector:
    app: scarletdme
```

### PersistentVolumeClaim

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: scarletdme-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: standard
  resources:
    requests:
      storage: 10Gi
```

### ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: scarletdme-config
data:
  scarlet.conf: |
    # ScarletDME Configuration
    MAXUSERS=50
    NUMFILES=100
    # ... additional configuration ...
```

## Deployment Patterns

### Single Instance Deployment

```bash
helm install scarletdme . \
  --set replicaCount=1 \
  --set persistence.enabled=true
```

**Use Case:** Development, testing, small production workloads

### High Availability (Future)

Currently, ScarletDME is designed for single-instance deployment. Multi-instance deployments require:
- Shared file system (NFS, CephFS, etc.)
- Distributed locking mechanism
- Session affinity or connection pooling

### StatefulSet Deployment (Future Enhancement)

For true HA, consider StatefulSet:

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: scarletdme
spec:
  serviceName: scarletdme
  replicas: 3
  selector:
    matchLabels:
      app: scarletdme
  template:
    # ... pod template ...
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 10Gi
```

## Networking

### Service Types

#### ClusterIP

Internal cluster access only:

```yaml
service:
  type: ClusterIP
```

#### NodePort

External access via node ports:

```yaml
service:
  type: NodePort
  qmserver:
    nodePort: 30242
  qmclient:
    nodePort: 30243
```

#### LoadBalancer

Cloud provider load balancer:

```yaml
service:
  type: LoadBalancer
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: nlb
```

### Ingress

For HTTP/HTTPS access:

```yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: scarletdme.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: scarletdme-tls
      hosts:
        - scarletdme.example.com
```

## Storage

### Storage Classes

#### Standard Disk

```yaml
persistence:
  storageClass: "standard"
  size: 10Gi
```

#### SSD Storage

```yaml
persistence:
  storageClass: "ssd"
  size: 50Gi
```

#### Cloud Provider Examples

**AWS:**
```yaml
persistence:
  storageClass: "gp3"  # or gp2, io1, io2
```

**GCP:**
```yaml
persistence:
  storageClass: "pd-ssd"  # or pd-standard
```

**Azure:**
```yaml
persistence:
  storageClass: "managed-premium"  # or managed-standard
```

### Volume Snapshots

Create volume snapshots for backups:

```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: scarletdme-snapshot
spec:
  volumeSnapshotClassName: standard-snapshot
  source:
    persistentVolumeClaimName: scarletdme-pvc
```

## Monitoring

### Prometheus Integration

```yaml
apiVersion: v1
kind: Service
metadata:
  name: scarletdme
  labels:
    app: scarletdme
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "9090"
    prometheus.io/path: "/metrics"
spec:
  # ... service spec ...
```

### Health Checks

```yaml
livenessProbe:
  exec:
    command:
    - pgrep
    - -x
    - qmlnxd
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3

readinessProbe:
  tcpSocket:
    port: 4243
  initialDelaySeconds: 20
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 3
```

### Startup Probe

```yaml
startupProbe:
  exec:
    command:
    - pgrep
    - -x
    - qmlnxd
  initialDelaySeconds: 0
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 30
```

## Security

### Pod Security Context

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
```

### Container Security Context

```yaml
securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
    - ALL
    add:
    - CHOWN
    - SETGID
    - SETUID
```

### Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: scarletdme-netpol
spec:
  podSelector:
    matchLabels:
      app: scarletdme
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: applications
    ports:
    - protocol: TCP
      port: 4243
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 53  # DNS
```

### Secrets Management

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: scarletdme-secret
type: Opaque
data:
  admin-password: <base64-encoded>
```

Use in deployment:

```yaml
env:
- name: ADMIN_PASSWORD
  valueFrom:
    secretKeyRef:
      name: scarletdme-secret
      key: admin-password
```

## Operations

### Viewing Logs

```bash
# Pod logs
kubectl logs -n scarletdme deployment/scarletdme

# Follow logs
kubectl logs -n scarletdme -f deployment/scarletdme

# Previous container logs
kubectl logs -n scarletdme deployment/scarletdme --previous
```

### Executing Commands

```bash
# Interactive shell
kubectl exec -n scarletdme -it deployment/scarletdme -- /bin/bash

# Run qm command
kubectl exec -n scarletdme deployment/scarletdme -- /usr/qmsys/bin/qm -c "LIST VOC"
```

### Scaling

```bash
# Manual scaling (note: requires shared storage for >1 replica)
kubectl scale deployment/scarletdme --replicas=1 -n scarletdme

# Via Helm
helm upgrade scarletdme . --set replicaCount=1
```

### Port Forwarding

```bash
# Forward local port to pod
kubectl port-forward -n scarletdme deployment/scarletdme 4243:4243

# Access from localhost
telnet localhost 4243
```

## Backup and Recovery

### Manual Backup

```bash
# Create a backup job
kubectl create job --from=cronjob/scarletdme-backup scarletdme-backup-manual
```

### CronJob for Scheduled Backups

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: scarletdme-backup
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: scarletdme:latest
            command:
            - /bin/bash
            - -c
            - |
              # Backup script
              tar czf /backup/scarletdme-$(date +%Y%m%d).tar.gz /usr/qmsys
            volumeMounts:
            - name: data
              mountPath: /usr/qmsys
            - name: backup
              mountPath: /backup
          volumes:
          - name: data
            persistentVolumeClaim:
              claimName: scarletdme-pvc
          - name: backup
            persistentVolumeClaim:
              claimName: backup-pvc
          restartPolicy: OnFailure
```

## Troubleshooting

### Pod Not Starting

```bash
# Describe pod
kubectl describe pod -n scarletdme -l app=scarletdme

# Check events
kubectl get events -n scarletdme --sort-by='.lastTimestamp'
```

### Storage Issues

```bash
# Check PVC status
kubectl get pvc -n scarletdme

# Describe PVC
kubectl describe pvc scarletdme-pvc -n scarletdme
```

### Network Issues

```bash
# Check service
kubectl get svc -n scarletdme

# Check endpoints
kubectl get endpoints -n scarletdme
```

## Next Steps

- [Configuration](09-configuration.md) - Configure ScarletDME
- [Monitoring](11-monitoring.md) - Set up monitoring
- [Troubleshooting](14-troubleshooting.md) - Common issues

