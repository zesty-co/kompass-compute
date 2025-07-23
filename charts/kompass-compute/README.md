# Kompass Compute Helm Chart

This chart deploys the Kompass Compute components.

## Prerequisites

*   Kubernetes 1.19+
*   Helm 3.2.0+
*   Kompass Insight Agent installed in the cluster
*   kompass-compute [terraform module](https://github.com/zesty-co/terraform-kompass-compute) installed
*   Pod Identity enabled in the cluster, otherwise go to the [IRSA section](#using-iam-roles-for-service-accounts-irsa)

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

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| cache | object | `{"affinity":{},"developmentMode":null,"enabled":true,"extraArgs":[],"extraEnv":[],"extraVolumeMounts":[],"extraVolumes":[],"image":{"pullPolicy":"Always","repository":"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/cache-controller","tag":""},"livenessProbe":{"httpGet":{"path":"/healthz","port":"probes"},"initialDelaySeconds":15,"periodSeconds":20,"timeoutSeconds":5},"logLevel":null,"logRemote":null,"nodeSelector":{},"podAnnotations":{"prometheus.io/port":"8080","prometheus.io/scrape":"true"},"podDisruptionBudget":{"enabled":true,"maxUnavailable":null,"minAvailable":null},"podLabels":{},"podSecurityContext":{"fsGroup":1000,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}},"ports":{"probes":{"name":"probes","port":8081}},"rbac":{"create":true},"readinessProbe":{"httpGet":{"path":"/readyz","port":"probes"},"initialDelaySeconds":5,"periodSeconds":10,"timeoutSeconds":5},"replicaCount":2,"resources":{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"128Mi"}},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true},"serviceAccount":{"annotations":{},"automount":true,"create":true,"name":""},"startupProbe":{"failureThreshold":50,"httpGet":{"path":"/healthz","port":"probes"},"periodSeconds":10,"timeoutSeconds":5},"tolerations":[],"traceRemote":null,"useDefaultAffinity":true}` | Cache component configuration |
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
| cache.podDisruptionBudget | object | `{"enabled":true,"maxUnavailable":null,"minAvailable":null}` | PodDisruptionBudget configuration for the Cache deployment. See: https://kubernetes.io/docs/tasks/run-application/configure-pdb/ |
| cache.podDisruptionBudget.enabled | bool | `true` | If true, creates a PodDisruptionBudget for the Cache deployment. This prevents downtime during voluntary disruptions (e.g., node upgrades). |
| cache.podDisruptionBudget.maxUnavailable | string | `nil` | Maximum number/percentage of pods that can be unavailable during a voluntary disruption. Cannot be used if 'minAvailable' is set. Example: 1 or "25%". If not set and PDB is enabled, defaults to 1. |
| cache.podDisruptionBudget.minAvailable | string | `nil` | Minimum number/percentage of pods that must remain available during a voluntary disruption. Cannot be used if 'maxUnavailable' is set. Example: 1 or "25%". |
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
| cache.serviceAccount.annotations | object | `{}` | Annotations to add to the ServiceAccount. Example: {"eks.amazonaws.com/role-arn": "arn:aws:iam::123456789012:role/YourKompassComputeCacheRole"} |
| cache.serviceAccount.automount | bool | `true` | If true, automatically mounts the service account token in the pod. |
| cache.serviceAccount.create | bool | `true` | If true, creates a ServiceAccount for the Cache component. |
| cache.serviceAccount.name | string | `""` | The name of the ServiceAccount to use. If not set and create is true, a name is generated using the fullname template. If create is false, this specifies an existing ServiceAccount to use. |
| cache.startupProbe | object | `{"failureThreshold":50,"httpGet":{"path":"/healthz","port":"probes"},"periodSeconds":10,"timeoutSeconds":5}` | Startup probe configuration for the Cache container. See: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/ |
| cache.tolerations | list | `[]` | Tolerations for scheduling Cache Pods. See: https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/ |
| cache.traceRemote | string | `nil` | Enable/disable remote tracing for the Cache component. |
| cache.useDefaultAffinity | bool | `true` | If true, applies default affinity rules. Ignored if 'affinity' is set. |
| cachePullMappings | object | `{}` | Configuration for mapping image registries to proxies/caches |
| developmentMode | bool | `false` | Global setting for development mode features for all components. Can be overridden per component. |
| fullnameOverride | string | `nil` | Override the full name of the chart. |
| hiberscaler | object | `{"affinity":{},"developmentMode":null,"enabled":true,"extraArgs":[],"extraEnv":[],"extraVolumeMounts":[],"extraVolumes":[],"image":{"pullPolicy":"Always","repository":"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/hiberscaler-controller","tag":""},"livenessProbe":{"httpGet":{"path":"/healthz","port":"probes"},"initialDelaySeconds":15,"periodSeconds":20,"timeoutSeconds":5},"logLevel":null,"logRemote":null,"nodeSelector":{},"podAnnotations":{"prometheus.io/port":"8080","prometheus.io/scrape":"true"},"podDisruptionBudget":{"enabled":false,"maxUnavailable":null,"minAvailable":null},"podLabels":{},"podSecurityContext":{"fsGroup":1000,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}},"ports":{"metrics":{"name":"metrics","port":8080},"nodeServer":{"name":"node-server","port":8082},"probes":{"name":"probes","port":8081},"webServer":{"name":"webhook-server","port":9443,"servicePort":443,"serviceType":"ClusterIP"}},"rbac":{"create":true},"readinessProbe":{"httpGet":{"path":"/readyz","port":"probes"},"initialDelaySeconds":5,"periodSeconds":10,"timeoutSeconds":5},"replicaCount":1,"resources":{"limits":{"cpu":"2000m","memory":"4096Mi"},"requests":{"cpu":"2000m","memory":"4096Mi"}},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true},"serviceAccount":{"annotations":{},"automount":true,"create":true,"name":""},"startupProbe":{"failureThreshold":50,"httpGet":{"path":"/healthz","port":"probes"},"periodSeconds":10,"timeoutSeconds":5},"tolerations":[],"traceRemote":null,"useDefaultAffinity":true}` | Hiberscaler component configuration |
| hiberscaler.affinity | object | `{}` | Affinity rules for scheduling Hiberscaler Pods. Overrides default affinity if set. |
| hiberscaler.developmentMode | string | `nil` | Enable/disable development mode for the Hiberscaler component. |
| hiberscaler.enabled | bool | `true` | If true, deploys the Hiberscaler component. |
| hiberscaler.extraArgs | list | `[]` | Extra command-line arguments to pass to the Hiberscaler container. |
| hiberscaler.extraEnv | list | `[]` | Extra environment variables to set in the Hiberscaler container. |
| hiberscaler.extraVolumeMounts | list | `[]` | Extra volume mounts to add to the Hiberscaler container. |
| hiberscaler.extraVolumes | list | `[]` | Extra volumes to add to the Hiberscaler container. |
| hiberscaler.image | object | `{"pullPolicy":"Always","repository":"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/hiberscaler-controller","tag":""}` | Image configuration for the Hiberscaler component. |
| hiberscaler.image.pullPolicy | string | `"Always"` | Image pull policy. |
| hiberscaler.image.repository | string | `"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/hiberscaler-controller"` | Image repository for the Hiberscaler component. |
| hiberscaler.image.tag | string | `""` | Specific image tag for the Hiberscaler component. |
| hiberscaler.livenessProbe | object | `{"httpGet":{"path":"/healthz","port":"probes"},"initialDelaySeconds":15,"periodSeconds":20,"timeoutSeconds":5}` | Liveness probe configuration for the Hiberscaler container. |
| hiberscaler.logLevel | string | `nil` | Log level for the Hiberscaler component. |
| hiberscaler.logRemote | string | `nil` | Enable/disable remote logging for the Hiberscaler component. |
| hiberscaler.nodeSelector | object | `{}` | Node selector for scheduling Hiberscaler Pods. |
| hiberscaler.podAnnotations | object | `{"prometheus.io/port":"8080","prometheus.io/scrape":"true"}` | Annotations to add to the Hiberscaler Pods. |
| hiberscaler.podDisruptionBudget | object | `{"enabled":false,"maxUnavailable":null,"minAvailable":null}` | PodDisruptionBudget configuration for the Hiberscaler deployment. |
| hiberscaler.podDisruptionBudget.enabled | bool | `false` | If true, creates a PodDisruptionBudget for the Hiberscaler deployment. |
| hiberscaler.podDisruptionBudget.maxUnavailable | string | `nil` | Maximum number/percentage of pods that can be unavailable during a voluntary disruption. |
| hiberscaler.podDisruptionBudget.minAvailable | string | `nil` | Minimum number/percentage of pods that must remain available during a voluntary disruption. |
| hiberscaler.podLabels | object | `{}` | Labels to add to the Hiberscaler Pods. |
| hiberscaler.podSecurityContext | object | `{"fsGroup":1000,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}}` | Security context for the Hiberscaler Pods. |
| hiberscaler.ports | object | `{"metrics":{"name":"metrics","port":8080},"nodeServer":{"name":"node-server","port":8082},"probes":{"name":"probes","port":8081},"webServer":{"name":"webhook-server","port":9443,"servicePort":443,"serviceType":"ClusterIP"}}` | Port configuration for the Hiberscaler component. |
| hiberscaler.ports.metrics | object | `{"name":"metrics","port":8080}` | Port for metrics exposition (e.g., Prometheus). |
| hiberscaler.ports.metrics.name | string | `"metrics"` | Name of the metrics port. |
| hiberscaler.ports.metrics.port | int | `8080` | Port number for metrics exposition. |
| hiberscaler.ports.nodeServer | object | `{"name":"node-server","port":8082}` | Port for the Node server. |
| hiberscaler.ports.nodeServer.name | string | `"node-server"` | Name of the node server port. |
| hiberscaler.ports.nodeServer.port | int | `8082` | Port number for the Node server. |
| hiberscaler.ports.probes | object | `{"name":"probes","port":8081}` | Port for health and readiness probes. |
| hiberscaler.ports.probes.name | string | `"probes"` | Name of the probes port. |
| hiberscaler.ports.probes.port | int | `8081` | Port number for health and readiness probes. |
| hiberscaler.ports.webServer | object | `{"name":"webhook-server","port":9443,"servicePort":443,"serviceType":"ClusterIP"}` | Port for the webhook server. |
| hiberscaler.ports.webServer.name | string | `"webhook-server"` | Name of the webhook server port. |
| hiberscaler.ports.webServer.port | int | `9443` | Port number for the webhook server. |
| hiberscaler.ports.webServer.servicePort | int | `443` | Port exposed by the webhook service. |
| hiberscaler.ports.webServer.serviceType | string | `"ClusterIP"` | Service type for the webhook. |
| hiberscaler.rbac | object | `{"create":true}` | RBAC configuration for the Hiberscaler component. |
| hiberscaler.rbac.create | bool | `true` | If true, creates RBAC resources for the Hiberscaler component. |
| hiberscaler.readinessProbe | object | `{"httpGet":{"path":"/readyz","port":"probes"},"initialDelaySeconds":5,"periodSeconds":10,"timeoutSeconds":5}` | Readiness probe configuration for the Hiberscaler container. |
| hiberscaler.replicaCount | int | `1` | Number of replicas for the Hiberscaler Deployment. |
| hiberscaler.resources | object | `{"limits":{"cpu":"2000m","memory":"4096Mi"},"requests":{"cpu":"2000m","memory":"4096Mi"}}` | Resource requests and limits for the Hiberscaler Pods. |
| hiberscaler.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true}` | Security context for the Hiberscaler containers. |
| hiberscaler.serviceAccount | object | `{"annotations":{},"automount":true,"create":true,"name":""}` | ServiceAccount configuration for the Hiberscaler component. |
| hiberscaler.serviceAccount.annotations | object | `{}` | Annotations to add to the ServiceAccount. Example: {"eks.amazonaws.com/role-arn": "arn:aws:iam::123456789012:role/YourKompassComputeHiberscalerRole"} |
| hiberscaler.serviceAccount.automount | bool | `true` | If true, automatically mounts the service account token in the pod. |
| hiberscaler.serviceAccount.create | bool | `true` | If true, creates a ServiceAccount for the Hiberscaler component. |
| hiberscaler.serviceAccount.name | string | `""` | The name of the ServiceAccount to use. If not set and create is true, a name is generated using the fullname template. If create is false, this specifies an existing ServiceAccount to use. |
| hiberscaler.startupProbe | object | `{"failureThreshold":50,"httpGet":{"path":"/healthz","port":"probes"},"periodSeconds":10,"timeoutSeconds":5}` | Startup probe configuration for the Hiberscaler container. |
| hiberscaler.tolerations | list | `[]` | Tolerations for scheduling Hiberscaler Pods. |
| hiberscaler.traceRemote | string | `nil` | Enable/disable remote tracing for the Hiberscaler component. |
| hiberscaler.useDefaultAffinity | bool | `true` | If true, applies default affinity (e.g., anti-affinity with other Hiberscaler pods on the same node if applicable). |
| imagePullSecrets | list | `[]` | Global image pull secrets A list of secrets to use for pulling images from private registries. Example: imagePullSecrets:   - name: "my-registry-secret" |
| imageSizeCalculator | object | `{"enabled":true,"extraEnv":[],"image":{"repository":"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/image-size-calculator","tag":""},"rbac":{"create":true},"serviceAccount":{"annotations":{},"automount":true,"create":true,"name":""}}` | ImageSizeCalculator component configuration This component is responsible for calculating the size of container images. It typically runs as a Job or a similar workload. |
| imageSizeCalculator.enabled | bool | `true` | If true, deploys resources related to the ImageSizeCalculator. |
| imageSizeCalculator.extraEnv | list | `[]` | Extra environment variables to set in the ImageSizeCalculator container. Example: extraEnv:   - name: SOME_VAR     value: 'some value' |
| imageSizeCalculator.image | object | `{"repository":"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/image-size-calculator","tag":""}` | Image configuration for the ImageSizeCalculator. |
| imageSizeCalculator.image.repository | string | `"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/image-size-calculator"` | Image repository for the ImageSizeCalculator. |
| imageSizeCalculator.image.tag | string | `""` | Specific image tag for the ImageSizeCalculator. If empty, uses the Chart's appVersion. |
| imageSizeCalculator.rbac | object | `{"create":true}` | RBAC configuration for the ImageSizeCalculator. |
| imageSizeCalculator.rbac.create | bool | `true` | If true, creates RBAC resources (e.g., Role, RoleBinding) for the ImageSizeCalculator. |
| imageSizeCalculator.serviceAccount | object | `{"annotations":{},"automount":true,"create":true,"name":""}` | ServiceAccount configuration for the ImageSizeCalculator. |
| imageSizeCalculator.serviceAccount.annotations | object | `{}` | Annotations to add to the ServiceAccount. Example: annotations:   eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/YourKompassComputeImageSizeCalculatorRole |
| imageSizeCalculator.serviceAccount.automount | bool | `true` | If true, automatically mounts the service account token into pods. |
| imageSizeCalculator.serviceAccount.create | bool | `true` | If true, a ServiceAccount is created for the ImageSizeCalculator. |
| imageSizeCalculator.serviceAccount.name | string | `""` | Name of the ServiceAccount for the ImageSizeCalculator. If empty, uses the generated name. |
| kompassInsightSecret | string | `"kompass-insights-secret"` | Name of the Kubernetes secret created by the Kompass Insight. |
| logLevel | string | `"info"` | Global log level for all components. Can be overridden per component. Valid levels: "debug", "info", "warn", "error". |
| logRemote | bool | `true` | Global setting to enable/disable remote logging for all components. Can be overridden per component. |
| monitorRemote | bool | `true` | Global setting to enable/disable remote monitoring for all components. Can be overridden per component. |
| nameOverride | string | `nil` | Override the chart name. |
| otel | object | `{"affinity":{},"developmentMode":null,"enabled":true,"extraArgs":[],"extraEnv":[],"extraVolumeMounts":[],"extraVolumes":[],"gomemlimit":"400MiB","image":{"pullPolicy":"Always","repository":"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/otel","tag":""},"livenessProbe":{"httpGet":{"path":"/","port":"probes"},"timeoutSeconds":10},"monitorRemote":null,"nodeSelector":{},"podAnnotations":{},"podDisruptionBudget":{"enabled":false,"maxUnavailable":null,"minAvailable":null},"podLabels":{},"podSecurityContext":{"fsGroup":1000,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}},"ports":{"otlp":{"name":"otlp","port":4317},"otlpHttp":{"name":"otlp-http","port":4318},"probes":{"name":"probes","port":13133}},"rbac":{"create":true},"readinessProbe":{"httpGet":{"path":"/","port":"probes"},"timeoutSeconds":8},"replicaCount":1,"resources":{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"200m","memory":"256Mi"}},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true},"serviceAccount":{"annotations":{},"automount":true,"create":true,"name":""},"startupProbe":{"failureThreshold":50,"httpGet":{"path":"/","port":"probes"}},"tolerations":[],"useDefaultAffinity":true}` | OTEL (OpenTelemetry) Collector configuration |
| otel.affinity | object | `{}` | Affinity rules for scheduling OTEL Collector Pods. Overrides default affinity if set. |
| otel.developmentMode | string | `nil` | Component-specific override for global developmentMode. |
| otel.enabled | bool | `true` | If true, deploys the OTEL Collector component. |
| otel.extraArgs | list | `[]` | Extra command-line arguments to pass to the OTEL Collector container. |
| otel.extraEnv | list | `[]` | Extra environment variables to set in the OTEL Collector container. |
| otel.extraVolumeMounts | list | `[]` | Additional volume mounts for the OTEL Collector containers. |
| otel.extraVolumes | list | `[]` | Additional volumes to mount in the OTEL Collector Pods. |
| otel.gomemlimit | string | `"400MiB"` | Go memory limit for the OTEL collector. Example: "400MiB". |
| otel.image | object | `{"pullPolicy":"Always","repository":"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/otel","tag":""}` | Image configuration for the OTEL Collector. |
| otel.image.pullPolicy | string | `"Always"` | Image pull policy. |
| otel.image.repository | string | `"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/otel"` | Image repository for the OTEL Collector. |
| otel.image.tag | string | `""` | Specific image tag for the OTEL Collector. |
| otel.livenessProbe | object | `{"httpGet":{"path":"/","port":"probes"},"timeoutSeconds":10}` | Liveness probe configuration for the OTEL Collector container. |
| otel.monitorRemote | string | `nil` | Component-specific override for global monitorRemote. |
| otel.nodeSelector | object | `{}` | Node selector for scheduling OTEL Collector Pods. |
| otel.podAnnotations | object | `{}` | Annotations to add to the OTEL Collector Pods. |
| otel.podDisruptionBudget | object | `{"enabled":false,"maxUnavailable":null,"minAvailable":null}` | PodDisruptionBudget configuration for the OTEL Collector deployment. |
| otel.podDisruptionBudget.enabled | bool | `false` | If true, creates a PodDisruptionBudget for the OTEL Collector deployment. |
| otel.podDisruptionBudget.maxUnavailable | string | `nil` | Maximum number/percentage of pods that can be unavailable during a voluntary disruption. |
| otel.podDisruptionBudget.minAvailable | string | `nil` | Minimum number/percentage of pods that must remain available during a voluntary disruption. |
| otel.podLabels | object | `{}` | Labels to add to the OTEL Collector Pods. |
| otel.podSecurityContext | object | `{"fsGroup":1000,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}}` | Security context for the OTEL Collector Pods. |
| otel.ports | object | `{"otlp":{"name":"otlp","port":4317},"otlpHttp":{"name":"otlp-http","port":4318},"probes":{"name":"probes","port":13133}}` | Port configuration for the OTEL Collector. |
| otel.ports.otlp | object | `{"name":"otlp","port":4317}` | Port for OTLP gRPC receiver. |
| otel.ports.otlp.name | string | `"otlp"` | Name of the port for OTLP gRPC receiver. |
| otel.ports.otlp.port | int | `4317` | Port number for OTLP gRPC receiver. |
| otel.ports.otlpHttp | object | `{"name":"otlp-http","port":4318}` | Port for OTLP HTTP receiver. |
| otel.ports.otlpHttp.name | string | `"otlp-http"` | Name of the port for OTLP HTTP receiver. |
| otel.ports.otlpHttp.port | int | `4318` | Port number for OTLP HTTP receiver. |
| otel.ports.probes | object | `{"name":"probes","port":13133}` | Port for OTEL Collector's own health and readiness probes. |
| otel.ports.probes.name | string | `"probes"` | Name of the port for OTEL Collector's own health and readiness probes. |
| otel.ports.probes.port | int | `13133` | Port number for OTEL Collector's own health and readiness probes. |
| otel.rbac | object | `{"create":true}` | RBAC configuration for the OTEL Collector. |
| otel.rbac.create | bool | `true` | If true, creates RBAC resources for the OTEL Collector. |
| otel.readinessProbe | object | `{"httpGet":{"path":"/","port":"probes"},"timeoutSeconds":8}` | Readiness probe configuration for the OTEL Collector container. |
| otel.replicaCount | int | `1` | Number of replicas for the OTEL Collector Deployment. |
| otel.resources | object | `{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"200m","memory":"256Mi"}}` | Resource requests and limits for the OTEL Collector Pods. |
| otel.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true}` | Security context for the OTEL Collector containers. |
| otel.serviceAccount | object | `{"annotations":{},"automount":true,"create":true,"name":""}` | ServiceAccount configuration for the OTEL Collector. |
| otel.serviceAccount.annotations | object | `{}` | Annotations to add to the ServiceAccount. |
| otel.serviceAccount.automount | bool | `true` | If true, automatically mounts the service account token in the pod. |
| otel.serviceAccount.create | bool | `true` | If true, creates a ServiceAccount for the OTEL Collector. |
| otel.serviceAccount.name | string | `""` | The name of the ServiceAccount to use. |
| otel.startupProbe | object | `{"failureThreshold":50,"httpGet":{"path":"/","port":"probes"}}` | Startup probe configuration for the OTEL Collector container. |
| otel.tolerations | list | `[]` | Tolerations for scheduling OTEL Collector Pods. |
| otel.useDefaultAffinity | bool | `true` | If true, applies default affinity rules. Ignored if 'affinity' is set. |
| qnode | object | `{"enabled":true}` | QNode specific configuration |
| qnode.enabled | bool | `true` | If true, enables QNode specific features or deployments. The exact impact depends on how this is used in templates. |
| qubexConfig | object | `{"architectures":null,"cacheConfig":{"acceptableLagResumeRatio":null,"additionalImages":null,"concurrentImagePullPerRevisionCreation":null,"concurrentLayerPullPerRevisionCreation":null,"diskFillAmount":null,"diskSize":null,"imageSizeCalculatorConfig":{"image":null,"jobNamePrefix":null,"pullSecrets":null,"serviceAccountName":null},"revisionCreationTimeout":null,"revisionMinCreationInterval":null,"shardsToMergeCount":null,"workloadExpirationTime":null,"workloadsExpirationCount":null,"workloadsPerRevisionCreation":null},"cloudProvider":"eks","defaultWorkloadProtectionThreshold":null,"disturbanceConfig":{"cooldownPeriod":null},"drainingConfig":{"drainGracePeriod":null,"replacementPodRetryInterval":null,"scaleInProtectionDuration":null},"enableExperimentalFeatures":null,"infraConfig":{"aws":{"additionalTags":null,"autodiscovery":true,"baseDiskSize":null,"containerRuntime":null,"enableM7FlexInstances":null,"enableNonTrunkingInstances":null,"resumeVMStartInstanceBucketSize":null,"resumeVMStartInstanceFillRate":null,"s3VpcEndpointID":null,"s3VpcEndpointIPAddresses":null,"spotFailuresQueueUrl":null,"zones":null}},"instanceTypeMaxCPU":null,"instanceTypesCount":null,"nodeAgentHTTPAddressPrefix":null,"resumingNodesRatio":null,"snapshooterInterval":null,"spotOceanConfig":{"enable":null,"spotOceanID":null,"spotOceanSecretAccountKey":null,"spotOceanSecretName":null,"spotOceanSecretNamespace":null,"spotOceanSecretTokenKey":null},"zestyConfig":{"uploadInterval":null}}` | QubexConfig |
| qubexConfig.architectures | string | `nil` | List of supported architectures |
| qubexConfig.cacheConfig | object | `{"acceptableLagResumeRatio":null,"additionalImages":null,"concurrentImagePullPerRevisionCreation":null,"concurrentLayerPullPerRevisionCreation":null,"diskFillAmount":null,"diskSize":null,"imageSizeCalculatorConfig":{"image":null,"jobNamePrefix":null,"pullSecrets":null,"serviceAccountName":null},"revisionCreationTimeout":null,"revisionMinCreationInterval":null,"shardsToMergeCount":null,"workloadExpirationTime":null,"workloadsExpirationCount":null,"workloadsPerRevisionCreation":null}` | Configuration for container image caching |
| qubexConfig.cacheConfig.acceptableLagResumeRatio | string | `nil` | Acceptable ratio of missing images in cache to qualify for resumption |
| qubexConfig.cacheConfig.additionalImages | string | `nil` | List of custom images which have to be cached |
| qubexConfig.cacheConfig.concurrentImagePullPerRevisionCreation | string | `nil` | Number of concurrent image pulls per revision creation |
| qubexConfig.cacheConfig.concurrentLayerPullPerRevisionCreation | string | `nil` | Number of concurrent layers pulls per revision creation |
| qubexConfig.cacheConfig.diskFillAmount | string | `nil` | The amount of disk which can be filled by cached images |
| qubexConfig.cacheConfig.diskSize | string | `nil` | The disk size for container cache in GB |
| qubexConfig.cacheConfig.imageSizeCalculatorConfig | object | `{"image":null,"jobNamePrefix":null,"pullSecrets":null,"serviceAccountName":null}` | Configuration for image size calculator |
| qubexConfig.cacheConfig.imageSizeCalculatorConfig.image | string | `nil` | Override the image size calculator image if you want to use a custom one |
| qubexConfig.cacheConfig.imageSizeCalculatorConfig.jobNamePrefix | string | `nil` | Override the image size calculator job name if you want to use a custom one |
| qubexConfig.cacheConfig.imageSizeCalculatorConfig.pullSecrets | string | `nil` | Override the image size calculator pull secrets if you want to use a custom one |
| qubexConfig.cacheConfig.imageSizeCalculatorConfig.serviceAccountName | string | `nil` | Override the image size calculator service account name if you want to use a custom one |
| qubexConfig.cacheConfig.revisionCreationTimeout | string | `nil` | Timeout for QCacheRevisionCreation to finish |
| qubexConfig.cacheConfig.revisionMinCreationInterval | string | `nil` | Default interval between QCache revisions creation |
| qubexConfig.cacheConfig.shardsToMergeCount | string | `nil` | Number of shards to merge |
| qubexConfig.cacheConfig.workloadExpirationTime | string | `nil` | Old Workload expiration time |
| qubexConfig.cacheConfig.workloadsExpirationCount | string | `nil` | Old Workload expiration count |
| qubexConfig.cacheConfig.workloadsPerRevisionCreation | string | `nil` | Number of workloads per RevisionCreation |
| qubexConfig.cloudProvider | string | `"eks"` | The cloud provider |
| qubexConfig.defaultWorkloadProtectionThreshold | string | `nil` | The default workload protection threshold |
| qubexConfig.disturbanceConfig | object | `{"cooldownPeriod":null}` | Configuration for disturbance handling |
| qubexConfig.disturbanceConfig.cooldownPeriod | string | `nil` | Time to wait for disturbance to be cold before committing a disturbance event |
| qubexConfig.drainingConfig | object | `{"drainGracePeriod":null,"replacementPodRetryInterval":null,"scaleInProtectionDuration":null}` | Configuration for node draining |
| qubexConfig.drainingConfig.drainGracePeriod | string | `nil` | The grace period of self managed drain before force termination |
| qubexConfig.drainingConfig.replacementPodRetryInterval | string | `nil` | The time after Qubex will create another replacement pod for the same workload |
| qubexConfig.drainingConfig.scaleInProtectionDuration | string | `nil` | Scale in protection for Qubex VMs. Before this time elapses, machines will not be scheduled for removal |
| qubexConfig.enableExperimentalFeatures | string | `nil` | Enable experimental features |
| qubexConfig.infraConfig | object | `{"aws":{"additionalTags":null,"autodiscovery":true,"baseDiskSize":null,"containerRuntime":null,"enableM7FlexInstances":null,"enableNonTrunkingInstances":null,"resumeVMStartInstanceBucketSize":null,"resumeVMStartInstanceFillRate":null,"s3VpcEndpointID":null,"s3VpcEndpointIPAddresses":null,"spotFailuresQueueUrl":null,"zones":null}}` | Infrastructure configuration |
| qubexConfig.infraConfig.aws | object | `{"additionalTags":null,"autodiscovery":true,"baseDiskSize":null,"containerRuntime":null,"enableM7FlexInstances":null,"enableNonTrunkingInstances":null,"resumeVMStartInstanceBucketSize":null,"resumeVMStartInstanceFillRate":null,"s3VpcEndpointID":null,"s3VpcEndpointIPAddresses":null,"spotFailuresQueueUrl":null,"zones":null}` | AWS specific configuration |
| qubexConfig.infraConfig.aws.additionalTags | string | `nil` | Additional AWS tags added to resources created by Qubex Controllers |
| qubexConfig.infraConfig.aws.autodiscovery | bool | `true` | Whether or not to enable autodiscovery, used for preventing race conditions during uninstallation |
| qubexConfig.infraConfig.aws.baseDiskSize | string | `nil` | The disk size used by Qubex VMs will be (BaseDiskSize + <instance memory size>) |
| qubexConfig.infraConfig.aws.containerRuntime | string | `nil` | The type of container runtime to use |
| qubexConfig.infraConfig.aws.enableM7FlexInstances | string | `nil` | Enable m7i-flex instances |
| qubexConfig.infraConfig.aws.enableNonTrunkingInstances | string | `nil` | Enable non-trunking instances |
| qubexConfig.infraConfig.aws.resumeVMStartInstanceBucketSize | string | `nil` | Bucket size used to cover for AWS API rate limit token bucket implementation |
| qubexConfig.infraConfig.aws.resumeVMStartInstanceFillRate | string | `nil` | Bucket fill rate used to cover for AWS API rate limit token bucket implementation |
| qubexConfig.infraConfig.aws.s3VpcEndpointID | string | `nil` | The ID of the S3 VPC endpoint |
| qubexConfig.infraConfig.aws.s3VpcEndpointIPAddresses | string | `nil` | The IP addresses for S3 VPC endpoint per region |
| qubexConfig.infraConfig.aws.spotFailuresQueueUrl | string | `nil` | The SQS queue for spot failures events |
| qubexConfig.infraConfig.aws.zones | string | `nil` | The zones to take into account |
| qubexConfig.instanceTypeMaxCPU | string | `nil` | Maximum CPU for instance type |
| qubexConfig.instanceTypesCount | string | `nil` | How many instance types should be selected for each QScaler |
| qubexConfig.nodeAgentHTTPAddressPrefix | string | `nil` | Path to NodeAgent HTTP address prefix The S3 bucket from which the QNode will download the Qubex assets Override the node agent HTTP address prefix if you want to use a custom one. Default is https://kompass-compute.s3.eu-west-1.amazonaws.com/<HIBERSCALER_TAG> |
| qubexConfig.resumingNodesRatio | string | `nil` | The ratio between the number of VM resumed and the number of the VMs that will be allowed to join the cluster |
| qubexConfig.snapshooterInterval | string | `nil` | Snapshooter interval |
| qubexConfig.spotOceanConfig | object | `{"enable":null,"spotOceanID":null,"spotOceanSecretAccountKey":null,"spotOceanSecretName":null,"spotOceanSecretNamespace":null,"spotOceanSecretTokenKey":null}` | Spot.io Ocean integration configuration |
| qubexConfig.spotOceanConfig.enable | string | `nil` | Enable turns on Spot.io Ocean integration |
| qubexConfig.spotOceanConfig.spotOceanID | string | `nil` | ID of the spot ocean cluster |
| qubexConfig.spotOceanConfig.spotOceanSecretAccountKey | string | `nil` | Key in the secret containing the spot.io account |
| qubexConfig.spotOceanConfig.spotOceanSecretName | string | `nil` | Name of the secret containing the spot.io credentials |
| qubexConfig.spotOceanConfig.spotOceanSecretNamespace | string | `nil` | Namespace of the secret containing the spot.io credentials |
| qubexConfig.spotOceanConfig.spotOceanSecretTokenKey | string | `nil` | Key in the secret containing the spot.io token |
| qubexConfig.zestyConfig | object | `{"uploadInterval":null}` | Zesty configuration |
| qubexConfig.zestyConfig.uploadInterval | string | `nil` | Upload interval |
| snapshooter | object | `{"affinity":{},"developmentMode":null,"enabled":true,"extraArgs":[],"extraEnv":[],"extraVolumeMounts":[],"extraVolumes":[],"image":{"pullPolicy":"Always","repository":"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/snapshooter","tag":""},"livenessProbe":{"httpGet":{"path":"/healthz","port":"probes"},"initialDelaySeconds":15,"periodSeconds":20,"timeoutSeconds":5},"logLevel":null,"logRemote":null,"nodeSelector":{},"podAnnotations":{},"podDisruptionBudget":{"enabled":false,"maxUnavailable":null,"minAvailable":null},"podLabels":{},"podSecurityContext":{"fsGroup":1000,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}},"ports":{"probes":{"name":"probes","port":8081}},"rbac":{"create":true},"readinessProbe":{"httpGet":{"path":"/readyz","port":"probes"},"initialDelaySeconds":5,"periodSeconds":10,"timeoutSeconds":5},"replicaCount":1,"resources":{"limits":{"cpu":"300m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"128Mi"}},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true},"serviceAccount":{"annotations":{},"automount":true,"create":true,"name":""},"startupProbe":{"failureThreshold":50,"httpGet":{"path":"/healthz","port":"probes"},"periodSeconds":10,"timeoutSeconds":5},"terminationGracePeriodSeconds":60,"tolerations":[],"traceRemote":null,"useDefaultAffinity":true}` | Snapshooter component configuration |
| snapshooter.affinity | object | `{}` | Affinity rules for scheduling Snapshooter pods. Overrides default affinity if set |
| snapshooter.developmentMode | string | `nil` | Component-specific override for global development mode |
| snapshooter.enabled | bool | `true` | If true, deploys the Snapshooter component |
| snapshooter.extraArgs | list | `[]` | Additional command line arguments for the Snapshooter container |
| snapshooter.extraEnv | list | `[]` | Additional environment variables for the Snapshooter container |
| snapshooter.extraVolumeMounts | list | `[]` | Additional volume mounts for the Snapshooter container |
| snapshooter.extraVolumes | list | `[]` | Additional volumes to mount in the Snapshooter pods |
| snapshooter.image | object | `{"pullPolicy":"Always","repository":"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/snapshooter","tag":""}` | Image configuration for the Snapshooter component |
| snapshooter.image.pullPolicy | string | `"Always"` | Image pull policy for the Snapshooter component |
| snapshooter.image.repository | string | `"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/snapshooter"` | Image repository for the Snapshooter component |
| snapshooter.image.tag | string | `""` | Specific image tag for the Snapshooter component |
| snapshooter.livenessProbe | object | `{"httpGet":{"path":"/healthz","port":"probes"},"initialDelaySeconds":15,"periodSeconds":20,"timeoutSeconds":5}` | Liveness probe configuration for the Snapshooter container |
| snapshooter.logLevel | string | `nil` | Component-specific override for global log level |
| snapshooter.logRemote | string | `nil` | Component-specific override for global remote logging configuration |
| snapshooter.nodeSelector | object | `{}` | Node selector for scheduling Snapshooter pods |
| snapshooter.podAnnotations | object | `{}` | Annotations to add to the Snapshooter pods |
| snapshooter.podDisruptionBudget | object | `{"enabled":false,"maxUnavailable":null,"minAvailable":null}` | PodDisruptionBudget configuration for the Snapshooter deployment |
| snapshooter.podDisruptionBudget.enabled | bool | `false` | If true, creates a PodDisruptionBudget for the Snapshooter deployment |
| snapshooter.podDisruptionBudget.maxUnavailable | string | `nil` | Maximum number/percentage of pods that can be unavailable during a voluntary disruption |
| snapshooter.podDisruptionBudget.minAvailable | string | `nil` | Minimum number/percentage of pods that must remain available during a voluntary disruption |
| snapshooter.podLabels | object | `{}` | Labels to add to the Snapshooter pods |
| snapshooter.podSecurityContext | object | `{"fsGroup":1000,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}}` | Security context for the Snapshooter pod |
| snapshooter.ports | object | `{"probes":{"name":"probes","port":8081}}` | Port configuration for the Snapshooter component |
| snapshooter.ports.probes | object | `{"name":"probes","port":8081}` | Port for Snapshooter health and readiness probes |
| snapshooter.ports.probes.name | string | `"probes"` | Name of the port for health and readiness probes |
| snapshooter.ports.probes.port | int | `8081` | Port number for health and readiness probes |
| snapshooter.rbac | object | `{"create":true}` | RBAC configuration for the Snapshooter component |
| snapshooter.rbac.create | bool | `true` | If true, creates RBAC resources for the Snapshooter component |
| snapshooter.readinessProbe | object | `{"httpGet":{"path":"/readyz","port":"probes"},"initialDelaySeconds":5,"periodSeconds":10,"timeoutSeconds":5}` | Readiness probe configuration for the Snapshooter container |
| snapshooter.replicaCount | int | `1` | Number of replicas for the Snapshooter Deployment |
| snapshooter.resources | object | `{"limits":{"cpu":"300m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"128Mi"}}` | Resource requests and limits for the Snapshooter container |
| snapshooter.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true}` | Security context for the Snapshooter container |
| snapshooter.serviceAccount | object | `{"annotations":{},"automount":true,"create":true,"name":""}` | ServiceAccount configuration for the Snapshooter component |
| snapshooter.serviceAccount.annotations | object | `{}` | Annotations to add to the ServiceAccount |
| snapshooter.serviceAccount.automount | bool | `true` | If true, automounts the Kubernetes API credentials for the ServiceAccount |
| snapshooter.serviceAccount.create | bool | `true` | If true, creates a ServiceAccount for the Snapshooter component |
| snapshooter.serviceAccount.name | string | `""` | Name of the ServiceAccount to use |
| snapshooter.startupProbe | object | `{"failureThreshold":50,"httpGet":{"path":"/healthz","port":"probes"},"periodSeconds":10,"timeoutSeconds":5}` | Startup probe configuration for the Snapshooter container |
| snapshooter.terminationGracePeriodSeconds | int | `60` | Grace period (in seconds) for the Snapshooter pod to terminate |
| snapshooter.tolerations | list | `[]` | Tolerations for scheduling Snapshooter pods |
| snapshooter.traceRemote | string | `nil` | Component-specific override for global remote tracing configuration |
| snapshooter.useDefaultAffinity | bool | `true` | If true, applies default affinity rules. Ignored if 'affinity' is set |
| tag | string | `nil` | Global fallback image tag for all components. Used if a component's specific image.tag is not set. If this is also not set (null or empty), Chart.AppVersion is used as the default. |
| telemetryManager | object | `{"affinity":{},"developmentMode":null,"enabled":true,"extraArgs":[],"extraEnv":[],"extraVolumeMounts":[],"extraVolumes":[],"image":{"pullPolicy":"Always","repository":"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/telemetry-manager","tag":""},"livenessProbe":{"httpGet":{"path":"/healthz","port":"probes"},"initialDelaySeconds":15,"periodSeconds":20,"timeoutSeconds":5},"logLevel":null,"logRemote":null,"nodeSelector":{},"podAnnotations":{"prometheus.io/port":"8080","prometheus.io/scrape":"true"},"podDisruptionBudget":{"enabled":false,"maxUnavailable":null,"minAvailable":null},"podLabels":{},"podSecurityContext":{"fsGroup":1000,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}},"ports":{"metrics":{"name":"metrics","port":8080},"probes":{"name":"probes","port":8081}},"rbac":{"create":true},"readinessProbe":{"httpGet":{"path":"/readyz","port":"probes"},"initialDelaySeconds":5,"periodSeconds":10,"timeoutSeconds":5},"replicaCount":1,"resources":{"limits":{"cpu":"400m","memory":"512Mi"},"requests":{"cpu":"200m","memory":"256Mi"}},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true},"serviceAccount":{"annotations":{},"automount":true,"create":true,"name":""},"startupProbe":{"failureThreshold":50,"httpGet":{"path":"/healthz","port":"probes"},"periodSeconds":10,"timeoutSeconds":5},"tolerations":[],"traceRemote":null,"useDefaultAffinity":true}` | Telemetry Manager component configuration |
| telemetryManager.affinity | object | `{}` | Affinity rules for scheduling Telemetry Manager pods. Overrides default affinity if set |
| telemetryManager.developmentMode | string | `nil` | Component-specific override for global development mode |
| telemetryManager.enabled | bool | `true` | If true, deploys the Telemetry Manager component |
| telemetryManager.extraArgs | list | `[]` | Additional command line arguments for the Telemetry Manager container |
| telemetryManager.extraEnv | list | `[]` | Additional environment variables for the Telemetry Manager container |
| telemetryManager.extraVolumeMounts | list | `[]` | Additional volume mounts for the Telemetry Manager container |
| telemetryManager.extraVolumes | list | `[]` | Additional volumes to mount in the Telemetry Manager pods |
| telemetryManager.image | object | `{"pullPolicy":"Always","repository":"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/telemetry-manager","tag":""}` | Image configuration for the Telemetry Manager component |
| telemetryManager.image.pullPolicy | string | `"Always"` | Image pull policy for the Telemetry Manager container |
| telemetryManager.image.repository | string | `"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/telemetry-manager"` | Image repository for the Telemetry Manager component |
| telemetryManager.image.tag | string | `""` | Specific image tag for the Telemetry Manager component |
| telemetryManager.livenessProbe | object | `{"httpGet":{"path":"/healthz","port":"probes"},"initialDelaySeconds":15,"periodSeconds":20,"timeoutSeconds":5}` | Liveness probe configuration for the Telemetry Manager container |
| telemetryManager.logLevel | string | `nil` | Component-specific override for global log level |
| telemetryManager.logRemote | string | `nil` | Component-specific override for global log remote endpoint |
| telemetryManager.nodeSelector | object | `{}` | Node selector for scheduling Telemetry Manager pods |
| telemetryManager.podAnnotations | object | `{"prometheus.io/port":"8080","prometheus.io/scrape":"true"}` | Annotations to add to the Telemetry Manager Pods |
| telemetryManager.podDisruptionBudget | object | `{"enabled":false,"maxUnavailable":null,"minAvailable":null}` | PodDisruptionBudget configuration for the Telemetry Manager deployment |
| telemetryManager.podDisruptionBudget.enabled | bool | `false` | If true, creates a PodDisruptionBudget for the Telemetry Manager deployment |
| telemetryManager.podDisruptionBudget.maxUnavailable | string | `nil` | Maximum number/percentage of pods that can be unavailable during a voluntary disruption |
| telemetryManager.podDisruptionBudget.minAvailable | string | `nil` | Minimum number/percentage of pods that must remain available during a voluntary disruption |
| telemetryManager.podLabels | object | `{}` | Additional labels to add to the Telemetry Manager Pods |
| telemetryManager.podSecurityContext | object | `{"fsGroup":1000,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}}` | Security context for the Telemetry Manager pods |
| telemetryManager.ports | object | `{"metrics":{"name":"metrics","port":8080},"probes":{"name":"probes","port":8081}}` | Port configuration for the Telemetry Manager component |
| telemetryManager.ports.metrics | object | `{"name":"metrics","port":8080}` | Port for metrics exposition |
| telemetryManager.ports.metrics.name | string | `"metrics"` | Name of the port |
| telemetryManager.ports.metrics.port | int | `8080` | Port number for metrics exposition |
| telemetryManager.ports.probes | object | `{"name":"probes","port":8081}` | Port for Telemetry Manager health and readiness probes |
| telemetryManager.ports.probes.name | string | `"probes"` | Name of the port |
| telemetryManager.ports.probes.port | int | `8081` | Port number for the Telemetry Manager health and readiness probes |
| telemetryManager.rbac | object | `{"create":true}` | RBAC configuration for the Telemetry Manager component |
| telemetryManager.rbac.create | bool | `true` | If true, creates RBAC resources for the Telemetry Manager component |
| telemetryManager.readinessProbe | object | `{"httpGet":{"path":"/readyz","port":"probes"},"initialDelaySeconds":5,"periodSeconds":10,"timeoutSeconds":5}` | Readiness probe configuration for the Telemetry Manager container |
| telemetryManager.replicaCount | int | `1` | Number of replicas for the Telemetry Manager Deployment |
| telemetryManager.resources | object | `{"limits":{"cpu":"400m","memory":"512Mi"},"requests":{"cpu":"200m","memory":"256Mi"}}` | Resource requests and limits for the Telemetry Manager container |
| telemetryManager.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true}` | Security context for the Telemetry Manager container |
| telemetryManager.serviceAccount | object | `{"annotations":{},"automount":true,"create":true,"name":""}` | ServiceAccount configuration for the Telemetry Manager component |
| telemetryManager.serviceAccount.annotations | object | `{}` | Annotations to add to the ServiceAccount |
| telemetryManager.serviceAccount.automount | bool | `true` | If true, automounts the Kubernetes API credentials for the ServiceAccount |
| telemetryManager.serviceAccount.create | bool | `true` | If true, creates a ServiceAccount for the Telemetry Manager component |
| telemetryManager.serviceAccount.name | string | `""` | The name of the ServiceAccount to use |
| telemetryManager.startupProbe | object | `{"failureThreshold":50,"httpGet":{"path":"/healthz","port":"probes"},"periodSeconds":10,"timeoutSeconds":5}` | Startup probe configuration for the Telemetry Manager container |
| telemetryManager.tolerations | list | `[]` | Tolerations for scheduling Telemetry Manager pods |
| telemetryManager.traceRemote | string | `nil` | Component-specific override for global trace remote endpoint |
| telemetryManager.useDefaultAffinity | bool | `true` | If true, applies default affinity rules. Ignored if 'affinity' is set |
| traceRemote | bool | `true` | Global setting to enable/disable remote tracing for all components. Can be overridden per component. |
| uninstaller | object | `{"affinity":{},"developmentMode":null,"enabled":true,"extraArgs":[],"extraEnv":[],"extraVolumeMounts":[],"extraVolumes":[],"image":{"pullPolicy":"Always","repository":"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/uninstaller","tag":""},"logLevel":null,"logRemote":null,"nodeSelector":{},"podAnnotations":{},"podLabels":{},"podSecurityContext":{"fsGroup":1000,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}},"rbac":{"create":true},"resources":{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"128Mi"}},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true},"serviceAccount":{"annotations":{},"automount":true,"create":true,"name":""},"tolerations":[],"traceRemote":null}` | Uninstaller Job configuration This component is typically a Job responsible for cleanup tasks during chart uninstallation. |
| uninstaller.affinity | object | `{}` | Affinity rules for scheduling Uninstaller Pod |
| uninstaller.developmentMode | string | `nil` | Component-specific override for global development mode |
| uninstaller.enabled | bool | `true` | If true, resources for the Uninstaller Job are created |
| uninstaller.extraArgs | list | `[]` | Additional command line arguments for the Uninstaller container |
| uninstaller.extraEnv | list | `[]` | Additional environment variables for the Uninstaller container |
| uninstaller.extraVolumeMounts | list | `[]` | Additional volume mounts for the Uninstaller container |
| uninstaller.extraVolumes | list | `[]` | Additional volumes to mount in the Uninstaller Pod |
| uninstaller.image | object | `{"pullPolicy":"Always","repository":"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/uninstaller","tag":""}` | Image configuration for the Uninstaller Job |
| uninstaller.image.pullPolicy | string | `"Always"` | Image pull policy for the Uninstaller container |
| uninstaller.image.repository | string | `"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/uninstaller"` | Image repository for the Uninstaller container |
| uninstaller.image.tag | string | `""` | Specific image tag for the Uninstaller |
| uninstaller.logLevel | string | `nil` | Component-specific override for global log level |
| uninstaller.logRemote | string | `nil` | Component-specific override for global remote logging |
| uninstaller.nodeSelector | object | `{}` | Node selector for scheduling Uninstaller Pod |
| uninstaller.podAnnotations | object | `{}` | Annotations to add to the Uninstaller Pod |
| uninstaller.podLabels | object | `{}` | Additional labels to add to the Uninstaller Pod |
| uninstaller.podSecurityContext | object | `{"fsGroup":1000,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}}` | Security context for Uninstaller Pod |
| uninstaller.rbac | object | `{"create":true}` | RBAC configuration for the Uninstaller component |
| uninstaller.rbac.create | bool | `true` | If true, creates RBAC resources for the Uninstaller Job |
| uninstaller.resources | object | `{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"128Mi"}}` | Resource requests and limits for the Uninstaller container |
| uninstaller.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true}` | Security context for Uninstaller container |
| uninstaller.serviceAccount | object | `{"annotations":{},"automount":true,"create":true,"name":""}` | ServiceAccount configuration for the Uninstaller component |
| uninstaller.serviceAccount.annotations | object | `{}` | Annotations to add to the ServiceAccount |
| uninstaller.serviceAccount.automount | bool | `true` | If true, automounts the Kubernetes API credentials for the ServiceAccount |
| uninstaller.serviceAccount.create | bool | `true` | If true, creates a ServiceAccount for the Uninstaller |
| uninstaller.serviceAccount.name | string | `""` | The name of the ServiceAccount to use |
| uninstaller.tolerations | list | `[]` | Tolerations for scheduling Uninstaller Pod |
| uninstaller.traceRemote | string | `nil` | Component-specific override for global remote tracing |
| vector | object | `{"developmentMode":null,"enabled":true,"extraArgs":[],"extraEnv":[],"extraVolumeMounts":[],"extraVolumes":[],"image":{"pullPolicy":"Always","repository":"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/vector","tag":""},"logLevel":null,"normal":{"affinity":{},"nodeSelector":{},"tolerations":[{"operator":"Exists"}],"useDefaultAffinity":true},"podAnnotations":{},"podLabels":{},"podSecurityContext":{"fsGroup":1000,"runAsGroup":null,"runAsNonRoot":null,"runAsUser":null,"seccompProfile":{"type":"RuntimeDefault"}},"qNode":{"affinity":{},"nodeSelector":{},"tolerations":[{"operator":"Exists"}],"useDefaultAffinity":true},"rbac":{"create":true},"resources":{"limits":{"cpu":"300m","memory":"600Mi"},"requests":{"cpu":"10m","memory":"50Mi"}},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true},"serviceAccount":{"annotations":{},"automount":true,"create":true,"name":""}}` | Vector component configuration (for log aggregation/forwarding) |
| vector.developmentMode | string | `nil` | Component-specific override for global development mode |
| vector.enabled | bool | `true` | If true, deploys the Vector component (typically as a DaemonSet) |
| vector.extraArgs | list | `[]` | Additional command line arguments for the Vector container |
| vector.extraEnv | list | `[]` | Additional environment variables for the Vector container |
| vector.extraVolumeMounts | list | `[]` | Additional volume mounts for the Vector container |
| vector.extraVolumes | list | `[]` | Additional volumes to mount in the Vector pods |
| vector.image | object | `{"pullPolicy":"Always","repository":"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/vector","tag":""}` | Image configuration for Vector |
| vector.image.pullPolicy | string | `"Always"` | Image pull policy for Vector container |
| vector.image.repository | string | `"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/vector"` | Image repository for Vector |
| vector.image.tag | string | `""` | Specific image tag for Vector. Note: Vector often has its own versioning |
| vector.logLevel | string | `nil` | Component-specific override for global log level |
| vector.normal | object | `{"affinity":{},"nodeSelector":{},"tolerations":[{"operator":"Exists"}],"useDefaultAffinity":true}` | Configuration for Vector running on normal Kubernetes nodes |
| vector.normal.affinity | object | `{}` | Affinity settings for Vector pods on normal nodes |
| vector.normal.nodeSelector | object | `{}` | Node selector for Vector pods on normal nodes |
| vector.normal.tolerations | list | `[{"operator":"Exists"}]` | Tolerations for Vector pods on normal nodes |
| vector.normal.useDefaultAffinity | bool | `true` | If true, applies default affinity rules. Ignored if 'affinity' is set |
| vector.podAnnotations | object | `{}` | Annotations to add to the Vector Pods |
| vector.podLabels | object | `{}` | Additional labels to add to the Vector Pods |
| vector.podSecurityContext | object | `{"fsGroup":1000,"runAsGroup":null,"runAsNonRoot":null,"runAsUser":null,"seccompProfile":{"type":"RuntimeDefault"}}` | Security context for Vector Pods |
| vector.podSecurityContext.fsGroup | int | `1000` | Group ID for the filesystem used by Vector |
| vector.podSecurityContext.runAsGroup | string | `nil` | Group ID for Vector processes |
| vector.podSecurityContext.runAsNonRoot | string | `nil` | If true, Vector must run as a non-root user |
| vector.podSecurityContext.runAsUser | string | `nil` | User ID for Vector processes |
| vector.qNode | object | `{"affinity":{},"nodeSelector":{},"tolerations":[{"operator":"Exists"}],"useDefaultAffinity":true}` | Configuration for Vector running on QNode (Qubex specific nodes) |
| vector.qNode.affinity | object | `{}` | Affinity settings for Vector pods on QNodes |
| vector.qNode.nodeSelector | object | `{}` | Node selector for Vector pods on QNodes |
| vector.qNode.tolerations | list | `[{"operator":"Exists"}]` | Tolerations for Vector pods on QNodes |
| vector.qNode.useDefaultAffinity | bool | `true` | If true, applies default affinity rules. Ignored if 'affinity' is set |
| vector.rbac | object | `{"create":true}` | RBAC configuration for the Vector component |
| vector.rbac.create | bool | `true` | If true, creates RBAC resources for Vector |
| vector.resources | object | `{"limits":{"cpu":"300m","memory":"600Mi"},"requests":{"cpu":"10m","memory":"50Mi"}}` | Resource requests and limits for Vector containers |
| vector.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true}` | Security context for Vector containers |
| vector.securityContext.allowPrivilegeEscalation | bool | `false` | If true, allows the Vector process to gain more privileges than its parent process |
| vector.securityContext.readOnlyRootFilesystem | bool | `true` | If true, mounts the container's root filesystem as read-only |
| vector.serviceAccount | object | `{"annotations":{},"automount":true,"create":true,"name":""}` | ServiceAccount configuration for the Vector component |
| vector.serviceAccount.annotations | object | `{}` | Annotations to add to the ServiceAccount |
| vector.serviceAccount.automount | bool | `true` | If true, automounts the Kubernetes API credentials for the ServiceAccount |
| vector.serviceAccount.create | bool | `true` | If true, creates a ServiceAccount for Vector |
| vector.serviceAccount.name | string | `""` | The name of the ServiceAccount to use |