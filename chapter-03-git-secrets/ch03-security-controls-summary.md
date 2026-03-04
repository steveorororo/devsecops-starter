# Chapter 3 — Git & Secrets Security Controls

## Controls Implemented This Chapter

### Detective Controls (Find existing exposure)
| Control | Tool | Scope | When to Run |
|---|---|---|---|
| Git history secret scan | Gitleaks | Full repo history | Day 1 at any new org |
| Git blob enumeration | Manual git commands | All objects | Investigation only |
| Verified secret detection | Trufflehog | Full repo history | Supplement Gitleaks |

### Preventive Controls (Stop future exposure)  
| Control | Implementation | Coverage |
|---|---|---|
| Pre-commit hook | .git/hooks/pre-commit | Local developer machine |
| Pre-commit framework | .pre-commit-config.yaml | All developers on clone |
| Hardened .gitignore | Template committed to repo | Working tree |
| CI/CD secret scan gate | Gitleaks in pipeline | Every PR and push |

### Architecture Controls (Remove secrets from git entirely)
| Pattern | Implementation | Maturity |
|---|---|---|
| Environment variables | Runtime injection | Tier 2 |
| Cloud secrets store | AWS Secrets Manager | Tier 3 |
| File-based secrets | Kubernetes Secrets / Docker Secrets | Tier 3 |
| Dynamic secrets | HashiCorp Vault | Tier 4 |

## Workstream Day 1 Action Plan

1. Run Gitleaks against all repositories
2. Triage all findings — rotate any live credentials immediately  
3. Implement pre-commit framework across all repos
4. Add Gitleaks to CI/CD pipeline as blocking gate
5. Audit current secrets management — are credentials in env vars,
   Secrets Manager, or still in config files?
6. Build roadmap to AWS Secrets Manager for all production secrets
