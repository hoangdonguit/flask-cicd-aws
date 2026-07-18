# Phase 5 — EC2 Deployment, Rollback, and Cleanup

## Outcome

Phase 5 completes the deployment lifecycle for the Flask application.

The verified workflow is:

    GitHub Actions workflow_dispatch
                |
                v
    Temporary AWS Academy credentials
                |
                v
       AWS Systems Manager
                |
                v
      Terraform-managed EC2
                |
                v
      Candidate container test
                |
                v
      Production promotion
                |
                v
       Public health checks
                |
                v
       Automated rollback

## Published images

The deployment test used two immutable images:

- baseline image: `hoangdonguit/flask-cicd-aws:sha-5edfc15`;
- new image: `hoangdonguit/flask-cicd-aws:sha-e390452`.

The mutable `latest` tag was not used as the deployment or rollback source of
truth.

## GitHub Actions runs

| Purpose | Run ID | Result |
|---|---:|---|
| Build, scan, and publish `sha-e390452` | `29648211050` | Success |
| Deploy `sha-e390452` through SSM | `29648475367` | Success |
| Roll back to `sha-5edfc15` | `29648498133` | Success |

The deployment workflow verified AWS identity, SSM registration, command
completion, the public endpoint, version metadata, and the requested image
tag.

## Candidate promotion

The deployment script does not immediately replace production.

It first:

1. pulls the requested immutable image;
2. starts a candidate container on loopback port `5001`;
3. checks `/health` and `/version`;
4. validates the expected immutable image tag;
5. removes the candidate;
6. starts the production container on port 80;
7. repeats the health and version checks.

A failed production promotion attempts to restore the previously running
image.

## Production container controls

The verified production container uses:

- configured user `10001:10001`;
- read-only root filesystem;
- `no-new-privileges`;
- all Linux capabilities dropped;
- 256 MiB memory limit;
- 0.75 CPU limit;
- 128 PID limit;
- restart policy `unless-stopped`;
- Docker health checking;
- public host port 80 mapped to container port 5000.

## Deployment verification

The new immutable image was deployed successfully:

    requested image: sha-e390452
    observed version: sha-e390452
    health status: ok

## Rollback verification

The rollback workflow restored the baseline image:

    rollback image: sha-5edfc15
    observed version: sha-5edfc15
    Docker state: running
    Docker health: healthy

The remote deployment history recorded the initial deployment, the new image
deployment, and the rollback.

## Access model

GitHub-hosted runners do not SSH directly into the EC2 instance.

Deployment uses AWS Systems Manager, allowing SSH port 22 to remain restricted
to the administrator's `/32` CIDR.

SSH was retained only as a manual administration and verification path during
the ephemeral lab session.

## AWS Academy credential boundary

The GitHub Actions workflow used temporary AWS Academy credentials stored as
repository secrets.

This is suitable for an ephemeral learning lab, but not a long-lived
production authentication model. The temporary AWS secrets were removed after
the infrastructure lifecycle completed.

A production implementation should use workload identity federation or a
similarly short-lived identity mechanism rather than stored access keys.

## Terraform lifecycle cleanup

After deployment and rollback evidence was captured, Terraform destroyed the
two project-managed resources:

- the application EC2 instance;
- the project Security Group.

The default VPC, AWS Academy Lab resources, Lab Instance, Bastion Host,
`vockey`, and `LabInstanceProfile` were not managed or deleted by this
project.

Post-destroy verification confirmed:

- the application EC2 instance was terminated;
- the project Security Group no longer existed;
- no managed resources remained in Terraform state;
- a second destroy plan had no remaining objects to destroy;
- the old public application endpoint was unavailable.

## Detailed evidence

Full logs and machine-readable evidence are available at:

- [Phase 5 raw evidence](../../evidence/phase5-ec2-deployment/README.md)

## Claim boundary

This phase proves a secure, automated, single-EC2 deployment and rollback
workflow in an ephemeral AWS Academy environment.

It does not claim:

- zero-downtime deployment;
- multi-instance high availability;
- multi-AZ resilience;
- production workload identity;
- managed load balancing;
- autoscaling;
- production-grade secret management.
