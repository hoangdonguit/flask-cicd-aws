# Phase 2 Evidence — Automated Tests and CI Quality Gates

Implementation commit: `93c266a`

Branch: `upgrade/cv-ready-ec2-pipeline`

GitHub Actions result: successful

Observed workflow duration: approximately 36 seconds

## 1. Scope

This milestone introduces automated application testing and CI quality gates before image publication or AWS deployment.

The milestone covers:

- automated Flask endpoint tests;
- runtime metadata and fallback tests;
- Ruff linting and formatting checks;
- Python dependency vulnerability auditing;
- Docker image building in CI;
- container endpoint smoke testing;
- non-root container identity verification;
- removal of the unsafe legacy auto-deployment workflow.

## 2. Automated test coverage

Pytest collected and passed six tests:

1. Root endpoint runtime summary
2. Health endpoint response
3. Version endpoint response
4. Metadata endpoint response
5. Application version fallback to image tag
6. Safe runtime metadata defaults

Local result:

    6 passed

The tests use Flask's test client and isolate runtime environment variables through Pytest monkeypatching.

## 3. Python quality gates

The following checks were verified locally and in GitHub Actions:

    ruff check .
    ruff format --check .
    python -m pytest
    pip-audit -r requirements.txt

Observed local results:

    All checks passed!
    6 passed
    No known vulnerabilities found

## 4. GitHub Actions workflow

The CI workflow runs on:

- repository pushes;
- pull requests targeting `main`;
- manual workflow dispatch.

The workflow uses read-only repository contents permission:

    permissions:
      contents: read

Concurrency control cancels an obsolete run when a newer commit is pushed to the same branch.

## 5. Container verification

After the Python quality gates pass, CI:

- builds the Docker image;
- starts a container;
- waits for the health endpoint;
- verifies `/health`;
- verifies `/version`;
- verifies `/metadata`;
- checks the configured container user;
- checks the effective runtime UID;
- removes the temporary test container.

The expected runtime identity is:

    configured user: 10001:10001
    runtime UID: 10001

The deployment version used by CI follows this format:

    sha-<short-git-commit>

This validates the immutable tag format before Docker Hub publishing is implemented.

## 6. Legacy workflow removal

The original workflow automatically:

- published only the mutable `latest` tag;
- attempted to deploy on every push to `main`;
- depended on a script stored outside the repository;
- lacked automated tests;
- lacked dependency auditing;
- lacked post-deployment verification.

That workflow was removed and replaced with a verification-only CI workflow.

AWS deployment will later be implemented as a separate manually triggered workflow.

## 7. Verified GitHub Actions result

The GitHub Actions interface reported a successful run for:

    ci: add tests and automated quality gates

Commit:

    93c266a

Branch:

    upgrade/cv-ready-ec2-pipeline

Job:

    Quality and Container Verification

## 8. Current limitations

This milestone does not yet provide:

- Trivy container image scanning;
- Docker Hub authentication;
- Docker image publication;
- immutable image persistence in a registry;
- Terraform infrastructure;
- AWS EC2 deployment;
- remote post-deployment health checking;
- rollback execution.

Those controls belong to later phases.

## 9. Claim boundary

Phase 2 proves that application, dependency and container checks are automatically executed by GitHub Actions.

It does not prove that the application has been deployed to AWS or that the system is production-ready.
