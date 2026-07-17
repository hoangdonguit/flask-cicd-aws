# Phase 3 Evidence — Secure Docker Image Supply Chain

Implementation commit: `ebf94a2`

Published main image tag: `sha-5edfc15`

GitHub Actions result: successful

Observed publish workflow duration: approximately 47 seconds

## 1. Scope

This milestone introduces a security-gated Docker image supply chain.

It covers:

- Docker image building from reviewed source;
- Trivy vulnerability scanning;
- immutable Git SHA image tags;
- Docker Hub authentication after security verification;
- Docker image publication from `main`;
- remote artifact verification;
- local execution of the image pulled back from the registry.

## 2. Supply-chain flow

The implemented workflow follows this order:

    Source checkout
        |
        v
    Docker image build
        |
        v
    Trivy security scan
        |
        v
    Docker Hub authentication
        |
        v
    Immutable and latest tag creation
        |
        v
    Docker Hub publication
        |
        v
    Remote immutable-image verification

Docker Hub credentials are not used until the image has passed the security gate.

## 3. Pull request behavior

For pull requests targeting `main`, the workflow:

- builds the Docker image;
- scans the image with Trivy;
- does not log in to Docker Hub;
- does not publish an image.

This prevents unmerged pull-request code from accessing registry credentials or creating official artifacts.

## 4. Main branch behavior

After the pull request was merged into `main`, the workflow successfully executed:

- image metadata preparation;
- Docker image build;
- Trivy security scan;
- Docker Hub authentication;
- immutable image publication;
- `latest` tag update;
- remote immutable-image verification.

Published tags:

    hoangdonguit/flask-cicd-aws:sha-5edfc15
    hoangdonguit/flask-cicd-aws:latest

## 5. Immutable tag strategy

The official deployment identifier is:

    sha-5edfc15

The immutable tag maps the Docker artifact to the Git commit that triggered the publishing workflow.

The `latest` tag is provided as a convenience tag only. Future deployment and rollback operations will use explicit SHA tags.

## 6. Trivy security gate

The workflow scans:

- operating-system packages;
- application libraries.

The configured policy evaluates:

- HIGH vulnerabilities;
- CRITICAL vulnerabilities.

The workflow exits with a failure when a vulnerability matching the blocking policy is found.

Unfixed vulnerabilities are currently ignored to prevent the pipeline from blocking on findings for which no remediation is available.

The Trivy GitHub Action is pinned to a full commit SHA instead of a mutable version tag.

## 7. Published artifact identity

Docker Hub reported the following digest for both the immutable and convenience tags:

    sha256:c2e689365ac3a7cd7008ef6775764df1ed0696eb553c58542540f9d44a511ce2

Because both tags share the same digest, they currently reference the same image manifest.

The immutable image was pulled successfully:

    docker pull hoangdonguit/flask-cicd-aws:sha-5edfc15

Local inspection after pulling reported:

    image ID: sha256:856f49331df1a94a8710ff5f7acffe8e6954e93a04fc774ded61587741218620
    configured user: 10001:10001
    local image size: 137054192 bytes
    Docker Hub compressed size: approximately 47.03 MB
    platform: linux/amd64

The registry digest and local image ID represent different concepts:

- the registry digest identifies the published image manifest;
- the local image ID identifies the locally stored image configuration and layers.

They are not expected to be identical.

## 8. Runtime verification

The immutable image pulled from Docker Hub was started locally with:

    DEPLOY_ENV=registry-verification
    IMAGE_TAG=sha-5edfc15
    APP_VERSION=sha-5edfc15

The health endpoint returned:

    {
      "app": "flask-cicd-aws",
      "status": "ok",
      "version": "sha-5edfc15"
    }

The version endpoint returned:

    {
      "app": "flask-cicd-aws",
      "image_tag": "sha-5edfc15",
      "version": "sha-5edfc15"
    }

The metadata endpoint confirmed:

- environment: `registry-verification`;
- image tag: `sha-5edfc15`;
- version: `sha-5edfc15`;
- deployment time was populated;
- container hostname was populated.

## 9. Runtime identity verification

Runtime identity verification returned:

    uid=10001(appuser)
    gid=10001(appgroup)

The artifact pulled from Docker Hub therefore preserves the non-root runtime configuration verified in earlier phases.

## 10. Startup retry observation

The first HTTP request returned a temporary connection reset while the container and Gunicorn workers were still starting.

The retry loop succeeded on the second attempt.

This demonstrates why automated smoke tests should use bounded retries rather than assuming that a started container is immediately ready to serve traffic.

Container start and application readiness are separate states.

## 11. Security decisions

The workflow implements the following controls:

- registry credentials are not exposed to pull-request publishing steps;
- the image is scanned before Docker Hub login;
- the scanned local image is tagged and pushed without rebuilding;
- the Trivy Action is pinned to a full commit SHA;
- official artifacts receive immutable Git SHA tags;
- path filters prevent documentation-only changes from publishing unchanged application images;
- remote artifact existence is verified after publication;
- the published artifact is pulled and executed as an additional verification step;
- runtime remains non-root.

## 12. Current limitations

This milestone does not yet provide:

- signed container images;
- provenance attestations;
- SBOM publication;
- multi-architecture images;
- Terraform infrastructure;
- AWS EC2 deployment;
- remote deployment health verification;
- rollback execution.

These items may be added in later phases according to project scope.

## 13. Claim boundary

Phase 3 proves that a reviewed Docker image can be built, vulnerability-scanned, published with an immutable tag and retrieved successfully from Docker Hub.

It does not prove that the image has been deployed to AWS or that the overall system is production-ready.
