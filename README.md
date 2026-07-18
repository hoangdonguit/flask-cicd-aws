# Flask CI/CD Deployment Pipeline on AWS EC2

A production-oriented DevOps portfolio lab for building, scanning, publishing and deploying a containerized Flask application to an ephemeral AWS EC2 environment.

> **Current status:** Phases 1–5 are complete. The project now demonstrates application and container hardening, automated CI, a secure immutable image supply chain, Terraform-based AWS EC2 provisioning, GitHub Actions deployment through AWS Systems Manager, verified rollback, and Terraform lifecycle cleanup.

## Recruiter Summary

This project demonstrates a traditional VM-based CI/CD workflow that complements Kubernetes and GitOps portfolio projects.

The target workflow covers:

- Python linting and automated tests;
- dependency and container-image scanning;
- immutable Docker image tags;
- Docker Hub image publication;
- AWS EC2 provisioning with Terraform;
- AWS Systems Manager-based application deployment;
- post-deployment health checks;
- rollback using a previously published image tag.

The project is intentionally scoped as an AWS Academy ephemeral infrastructure lab. It does not claim to be a production-grade, highly available platform.

## Project Positioning

This repository focuses on a VM-based deployment model:

    Flask application
        |
        v
    GitHub Actions CI
        |
        v
    Docker Hub
        |
        v
    Terraform-provisioned AWS EC2
        |
        v
    SSH deployment
        |
        v
    Docker container and health verification

It differs from a Kubernetes GitOps project because the deployment target is a standalone EC2 virtual machine rather than a Kubernetes cluster.

## Target CI/CD Architecture

    Developer push or pull request
                |
                v
         GitHub Actions CI
                |
                +--> Ruff lint
                |
                +--> Pytest
                |
                +--> pip-audit
                |
                +--> Docker build
                |
                +--> Trivy image scan
                |
                v
          Docker Hub registry
                |
                +--> sha-<short-commit>
                |
                +--> latest
                |
                v
      Manual deployment workflow
                |
                v
        Terraform-managed EC2
                |
                v
       AWS SSM image deployment
                |
                v
       Post-deployment health check

The SHA-based image tag is the primary deployment identifier. The `latest` tag is informational and is not intended to be the rollback or deployment source of truth.

## Current Features

Phase 1 currently provides:

- Python 3.12 Flask application;
- Gunicorn WSGI runtime;
- JSON runtime metadata endpoints;
- environment-based version information;
- dependency vulnerability auditing;
- Ruff static analysis;
- non-root Docker execution;
- Docker health checking;
- sensitive-file ignore controls.

## CI Quality Gates

The repository now includes an automated GitHub Actions workflow that verifies:

- Ruff linting;
- Ruff formatting;
- six Pytest application tests;
- runtime dependency auditing with pip-audit;
- Docker image building;
- container endpoint smoke tests;
- non-root runtime identity.

The workflow runs on pushes, pull requests targeting `main`, and manual dispatch.

Deployment is intentionally kept separate from CI so that validation does not depend on an active AWS Academy EC2 instance.

## Application Endpoints

| Endpoint | Purpose |
|---|---|
| `GET /` | Application and runtime summary |
| `GET /health` | Application health status |
| `GET /version` | Application version and Docker image tag |
| `GET /metadata` | Hostname, environment and deployment metadata |

Example health response:

~~~json
{
  "app": "flask-cicd-aws",
  "status": "ok",
  "version": "local-dev"
}
~~~

Example version response:

~~~json
{
  "app": "flask-cicd-aws",
  "image_tag": "local-dev",
  "version": "local-dev"
}
~~~

## Runtime Environment Variables

| Variable | Description | Default |
|---|---|---|
| `APP_VERSION` | Application version returned by the API | Value of `IMAGE_TAG` |
| `IMAGE_TAG` | Docker image or deployment version | `dev` |
| `DEPLOY_ENV` | Deployment environment name | `local` |
| `DEPLOY_TIME` | Deployment timestamp | `unknown` |
| `PORT` | Port used when running `app.py` directly | `5000` |

## Technology Stack

Current and planned technologies include:

