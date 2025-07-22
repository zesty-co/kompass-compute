# Kompass Compute Helm Chart

This chart deploys the Kompass Compute components.

## Prerequisites

*   Kubernetes 1.19+
*   Helm 3.2.0+
*   Kompass Insight Agent installed in the cluster

## Installing the Chart

To install the chart with the release name `kompass-compute`:

```bash
helm repo add zesty-kompass-compute https://zesty-co.github.io/kompass-compute
helm repo update
helm install kompass-compute zesty-kompass-compute/kompass-compute --namespace zesty-system
```

Or, if installing from a local path:

```bash
helm install kompass-compute ./helm --namespace zesty-system --create-namespace
```

## Uninstalling the Chart

To uninstall/delete the `kompass-compute` deployment:

```bash
helm uninstall kompass-compute --namespace zesty-system
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following table lists the configurable parameters of the Kompass Compute chart and their default values.
This section can be automatically generated using [helm-docs](https://github.com/norwoodj/helm-docs). Run `make docs` from the `helm` directory.

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example:

```bash
helm install kompass-compute ./helm \
  --namespace zesty-system \
  --set hiberscaler.replicaCount=2 \
  --set logLevel="debug"
```

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example:

```bash
helm install kompass-compute ./helm \
  --namespace zesty-system \
  -f my-values.yaml
```

> **Tip**: You can use the default [values.yaml](values.yaml)

## Examples

### Basic Installation

To install the chart with default values (not typically recommended for production without reviewing defaults):

```bash
helm install kompass-compute ./helm --namespace zesty-system --create-namespace
```

### Configuring ECR Pull-Through Cache and AWS Infrastructure

You can provide ECR pull-through cache mappings, S3 VPC Endpoint ID, and SQS queue URL via a custom values file or `--set` arguments.

Create a `my-infra-values.yaml` file:

```yaml
cachePullMappings:
  dockerhub:
    - proxyAddress: "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-dockerhub-proxy"
  ghcr:
    - proxyAddress: "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-ghcr-proxy"
  # Add other registries as needed, e.g., ecr, k8s, quay

qubexConfig:
  infraConfig:
    aws:
      spotFailuresQueueUrl: "https://sqs.us-east-1.amazonaws.com/123456789012/MyKompassSQS"
      s3VpcEndpointID: "vpce-0abcdef1234567890"
```

Then install the chart:

```bash
helm install kompass-compute ./helm \
  --namespace zesty-system \
  --create-namespace \
  -f my-infra-values.yaml
```

These values are typically obtained from the output of the [Kompass Compute Terraform module](https://github.com/zesty-co/terraform-kompass-compute).

### Using IAM Roles for Service Accounts (IRSA)

To configure the Kompass Compute components to use IRSA, you need to annotate their respective service accounts with the ARN of the IAM role.

Create an `irsa-values.yaml` file:

```yaml
# Ensure serviceAccount.create is true for each component if the chart manages them,
# or false if you manage them externally but still want to set annotations via Helm.

hiberscaler:
  serviceAccount:
    # create: true # Default is true
    annotations:
      "eks.amazonaws.com/role-arn": "arn:aws:iam::123456789012:role/YourKompassComputeHiberscalerRole"

imageSizeCalculator:
  serviceAccount:
    # create: true # Default is true
    annotations:
      "eks.amazonaws.com/role-arn": "arn:aws:iam::123456789012:role/YourKompassComputeImageSizeCalculatorRole"

snapshooter:
  serviceAccount:
    # create: true # Default is true
    annotations:
      "eks.amazonaws.com/role-arn": "arn:aws:iam::123456789012:role/YourKompassComputeSnapshooterRole"

telemetryManager:
  serviceAccount:
    # create: true # Default is true
    annotations:
      "eks.amazonaws.com/role-arn": "arn:aws:iam::123456789012:role/YourKompassComputeTelemetryManagerRole"

# If EKS Pod Identity is enabled in your cluster and you want to disable it for these pods
# (preferring IRSA), ensure no pod identity related labels/annotations are set by default,
# or override them if the chart provides such options.
```

Then install the chart:

```bash
helm install kompass-compute ./helm \
  --namespace zesty-system \
  --create-namespace \
  -f irsa-values.yaml
