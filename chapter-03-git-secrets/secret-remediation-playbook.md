# Secret Exposure Remediation Playbook

## Step 1 — IMMEDIATE (within 1 hour of discovery)
- Rotate the exposed credential immediately
- Do not wait for history cleanup
- The secret is already exposed — assume it has been compromised

## Step 2 — ASSESS BLAST RADIUS
- What does this credential access?
- Has it been used since the commit date?
- Check cloud provider access logs (AWS CloudTrail, GCP Audit Logs)
- Check for any unauthorized API calls using this key

## Step 3 — CONTAIN
- Revoke the old credential in the issuing system
- Issue new credential
- Update all systems using the old credential

## Step 4 — CLEAN GIT HISTORY
# Using git filter-repo (preferred over BFG)
pip install git-filter-repo --break-system-packages

git filter-repo --path config.js --invert-paths
# This removes the file from all history
# WARNING: This rewrites history — all clones must be re-cloned

## Step 5 — NOTIFY
- If the repository was ever public or accessible to contractors
  — treat the secret as fully compromised regardless of git cleanup
- If SOC 2 is in scope — this may be a reportable incident
- If PII was accessible via the credential — privacy breach assessment

## Step 6 — PREVENT RECURRENCE
- Implement pre-commit hooks
- Implement CI/CD secret scanning gate
- Run organization-wide git history scan
- Add to security onboarding checklist
