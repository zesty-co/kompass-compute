# Kompass Compute CRD Helm Chart

This chart deploys the Kompass Compute CRD components.

## Prerequisites

*   Kubernetes 1.19+
*   Helm 3.2.0+

## Installing the Chart

To install the chart with the release name `kompass-compute`:

```bash
helm repo add zesty-kompass-compute https://zesty-co.github.io/kompass-compute
helm repo update
helm install kompass-compute-crd zesty-kompass-compute/kompass-compute-crd --namespace zesty-system
```

Or, if installing from a local path:

```bash
helm install kompass-compute-crd ./helm --namespace zesty-system --create-namespace
```

## Uninstalling the Chart

To uninstall/delete the `kompass-compute-crd` deployment:

```bash
helm uninstall kompass-compute-crd --namespace zesty-system
```

The command removes all the Kompass Compute CRDs associated with the chart and deletes the release.

## Contributing

Please refer to the contribution guidelines for this project.

## License

Specify your license information here.
