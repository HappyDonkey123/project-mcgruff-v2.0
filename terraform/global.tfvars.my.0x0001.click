# Required variables
# An AWS Route 53 registered domain name owned by the AWS admin user must be provided.
domain_name = "my.0x0001.click"


# aws_profile = "temp"
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs#environment-variables
# better to "export AWS_PROFILE='foobar'" than to use this here *and* in the provider.tf files below


# Override variable defaults with values below as desired.

# aws_region = "us-east-1"
# aws_availability_zones = [
#     "us-east-1a",
#     "us-east-1b"
#   ]
vpc_name     = "my-mcgruff"
vpc_cidr     = "10.0.0.0/21"
vpc_private_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24",
  ]
vpc_public_subnets = [
   "10.0.4.0/24",
    "10.0.5.0/24",
  ]
cluster_name = "my-mcgruff-pod-host"
k8s_namespace_name = "my-mcgruff"
node_group_name = "my-mcgruff"
application_database_name = "my-wordpress"

