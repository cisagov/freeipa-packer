build {
  sources = [
    # The CDM Nessus Agent does not support ARM64 on Fedora.
    # "source.amazon-ebs.arm64",
    "source.amazon-ebs.x86_64",
  ]

  provisioner "ansible" {
    playbook_file = "ansible/upgrade.yml"
    use_proxy     = false
    use_sftp      = true
  }

  provisioner "ansible" {
    playbook_file = "ansible/python.yml"
    use_proxy     = false
    use_sftp      = true
  }

  provisioner "ansible" {
    ansible_env_vars = ["AWS_DEFAULT_REGION=${var.build_region}"]
    extra_arguments  = ["--extra-vars", "build_bucket=${var.build_bucket}"]
    playbook_file    = "ansible/playbook.yml"
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
