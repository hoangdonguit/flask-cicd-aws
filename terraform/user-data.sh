#!/bin/bash

set -euxo pipefail

dnf update -y
dnf install -y docker curl jq

systemctl enable --now docker
usermod -aG docker ec2-user

mkdir -p /opt/flask-cicd-aws
chown ec2-user:ec2-user /opt/flask-cicd-aws

systemctl enable --now amazon-ssm-agent || true

cat > /etc/motd <<'MOTD'
Flask CI/CD AWS lab
Provisioned by Terraform
Docker bootstrap completed through EC2 user data
MOTD
