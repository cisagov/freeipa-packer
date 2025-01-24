module "iam_user" {
  source = "github.com/cisagov/ami-build-iam-user-tf-module"

  providers = {
    aws            = aws
    aws.images-ami = aws.images-ami
    aws.images-ssm = aws.images-ssm
  }

  ssm_parameters = [
    "/cyhy/dev/users",
    "/ssh/public_keys/*",
  ]
  user_name = "build-freeipa-server-packer"
}

# Attach 3rd party S3 bucket read-only policy from
# cisagov/ansible-role-cdm-certificates to the production EC2AMICreate
# role
resource "aws_iam_role_policy_attachment" "thirdpartybucketread_certificates_production" {
  provider = aws.images-production-ami

  policy_arn = data.terraform_remote_state.ansible_role_cdm_certificates.outputs.production_bucket_policy.arn
  role       = module.iam_user.ec2amicreate_role_production.name
}

# Attach 3rd party S3 bucket read-only policy from
# cisagov/ansible-role-cdm-certificates to the staging EC2AMICreate
# role
resource "aws_iam_role_policy_attachment" "thirdpartybucketread_certificates_staging" {
  provider = aws.images-staging-ami

  policy_arn = data.terraform_remote_state.ansible_role_cdm_certificates.outputs.staging_bucket_policy.arn
  role       = module.iam_user.ec2amicreate_role_staging.name
}

# Attach 3rd party S3 bucket read-only policy from
# cisagov/ansible-role-crowdstrike to the production EC2AMICreate role
resource "aws_iam_role_policy_attachment" "thirdpartybucketread_crowdstrike_production" {
  provider = aws.images-production-ami

  policy_arn = data.terraform_remote_state.ansible_role_crowdstrike.outputs.production_bucket_policy.arn
  role       = module.iam_user.ec2amicreate_role_production.name
}

# Attach 3rd party S3 bucket read-only policy from
# cisagov/ansible-role-crowdstrike to the staging EC2AMICreate role
resource "aws_iam_role_policy_attachment" "thirdpartybucketread_crowdstrike_staging" {
  provider = aws.images-staging-ami

  policy_arn = data.terraform_remote_state.ansible_role_crowdstrike.outputs.staging_bucket_policy.arn
  role       = module.iam_user.ec2amicreate_role_staging.name
}

# Attach 3rd party S3 bucket read-only policy from
# cisagov/ansible-role-cdm-nessus-agent to the production
# EC2AMICreate role
resource "aws_iam_role_policy_attachment" "thirdpartybucketread_nessus_production" {
  provider = aws.images-production-ami

  policy_arn = data.terraform_remote_state.ansible_role_cdm_nessus_agent.outputs.production_bucket_policy.arn
  role       = module.iam_user.ec2amicreate_role_production.name
}

# Attach 3rd party S3 bucket read-only policy from
# cisagov/ansible-role-cdm-nessus-agent to the staging EC2AMICreate
# role
resource "aws_iam_role_policy_attachment" "thirdpartybucketread_nessus_staging" {
  provider = aws.images-staging-ami

  policy_arn = data.terraform_remote_state.ansible_role_cdm_nessus_agent.outputs.staging_bucket_policy.arn
  role       = module.iam_user.ec2amicreate_role_staging.name
}