- Python 3.12
- Flask
- Gunicorn
- Pytest
- Ruff
- pip-audit
- Docker
- Trivy
- Docker Hub
- GitHub Actions
- Terraform
- AWS EC2
- AWS Security Groups
- SSH deployment

Items not yet implemented are identified in the roadmap.

## Local Development

Create a Python virtual environment:

~~~bash
python3.12 -m venv venv
source venv/bin/activate
~~~

Install development dependencies:

~~~bash
python -m pip install --upgrade pip
python -m pip install -r requirements-dev.txt
~~~

Run quality checks:

~~~bash
ruff check app.py
pip-audit -r requirements.txt
python -m py_compile app.py
~~~

Start the application through Gunicorn:

~~~bash
APP_VERSION=local-dev \
IMAGE_TAG=local-dev \
DEPLOY_ENV=local \
DEPLOY_TIME="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
gunicorn \
  --bind 127.0.0.1:5000 \
  --workers 2 \
  --threads 2 \
  app:app
~~~

Verify the endpoints:

~~~bash
curl -fsS http://127.0.0.1:5000/health
curl -fsS http://127.0.0.1:5000/version
curl -fsS http://127.0.0.1:5000/metadata
~~~

## Docker Build

Build the local image:

~~~bash
docker build \
  --tag flask-cicd-aws:local \
  .
~~~

Inspect the configured runtime user and health check:

~~~bash
docker image inspect flask-cicd-aws:local \
  --format 'user={{.Config.User}} healthcheck={{json .Config.Healthcheck}}'
~~~

## Docker Run

Run the container:

~~~bash
docker run --rm \
  --name flask-cicd-aws-local \
  --publish 5000:5000 \
  --env APP_VERSION=local-docker \
  --env IMAGE_TAG=local-docker \
  --env DEPLOY_ENV=local \
  --env DEPLOY_TIME="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  flask-cicd-aws:local
~~~

Verify container health:

~~~bash
docker inspect flask-cicd-aws-local \
  --format 'status={{.State.Status}} health={{.State.Health.Status}}'
~~~

Verify the container identity:

~~~bash
docker exec flask-cicd-aws-local id
~~~

Expected identity:

    uid=10001(appuser) gid=10001(appgroup)

## Container Security

The Docker image currently:

- uses `python:3.12-slim`;
- runs the application through Gunicorn;
- executes with UID and GID 10001;
- uses `/usr/sbin/nologin` as the application user's shell;
- includes an HTTP application health check;
- excludes Git history, local environments, keys, Terraform and documentation from the build context;
- installs runtime dependencies without installing development-only tooling.

These controls reduce risk but do not make the image or deployment fully secure by themselves.

## Dependency Management

Runtime dependencies are stored in:

    requirements.txt

Development and CI dependencies are stored in:

    requirements-dev.txt

The development requirements include the runtime requirements through:

    -r requirements.txt

This keeps Pytest, Ruff and pip-audit out of the runtime Docker image.

## Evidence

Engineering evidence is stored under:

    docs/evidence/

Current evidence:

- [Phase 1 — Local application and container hardening](docs/evidence/phase1-local-application-and-container.md)
- [Phase 2 — Automated tests and CI quality gates](docs/evidence/phase2-ci-quality-gates.md)
- [Phase 3 — Secure Docker image supply chain](docs/evidence/phase3-image-supply-chain.md)
- [Phase 4 — Terraform EC2 provisioning](docs/evidence/phase4-terraform-ec2.md)
- [Phase 5 — EC2 deployment, rollback, and cleanup](docs/evidence/phase5-ec2-deployment-rollback.md)

Portfolio screenshots will be stored under:

    docs/screenshots/

## Project Roadmap

