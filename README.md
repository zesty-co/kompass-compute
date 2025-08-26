# Kompass Compute Helm Charts

This repository contains Helm charts for deploying Kompass Compute.

One chart deploys the components and the other deploys the CRDs. The charts are separated and managed independently, following the [Helm best practices for CRDs](https://helm.sh/docs/chart_best_practices/custom_resource_definitions/).

## Repository structure

-   [charts/kompass-compute](https://github.com/zesty-co/kompass-compute/tree/main/charts/kompass-compute): chart for the main Kompass Compute components
-   [charts/kompass-compute-crd](https://github.com/zesty-co/kompass-compute/tree/main/charts/kompass-compute-crd): chart for the CRDs

Regarding CRDs: Installing **charts/kompass-compute** will install the CRDs as-is. To update the CRDs, install both charts, and when you install the **charts/kompass-compute** chart, use the '--skip-crds' flag.

## Usage

For details about each chart, see their respective README files inside each folder:

-   [charts/kompass-compute-crd](https://github.com/zesty-co/kompass-compute/tree/main/charts/kompass-compute-crd)
-   [charts/kompass-compute](https://github.com/zesty-co/kompass-compute/tree/main/charts/kompass-compute)
