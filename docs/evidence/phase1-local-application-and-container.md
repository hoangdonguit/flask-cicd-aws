# Phase 1 Evidence — Local Application and Container Hardening

Implementation commit: `914f937`

## 1. Scope

This milestone establishes a reproducible local runtime for the Flask application before introducing GitHub Actions, Docker Hub or AWS infrastructure.

The milestone covers:

- environment-aware Flask endpoints;
- Gunicorn application serving;
- dependency remediation and auditing;
- Docker image hardening;
- non-root container execution;
- container-level health checks;
- repository ignore rules.

## 2. Verified implementation

| Control | Verified result |
|---|---|
| Python runtime | Python 3.12.3 |
| Application server | Gunicorn 26.0.0 |
| Runtime endpoints | `/`, `/health`, `/version`, `/metadata` |
| Runtime variables | `APP_VERSION`, `IMAGE_TAG`, `DEPLOY_ENV`, `DEPLOY_TIME`, `PORT` |
| Vulnerable dependency remediation | Click upgraded from 8.3.1 to 8.4.2 |
| Dependency scanning | `pip-audit` reported no known vulnerabilities |
| Static analysis | Ruff reported all checks passed |
| Docker build | Completed successfully |
| Container health | Docker reported `running` and `healthy` |
| Runtime identity | UID/GID 10001, non-root |
| Health probe | HTTP request to `/health` |
| Sensitive-file controls | Virtual environments, environment files, keys and Terraform state are ignored |

## 3. Application verification

The application was tested directly through Gunicorn.

The root endpoint returned application and runtime metadata, including:

- application name;
- deployed version;
- image tag;
- deployment environment;
- hostname;
- deployment time.

Expected health response:

~~~json
{
  "app": "flask-cicd-aws",
  "status": "ok",
  "version": "phase1-local"
}
~~~

Expected version response:

~~~json
{
  "app": "flask-cicd-aws",
  "image_tag": "phase1-local",
  "version": "phase1-local"
}
~~~

## 4. Dependency verification

The following commands were executed:

~~~bash
ruff check app.py
pip-audit -r requirements.txt
python -m py_compile app.py
~~~

Observed results:

~~~text
All checks passed!
No known vulnerabilities found
~~~

The audit result confirms that the pinned runtime dependencies did not match a vulnerability known to the advisory database at the time of testing.

It does not prove that the application is free from every possible vulnerability.

## 5. Docker verification

The local image was built as:

~~~bash
docker build \
  --tag flask-cicd-aws:local \
  .
~~~

The container was started with version metadata injected through environment variables.

Container inspection confirmed:

~~~text
status=running
health=healthy
user=10001:10001
~~~

Runtime identity verification confirmed:

~~~text
uid=10001(appuser) gid=10001(appgroup)
~~~

The application process therefore runs as a dedicated non-root user rather than as root.

## 6. Docker health check

The Docker image contains an HTTP health probe that requests:

    http://127.0.0.1:5000/health

The health check uses Python's standard library instead of installing an additional command-line HTTP client into the image.

The container reached the `healthy` state successfully.

## 7. Runtime configuration

The same container image can represent different deployments by injecting:

| Variable | Purpose |
|---|---|
| `APP_VERSION` | Application version presented by the API |
| `IMAGE_TAG` | Immutable or human-readable image tag |
| `DEPLOY_ENV` | Deployment environment |
| `DEPLOY_TIME` | Deployment timestamp |
| `PORT` | Local Flask development port when running `app.py` directly |

This avoids rebuilding source code merely to change deployment metadata.

## 8. Security decisions

The following security-oriented decisions were implemented:

- the application does not run as root;
- UID and GID are explicitly set to 10001;
- the login shell is set to `/usr/sbin/nologin`;
- secrets and credentials are excluded from the Docker build context;
- development tools are separated from runtime dependencies;
- virtual environments are not tracked by Git;
- private keys and Terraform state are ignored;
- the Docker image has an application-level health check.

## 9. Reproduction commands

Install development dependencies:

~~~bash
python3.12 -m venv venv
source venv/bin/activate
python -m pip install -r requirements-dev.txt
~~~

Run local quality checks:

~~~bash
ruff check app.py
pip-audit -r requirements.txt
python -m py_compile app.py
~~~

Build the image:

~~~bash
docker build -t flask-cicd-aws:local .
~~~

Run the image:

~~~bash
docker run --rm \
  --publish 5000:5000 \
  --env APP_VERSION=phase1-local \
  --env IMAGE_TAG=phase1-local \
  --env DEPLOY_ENV=local \
  flask-cicd-aws:local
~~~

Verify the application:

~~~bash
curl -fsS http://127.0.0.1:5000/health
curl -fsS http://127.0.0.1:5000/version
curl -fsS http://127.0.0.1:5000/metadata
~~~

## 10. Current limitations

This milestone does not yet prove:

- automated pytest coverage;
- GitHub Actions quality gates;
- Docker Hub image publication;
- immutable Git SHA image tags;
- Trivy image scanning;
- Terraform provisioning;
- AWS EC2 deployment;
- remote post-deployment health checks;
- rollback using a previous image tag.

Those controls belong to later project phases.

## 11. Claim boundary

This milestone provides a production-oriented local application and container foundation.

It is not evidence of a production-ready, highly available or enterprise-grade deployment.
