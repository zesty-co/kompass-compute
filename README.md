# Kompass Compute Helm Charts

This repository contains 2 Helm Charts for deploying Kompass Compute.

One with the components and another for the CRDs.

The CRDs are in a separate chart and managed independently, following the [Helm best practices for CRDs](https://helm.sh/docs/chart_best_practices/custom_resource_definitions/).

## Repository Structure

- [charts/kompass-compute-crd](https://github.com/zesty-co/kompass-compute/tree/main/charts/kompass-compute-crd): Contains the Helm chart for the Custom Resource Definitions (CRDs) required by Kompass Compute.
- [charts/kompass-compute](https://github.com/zesty-co/kompass-compute/tree/main/charts/kompass-compute): Contains the Helm chart for the main Kompass Compute components.

Regarding CRDs: Installing [charts/kompass-compute](https://github.com/zesty-co/kompass-compute/tree/main/charts/kompass-compute) will install the CRDs as well, but updating it will not change the CRDs.
To update the CRDs you should use the [CRDs chart (charts/kompass-compute-crd)](https://github.com/zesty-co/kompass-compute/tree/main/charts/kompass-compute-crd).

## Usage

For details about each chart, please refer to their respective README files:

- [charts/kompass-compute-crd](https://github.com/zesty-co/kompass-compute/tree/main/charts/kompass-compute-crd)
- [charts/kompass-compute](https://github.com/zesty-co/kompass-compute/tree/main/charts/kompass-compute)