```

The IAM roles and policies should be created beforehand, for example, using the [Kompass Compute Terraform module](https://github.com/zesty-co/terraform-kompass-compute) with `enable_irsa = true`.

## Contributing

Please refer to the contribution guidelines for this project.

## License

Specify your license information here.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| cache | object | `{"affinity":{},"developmentMode":null,"enabled":true,"extraArgs":[],"extraEnv":[],"extraVolumeMounts":[],"extraVolumes":[],"image":{"pullPolicy":"Always","repository":"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/cache-controller","tag":""},"livenessProbe":{"httpGet":{"path":"/healthz","port":"probes"},"initialDelaySeconds":15,"periodSeconds":20,"timeoutSeconds":5},"logLevel":null,"logRemote":null,"nodeSelector":{},"podAnnotations":{"prometheus.io/port":"8080","prometheus.io/scrape":"true"},"podDisruptionBudget":{"enabled":true},"podLabels":{},"podSecurityContext":{"fsGroup":1000,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}},"ports":{"probes":{"name":"probes","port":8081}},"rbac":{"create":true},"readinessProbe":{"httpGet":{"path":"/readyz","port":"probes"},"initialDelaySeconds":5,"periodSeconds":10,"timeoutSeconds":5},"replicaCount":2,"resources":{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"128Mi"}},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true},"serviceAccount":{"annotations":{},"automount":true,"create":true,"name":""},"startupProbe":{"failureThreshold":50,"httpGet":{"path":"/healthz","port":"probes"},"periodSeconds":10,"timeoutSeconds":5},"tolerations":[],"traceRemote":null,"useDefaultAffinity":true}` | Cache component configuration |
| cache.affinity | object | `{}` | Affinity rules for scheduling Cache Pods. Overrides default affinity if set. See: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity |
| cache.developmentMode | string | `nil` | Enable/disable development mode for the Cache component. |
| cache.enabled | bool | `true` | If true, deploys the Cache component. |
| cache.extraArgs | list | `[]` | Extra command-line arguments to pass to the Cache container. -- Example: extraArgs:   - --some-flag=value |
| cache.extraEnv | list | `[]` | Extra environment variables to set in the Cache container. -- Example: extraEnv: - name: SOME_VAR   value: 'some value' |
| cache.extraVolumeMounts | list | `[]` | Additional volume mounts for the Cache containers. See: https://kubernetes.io/docs/concepts/storage/volumes/ |
| cache.extraVolumes | list | `[]` | Additional volumes to mount in the Cache Pods. See: https://kubernetes.io/docs/concepts/storage/volumes/ |
| cache.image | object | `{"pullPolicy":"Always","repository":"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/cache-controller","tag":""}` | Image configuration for the Cache component. |
| cache.image.pullPolicy | string | `"Always"` | Image pull policy. Valid values: Always, IfNotPresent, Never. |
| cache.image.repository | string | `"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/cache-controller"` | Image repository for the Cache component. |
| cache.image.tag | string | `""` | Specific image tag for the Cache component. -- Overrides the global 'tag' and Chart.AppVersion if set. -- If empty, uses global 'tag' or Chart.AppVersion. |
| cache.livenessProbe | object | `{"httpGet":{"path":"/healthz","port":"probes"},"initialDelaySeconds":15,"periodSeconds":20,"timeoutSeconds":5}` | Liveness probe configuration for the Cache container. See: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/ |
| cache.logLevel | string | `nil` | Log level for the Cache component. |
| cache.logRemote | string | `nil` | Enable/disable remote logging for the Cache component. |
| cache.nodeSelector | object | `{}` | Node selector for scheduling Cache Pods. See: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector |
| cache.podAnnotations | object | `{"prometheus.io/port":"8080","prometheus.io/scrape":"true"}` | Annotations to add to the Cache Pods. See: https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/ |
| cache.podDisruptionBudget | object | `{"enabled":true}` | PodDisruptionBudget configuration for the Cache deployment. See: https://kubernetes.io/docs/tasks/run-application/configure-pdb/ |
| cache.podLabels | object | `{}` | Labels to add to the Cache Pods. See: https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/ |
| cache.podSecurityContext | object | `{"fsGroup":1000,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}}` | Security context for the Cache Pods. See: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod |
| cache.ports | object | `{"probes":{"name":"probes","port":8081}}` | Port configuration for Cache component. |
| cache.ports.probes | object | `{"name":"probes","port":8081}` | Port configuration for Cache probes. |
| cache.ports.probes.name | string | `"probes"` | Name of the probes port. |
| cache.ports.probes.port | int | `8081` | Port number for health and readiness probes. |
| cache.rbac | object | `{"create":true}` | RBAC configuration for the Cache component. |
| cache.rbac.create | bool | `true` | If true, creates RBAC resources (ClusterRoles, ClusterRoleBindings) for the Cache component. |
| cache.readinessProbe | object | `{"httpGet":{"path":"/readyz","port":"probes"},"initialDelaySeconds":5,"periodSeconds":10,"timeoutSeconds":5}` | Readiness probe configuration for the Cache container. See: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/ |
| cache.replicaCount | int | `2` | Number of replicas for the Cache Deployment. |
| cache.resources | object | `{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"128Mi"}}` | Resource requests and limits for the Cache container. See: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/ We usually recommend not to specify default resources and to leave this as a conscious choice for the user. This also increases chances charts run on environments with little resources, such as Minikube. If you do want to specify resources, uncomment the following lines, adjust them as necessary, and remove the curly braces after 'resources:'. |
| cache.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true}` | Security context for the Cache container. See: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-container |
| cache.serviceAccount | object | `{"annotations":{},"automount":true,"create":true,"name":""}` | ServiceAccount configuration for the Cache component. |
| cache.startupProbe | object | `{"failureThreshold":50,"httpGet":{"path":"/healthz","port":"probes"},"periodSeconds":10,"timeoutSeconds":5}` | Startup probe configuration for the Cache container. See: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/ |
| cache.tolerations | list | `[]` | Tolerations for scheduling Cache Pods. See: https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/ |
| cache.traceRemote | string | `nil` | Enable/disable remote tracing for the Cache component. |
| cache.useDefaultAffinity | bool | `true` | If true, applies default affinity rules. Ignored if 'affinity' is set. |
| cachePullMappings | object | `{}` | CachePullMappings: Configuration for mapping image registries to proxies/caches. Defines how image pull requests for certain registries should be redirected. |
| developmentMode | bool | `false` | Global setting for development mode features for all components. Can be overridden per component. |
| hiberscaler | object | `{"affinity":{},"developmentMode":null,"enabled":true,"extraArgs":[],"extraEnv":[],"extraVolumeMounts":[],"extraVolumes":[],"image":{"pullPolicy":"Always","repository":"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/hiberscaler-controller","tag":""},"livenessProbe":{"httpGet":{"path":"/healthz","port":"probes"},"initialDelaySeconds":15,"periodSeconds":20,"timeoutSeconds":5},"logLevel":null,"logRemote":null,"nodeSelector":{},"podAnnotations":{"prometheus.io/port":"8080","prometheus.io/scrape":"true"},"podDisruptionBudget":{"enabled":false},"podLabels":{},"podSecurityContext":{"fsGroup":1000,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}},"ports":{"metrics":{"name":"metrics","port":8080},"nodeServer":{"name":"node-server","port":8082},"probes":{"name":"probes","port":8081},"webServer":{"name":"webhook-server","port":9443,"servicePort":443,"serviceType":"ClusterIP"}},"rbac":{"create":true},"readinessProbe":{"httpGet":{"path":"/readyz","port":"probes"},"initialDelaySeconds":5,"periodSeconds":10,"timeoutSeconds":5},"replicaCount":1,"resources":{"limits":{"cpu":"2000m","memory":"4096Mi"},"requests":{"cpu":"2000m","memory":"4096Mi"}},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true},"serviceAccount":{"annotations":{},"automount":true,"create":true,"name":""},"startupProbe":{"failureThreshold":50,"httpGet":{"path":"/healthz","port":"probes"},"periodSeconds":10,"timeoutSeconds":5},"tolerations":[],"traceRemote":null,"useDefaultAffinity":true}` | Hiberscaler component configuration |
| imagePullSecrets | list | `[]` | Global image pull secrets A list of secrets to use for pulling images from private registries. Example: imagePullSecrets:   - name: "my-registry-secret" |
| imageSizeCalculator | object | `{"enabled":true,"extraEnv":[],"image":{"repository":"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/image-size-calculator","tag":""},"rbac":{"create":true},"serviceAccount":{"annotations":{},"automount":true,"create":true,"name":""}}` | ImageSizeCalculator component configuration This component is responsible for calculating the size of container images. It typically runs as a Job or a similar workload. |
| kompassInsightSecret | string | `"kompass-insights-secret"` | Name of the Kubernetes secret created by the Kompass Insight. |
| logLevel | string | `"info"` | Global log level for all components. Can be overridden per component. Valid levels: "debug", "info", "warn", "error". |
| logRemote | bool | `true` | Global setting to enable/disable remote logging for all components. Can be overridden per component. |
| monitorRemote | bool | `true` | Global setting to enable/disable remote monitoring for all components. Can be overridden per component. |
| otel | object | `{"affinity":{},"developmentMode":null,"enabled":true,"extraArgs":[],"extraEnv":[],"extraVolumeMounts":[],"extraVolumes":[],"gomemlimit":"400MiB","image":{"pullPolicy":"Always","repository":"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/otel","tag":""},"livenessProbe":{"httpGet":{"path":"/","port":"probes"},"timeoutSeconds":10},"monitorRemote":null,"nodeSelector":{},"podAnnotations":{},"podDisruptionBudget":{"enabled":false},"podLabels":{},"podSecurityContext":{"fsGroup":1000,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}},"ports":{"otlp":{"name":"otlp","port":4317},"otlpHttp":{"name":"otlp-http","port":4318},"probes":{"name":"probes","port":13133}},"rbac":{"create":true},"readinessProbe":{"httpGet":{"path":"/","port":"probes"},"timeoutSeconds":8},"replicaCount":1,"resources":{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"200m","memory":"256Mi"}},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true},"serviceAccount":{"annotations":{},"automount":true,"create":true,"name":""},"startupProbe":{"failureThreshold":50,"httpGet":{"path":"/","port":"probes"}},"tolerations":[],"useDefaultAffinity":true}` | OTEL (OpenTelemetry) Collector configuration |
| qnode | object | `{"enabled":true}` | QNode specific configuration |
| qubexConfig.cacheConfig.imageSizeCalculatorConfig | object | `{}` |  |
| qubexConfig.cloudProvider | string | `"eks"` |  |
| qubexConfig.disturbanceConfig | object | `{}` |  |
| qubexConfig.drainingConfig | object | `{}` |  |
| qubexConfig.infraConfig.aws | object | `{}` |  |
| qubexConfig.spotOceanConfig | object | `{}` |  |
| qubexConfig.zestyConfig | object | `{}` |  |
| snapshooter | object | `{"affinity":{},"developmentMode":null,"enabled":true,"extraArgs":[],"extraEnv":[],"extraVolumeMounts":[],"extraVolumes":[],"image":{"pullPolicy":"Always","repository":"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/snapshooter","tag":""},"livenessProbe":{"httpGet":{"path":"/healthz","port":"probes"},"initialDelaySeconds":15,"periodSeconds":20,"timeoutSeconds":5},"logLevel":null,"logRemote":null,"nodeSelector":{},"podAnnotations":{},"podDisruptionBudget":{"enabled":false},"podLabels":{},"podSecurityContext":{"fsGroup":1000,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}},"ports":{"probes":{"name":"probes","port":8081}},"rbac":{"create":true},"readinessProbe":{"httpGet":{"path":"/readyz","port":"probes"},"initialDelaySeconds":5,"periodSeconds":10,"timeoutSeconds":5},"replicaCount":1,"resources":{"limits":{"cpu":"300m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"128Mi"}},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true},"serviceAccount":{"annotations":{},"automount":true,"create":true,"name":""},"startupProbe":{"failureThreshold":50,"httpGet":{"path":"/healthz","port":"probes"},"periodSeconds":10,"timeoutSeconds":5},"terminationGracePeriodSeconds":60,"tolerations":[],"traceRemote":null,"useDefaultAffinity":true}` | Snapshooter component configuration |
| tag | string | `nil` | Override the chart name. nameOverride: "" Override the full name of the chart. fullnameOverride: "" |
| telemetryManager | object | `{"affinity":{},"developmentMode":null,"enabled":true,"extraArgs":[],"extraEnv":[],"extraVolumeMounts":[],"extraVolumes":[],"image":{"pullPolicy":"Always","repository":"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/telemetry-manager","tag":""},"livenessProbe":{"httpGet":{"path":"/healthz","port":"probes"},"initialDelaySeconds":15,"periodSeconds":20,"timeoutSeconds":5},"logLevel":null,"logRemote":null,"nodeSelector":{},"podAnnotations":{"prometheus.io/port":"8080","prometheus.io/scrape":"true"},"podDisruptionBudget":{"enabled":false},"podLabels":{},"podSecurityContext":{"fsGroup":1000,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}},"ports":{"metrics":{"name":"metrics","port":8080},"probes":{"name":"probes","port":8081}},"rbac":{"create":true},"readinessProbe":{"httpGet":{"path":"/readyz","port":"probes"},"initialDelaySeconds":5,"periodSeconds":10,"timeoutSeconds":5},"replicaCount":1,"resources":{"limits":{"cpu":"400m","memory":"512Mi"},"requests":{"cpu":"200m","memory":"256Mi"}},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true},"serviceAccount":{"annotations":{},"automount":true,"create":true,"name":""},"startupProbe":{"failureThreshold":50,"httpGet":{"path":"/healthz","port":"probes"},"periodSeconds":10,"timeoutSeconds":5},"tolerations":[],"traceRemote":null,"useDefaultAffinity":true}` | Telemetry Manager component configuration |
| traceRemote | bool | `true` | Global setting to enable/disable remote tracing for all components. Can be overridden per component. |
| uninstaller | object | `{"affinity":{},"developmentMode":null,"enabled":true,"extraArgs":[],"extraEnv":[],"extraVolumeMounts":[],"extraVolumes":[],"image":{"pullPolicy":"Always","repository":"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/uninstaller","tag":""},"logLevel":null,"logRemote":null,"nodeSelector":{},"podAnnotations":{},"podLabels":{},"podSecurityContext":{"fsGroup":1000,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}},"rbac":{"create":true},"resources":{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"128Mi"}},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true},"serviceAccount":{"annotations":{},"automount":true,"create":true,"name":""},"tolerations":[],"traceRemote":null}` | Uninstaller Job configuration This component is typically a Job responsible for cleanup tasks during chart uninstallation. |
| vector | object | `{"developmentMode":null,"enabled":true,"extraArgs":[],"extraEnv":[],"extraVolumeMounts":[],"extraVolumes":[],"image":{"pullPolicy":"Always","repository":"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/vector","tag":""},"logLevel":null,"normal":{"affinity":{},"nodeSelector":{},"tolerations":[{"operator":"Exists"}],"useDefaultAffinity":true},"podAnnotations":{},"podLabels":{},"podSecurityContext":{"fsGroup":1000,"seccompProfile":{"type":"RuntimeDefault"}},"qNode":{"affinity":{},"nodeSelector":{},"tolerations":[{"operator":"Exists"}],"useDefaultAffinity":true},"rbac":{"create":true},"resources":{"limits":{"cpu":"300m","memory":"600Mi"},"requests":{"cpu":"10m","memory":"50Mi"}},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true},"serviceAccount":{"annotations":{},"automount":true,"create":true,"name":""}}` | Vector component configuration (for log aggregation/forwarding) |