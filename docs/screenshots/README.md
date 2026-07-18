# Portfolio Screenshots

These screenshots summarize the verified delivery lifecycle of
`flask-cicd-aws`.

## 1. CI quality gates

![CI quality gates](01-ci-quality-gates.png)

Automated testing, linting, container verification, and non-root checks gate
pull requests before merge.

## 2. Immutable image tags

![Immutable image tags](02-immutable-image-tags.png)

The image supply-chain workflow publishes immutable `sha-<short-sha>` tags and
keeps `latest` only as a convenience tag.

## 3. Terraform-provisioned EC2 runtime

![Terraform EC2 runtime](03-terraform-ec2-runtime.png)

Terraform provisioned the AWS EC2 runtime and project Security Group in the
AWS Academy Sandbox.

## 4. Terraform pull-request verification

![Terraform pull-request checks](04-terraform-pr-checks.png)

The infrastructure implementation passed repository checks and merged without
base-branch conflicts.

## 5. AWS Systems Manager deployment and rollback

![AWS SSM deployment workflow](05-ssm-deployment-rollback.png)

GitHub Actions executed the production deployment and rollback through AWS
Systems Manager, preserving the restricted SSH administration path.
