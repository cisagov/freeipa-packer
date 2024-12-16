data "amazon-ami" "fedora_39_arm64" {
  filters = {
    architecture        = "arm64"
    name                = "Fedora-Cloud-Base-39-*aarch64-hvm-*-gp3-*"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["125523088429"]
  region      = var.build_region
}

data "amazon-ami" "fedora_39_x86_64" {
  filters = {
    architecture        = "x86_64"
    name                = "Fedora-Cloud-Base-39-*x86_64-hvm-*-gp3-*"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["125523088429"]
  region      = var.build_region
}
