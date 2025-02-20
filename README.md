# CiscoDevNet/project-mcgruff

## Overview

Reference cloud application deployment incorporating various Cisco security technology APIs.  Focuses on common real-world components and patterns, applying security best practices.

![Network architecture](images/network_architecture.png)

Tested using:

* Ubuntu 22.04

* Kubernetes 1.29

* Terraform 1.8.4 / OpenTofu 1.7.1

* Kubectl 1.30.0

* Helm 3.14.4

## Application

A 'typical' containerized, client-server web application with internal REST API and access group use-cases for at least 3 classes of users (admin/employee/external-customer).

### Components

#### Application

* [AWS EKS](https://aws.amazon.com/eks/) (Kubernetes) - single pod/node/cluster.

* [Wordpress container](https://hub.docker.com/_/wordpress) as the sample web application.

* [AWS Relational Database Services (RDS)](https://aws.amazon.com/rds/) hosting MariaDB.

#### Network Infrastructure

* [AWS Virtual Private Cloud](https://aws.amazon.com/vpc/) for egress/ingress and standard network services (DNS).

* [AWS Cloud Compute](https://aws.amazon.com/ec2/) providing instance hosting EKS pods.

* [AWS Directory Services](https://aws.amazon.com/directoryservice/) providing Microsoft Active Directory.

Also using: AWS [IAM](https://aws.amazon.com/iam/) / [ACM](https://aws.amazon.com/certificate-manager/) / [Route 53](https://aws.amazon.com/route53/)

#### Security Products

* [Cisco Duo Single-Sign-On/Multi-factor Authentication](https://duo.com/)

* (Others TBD)

## Pre-Requisites

* **Amazon AWS admin account** - this must be a paid account.  It is **highly** recommended that this _not_ be a production account, and/or that it is based in an AWS region not used by any production resources.

   **Note:** This project creates AWS resources that will incur (modest) ongoing charges - be sure to perform the steps in [Cleanup AWS Resources](#cleanup-aws-resources) when they are no longer needed.

* [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) installation - assumes [login credentials have been configured](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html) and CLI commands can be executed against the target AWS account/region.

* [AWS Route 53](https://aws.amazon.com/route53/) registered domain, owned by the AWS admin account above.  This domain will be used for the web-site/MS-AD - required for integration with Cisco Duo SSO/MFA. This should cost not cost much and the domain is transferable.

* [Kubectl](https://kubernetes.io/docs/tasks/tools/) installation.

* [Helm](https://helm.sh/docs/intro/install/) installation.

## Getting Started

1. Clone the repository and change into the directory:

   ```
   git clone https://github.com/CiscoDevNet/project-mcgruff
   cd project-mcgruff
   ```

1. Create an S3 bucket - this will be used for Terraform state files.

   Be sure to keep encryption and bucket versioning enabled.

   Then, update `terraform/infrastructure/provider.tf` and `terraform/infrastructure/provider.tf` including the backend sections with your S3 bucket name and region.

1. Edit `/terraform/global.tfvars`.

   All values can be left commented/default except `domain_name`, which must be provided (see [Pre-Requisites](#pre-requisites) above).

1. First, create the infrastructure resources:

    Note: `terraform init` is required on the first run and only (or when you need to use the `-reconfigure` switch.
   ```
   cd terraform/infrastructure
   terraform init
   terraform plan -var-file="../global.tfvars"
   terraform apply -var-file="../global.tfvars"
   ```

   Allow this to complete (approx. 35 minutes).

   The last few lines of the output will identify the EC2 key and access credentials which are also stored in [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/) for the credentials to log in to the Active Directory management instance. The .pem file will be automatically created within your project Mcgruff folder on your local computer and you can find it there.
   
   ```
   Active_Directory_Management_Instance_Private_Key_FIle_Name = "mcgruff-20240523161937071600000001.pem"
   Secrets_Manager_Active_Directory_Credential_Name = "mcgruff-active-directory-credential-20240523154127198200000001"
   ```

   Later, when you need to log into the AD management instance you will need to use AWS Fleet Manager from the EC2 Instance page. You can use the credentials that you got from the log file which can also be found in: [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/).

   **Note:** It may take a few minutes before the AD management instance is fully started/online/SSM-managed before you can connect to it.  Note also that joining it to the AD domain (which happens after the directory has been created) causes it to reboot again.

1. Next, create resources and deploy the application:

   **(First run only)**
   ```
   ```

   ```
   cd terraform/application
   terraform init
   terraform apply -var-file="../global.tfvars"
   ```

   Allow this to complete (approx. 10 minutes).

   Output from the logs will provide the AWS Secrets Manager secret name for the database Admin credential, and the URL for the running application:

   ```
   Application_URL = "https://wordpress.mcgruff.click"
   Secrets_Manager_Database_Credential_Name = "mcgruff-database-credential-20240523163719521000000001"
   ```
  You will need to change the permissions to access the EKS Compute instance. You will need to add the ClusterAdmin policy to your role in the AWS console. When you go to the EKS service in AWS and go to Compute, it will prompt you for additional permissions. Click on access and add the ClusterAdmin there rather than in IAM.

## Example/estimated apply times (us-east-1)

| Config           | File             | Create | Destroy |
| ---------------- | ---------------- | ------ | ------- |
| 1_infrastructure | (all)            |  34:54 |   11:02 |
|                  | vpc.tf           |   2:12 |    0:57 |
|                  | cluster.tf       |  10:52 |   12:11 |
|                  | directory.tf     |  32:52 |    8:14 |
|                  | jump_host.tf     |   2:54 |    ?:?? |
| 2_application    | (all)            |   9:17 |    6:04 |
|                  | database.tf      |   4:56 |    4:50 |
|                  | load_balancer.tf |   0:31 |    0:15 |
|                  | deployment.tf    |   0:41 |    0:06 |
|                  | ingress.tf       |   3:35 |    1:36 |

## Cleanup AWS Resources

Resources will need to be cleaned up in reverse order of their creation:

1. Destroy the Kubernetes application resources/deployment:

   ```
   cd terraform/2_application
   terraform destroy -var-file="../global.tfvars"
   ```

   Wait for this to complete (approx. 11 minutes)

1. Destroy the AWS infrastructure resources:

   ```
   cd terraform/1_infrastructure
   terraform destroy -var-file="../global.tfvars"
   ```

   Wait for this to complete (approx. 6 minutes)

## Notes

* **`mariadb.sh` and `wordpress.sh`** - These script files will launch MariaDB and Wordpress instances in local Docker containers on your computer, for testing/experimentation.  Optional to use.

* **Component versions** - This project specifies component versions where possible (e.g. Terraform providers, AWS NLB, etc.) - one notable exception being the Windows AMI for the AD management instance.  This should make things reproducible, but may drift re functionality and/or security updates on certain components over time.  An update/upgrade plan (and automation) for keeping things up-to-date yet stable is advised.

  **Note:** In production, you would definitely want to identify/specify component versions whenever possible for consistency/reproducibility reasons.

* **Resource version updates/upgrades** -   AWS makes availiable update/upgrade services for many/most components if provides (notable exception: the [AWS load-balancer controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/deploy/installation/#create-update-strategy)) - you will likely want to investigate/implement these in a production environment.  (TODO: modify this project to implement those as a best practice).

* **Partial configurations** - `.tf` files can be moved into/out-of associated `disabled` folders to remove/create portions of a config.  There are dependencies between most files in a config, however - these are refelected by the file name prefixes (e.g. `2_cluster.tf`), be sure to enable/disable these in order.

  Note: if installing files piece-meal, you may need to update the Terraform libraries installed in the config, i.e.:

  ```
  terraform init -upgrade
  ```

* **AWS CLI credentials timeout** - This can occur during Terraform `apply` and may result in interruption of the run (potentially causing corruption/sync problems between the actual resources and the Terraform state file.)

  It is possible to modify (i.e. increase) the AWS authentication session duration via: **IAM/Access management/Roles/{admin role}/Summary/Edit**.

  **Note:** Do this at your own risk and only in non-production environments - extended session lifetime can be a security risk.

  Once modified, you will want to modify your [AWS CLI authentication mechanism](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html) to start requesting the longer session duration.

* **Corruption/sync issues in Terraform state files** - This can occur due to `apply` run interruptions (credential timeouit/network connection loss), or even just when provider-side errors/issues cause an abort.

  This can be difficult to recover from, but a few initial things to try, in increasing order of desperation:

  * Correct any problems in the configuration and re-`apply`.

  * Try `terraform plan -refresh=ADDRESS`, see [Command: plan](https://developer.hashicorp.com/terraform/cli/commands/plan#replace-address).

  * Destroy resources affected by the error using Terraform.  Try moving individual `.tf` files into `disabled/` or commenting-out specific resources.

  * Destroy the entire Terraform configuration and start fresh (`terraform destroy --var-file="../global.tfvars`).

  * If all else fails, you may need to manually delete some/all resources via the AWS admin console and delete the Terraform state files from the S3 bucket.

  * Start Googling, e.g. [How to Recover Your Deployment From a Terraform Apply Crash](https://eclipsys.ca/terraform-tips-how-to-recover-your-deployment-from-a-terraform-apply-crash/).

## Useful Commands  

* **Update kubectl credentials** - Once the EKS cluster has been created, you can refresh kubectl credentials with:

  ```
  aws eks update-kubeconfig --region us-east-1 --name CLUSTERNAME
  ```

  **Note:** this is done automatically when the `terraform/1_infrastructure` configuration is applied.

* **View aws-load-balancer-controller versions**

  ```
  helm search repo eks/aws-load-balancer-controller --versions
  ```
* **View EKS cluster add-on versions**

  ```
  aws eks describe-addon-versions --adon-name vpc-cni --no-cli-pager
  ```

* **View Kubernetes logs** - for the application deployment:

  ```
  kubectl -n namespace get pods
  kubectl -n namespace logs deployment-bbfd776f5-cs4fj
  ```

* **Restart deployment** - restart the application container, if necessary:

  ```
  kubectl -n namespace get pods
  kubectl rolling restart deployment deployment-bbfd776f5-cs4fj
  ```

* **Container interactive terminal session**:

  ```
  kubectl -n namespace get pods
  kubectl -n namespace exec -it deployment-bbfd776f5-cs4fj -- /bin/bash
  ```

* **Port forwarding from instance to local PC**:

  E.g. `3389` for RDP.

  ```
  aws ssm start-session --target yourinstanceid --document-name AWS-StartPortForwardingSession --parameters "localPortNumber=55678,portNumber=3389"
  ```

* **Check windows instance domain membership**:

  **Local PC:**
  ```
  aws ssm start-session --target yourInstanceId
  ```

  **Instance:**
  ```
  Get-WmiObject Win32_ComputerSystem
  ```

* **Manually Join AD Management Instance to Domain**

  **Local PC:**
  ```
  aws ssm start-session --target yourInstanceId
  ```

  **Instance:**
  
  ```
  Add-Computer -DomainName “mcgruff.click” -Credential “Admin”
  ```
  
  You will be asked for the domain Admin password (created during `infrastructure/` run.)

* **Manually install AD tools on the AD Managerment Instance**

  **Instance:**

  ```
  Install-WindowsFeature -Name GPMC,RSAT-AD-PowerShell,RSAT-AD-AdminCenter,RSAT-ADDS-Tools,RSAT-DNS-Server
  ```
