# Kompass Compute Helm Charts

This repository contains 2 Helm Charts for deploying Kompass Compute.

One with the components and another for the CRDs.

The CRDs are in a separate chart and managed independently, following the [Helm best practices for CRDs](https://helm.sh/docs/chart_best_practices/custom_resource_definitions/).

## Repository Structure

- [charts/kompass-compute-crd](https://github.com/zesty-co/kompass-compute/tree/main/charts/kompass-compute-crd): Contains the Helm chart for the Custom Resource Definitions (CRDs) required by Kompass Compute.
- [charts/kompass-compute](https://github.com/zesty-co/kompass-compute/tree/main/charts/kompass-compute): Contains the Helm chart for the main Kompass Compute components.

Both charts need to be installed together because the CRDs are required by the components.

## Usage

For details about each chart, please refer to their respective README files:

- [charts/kompass-compute-crd](https://github.com/zesty-co/kompass-compute/tree/main/charts/kompass-compute-crd)
- [charts/kompass-compute](https://github.com/zesty-co/kompass-compute/tree/main/charts/kompass-compute)
