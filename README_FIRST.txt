PROJECT 40 - COPY/PASTE BUNDLE
Target repo: sarathi03/wanderlust-devsecops-platform
Original source: NotHarshhaa/DevOps-Projects, DevOps-Project-40/Devops-Mega-Project-Jenkins-ArgoCD-EKS

HOW TO USE
1. Extract this ZIP.
2. Copy the included files/folders into the ROOT of your local repository.
3. For files marked REPLACE, replace the existing file.
4. Review the generated changes with: git status && git diff
5. Test before pushing: docker build -t wanderlust-backend-test ./backend
   docker build -t wanderlust-frontend-test ./frontend
6. Commit and push only after checking the diff.

IMPORTANT
- This bundle is a tailored starting point, not a guarantee that CI will pass without matching Jenkins configuration.
- Jenkinsfile expects Jenkins tools: Sonar (SonarScanner installation), DP-Check (OWASP Dependency-Check installation), Trivy available on agent, Docker CLI/daemon access, SonarQube server name "Sonar", and Jenkins credential ID "docker".
- Docker Hub credential username must have push permission for the configured image namespace.
- Kubernetes/Terraform are retained for the later AWS/CD phase; they are not required to finish local CI.
- Do not commit real secrets. Rotate the JWT_SECRET that was previously committed and inject it through Jenkins credentials or a local ignored env file.
