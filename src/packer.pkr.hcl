packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1.2"
    }
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = "~> 1.1"
    }
  }
  # The required_plugins section is only supported in Packer 1.7.0 and
  # later.  We also want to avoid jumping to Packer v2 until we are
  # ready.
  required_version = "~> 1.7"
}

variable "ami_regions" {
  default     = []
  description = "The list of AWS regions to copy the AMI to once it has been created. Example: [\"us-east-1\"]"
  type        = list(string)
}

# Note: This is only defined as an optional variable because of a current
# limitation in the cisagov/pre-commit-packer hook. Please see
# https://github.com/cisagov/pre-commit-packer/issues/16 for the status of
# that effort.
variable "build_bucket" {
  default     = ""
  description = "The S3 bucket containing the CDM tool installers."
  type        = string
}

variable "build_region" {
  default     = "us-east-1"
  description = "The region in which to retrieve the base AMI from and build the new AMI."
  type        = string
}

variable "build_region_kms" {
  default     = "alias/cool-amis"
  description = "The ID or ARN of the KMS key to use for AMI encryption."
  type        = string
}

variable "is_prerelease" {
  default     = false
  description = "The pre-release status to use for the tags applied to the created AMI."
  type        = bool
}

variable "region_kms_keys" {
  default     = {}
  description = "A map of regions to copy the created AMI to and the KMS keys to use for encryption in that region. The keys for this map must match the values provided to the aws_regions variable. Example: {\"us-east-1\": \"alias/example-kms\"}"
  type        = map(string)
}

variable "release_tag" {
  default     = ""
  description = "The GitHub release tag to use for the tags applied to the created AMI."
  type        = string
}

variable "release_url" {
  default     = ""
  description = "The GitHub release URL to use for the tags applied to the created AMI."
  type        = string
}

variable "skip_create_ami" {
  default     = false
  description = "Indicate if Packer should not create the AMI."
  type        = bool
}

data "amazon-ami" "fedora_40" {
  filters = {
    name                = "Fedora-Cloud-Base-AmazonEC2.x86_64-40-*"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["125523088429"]
  region      = var.build_region
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

source "amazon-ebs" "freeipa" {
  ami_name                    = "freeipa-server-hvm-${local.timestamp}-x86_64-ebs"
  ami_regions                 = var.ami_regions
  associate_public_ip_address = true
  encrypt_boot                = true
  instance_type               = "t3.small"
  kms_key_id                  = var.build_region_kms
  launch_block_device_mappings {
    delete_on_termination = true
    device_name           = "/dev/sda1"
    encrypted             = true
    volume_size           = 8
    volume_type           = "gp3"
  }
  region             = var.build_region
  region_kms_key_ids = var.region_kms_keys
  skip_create_ami    = var.skip_create_ami
  source_ami         = data.amazon-ami.fedora_40.id
  ssh_username       = "fedora"
  subnet_filter {
    filters = {
      "tag:Name" = "AMI Build"
    }
  }
  tags = {
    Application        = "FreeIPA server"
    Base_AMI_Name      = data.amazon-ami.fedora_40.name
    GitHub_Release_URL = var.release_url
    OS_Version         = "Fedora 40"
    Pre_Release        = var.is_prerelease
    Release            = var.release_tag
    Team               = "VM Fusion - Development"
  }
  # Many Linux distributions are now disallowing the use of RSA keys,
  # so it makes sense to use an ED25519 key instead.
  temporary_key_pair_type = "ed25519"
  user_data_file          = "src/user_data.sh"
  vpc_filter {
    filters = {
      "tag:Name" = "AMI Build"
    }
  }
}

build {
  sources = ["source.amazon-ebs.freeipa"]

  provisioner "ansible" {
    playbook_file = "src/upgrade.yml"
    use_proxy     = false
    use_sftp      = true
  }

  provisioner "ansible" {
    playbook_file = "src/python.yml"
    use_proxy     = false
    use_sftp      = true
  }

  provisioner "ansible" {
    ansible_env_vars = ["AWS_DEFAULT_REGION=${var.build_region}"]
    extra_arguments  = ["--extra-vars", "build_bucket=${var.build_bucket}"]
    playbook_file    = "src/playbook.yml"
    use_proxy        = false
    use_sftp         = true
  }

  provisioner "shell" {
    # We need to call bash here because after hardening /tmp has the
    # noexec bit set on it.
    execute_command = "chmod +x {{ .Path }}; sudo env {{ .Vars }} bash {{ .Path }} ; rm -f {{ .Path }}"
    skip_clean      = true
    inline          = ["update-crypto-policies --set DEFAULT", "sed -i '/^users:/ {N; s/users:.*/users: []/g}' /etc/cloud/cloud.cfg", "rm --force /etc/sudoers.d/90-cloud-init-users", "rm --force /root/.ssh/authorized_keys", "/usr/sbin/userdel --remove --force fedora"]
  }
}
