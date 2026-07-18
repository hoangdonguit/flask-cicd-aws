# Phase 4 — Terraform EC2 Provisioning

## Outcome

Phase 4 provisions a reproducible AWS EC2 runtime through Terraform in an
AWS Academy Sandbox.

Terraform manages:

- one Amazon Linux 2023 EC2 instance;
- one project-specific Security Group;
- Docker installation through EC2 user data;
- the existing AWS Academy `vockey` key pair;
- the existing `LabInstanceProfile`;
- SSH and HTTP network access;
- IMDSv2 token enforcement.

## Verification

The implementation was verified through:

- `terraform fmt`;
- `terraform validate`;
- a saved Terraform execution plan;
- successful EC2 creation;
- EC2 system and instance status checks;
- SSH connectivity using `ec2-user`;
- `cloud-init status: done`;
- Docker enabled and active;
- Docker access by `ec2-user` without `sudo`;
- SSM Agent enabled, active, and registered Online;
- tokenless metadata requests rejected with HTTP `401`;
- a final Terraform plan reporting no infrastructure drift.

## Immutable remediation test

The first EC2 instance reached the Running state and accepted SSH, but its
cloud-init bootstrap failed.

Amazon Linux 2023 already contained `curl-minimal`, while the original user
data attempted to install the conflicting full `curl` package:

    dnf install -y docker curl jq

The corrected command is:

    dnf install -y docker jq

The user-data correction was committed as `0f18eac`.

The EC2 Terraform resource enables replacement whenever user data changes:

    user_data_replace_on_change = true

Terraform therefore replaced the failed instance instead of repairing it
manually:

    Plan: 1 to add, 0 to change, 1 to destroy.

The old instance was terminated, and the replacement instance completed
cloud-init successfully and passed all runtime checks.

This demonstrates declarative remediation and immutable infrastructure rather
than undocumented manual server mutation.

## Security controls

- SSH access is restricted to the administrator's current `/32` CIDR.
- Only application HTTP port 80 is publicly exposed.
- EC2 Instance Metadata Service requires IMDSv2.
- Temporary AWS credentials and the PEM key remain outside Git.
- The PEM key is protected with filesystem mode `0600`.
- Terraform state, plans, cache files, and local tfvars are excluded from Git.
- The application will be deployed using immutable Docker image tags.

## Systems Manager

The EC2 instance uses the existing AWS Academy `LabInstanceProfile`.

Verification confirmed:

- `amazon-ssm-agent` is enabled;
- `amazon-ssm-agent` is active;
- the instance reports `Online` in AWS Systems Manager.

This provides a managed access path in addition to SSH.

## MOTD observation

Amazon Linux 2023 exposes `/etc/motd` as a symbolic link managed by its
dynamic update-motd mechanism.

Although the user-data script contained the custom banner, the runtime MOTD
file remained empty. MOTD is therefore not used as an acceptance criterion.

The reliable acceptance checks are:

- cloud-init status;
- Docker service status;
- Docker access for `ec2-user`;
- SSM registration;
- IMDSv2 enforcement;
- Terraform no-drift verification.

## Detailed evidence

Full Terraform outputs, AWS runtime information, remote bootstrap checks, and
troubleshooting history are available in:

- [Phase 4 raw evidence](../../evidence/phase4-terraform-ec2/README.md)

Raw files include:

- `terraform-tooling.txt`;
- `terraform-state-summary.txt`;
- `terraform-no-drift.txt`;
- `aws-runtime-summary.txt`;
- `remote-bootstrap-verification.txt`;
- `bootstrap-troubleshooting-history.txt`.

## Lifecycle status

The EC2 infrastructure remains active for Phase 5 deployment, health-check,
version verification, and rollback testing.

After Phase 5 evidence is collected, the project infrastructure must be
destroyed through Terraform.
