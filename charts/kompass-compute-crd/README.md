# Kompass Compute CRD Helm Chart

This chart deploys the Kompass Compute CRD components.

## Prerequisites

- Kubernetes v1.28, or later
- Helm v3.2.0, or later

## Install the chart

The following example shows how to install the chart with the release name, `kompass-compute`:

```bash
helm repo add zesty-kompass-compute https://zesty-co.github.io/kompass-compute
helm repo update
helm install kompass-compute-crd zesty-kompass-compute/kompass-compute-crd --namespace zesty-system
```

# Troubleshooting

## Upgrade Issues

### Uninstalling Old CRDs
Upgrading from an older version in a different namespace might fail due to namespace mismatch. In such a case the CRDs will need to be deleted manually:
```bash
kubectl delete crd workloaddescriptors.kompass.zesty.co ||
kubectl delete crd qbakers.qscaler.qubex.ai ||
kubectl delete crd qcachepullmappings.qscaler.qubex.ai ||
kubectl delete crd qcacherevisioncreations.qscaler.qubex.ai ||
kubectl delete crd qcacheshards.qscaler.qubex.ai ||
kubectl delete crd qnodes.qscaler.qubex.ai ||
kubectl delete crd qscalers.qscaler.qubex.ai ||
kubectl delete crd qubexconfigs.qscaler.qubex.ai ||
kubectl delete crd resumetasks.qscaler.qubex.ai
```