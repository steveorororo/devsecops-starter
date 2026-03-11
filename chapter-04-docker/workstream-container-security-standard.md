# Workstream Container Security Standard
Owner: Security Engineering  
Applies To: All containerized services  
Version: 1.0  

This is a builder reference. If you ship containers at Workstream, you follow this.

---

# 1️⃣ Base Image Standard

## Approved Base Images

All production services must use:

- node:<approved-version>-alpine
- python:<approved-version>-alpine
- gcr.io/distroless/* (preferred runtime-only)

Approved versions are maintained in:
engineering/base-image-versions.md

---

## Pinning Requirement (Mandatory)

Images must be pinned by digest:

FROM node:20.11.1-alpine3.19@sha256:<digest>

Never use:
- latest
- floating tags (node:20)

Why: Prevents supply-chain drift.

---

## Image Source Rules

Images must come from:

- Docker Official Library
- Google Distroless
- Workstream internal registry

No random Docker Hub images.

---

# 2️⃣ Dockerfile Requirements (Mandatory)

Every production Dockerfile must:

---

## Multi-Stage Build

FROM node:20.11.1-alpine3.19@sha256:<digest> AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .

FROM node:20.11.1-alpine3.19@sha256:<digest>
WORKDIR /app
COPY --from=builder /app /app

---

## Non-Root User (Explicit UID)

RUN addgroup -S appgroup && adduser -S -u 10001 -G appgroup appuser
USER 10001

Root containers are prohibited.

---

## No Secrets in Image

Never:
- COPY .env
- Hardcode credentials
- Bake API keys into layers

Secrets must come from:
- Kubernetes Secrets
- AWS Secrets Manager

---

## Healthcheck Required

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/healthz', r => process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))"

---

## .dockerignore Required

Must exclude:

.git
.env
node_modules
*.log

---

## Prohibited

- --privileged
- Installing debug tools in runtime image
- Package managers in runtime image
- Unpinned apt/apk installs

---

# 3️⃣ Image Scanning Gate (CI Standard)

All images are scanned in GitHub Actions using:

- Trivy (vulnerability, secret, misconfig scanning)
- Snyk (dependency scanning)

---

## Blocking Rules

CRITICAL → Block merge  
HIGH → Block merge  
MEDIUM → Warning only  
LOW → Warning only  

We ship fast — but we do not ship HIGH or CRITICAL risk.

---

## Required Trivy Command

trivy image \
  --severity HIGH,CRITICAL \
  --exit-code 1 \
  \$IMAGE_NAME

Secrets scanning must also run:

trivy image --scanners secret

---

# 4️⃣ Runtime Security Baseline (Kubernetes Standard)

securityContext:
  runAsUser: 10001
  runAsNonRoot: true
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
      - ALL
  seccompProfile:
    type: RuntimeDefault

---

## Resource Limits Required

resources:
  limits:
    memory: "512Mi"
    cpu: "500m"
  requests:
    memory: "256Mi"
    cpu: "200m"

---

## Temporary Storage Restriction

volumeMounts:
  - mountPath: /tmp
    name: tmp

volumes:
  - name: tmp
    emptyDir:
      medium: Memory

---

## Prohibited in Production

- privileged: true
- hostNetwork: true
- hostPID: true
- hostPath mounts without approval

---

# 5️⃣ Exceptions Process

If your service requires elevated capability (example: CAP_NET_BIND_SERVICE):

1. Submit Jira request including:
   - Why required
   - Why alternatives won’t work
   - Risk impact
   - Duration

2. Reviewed within 48 hours by:
   - Security Engineering
   - Platform Engineering

3. Approved exceptions documented in:
engineering/container-exceptions.md

No undocumented exceptions.

---

# 6️⃣ GitHub Actions Example Workflow

Create:
.github/workflows/container-security.yml

name: Container Security

on:
  pull_request:
  push:
    branches: [ main ]

jobs:
  build-and-scan:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Build Image
        run: |
          docker build -t workstream-api:\${{ github.sha }} .

      - name: Trivy Scan (Block HIGH/CRITICAL)
        uses: aquasecurity/trivy-action@0.20.0
        with:
          image-ref: workstream-api:\${{ github.sha }}
          severity: HIGH,CRITICAL
          exit-code: 1
          ignore-unfixed: true
          scanners: vuln,secret,misconfig

      - name: Snyk Dependency Scan
        uses: snyk/actions/docker@master
        env:
          SNYK_TOKEN: \${{ secrets.SNYK_TOKEN }}
        with:
          image: workstream-api:\${{ github.sha }}
          args: --severity-threshold=high

---

# Final Rule

If your container does not meet this standard:

It does not ship.

Security Engineering  
Workstream
