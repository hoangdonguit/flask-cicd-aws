# Evidence Documentation

This directory contains concise and reproducible evidence for important project milestones.

## Purpose

Evidence documents are used to:

- prove that a technical control was implemented and tested;
- record the commands or verification methods used;
- distinguish completed work from planned work;
- provide reviewable proof for recruiters and technical interviewers;
- preserve troubleshooting and engineering decisions.

## Evidence requirements

Each evidence document should include:

- the milestone scope;
- the implementation claim;
- the verification method;
- the observed result;
- known limitations;
- a clear claim boundary.

Files under `docs/evidence/` summarize important output for human review. Raw machine-generated logs and lifecycle artifacts are stored separately under [`evidence/`](../../evidence/README.md).

## Security rules

Evidence documents must not contain:

- passwords;
- API tokens;
- Docker Hub access tokens;
- AWS access keys or secret keys;
- private SSH key contents;
- raw `.env` contents;
- Terraform state containing sensitive values;
- temporary infrastructure details that should remain private.

Public portfolio screenshots are stored under:

    docs/screenshots/

Sensitive or temporary local evidence must remain outside Git or in an ignored local directory.

## Current milestones

- [x] Phase 1: Local application and container hardening
- [x] Phase 2: Automated tests and CI quality gates
- [x] Phase 3: Docker Hub publishing and image scanning
- [ ] Phase 4: Terraform and AWS EC2 provisioning
- [ ] Phase 5: Deployment, health verification and rollback
