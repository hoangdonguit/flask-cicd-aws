# Phase 4 — Terraform EC2 Provisioning Evidence

## Status

Phase 4 completed successfully in the AWS Academy Sandbox.

Terraform provisioned and manages:

- one Amazon Linux 2023 EC2 instance;
- one project-specific Security Group;
- the association with the existing `vockey` key pair;
- the existing `LabInstanceProfile`;
- Docker and Systems Manager bootstrap through EC2 user data.

## Runtime snapshot

| Property | Value |
|---|---|
| AWS region | `us-east-1` |
| Instance ID | `i-0df673da1758aaca4` |
| Instance type | `t3.micro` |
| AMI | `ami-0fd6240f599091088` |
| Public IP | `32.192.209.173` |
| Public DNS | `ec2-32-192-209-173.compute-1.amazonaws.com` |
| Subnet | `subnet-025c958da87196336` |
| SSH user | `ec2-user` |
| Terraform implementation commit | `99cc501` |
| Bootstrap fix commit | `0f18eac` |

The identifiers above belong to an ephemeral AWS Academy lab and are not
expected to remain valid after the lab is destroyed or reset.

## Verification results

The following checks passed:

- Terraform configuration formatting and validation;
- EC2 creation through a saved Terraform plan;
- EC2 system and instance status checks;
- SSH access restricted to the configured administrator CIDR;
- Amazon Linux 2023 startup;
- cloud-init completed with `status: done`;
- Docker service enabled and active;
- `ec2-user` can access Docker without `sudo`;
- application directory owned by `ec2-user`;
- Systems Manager Agent enabled, active, and registered Online;
- EC2 Instance Metadata Service requires IMDSv2 tokens;
- Terraform post-apply plan reports no infrastructure drift.

## Security controls

- SSH port 22 is restricted to a single administrator `/32` CIDR.
- HTTP port 80 is the only public application ingress port.
- EC2 uses IMDSv2 with token enforcement.
- AWS temporary credentials are stored outside the repository.
- The PEM private key is stored outside the repository with mode `0600`.
- Terraform state, plans, cache, and local tfvars are excluded from Git.
- The application image will be deployed by immutable image tag in Phase 5.

## Troubleshooting: Amazon Linux curl conflict

The first EC2 instance reached the Running state and accepted SSH, but
cloud-init reported an error.

The initial user-data command attempted to install:

```bash
dnf install -y docker curl jq
```

Amazon Linux 2023 already included `curl-minimal`. Installing the full
`curl` package caused a package conflict. Because the bootstrap script used
strict shell error handling, execution stopped before Docker setup completed.

The correction removed the conflicting package installation:

```bash
dnf install -y docker jq
```

The correction was committed as `0f18eac`. Since the EC2 resource uses
`user_data_replace_on_change = true`, Terraform planned an immutable
replacement:

```text
Plan: 1 to add, 0 to change, 1 to destroy.
```

The failed instance was terminated and replaced. The replacement completed
cloud-init successfully and passed all runtime checks.

## MOTD observation

Amazon Linux 2023 exposes `/etc/motd` as a symbolic link managed by its
dynamic update-motd mechanism. Although the user-data script contained the
banner, the runtime MOTD file was empty after boot.

MOTD is therefore not used as an acceptance criterion. Cloud-init status,
Docker status, SSM registration, IMDSv2 enforcement, and Terraform no-drift
results are used instead.

## Evidence files

- `raw/terraform-tooling.txt`
- `raw/terraform-state-summary.txt`
- `raw/terraform-no-drift.txt`
- `raw/aws-runtime-summary.txt`
- `raw/remote-bootstrap-verification.txt`
- `raw/bootstrap-troubleshooting-history.txt`

## Lifecycle note

The infrastructure remains active for Phase 5 deployment and rollback
verification. It must be destroyed with Terraform after the deployment
evidence has been collected.
