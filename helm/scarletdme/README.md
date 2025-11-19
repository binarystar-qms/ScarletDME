# ScarletDME Helm Chart

A Helm chart for deploying ScarletDME Multi-Value Database Server on Kubernetes.

## Introduction

This chart bootstraps a ScarletDME deployment on a Kubernetes cluster using the Helm package manager.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- PV provisioner support in the underlying infrastructure (if persistence is enabled)

## Installing the Chart

To install the chart with the release name `my-scarletdme`:

```bash
helm install my-scarletdme ./helm/scarletdme
```

The command deploys ScarletDME on the Kubernetes cluster with default configuration. The [Parameters](#parameters) section lists the parameters that can be configured during installation.

## Uninstalling the Chart

To uninstall/delete the `my-scarletdme` deployment:

```bash
helm uninstall my-scarletdme
```

This command removes all the Kubernetes components associated with the chart and deletes the release.

## Parameters

### Global Parameters

| Name               | Description                                     | Value |
| ------------------ | ----------------------------------------------- | ----- |
| `nameOverride`     | String to partially override scarletdme.name    | `""`  |
| `fullnameOverride` | String to fully override scarletdme.fullname    | `""`  |

### Image Parameters

| Name               | Description                          | Value                    |
| ------------------ | ------------------------------------ | ------------------------ |
| `image.repository` | ScarletDME image repository          | `scarletdme/scarletdme`  |
| `image.tag`        | ScarletDME image tag                 | `""` (chart appVersion)  |
| `image.pullPolicy` | Image pull policy                    | `IfNotPresent`           |

### Deployment Parameters

| Name              | Description                    | Value |
| ----------------- | ------------------------------ | ----- |
| `replicaCount`    | Number of replicas to deploy   | `1`   |

### Service Parameters

| Name                      | Description                            | Value       |
| ------------------------- | -------------------------------------- | ----------- |
| `service.type`            | Service type                           | `ClusterIP` |
| `service.qmServerPort`    | QMServer port (telnet connections)     | `4242`      |
| `service.qmClientPort`    | QMClient port (API connections)        | `4243`      |
| `service.annotations`     | Service annotations                    | `{}`        |

### Persistence Parameters

| Name                          | Description                               | Value              |
| ----------------------------- | ----------------------------------------- | ------------------ |
| `persistence.enabled`         | Enable persistence using PVC              | `true`             |
| `persistence.storageClassName`| Storage class name                        | `""`               |
| `persistence.accessMode`      | PVC access mode                           | `ReadWriteOnce`    |
| `persistence.size`            | PVC size                                  | `10Gi`             |
| `persistence.existingClaim`   | Name of an existing PVC to use            | `""`               |

### ScarletDME Configuration Parameters

| Name                          | Description                               | Value          |
| ----------------------------- | ----------------------------------------- | -------------- |
| `scarletdme.qmsysPath`        | QMSYS path                                | `/usr/qmsys`   |
| `scarletdme.grpSize`          | Group size                                | `2`            |
| `scarletdme.numUsers`         | Number of users                           | `10`           |
| `scarletdme.sortMem`          | Sort memory (in KB)                       | `4096`         |
| `scarletdme.extraConfig`      | Additional configuration options          | `{}`           |

### Resource Parameters

| Name                       | Description                           | Value     |
| -------------------------- | ------------------------------------- | --------- |
| `resources.limits.cpu`     | CPU limit                             | `2000m`   |
| `resources.limits.memory`  | Memory limit                          | `2Gi`     |
| `resources.requests.cpu`   | CPU request                           | `500m`    |
| `resources.requests.memory`| Memory request                        | `512Mi`   |

### Autoscaling Parameters

| Name                                         | Description                    | Value   |
| -------------------------------------------- | ------------------------------ | ------- |
| `autoscaling.enabled`                        | Enable autoscaling             | `false` |
| `autoscaling.minReplicas`                    | Minimum replicas               | `1`     |
| `autoscaling.maxReplicas`                    | Maximum replicas               | `10`    |
| `autoscaling.targetCPUUtilizationPercentage` | Target CPU utilization         | `80`    |

### Ingress Parameters

| Name                  | Description                    | Value   |
| --------------------- | ------------------------------ | ------- |
| `ingress.enabled`     | Enable ingress                 | `false` |
| `ingress.className`   | Ingress class name             | `""`    |
| `ingress.annotations` | Ingress annotations            | `{}`    |

## Examples

### Install with custom values

```bash
helm install my-scarletdme ./helm/scarletdme \
  --set image.tag=1.0.0 \
  --set service.type=LoadBalancer \
  --set persistence.size=20Gi
```

### Install with values file

Create a `custom-values.yaml` file:

```yaml
replicaCount: 2

service:
  type: LoadBalancer
  
persistence:
  size: 20Gi
  storageClassName: fast-ssd

resources:
  limits:
    cpu: 4000m
    memory: 4Gi
  requests:
    cpu: 1000m
    memory: 1Gi

scarletdme:
  numUsers: 50
  sortMem: 8192
```

Install the chart:

```bash
helm install my-scarletdme ./helm/scarletdme -f custom-values.yaml
```

### Access the Service

#### Using Port-Forward

```bash
kubectl port-forward service/my-scarletdme 4242:4242 4243:4243
```

Then connect to:
- QMServer (Telnet): `localhost:4242`
- QMClient (API): `localhost:4243`

#### Using LoadBalancer

If you set `service.type=LoadBalancer`, get the external IP:

```bash
kubectl get svc my-scarletdme
```

### Upgrade the Deployment

```bash
helm upgrade my-scarletdme ./helm/scarletdme -f custom-values.yaml
```

## Configuration and Installation Details

### Persistence

The chart mounts a Persistent Volume at `/usr/qmsys` by default. The volume is created using dynamic volume provisioning. If you want to use an existing claim, set `persistence.existingClaim`.

To disable persistence:

```bash
helm install my-scarletdme ./helm/scarletdme --set persistence.enabled=false
```

**Warning**: Disabling persistence will cause data loss when pods are restarted.

### Security Context

The container runs as root by default to allow ScarletDME to manage users and groups. You can customize the security context in `values.yaml`.

### Resource Limits

It's recommended to set appropriate resource limits based on your workload. Monitor the application and adjust accordingly.

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -l app.kubernetes.io/name=scarletdme
```

### View Logs

```bash
kubectl logs -l app.kubernetes.io/name=scarletdme
```

### Describe Pod

```bash
kubectl describe pod <pod-name>
```

### Execute Commands in Pod

```bash
kubectl exec -it <pod-name> -- /bin/bash
```

## License

ScarletDME is distributed under the GNU General Public License v3.0.

## Links

- [ScarletDME Website](https://scarlet.deltasoft.com)
- [ScarletDME GitHub](https://github.com/geneb/ScarletDME)
- [ScarletDME Mailing List](https://groups.google.com/g/scarletdme)
- [ScarletDME Discord](https://discord.gg/H7MPapC2hK)