- [x] Audit the original repository
- [x] Verify that `venv/` is not tracked
- [x] Remediate the pinned Click dependency
- [x] Add dependency vulnerability scanning
- [x] Add environment-aware application endpoints
- [x] Replace the Flask development runtime with Gunicorn
- [x] Run the container as a non-root user
- [x] Add a Docker health check
- [x] Record Phase 1 evidence
- [x] Add automated Pytest coverage
- [x] Add Ruff and test configuration
- [x] Replace the original auto-deployment workflow
- [x] Add GitHub Actions CI quality gates
- [x] Add Trivy image scanning
- [x] Publish immutable `sha-<short-sha>` image tags
- [x] Provision AWS EC2 with Terraform
- [x] Deploy immutable Docker images through GitHub Actions and AWS SSM
- [x] Verify automated rollback to a previous immutable image
- [x] Destroy project infrastructure through Terraform
- [x] Add repository-managed deployment and rollback scripts
- [x] Add a manual GitHub Actions `workflow_dispatch` deployment workflow
- [x] Verify deployment health remotely through public endpoints
- [x] Demonstrate rollback using a previous immutable image tag
- [ ] Capture final portfolio screenshots
> All functional implementation phases are complete. Final portfolio screenshots remain a presentation-only task.


## Image Supply Chain

The `Image Supply Chain` workflow builds and scans Docker images for pull requests.

After code is merged into `main`, the same workflow:

- authenticates to Docker Hub;
- publishes an immutable `sha-<short-sha>` tag;
- updates the convenience `latest` tag;
- verifies the immutable image exists remotely.

Deployment and rollback will use immutable SHA tags instead of `latest`.

Documentation-only changes do not trigger image publication because the workflow is restricted to application, dependency, Docker, and supply-chain workflow changes.

Current published verification tag:

    hoangdonguit/flask-cicd-aws:sha-5edfc15

## GitHub Actions Secrets

The deployment workflow used the following temporary repository secrets:

| Secret | Purpose |
|---|---|
| `AWS_ACCESS_KEY_ID` | Temporary AWS Academy access key |
| `AWS_SECRET_ACCESS_KEY` | Temporary AWS Academy secret key |
| `AWS_SESSION_TOKEN` | Temporary AWS Academy session token |
| `AWS_REGION` | AWS deployment region |
| `AWS_EC2_INSTANCE_ID` | Terraform-managed deployment target |
| `DOCKERHUB_USERNAME` | Docker Hub account name |
| `DOCKERHUB_TOKEN` | Docker Hub publishing token |

The temporary AWS secrets are removed after Terraform cleanup. Docker Hub
publishing secrets remain configured for the image supply-chain workflow.

## AWS Academy Lab Limitation

The AWS deployment target is an ephemeral AWS Academy lab.

Consequences include:

- EC2 instances may exist for only a limited session;
- public IP addresses may change between sessions;
- infrastructure may need to be recreated;
- deployment is triggered manually rather than automatically on every push;
- Terraform destroy and cleanup must be performed before the lab session ends when possible.

This constraint is part of the project design rather than being hidden.

## Verified Rollback Strategy

Deployment and rollback use explicit immutable image tags:

    hoangdonguit/flask-cicd-aws:sha-<short-sha>

The verified test deployed `sha-e390452` and rolled production back to
`sha-5edfc15`.

The rollback workflow uses the previous verified image recorded by the
deployment script. It does not rely on the mutable `latest` tag.

## Security Notes

The project follows these controls:

- credentials are stored in GitHub Actions secrets;
- private keys are not committed;
- Terraform state is not committed;
- the application runs as a non-root container user;
- dependencies are audited;
- images will be scanned before publication;
- immutable image tags are used for deployment and rollback;
- remote deployment requires a post-deployment health check.

This is a security-oriented lab design, not a complete production security model.

## Limitations

The project does not currently claim:

- production readiness;
- enterprise-grade security;
- multi-AZ high availability;
- zero-downtime deployment;
- automated scaling;
- managed secret storage;
- a load balancer;
- disaster recovery;
- a managed database;
- Kubernetes deployment.

## Target CV Bullet

> Implemented an end-to-end CI/CD and IaC lab for a Dockerized Flask application on AWS EC2 using GitHub Actions, Docker Hub and Terraform, with automated tests, dependency and image scanning, immutable image tags, AWS Systems Manager-based deployment, post-deployment health checks and rollback using versioned Docker images.

All referenced CI, image supply chain, Terraform provisioning, deployment, rollback, and cleanup evidence has been completed.
