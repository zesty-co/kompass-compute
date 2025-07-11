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
