# Phase 5 — Raw Deployment and Rollback Evidence

## Runtime identifiers

| Property | Value |
|---|---|
| EC2 instance | `i-0df673da1758aaca4` |
| Public IP during lab | `32.192.209.173` |
| Security Group | `sg-04a393a42ca947d5e` |
| Baseline image | `sha-5edfc15` |
| New image | `sha-e390452` |
| Merge commit | `e390452615379af3390a46600eee3de738f60aff` |
| Publish workflow run | `29648211050` |
| Deployment workflow run | `29648475367` |
| Rollback workflow run | `29648498133` |

These identifiers belong to an ephemeral AWS Academy session and are retained
only as technical evidence.

## Verified lifecycle

1. The baseline image `sha-5edfc15` was running successfully.
2. GitHub Actions published `sha-e390452`.
3. GitHub Actions deployed `sha-e390452` through AWS Systems Manager.
4. Public health and version checks passed.
5. GitHub Actions rolled production back to `sha-5edfc15`.
6. Docker reported the rolled-back container as running and healthy.
7. Terraform destroyed the application EC2 instance and Security Group.
8. Post-destroy verification found no remaining managed resources.

## Evidence files

- `raw/pull-request-5.json`
- `raw/github-run-29648211050.json`
- `raw/github-run-29648211050.log`
- `raw/github-run-29648475367.json`
- `raw/github-run-29648475367.log`
- `raw/github-run-29648498133.json`
- `raw/github-run-29648498133.log`
- `raw/public-health.json`
- `raw/public-version.json`
- `raw/public-metadata.json`
- `raw/remote-runtime-final.txt`
- `raw/aws-runtime-before-destroy.txt`
- `raw/terraform-before-destroy.txt`
- `raw/terraform-destroy-plan.txt`
- `raw/terraform-destroy-apply.txt`
- `raw/aws-instance-after-destroy.json`
- `raw/aws-security-group-after-destroy.txt`
- `raw/terraform-state-after-destroy.txt`
- `raw/terraform-post-destroy-check.txt`
- `raw/public-endpoint-after-destroy.txt`

## Security note

No AWS access key, secret access key, session token, Docker Hub token, GitHub
token, or private SSH key is intentionally included in this directory.
