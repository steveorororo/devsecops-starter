#!/usr/bin/env python3
import json
import sys

with open(sys.argv[1]) as f:
    results = json.load(f)

sarif = {
    "version": "2.1.0",
    "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
    "runs": [{
        "tool": {
            "driver": {
                "name": "OPA Conftest",
                "informationUri": "https://www.conftest.dev/",
                "rules": []
            }
        },
        "results": []
    }]
}

for item in results:
    sarif["runs"][0]["results"].append({
        "ruleId": item.get("policy", "opa-policy"),
        "level": "error",
        "message": {"text": item.get("message", "OPA policy violation")},
        "locations": [{
            "physicalLocation": {
                "artifactLocation": {
                    "uri": item.get("filename", "unknown")
                }
            }
        }]
    })

print(json.dumps(sarif, indent=2))

