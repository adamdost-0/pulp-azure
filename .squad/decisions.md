---
date: "2026-05-05T00:00:00Z"
context: "Local integration testing with Pulp via CLI."
decision: "Automated test clients interacting with Pulp must install pulp-cli in an isolated venv and require an explicit pre-requisite step of resetting the admin password inside the container since the default images don't yield a known default."
---

---
date: "2026-05-05T00:00:00Z"
context: "Initial implementation of disposable local Pulp solution-as-code harness."
decision: "Use dependency-free JSON solution definitions for v1, execute Pulp repository workflows through native pulp-cli commands, validate package consumption with apt-get inside an isolated client container, and require Playwright CLI evidence under evidence/<session-id>/. Do not create a custom Pulp API wrapper or mutate host apt configuration during automated tests."
---

---
date: "2026-05-05T04:36:44.030+00:00"
author: "river"
topic: "local harness setup blocker"
---

# Decision: Treat reset-admin-password CLI compatibility as a hard gate

During validation, `harness/local/scripts/setup-pulp-session.sh` failed on `pulp/pulp:3.21` because `pulpcore-manager reset-admin-password` rejected `--username`. We should treat admin-reset command compatibility with the target Pulp image as a required preflight gate before declaring local harness readiness.

Implication: if setup cannot write `session.env`, the remaining operator flow (`run-pulp-solution.sh`, `validate-apt-client.sh`, `capture-evidence.sh`) is expected to fail, and no evidence package should be considered valid.
