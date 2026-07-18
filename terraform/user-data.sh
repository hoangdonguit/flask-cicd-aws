#!/bin/bash

set -euxo pipefail

# Amazon Linux 2023 already provides curl through curl-minimal.
# Installing the full curl package would conflict with curl-minimal.
dnf install -y docker jq

systemctl enable --now docker
usermod -aG docker ec2-user

install \
  -d \
  -o ec2-user \
  -g ec2-user \
  -m 0755 \
  /opt/flask-cicd-aws

systemctl enable --now amazon-ssm-agent || true

cat > /etc/motd <<'MOTD'
Flask CI/CD AWS lab
Provisioned by Terraform
Docker bootstrap completed through EC2 user data
MOTD
