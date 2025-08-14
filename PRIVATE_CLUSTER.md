# Private EKS cluster requirements

## Downloading Kompass Compute Images and binaries:

All Kompass Compute images and binaries are stored in the ECR repositories and S3 buckets in `eu-west-1` region.

If your cluster is not deployed in `eu-west-1` region, go to the [Deploying Kompass Compute in a region without Kompass artifacts](#deploying-kompass-compute-in-a-region-without-kompass-artifacts) section and then return here.

## Downloading dependencies from Amazon Linux YUM repository:

Kompass Compute requires access to Amazon Linux YUM repository to download system dependencies.

To be able to download dependencies from it, your nodes need to be in subnets that have access to S3.

To have access to S3 in a private Gateway you need the following:

- S3 VPC gateway endpoint
- Route tables in the subnets where your EKS nodes are deployed that route traffic to the S3 VPC gateway endpoint

## Granting AWS API Access to Kompass Compute Deployments:

Kompass Compute require the following VPC endpoints to operate in a private cluster:

- IAM private endpoint
- EC2 private endpoint
- EKS private endpoint
- ECR API private endpoint
- ECR DKR private endpoint
- SQS private endpoint
- Autoscaling private endpoint
- STS endpoint if using IRSA

Additionally, you need either EKS Pod Identity or IRSA enabled in the cluster.

If you are using IRSA, you also need to create a STS private endpoint.

If the "private DNS names" option is disabled, go to the [Configuring VPC endpoint integration when "private DNS names" is disabled on VPC endpoints](#configuring-vpc-endpoint-integration-when-private-dns-names-is-disabled-on-vpc-endpoints) section.

For more details about the endpoints, go to the [Details about the created endpoints](#details-about-the-created-endpoints) section.


## Sending telemetry to Coralogix:

Kompass is sending telemetry data to Coralogix.
To send this data through a private cluster, you need to first [create an AWS PrivateLink to Coralogix](https://coralogix.com/docs/integrations/aws/aws-privatelink/aws-privatelink/).

After creating the PrivateLink, you need to configure Kompass Insight to use the private Coralogix endpoint:

```yaml
cxLogging:
  enabled: true
  domain: "private.eu2.coralogix.com"
  logUrl: "https://ingress.private.eu2.coralogix.com:443/api/v1/logs"
  timeDeltaUrl: "https://ingress.private.eu2.coralogix.com:443/sdk/v1/time"
  ingressLogsUrl: "https://ingress.private.eu2.coralogix.com/logs/v1/singles"
  ingressUrl: "https://ingress.private.eu2.coralogix.com"
```

## Configuring VPC endpoint integration when "private DNS names" is disabled on VPC endpoints:

If you want to disable "private DNS names" on VPC endpoints, you have to provide the following environment variables through the values.yaml file:

```yaml
hiberscaler:
  extraEnv:
    - name: "AWS_ENDPOINT_URL_IAM"
      value: "https://<IAM_PRIVATE_ENDPOINT_DNS_NAME>"
    - name: "AWS_ENDPOINT_URL_EKS"
      value: "https://<EKS_PRIVATE_ENDPOINT_DNS_NAME>"
    - name: "AWS_ENDPOINT_URL_ECR" # It is highly recommended to use "Private DNS Names" and not to use "AWS_ENDPOINT_URL_ECR"
      value: "https://<ECR_API_PRIVATE_ENDPOINT_DNS_NAME>"
    - name: "AWS_ENDPOINT_URL_SQS"
      value: "https://<SQS_PRIVATE_ENDPOINT_DNS_NAME>"
    - name: "AWS_ENDPOINT_URL_AUTO_SCALING"
      value: "https://<AUTOSCALING_PRIVATE_ENDPOINT_DNS_NAME>"
    - name: "AWS_ENDPOINT_URL_STS"
      value: "https://<STS_PRIVATE_ENDPOINT_DNS_NAME>"

imageSizeCalculator:
  extraEnv:
    - name: "AWS_ENDPOINT_URL_ECR" # It is highly recommended to use "Private DNS Names" and not to use "AWS_ENDPOINT_URL_ECR"
      value: "https://<ECR_API_PRIVATE_ENDPOINT_DNS_NAME>"
    - name: "AWS_ENDPOINT_URL_STS"
      value: "https://<STS_PRIVATE_ENDPOINT_DNS_NAME>"

snapshooter:
  extraEnv:
    - name: "AWS_ENDPOINT_URL_STS"
      value: "https://<STS_PRIVATE_ENDPOINT_DNS_NAME>"

telemetryManager:
  extraEnv:
    - name: "AWS_ENDPOINT_URL_STS"
      value: "https://<STS_PRIVATE_ENDPOINT_DNS_NAME>"
```

## Deploying Kompass Compute in a region without Kompass Compute artifacts:

The Kompass Compute artifacts are located in `eu-west-1`.
To access them from a different region through the AWS private network you should at the high level:
- Create a VPC in `eu-west-1` with the relevant endpoints
- Peer the proxy VPC to the VPC of your cluster.
- Configure the DNS to route all traffic to ECR/S3 in eu-west-1 to the previously created endpoints. 

Details on how to do it:

1. Create a VPC (without internet access) in the `eu-west-1` region.
2. Create three VPC endpoints, "private DNS names" option can be disabled:
   - ECR API endpoint. It is used to authenticate to ECR in the `eu-west-1` region.
   - ECR DKR endpoint. It is used to get container image metadata from ECR.
   - S3 Interface endpoints. It is used to get container images from ECR and binaries from S3.
3. Create a VPC Peering connection between the VPC in which your EKS cluster is deployed and the VPC created in step 1.
4. Create three private DNS zones in Route 53 connected to your VPC in which your EKS cluster is deployed.
   - `api.ecr.eu-west-1.amazonaws.com`. Add a `api.ecr.eu-west-1.amazonaws.com` ALIAS record which will point to the VPC endpoint created in step 2.
   - `dkr.ecr.eu-west-1.amazonaws.com`. Add a `*.dkr.ecr.eu-west-1.amazonaws.com` ALIAS record which will point to the VPC endpoint created in step 2.
   - `s3.eu-west-1.amazonaws.com`. Add `s3.eu-west-1.amazonaws.com` and `*.s3.eu-west-1.amazonaws.com` ALIAS records which will point to the VPC endpoint created in step 2. (DKR is using *, while S3 API to put object is using exact name).

## Details about the created endpoints

- IAM private endpoint

  _Used to discover Autoscaling groups_.

  Configure IAM private endpoint in the VPC in `us-east-1` region.
  Peer the VPC in which the EKS cluster is deployed to the VPC with IAM private endpoint in `us-east-1` region.
  Modify Hiberscaler deployment with additional environment variable:

  ```yaml
  - name: "AWS_ENDPOINT_URL_IAM"
    value: "https://<IAM_PRIVATE_ENDPOINT_DNS_NAME>"
  ```
  
  If you are using [non-commercial AWS Regions](https://docs.aws.amazon.com/organizations/latest/userguide/region-support.html), you have to create a VPC endpoint in the region where the IAM control plane is deployed.
  In addition, you need to configure region using `AWS_REGION_IAM` environment variable:

  ```yaml
  - name: "AWS_REGION_IAM"
    value: "<YOUR_REGION>"
  ```

- EC2 private endpoint

  _Used to discover EC2 instances and other staff._
  _Required at least by nodeadm-config and eks/bootstrap.sh._

  Configure EC2 private endpoint in the VPC in which the EKS cluster is deployed.
  You have to enable "Private DNS Names".

- EKS private endpoint

  _Used to discover nodes groups_.

  Configure EKS private endpoint in the VPC in which the EKS cluster is deployed.
  Enable "Private DNS Names" or modify Hiberscaler deployment with additional environment variable:

  ```yaml
  - name: "AWS_ENDPOINT_URL_EKS"
    value: "https://<EKS_PRIVATE_ENDPOINT_DNS_NAME>"
  ```
  
- ECR API private endpoint

  _Used to authenticate to ECR_.
  _Required at least by eks/bootstrap.sh._

  Configure ECR API private endpoint in the VPC in which the EKS cluster is deployed.
  Enable "Private DNS Names" (this option is required when using Amazon Linux 2 AMI and it is highly recommended when using images from different regions) or modify Hiberscaler and ImageSizeCalculator deployment with additional environment variable:

  ```yaml
  - name: "AWS_ENDPOINT_URL_ECR"
    value: "https://<ECR_API_PRIVATE_ENDPOINT_DNS_NAME>"
  ```
  
- ECR DKR private endpoint

  _Used to download container images_.

  Configure ECR DKR private endpoint in the VPC in which the EKS cluster is deployed.
  You have to enable "Private DNS Names".

- SQS private endpoint

  _Used to get spot failures._

  Configure SQS private endpoint in the VPC in which the EKS cluster is deployed.
  Enable "Private DNS Names" or modify Hiberscaler deployment with additional environment variable:

  ```yaml
  - name: "AWS_ENDPOINT_URL_SQS"
    value: "https://<SQS_PRIVATE_ENDPOINT_DNS_NAME>"
  ```

- Autoscaling private endpoint

  _Used to autodiscover autoscaling groups._

  Configure the Autoscaling private endpoint in the VPC in which the EKS cluster is deployed.
  Enable "Private DNS Names" or modify deployments with the following environment variable:

  ```yaml
  - name: "AWS_ENDPOINT_URL_AUTO_SCALING"
    value: "https://<AUTOSCALING_PRIVATE_ENDPOINT_DNS_NAME>"
  ```

- STS private endpoint

  _Used by IRSA to authenticate pods to AWS API._

  Configure STS private endpoint in the VPC in which the EKS cluster is deployed.
  Enable "Private DNS Names" or modify Hiberscaler, ImageSizeCalculator, Snapshooter and TelemetryManager deployments with additional environment variable:

  ```yaml
  - name: "AWS_ENDPOINT_URL_STS"
    value: "https://<STS_PRIVATE_ENDPOINT_DNS_NAME>"
  ```