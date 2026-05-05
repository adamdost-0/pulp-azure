---
date: "2026-05-05T00:00:00Z"
context: "Local integration testing with Pulp via CLI."
decision: "Automated test clients interacting with Pulp must install pulp-cli in an isolated venv and require an explicit pre-requisite step of resetting the admin password inside the container since the default images don't yield a known default."
---
