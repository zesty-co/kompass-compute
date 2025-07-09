# Kompass Compute Helm Charts

This repository contains Helm charts for deploying components related to Kompass Compute on Kubernetes clusters.

## Repository Structure

- `charts/kompass-compute`: Contains the Helm chart for the main Kompass Compute deployment.
- `charts/kompass-compute-crd`: Contains the Helm chart for the Custom Resource Definitions (CRDs) required by Kompass Compute.

## Usage

For installation instructions, configuration options, and other details, please refer to the README files located in each chart's directory:

- [charts/kompass-compute](charts/kompass-compute)
- [charts/kompass-compute-crd](charts/kompass-compute-crd)

## CRDs

The CRDs are provided in a separate chart and managed independently, following the [Helm best practices for CRDs](https://helm.sh/docs/chart_best_practices/custom_resource_definitions/).
While the CRDs are also available in the main chart, Helm installs them only during the first installation and does not upgrade or delete them during subsequent upgrades or rollbacks.
This approach allows for independent management and upgrades of custom resources, ensuring compatibility and safe lifecycle handling when deploying or updating Kompass Compute components.

**Benefits of this pattern:**

- Allows CRDs to be upgraded independently of application releases, reducing risk of breaking changes.
- Simplifies lifecycle management and supports safe, gradual adoption of new CRD versions.
- Aligns with Helm’s recommendations for managing CRDs in production environments.

## License

See the LICENSE file for licensing information.
