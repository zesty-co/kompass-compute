# Kompass Compute Helm Chart

This chart deploys the Kompass Compute components.

## Prerequisites

-   Kubernetes v1.19, or later
-   Helm v3.2.0, or later
-   Kompass Insight agent installed in the cluster
-   kompass-compute [terraform module](https://github.com/zesty-co/terraform-kompass-compute) installed
-   Pod Identity enabled in the cluster (alternatively, see [Use IAM Roles for Service Accounts (IRSA)](#use-iam-roles-for-service-accounts-irsa))

## Install the chart

The following example shows how to install the chart with the release name, `kompass-compute`:

```bash
helm repo add zesty-kompass-compute https://zesty-co.github.io/kompass-compute
helm repo update
helm install kompass-compute zesty-kompass-compute/kompass-compute --namespace zesty-system
```

>   **Note**: To enable Spot protection, you must provide the SQS queue URL in **values.yaml**.

## Advanced configuration

This section describes the following advanced configuration options:

-   [ECR pull through cache](#ecr-pull-through-cache)
-   [Spot interruption monitoring](#spot-interruption-monitoring)
-   [Use IAM Roles for Service Accounts (IRSA)](#use-iam-roles-for-service-accounts-irsa)

### ECR pull through cache

Caching the images on all hibernated nodes can increase network costs.

To reduce network costs, it is recommended to configure an ECR pull through cache and configure the nodes to pull images through it, thus only downloading each image from the internet once.

**To configure ECR pull through cache:**

1.  Create the ECR pull through cache rules for the desired container registries.
2.  Configure Kompass Compute to use those rules by configuring **values.yaml** as follows:

```yaml
cachePullMappings:
  dockerhub:
    - proxyAddress: "<ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/<DOCKER_PROXY_NAME>"
  ghcr:
    - proxyAddress: "<ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/<GHCR_PROXY_NAME>"
  # Add other registries as needed, e.g., ecr, k8s, quay
```

1.  To enable downloading from ECR through S3, configure an S3 VPC endpoint in your cluster. Enable Kompass Compute to access it by adding the following to values.yaml:

```yaml
qubexConfig:
  infraConfig:
    aws:
      s3VpcEndpointID: "vpce-..."
```

### Spot interruption monitoring

Kompass Compute monitors Spot interruptions through an SQS queue that was created by the [Kompass Compute Terraform module](https://github.com/zesty-co/terraform-kompass-compute).

**To configure Spot interruption monitoring:**

-   To connect the queue to the Kubernetes components, add the following to values.yaml:

```yaml
qubexConfig:
  infraConfig:
    aws:
      spotFailuresQueueUrl: "https://sqs.<REGION>.amazonaws.com/<ACCOUNT_ID>/<QUEUE_NAME>"
```

These values are typically obtained from the output of the [Kompass Compute Terraform module](https://github.com/zesty-co/terraform-kompass-compute).

### Use IAM Roles for Service Accounts (IRSA)

It's recommended to use EKS Pod Identity. If you must use IRSA, you need to configure it.

**To configure IRSA:**

1.  Create the necessary IAM roles and policies. 
    Use the [Kompass Compute Terraform module](https://github.com/zesty-co/terraform-kompass-compute) by specifying `enable_irsa = true` and `irsa_oidc_provider_arn=<OIDC_PROVIDER_ARN>`.
2.  Ensure that all controllers are configured to use IRSA by adding the following to values.yaml:

```yaml
# Ensure serviceAccount.create is true for each component if the chart manages them,
# or false if you manage them externally but still want to set annotations via Helm.

hiberscaler:
  serviceAccount:
    # create: true # Default is true
    annotations:
      "eks.amazonaws.com/role-arn": "arn:aws:iam::<ACCOUNT_ID>:role/<ROLE_NAME>"

imageSizeCalculator:
  serviceAccount:
    # create: true # Default is true
    annotations:
      "eks.amazonaws.com/role-arn": "arn:aws:iam::<ACCOUNT_ID>:role/<ROLE_NAME>"

snapshooter:
  serviceAccount:
    # create: true # Default is true
    annotations:
      "eks.amazonaws.com/role-arn": "arn:aws:iam::<ACCOUNT_ID>:role/<ROLE_NAME>"

telemetryManager:
  serviceAccount:
    # create: true # Default is true
    annotations:
      "eks.amazonaws.com/role-arn": "arn:aws:iam::<ACCOUNT_ID>:role/<ROLE_NAME>"

# If EKS Pod Identity is enabled in your cluster and you want to disable it for these pods
# (preferring IRSA), ensure no pod identity related labels/annotations are set by default,
# or override them if the chart provides such options.
```

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
| cache.podDisruptionBudget.enabled | bool | `true` | If true, creates a PodDisruptionBudget for the Cache deployment. This prevents downtime during voluntary disruptions (e.g., node upgrades). |
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
| hiberscaler | object | `{"affinity":{},"developmentMode":null,"enabled":true,"extraArgs":[],"extraEnv":[],"extraVolumeMounts":[],"extraVolumes":[],"image":{"pullPolicy":"Always","repository":"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/hiberscaler-controller","tag":""},"livenessProbe":{"httpGet":{"path":"/healthz","port":"probes"},"initialDelaySeconds":15,"periodSeconds":20,"timeoutSeconds":5},"logLevel":null,"logRemote":null,"nodeSelector":{},"podAnnotations":{"prometheus.io/port":"8080","prometheus.io/scrape":"true"},"podDisruptionBudget":{"enabled":false},"podLabels":{},"podSecurityContext":{"fsGroup":1000,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}},"ports":{"metrics":{"name":"metrics","port":8080},"nodeServer":{"name":"node-server","port":8082},"probes":{"name":"probes","port":8081},"webServer":{"name":"webhook-server","port":9443,"servicePort":443,"serviceType":"ClusterIP"}},"rbac":{"create":true},"readinessProbe":{"httpGet":{"path":"/readyz","port":"probes"},"initialDelaySeconds":5,"periodSeconds":10,"timeoutSeconds":5},"replicaCount":1,"resources":{"limits":{"cpu":"2000m","memory":"4096Mi"},"requests":{"cpu":"2000m","memory":"4096Mi"}},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true},"serviceAccount":{"annotations":{},"automount":true,"create":true,"name":""},"startupProbe":{"failureThreshold":50,"httpGet":{"path":"/healthz","port":"probes"},"periodSeconds":10,"timeoutSeconds":5},"tolerations":[],"traceRemote":null,"useDefaultAffinity":true}` | Hiberscaler component configuration |
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
| hiberscaler.podDisruptionBudget | object | `{"enabled":false}` | PodDisruptionBudget configuration for the Hiberscaler deployment. |
| hiberscaler.podDisruptionBudget.enabled | bool | `false` | If true, creates a PodDisruptionBudget for the Hiberscaler deployment. |
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
| imageSizeCalculator | object | `{"affinity":{},"enabled":true,"extraEnv":[],"image":{"repository":"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/image-size-calculator","tag":""},"nodeSelector":{},"podAnnotations":{},"podLabels":{},"podSecurityContext":{},"rbac":{"create":true},"resources":{"limits":{"cpu":"2000m","memory":"1024Mi"},"requests":{"cpu":"1000m","memory":"512Mi"}},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]}},"serviceAccount":{"annotations":{},"automount":true,"create":true,"name":""},"tolerations":[],"useDefaultAffinity":false}` | ImageSizeCalculator component configuration This component is responsible for calculating the size of container images. It typically runs as a Job or a similar workload. |
| imageSizeCalculator.affinity | object | `{}` | Affinity rules for scheduling ImageSizeCalculator Pods. Overrides default affinity if set. |
| imageSizeCalculator.enabled | bool | `true` | If true, deploys resources related to the ImageSizeCalculator. |
| imageSizeCalculator.extraEnv | list | `[]` | Extra environment variables to set in the ImageSizeCalculator container. Example: extraEnv:   - name: SOME_VAR     value: 'some value' |
| imageSizeCalculator.image | object | `{"repository":"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/image-size-calculator","tag":""}` | Image configuration for the ImageSizeCalculator. |
| imageSizeCalculator.image.repository | string | `"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/image-size-calculator"` | Image repository for the ImageSizeCalculator. |
| imageSizeCalculator.image.tag | string | `""` | Specific image tag for the ImageSizeCalculator. If empty, uses the Chart's appVersion. |
| imageSizeCalculator.nodeSelector | object | `{}` | Node selector for scheduling ImageSizeCalculator Pods. |
| imageSizeCalculator.podAnnotations | object | `{}` | Annotations to add to the ImageSizeCalculator Pods. |
| imageSizeCalculator.podLabels | object | `{}` | Labels to add to the ImageSizeCalculator Pods. |
| imageSizeCalculator.podSecurityContext | object | `{}` | Security context for the ImageSizeCalculator Pods. It requires root to run. |
| imageSizeCalculator.rbac | object | `{"create":true}` | RBAC configuration for the ImageSizeCalculator. |
| imageSizeCalculator.rbac.create | bool | `true` | If true, creates RBAC resources (e.g., Role, RoleBinding) for the ImageSizeCalculator. |
| imageSizeCalculator.resources | object | `{"limits":{"cpu":"2000m","memory":"1024Mi"},"requests":{"cpu":"1000m","memory":"512Mi"}}` | Resource requests and limits for the ImageSizeCalculator Pods. |
| imageSizeCalculator.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]}}` | Security context for the ImageSizeCalculator containers. |
| imageSizeCalculator.serviceAccount | object | `{"annotations":{},"automount":true,"create":true,"name":""}` | ServiceAccount configuration for the ImageSizeCalculator. |
| imageSizeCalculator.serviceAccount.annotations | object | `{}` | Annotations to add to the ServiceAccount. Example: annotations:   eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/YourKompassComputeImageSizeCalculatorRole |
| imageSizeCalculator.serviceAccount.automount | bool | `true` | If true, automatically mounts the service account token into pods. |
| imageSizeCalculator.serviceAccount.create | bool | `true` | If true, a ServiceAccount is created for the ImageSizeCalculator. |
| imageSizeCalculator.serviceAccount.name | string | `""` | Name of the ServiceAccount for the ImageSizeCalculator. If empty, uses the generated name. |
| imageSizeCalculator.tolerations | list | `[]` | Tolerations for scheduling ImageSizeCalculator Pods. |
| imageSizeCalculator.useDefaultAffinity | bool | `false` | If true, applies default affinity (e.g., anti-affinity with other ImageSizeCalculator pods on the same node if applicable). |
| kompassInsightSecret | string | `"kompass-insights-secret"` | Name of the Kubernetes secret created by the Kompass Insight. |
| logLevel | string | `"info"` | Global log level for all components. Can be overridden per component. Valid levels: "debug", "info", "warn", "error". |
| logRemote | bool | `true` | Global setting to enable/disable remote logging for all components. Can be overridden per component. |
| monitorRemote | bool | `true` | Global setting to enable/disable remote monitoring for all components. Can be overridden per component. |
| otel | object | `{"affinity":{},"developmentMode":null,"enabled":true,"extraArgs":[],"extraEnv":[],"extraVolumeMounts":[],"extraVolumes":[],"gomemlimit":"400MiB","image":{"pullPolicy":"Always","repository":"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/otel","tag":""},"livenessProbe":{"httpGet":{"path":"/","port":"probes"},"timeoutSeconds":10},"monitorRemote":null,"nodeSelector":{},"podAnnotations":{},"podDisruptionBudget":{"enabled":false},"podLabels":{},"podSecurityContext":{"fsGroup":1000,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}},"ports":{"otlp":{"name":"otlp","port":4317},"otlpHttp":{"name":"otlp-http","port":4318},"probes":{"name":"probes","port":13133}},"rbac":{"create":true},"readinessProbe":{"httpGet":{"path":"/","port":"probes"},"timeoutSeconds":8},"replicaCount":1,"resources":{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"200m","memory":"256Mi"}},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true},"serviceAccount":{"annotations":{},"automount":true,"create":true,"name":""},"startupProbe":{"failureThreshold":50,"httpGet":{"path":"/","port":"probes"}},"tolerations":[],"useDefaultAffinity":true}` | OTEL (OpenTelemetry) Collector configuration |
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
| otel.podDisruptionBudget | object | `{"enabled":false}` | PodDisruptionBudget configuration for the OTEL Collector deployment. |
| otel.podDisruptionBudget.enabled | bool | `false` | If true, creates a PodDisruptionBudget for the OTEL Collector deployment. |
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
| qubexConfig | object | `{"cacheConfig":{"imageSizeCalculatorConfig":null},"cloudProvider":"eks","disturbanceConfig":{},"drainingConfig":{},"infraConfig":{"aws":{}},"spotOceanConfig":{},"zestyConfig":{}}` | QubexConfig |
| qubexConfig.cacheConfig | object | `{"imageSizeCalculatorConfig":null}` | Configuration for container image caching |
| qubexConfig.cacheConfig.imageSizeCalculatorConfig | string | `nil` | Configuration for image size calculator |
| qubexConfig.cloudProvider | string | `"eks"` | The cloud provider |
| qubexConfig.disturbanceConfig | object | `{}` | Configuration for disturbance handling |
| qubexConfig.drainingConfig | object | `{}` | Configuration for node draining |
| qubexConfig.infraConfig.aws | object | `{}` | AWS specific configuration |
| qubexConfig.spotOceanConfig | object | `{}` | Spot.io Ocean integration configuration |
| qubexConfig.zestyConfig | object | `{}` | Zesty configuration |
| snapshooter | object | `{"affinity":{},"developmentMode":null,"enabled":true,"extraArgs":[],"extraEnv":[],"extraVolumeMounts":[],"extraVolumes":[],"image":{"pullPolicy":"Always","repository":"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/snapshooter","tag":""},"livenessProbe":{"httpGet":{"path":"/healthz","port":"probes"},"initialDelaySeconds":15,"periodSeconds":20,"timeoutSeconds":5},"logLevel":null,"logRemote":null,"nodeSelector":{},"podAnnotations":{},"podDisruptionBudget":{"enabled":false},"podLabels":{},"podSecurityContext":{"fsGroup":1000,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}},"ports":{"probes":{"name":"probes","port":8081}},"rbac":{"create":true},"readinessProbe":{"httpGet":{"path":"/readyz","port":"probes"},"initialDelaySeconds":5,"periodSeconds":10,"timeoutSeconds":5},"replicaCount":1,"resources":{"limits":{"cpu":"300m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"128Mi"}},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true},"serviceAccount":{"annotations":{},"automount":true,"create":true,"name":""},"startupProbe":{"failureThreshold":50,"httpGet":{"path":"/healthz","port":"probes"},"periodSeconds":10,"timeoutSeconds":5},"terminationGracePeriodSeconds":60,"tolerations":[],"traceRemote":null,"useDefaultAffinity":true}` | Snapshooter component configuration |
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
| snapshooter.podDisruptionBudget | object | `{"enabled":false}` | PodDisruptionBudget configuration for the Snapshooter deployment |
| snapshooter.podDisruptionBudget.enabled | bool | `false` | If true, creates a PodDisruptionBudget for the Snapshooter deployment |
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
| telemetryManager | object | `{"affinity":{},"developmentMode":null,"enabled":true,"extraArgs":[],"extraEnv":[],"extraVolumeMounts":[],"extraVolumes":[],"image":{"pullPolicy":"Always","repository":"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/telemetry-manager","tag":""},"livenessProbe":{"httpGet":{"path":"/healthz","port":"probes"},"initialDelaySeconds":15,"periodSeconds":20,"timeoutSeconds":5},"logLevel":null,"logRemote":null,"nodeSelector":{},"podAnnotations":{"prometheus.io/port":"8080","prometheus.io/scrape":"true"},"podDisruptionBudget":{"enabled":false},"podLabels":{},"podSecurityContext":{"fsGroup":1000,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}},"ports":{"metrics":{"name":"metrics","port":8080},"probes":{"name":"probes","port":8081}},"rbac":{"create":true},"readinessProbe":{"httpGet":{"path":"/readyz","port":"probes"},"initialDelaySeconds":5,"periodSeconds":10,"timeoutSeconds":5},"replicaCount":1,"resources":{"limits":{"cpu":"400m","memory":"512Mi"},"requests":{"cpu":"200m","memory":"256Mi"}},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true},"serviceAccount":{"annotations":{},"automount":true,"create":true,"name":""},"startupProbe":{"failureThreshold":50,"httpGet":{"path":"/healthz","port":"probes"},"periodSeconds":10,"timeoutSeconds":5},"tolerations":[],"traceRemote":null,"useDefaultAffinity":true}` | Telemetry Manager component configuration |
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
| telemetryManager.podDisruptionBudget | object | `{"enabled":false}` | PodDisruptionBudget configuration for the Telemetry Manager deployment |
| telemetryManager.podDisruptionBudget.enabled | bool | `false` | If true, creates a PodDisruptionBudget for the Telemetry Manager deployment |
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
| traceRemote | bool | `false` | Global setting to enable/disable remote tracing for all components. Can be overridden per component. |
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
| vector | object | `{"developmentMode":null,"enabled":true,"extraArgs":[],"extraEnv":[],"extraVolumeMounts":[],"extraVolumes":[],"image":{"pullPolicy":"Always","repository":"672188301118.dkr.ecr.eu-west-1.amazonaws.com/zesty-k8s/kompass-compute/vector","tag":""},"logLevel":null,"normal":{"affinity":{},"nodeSelector":{},"tolerations":[{"operator":"Exists"}],"useDefaultAffinity":true},"podAnnotations":{},"podLabels":{},"podSecurityContext":{"fsGroup":1000,"seccompProfile":{"type":"RuntimeDefault"}},"qNode":{"affinity":{},"nodeSelector":{},"tolerations":[{"operator":"Exists"}],"useDefaultAffinity":true},"rbac":{"create":true},"resources":{"limits":{"cpu":"300m","memory":"600Mi"},"requests":{"cpu":"10m","memory":"50Mi"}},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true},"serviceAccount":{"annotations":{},"automount":true,"create":true,"name":""}}` | Vector component configuration (for log aggregation/forwarding) |
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
| vector.podSecurityContext | object | `{"fsGroup":1000,"seccompProfile":{"type":"RuntimeDefault"}}` | Security context for Vector Pods |
| vector.podSecurityContext.fsGroup | int | `1000` | Group ID for the filesystem used by Vector |
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