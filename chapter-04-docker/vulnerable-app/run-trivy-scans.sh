#!/bin/bash

mkdir -p trivy-reports

echo "Scanning vulnerable image (JSON)..."
trivy image workstream-api:vulnerable \
  --severity HIGH,CRITICAL \
  --scanners vuln,secret,misconfig \
  --format json \
  -o trivy-reports/vulnerable.json

echo "Scanning hardened image (JSON)..."
trivy image workstream-api:hardened \
  --severity HIGH,CRITICAL \
  --scanners vuln,secret,misconfig \
  --format json \
  -o trivy-reports/hardened.json

echo "Generating readable reports..."
trivy image workstream-api:vulnerable \
  --severity HIGH,CRITICAL \
  --scanners vuln,secret,misconfig \
  --format table \
  -o trivy-reports/vulnerable.txt

trivy image workstream-api:hardened \
  --severity HIGH,CRITICAL \
  --scanners vuln,secret,misconfig \
  --format table \
  -o trivy-reports/hardened.txt

echo "Creating comparison summary..."
cat << 'SUMMARY' > trivy-reports/security-comparison.md
# Container Security Comparison

## Vulnerable Image
See vulnerable.txt for full report.

## Hardened Image
See hardened.txt for full report.

## Expected Improvements
- Reduced attack surface
- No embedded secrets
- Non-root execution
- Fewer HIGH/CRITICAL vulnerabilities
- Smaller image footprint
SUMMARY

echo "Done. Reports saved in trivy-reports/"
