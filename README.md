# wanderlust-devsecops-platform

A hands-on DevSecOps + GitOps project: a small two-service app is tested, scanned, built and
pushed by **Jenkins**, and deployed to **AWS EKS** by **Argo CD**. The app is intentionally tiny
(no database) so the focus stays on the CI/CD workflow.

Region: **ap-south-1 (Mumbai)** everywhere.

## End-to-end flow

```
 You push code / click "Build"
          │
          ▼
 ┌─────────────────────── Wanderlust-CI (Jenkinsfile) ────────────────────────┐
 │ Checkout → compute IMAGE_TAG = <build#>-<git sha>                            │
 │ → Unit tests (node:22 container) → Trivy FS scan → OWASP Dependency-Check   │
 │ → SonarQube analysis → Quality Gate → docker build (x2) → Trivy image scan  │
 │ → docker push to Docker Hub → trigger Wanderlust-CD with IMAGE_TAG          │
 └──────────────────────────────────────────────────────────────────────────────┘
          │ IMAGE_TAG
          ▼
 ┌─────────────────────── Wanderlust-CD (GitOps/Jenkinsfile) ──────────────────┐
 │ Checkout main → scripts/update-image-tags.sh edits kubernetes/*.yaml       │
 │ → git commit "cd: deploy image tag <tag> [skip ci]" → git push to GitHub    │
 └──────────────────────────────────────────────────────────────────────────────┘
          │ new commit on main
          ▼
 ┌─────────────────────── Argo CD (argocd/application.yaml) ───────────────────┐
 │ Polls this repo (every ~3 min) → sees changed manifests → applies them to   │
 │ EKS → Kubernetes rolling update → page shows the new version               │
 └──────────────────────────────────────────────────────────────────────────────┘
```

Jenkins never runs `kubectl`. CD only changes Git; Argo CD makes the cluster match Git.

## Repository layout

| Path | Purpose |
|---|---|
| `backend/` | Express API (`/api/health`, `/api/info`, `/api/destinations`), tests, Dockerfile |
| `frontend/` | Static page served by nginx; nginx proxies `/api/` to `backend-service` |
| `Jenkinsfile` | CI pipeline (job `Wanderlust-CI`) |
| `GitOps/Jenkinsfile` | CD pipeline (job `Wanderlust-CD`) |
| `scripts/update-image-tags.sh` | Used by CD to set image names and tags in the manifests |
| `kubernetes/` | Manifests that Argo CD deploys (namespace, backend, frontend) |
| `argocd/application.yaml` | Argo CD Application pointing at `kubernetes/` on `main` |
| `eks/cluster.yaml` | eksctl definition of the EKS cluster |
| `terraform/` | Jenkins master + worker EC2 instances and security groups |
| `docker-compose.yml` | Run both images locally |

## Image tags

Every CI build produces **one tag for both images**: `<BUILD_NUMBER>-<7-char git SHA>`,
e.g. `12-a1b2c3d`. The tag is also baked into the images as `APP_VERSION`, so the web page shows
exactly which build is running, and which pod served the request.

## Docker Hub username

The username is **not hardcoded** anywhere. Both pipelines read it from the Jenkins credential
with ID `docker` (Username = your Docker Hub username, Password = a Docker Hub access token).

The manifests start with the placeholder `DOCKERHUB_USERNAME/...:initial`. The first CD run
replaces it with the real username and tag and commits that to Git. So you edit **no files**;
you only create the `docker` credential. Leave "Treat username as secret" unchecked on that
credential, otherwise Jenkins masks the image names in the logs.

## Names Jenkins must match

| What | Where in Jenkins | Exact value |
|---|---|---|
| Agent label | Manage Jenkins → Nodes → (worker) → Labels | `wanderlust-agent` |
| SonarQube Scanner tool | Manage Jenkins → Tools | `Sonar` |
| Dependency-Check tool | Manage Jenkins → Tools | `DP-Check` |
| SonarQube server | Manage Jenkins → System → SonarQube servers | `Sonar` |
| Docker Hub credential | Credentials (Username with password) | `docker` |
| GitHub credential | Credentials (Username + Personal Access Token) | `github-cred` |
| NVD API key | Credentials (Secret text) | `nvd-api-key` |
| CI job | New Item → Pipeline, script path `Jenkinsfile` | `Wanderlust-CI` |
| CD job | New Item → Pipeline, script path `GitOps/Jenkinsfile` | `Wanderlust-CD` |
| Email recipients | System → Extended E-mail Notification → Default Recipients | your email |
| SonarQube webhook | SonarQube → Administration → Webhooks | `http://<jenkins>:8080/sonarqube-webhook/` |

Required plugins (beyond the suggested set): OWASP Dependency-Check, SonarQube Scanner,
Docker Pipeline, Pipeline: Stage View, Email Extension.

**First-time note:** Jenkins only learns a job's parameters after it has run once. Click
**Build Now** on `Wanderlust-CD` once before the first CI run. It fails immediately at
"Validate Tag" (expected) and from then on accepts `IMAGE_TAG` from CI.

## Run locally

```bash
cd backend && npm install && npm test && cd ..
docker compose up --build          # open http://localhost:8000
```

## Cleanup (avoid charges)

```bash
kubectl delete -f argocd/application.yaml       # optional, the cluster is deleted anyway
eksctl delete cluster -f eks/cluster.yaml
cd terraform && terraform destroy
```
