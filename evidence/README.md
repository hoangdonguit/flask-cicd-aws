# Raw Technical Evidence

This directory contains raw or machine-generated evidence captured from the
verified infrastructure and deployment lifecycle.

## Evidence model

The repository intentionally uses two evidence layers.

### Curated documentation

Human-readable milestone summaries are stored in:

    docs/evidence/

These documents explain:

- milestone scope;
- implementation decisions;
- verification methods;
- observed outcomes;
- troubleshooting;
- limitations and claim boundaries.

They are the recommended starting point for reviewers, recruiters, and
technical interviewers.

### Raw technical evidence

Supporting logs and machine-readable artifacts are stored in:

    evidence/

These files include:

- Terraform plans and apply output;
- Terraform no-drift and destroy verification;
- AWS EC2 and Systems Manager runtime information;
- GitHub Actions run metadata and logs;
- public health, version, and metadata responses;
- deployment and rollback history;
- post-destroy infrastructure checks.

Raw evidence supports the claims made in `docs/evidence/` and is not intended
to replace the curated documentation.

## Current raw evidence

| Phase | Directory | Scope |
|---|---|---|
| Phase 4 | `phase4-terraform-ec2/` | Terraform provisioning, EC2 bootstrap, SSM, IMDSv2, and no-drift verification |
| Phase 5 | `phase5-ec2-deployment/` | Image deployment, rollback, runtime hardening, Terraform destroy, and cleanup |

Phases 1–3 are represented by curated evidence documents under
`docs/evidence/`. Full raw capture was introduced for the AWS and Terraform
lifecycle in Phases 4–5.

## Security rules

Raw evidence must not contain:

- AWS access keys or session tokens;
- GitHub or Docker Hub tokens;
- passwords;
- private SSH keys;
- Terraform state files;
- local tfvars;
- unredacted secret values.

Temporary credentials and private keys must remain outside Git.
