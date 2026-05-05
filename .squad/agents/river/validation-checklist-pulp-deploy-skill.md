# Validation Checklist: `pulp-container-deployment` Skill

Reviewer: River (Tester / Validation Engineer)  
Created: 2026-05-05T01:45:46.172+00:00  
Source baseline: Pulp OCI Images quickstart for single-container deployment plus project skills `container-runtime-harness`, `local-container-validation`, and `pulp-bundle-workflows`.

Use this checklist to review Wash's draft skill. Mark each item **PASS** only when the skill gives an operator enough exact guidance to execute, verify, troubleshoot, and safely adapt the deployment path. Mark **FAIL** when the skill is missing the item, gives ambiguous advice, contradicts the official quickstart, or relies on a single happy-path start as proof of readiness.

1. [ ] **Directory scaffold lists all five official directories.**  
   **PASS:** The skill explicitly creates/documents `settings`, `pulp_storage`, `pgsql`, `containers`, and `container_build`, and maps each to its container mount path.  
   **FAIL:** Any directory is omitted, renamed without explanation, or treated as an implementation detail the operator can guess.

2. [ ] **Directory purpose is documented for each mount.**  
   **PASS:** `settings` is described as Pulp configuration, generated certificates, and database encrypted-fields key storage; `pulp_storage` as application/content data; `pgsql` as database state; `containers` and `container_build` as temporary `pulp_container` application/build data.  
   **FAIL:** The skill only shows `mkdir` and `--volume` commands without explaining what data lives where.

3. [ ] **Persistence requirements distinguish critical from recommended.**  
   **PASS:** The skill says `settings`, `pulp_storage`, and `pgsql` must be preserved, while `containers` and `container_build` are less critical but recommended to preserve for `pulp_container` stability and recoverability.  
   **FAIL:** All directories are described as equally disposable, or the database/content/config paths are not identified as critical backup/restore targets.

4. [ ] **Ownership and permissions guidance is actionable.**  
   **PASS:** The skill tells operators to verify host ownership/write access before start, includes rootless Podman considerations, documents the compose folder-volume ownership pattern (`podman unshare chown 700:700` for Podman and `sudo chown 700:700` for Docker where applicable), and gives a recovery path for permission denied errors.  
   **FAIL:** It ignores ownership, assumes every host can write mounted volumes, or does not explain permission failures from bind mounts.

5. [ ] **`settings.py` uses a templated `CONTENT_ORIGIN`.**  
   **PASS:** The skill requires operators to set `CONTENT_ORIGIN` from an explicit deployment variable such as `${PULP_CONTENT_ORIGIN}` or a documented host/FQDN input, and aligns the scheme/port with HTTP vs HTTPS choices.  
   **FAIL:** It hardcodes a hostname, blindly copies `$(hostname)` as production guidance, or leaves `CONTENT_ORIGIN` disconnected from the published endpoint.

6. [ ] **`settings.py` links to full settings documentation.**  
   **PASS:** The skill references the Pulpcore settings documentation for the complete settings list and makes clear that quickstart settings are not exhaustive.  
   **FAIL:** It presents the quickstart snippet as complete production configuration.

7. [ ] **`SECRET_KEY` guidance is explicit and production-safe.**  
   **PASS:** The skill requires a unique, unpredictable `SECRET_KEY`, explains that it must persist with `settings`, and includes a check that deployed instances are not reusing a sample/default key.  
   **FAIL:** It omits `SECRET_KEY`, stores a fake key as guidance, or treats automatic generation as sufficient without persistence and uniqueness checks.

8. [ ] **Podman with SELinux run variant is present.**  
   **PASS:** The skill includes a complete `podman run` example with SELinux `:Z` labels on host bind mounts, the five official mounts, `--publish`, `--name`, image reference, and `--device /dev/fuse`.  
   **FAIL:** SELinux systems get the non-SELinux command, labels are missing, or the command is incomplete.

9. [ ] **Podman without SELinux run variant is present.**  
   **PASS:** The skill includes the no-SELinux bind-mount form and explains when to use it.  
   **FAIL:** It only documents the SELinux form or leaves operators guessing which command fits their host.

10. [ ] **Docker substitution path is present.**  
    **PASS:** The skill explicitly states Docker users can substitute `docker` for `podman` for the single-container path, while preserving all other required options and noting Docker host permission differences.  
    **FAIL:** Docker is omitted, described as unsupported without reason, or given a divergent command that loses required mounts/options.

11. [ ] **HTTPS variant is complete.**  
    **PASS:** The skill explains adding `-e PULP_HTTPS=true`, publishing host port to container port `443`, and updating `CONTENT_ORIGIN` and `pulp-cli` base URL to `https://...`.  
    **FAIL:** It only toggles the environment variable, leaves port `80`, or keeps HTTP URLs after enabling HTTPS.

12. [ ] **Image pinning policy forbids `latest` in automation.**  
    **PASS:** The skill warns that quickstart `pulp/pulp`/stable/latest-style references are acceptable only for manual exploration, and requires explicit version tags or digests for automation, validation, and air-gap work.  
    **FAIL:** It recommends `latest`, omits pinning, or does not distinguish exploratory quickstart from repeatable deployment.

13. [ ] **`--device /dev/fuse` is explained.**  
    **PASS:** The skill states why `/dev/fuse` is needed for container image/build functionality used by Pulp container workflows, how to verify the device exists, and what failure looks like when it is unavailable.  
    **FAIL:** It includes the flag without explanation, omits it, or gives no troubleshooting guidance for hosts without FUSE.

14. [ ] **Admin password reset is first-class post-deploy work.**  
    **PASS:** The skill requires `pulpcore-manager reset-admin-password` via container exec before declaring setup usable and notes Docker substitution.  
    **FAIL:** It skips password reset, leaves default/admin state ambiguous, or treats reset as optional.

15. [ ] **Health check endpoint is included but not over-trusted.**  
    **PASS:** The skill verifies `curl http://localhost:8080/pulp/api/v3/status/` or HTTPS equivalent and explicitly says health alone is insufficient readiness evidence.  
    **FAIL:** It declares success from a single `/status/` response, violating `local-container-validation` guidance.

16. [ ] **`pulpcore-manager check --deploy` is required.**  
    **PASS:** The skill runs `pulpcore-manager check --deploy` inside the container and treats warnings/errors as reviewable deployment findings.  
    **FAIL:** It omits the deploy check or leaves it as optional future hardening.

17. [ ] **`SECRET_KEY` uniqueness check is part of verification.**  
    **PASS:** The skill includes a repeatable check that the active `SECRET_KEY` exists, is not a documented placeholder, and is unique per environment; it avoids printing the secret into logs.  
    **FAIL:** It says “set a secret” but provides no validation or risks leaking the secret in evidence.

18. [ ] **Plugin-specific setup is covered for `pulp_container`.**  
    **PASS:** The skill calls out `pulp_container` key pair generation/authentication setup before container use and links to plugin documentation.  
    **FAIL:** It assumes the bundled container is ready for container repository workflows without key setup.

19. [ ] **Worker status verification is required.**  
    **PASS:** The skill verifies online workers from status output/API/CLI and requires enough workers for expected task execution before workflow tests.  
    **FAIL:** It only verifies the web process responds.

20. [ ] **`pulp-cli` install command is present.**  
    **PASS:** The skill includes `pip install pulp-cli[pygments]` or an equivalent documented install path with Python prerequisite notes.  
    **FAIL:** It tells operators to “use pulp-cli” without installation guidance.

21. [ ] **`pulp-cli` config creation command is present.**  
    **PASS:** The skill includes `pulp config create --username admin --base-url <http-or-https-url> --password <admin password>` or a safer equivalent, and aligns URL with deployed scheme/port.  
    **FAIL:** It omits config creation or hardcodes the wrong base URL.

22. [ ] **`pulp-cli` verification command is present.**  
    **PASS:** The skill includes a command such as `pulp status`, `pulp --version`, or another low-risk authenticated CLI check that proves the CLI can reach the deployed instance.  
    **FAIL:** It stops after creating config without testing it.

23. [ ] **Cross-skill link: `container-runtime-harness`.**  
    **PASS:** The skill references runtime selection principles: avoid hardcoded runtime assumptions in reusable automation, prefer explicit runtime variables/helpers, and preserve `PULP_PULL_POLICY=never` for repeatable air-gap work.  
    **FAIL:** It writes automation as Podman-only or Docker-only without an intentional boundary.

24. [ ] **Cross-skill link: `local-container-validation`.**  
    **PASS:** The skill imports the validation ladder: prerequisites, static config, single-service readiness, workflow smoke, disconnected path, negative tests, and evidence.  
    **FAIL:** It treats container start or status response as the whole validation strategy.

25. [ ] **Cross-skill link: `pulp-bundle-workflows`.**  
    **PASS:** The skill states the deployed Pulp instance is the target for native Pulp export/import bundle workflows, preserves low-to-high one-way semantics, and validates manifests/checksums before import.  
    **FAIL:** It suggests custom API wrapping, high-to-low feedback, or mutable “latest state” bundle handling.

26. [ ] **Air-gap: pre-pulled images are required.**  
    **PASS:** The skill tells operators to pre-stage/pull/load the pinned Pulp image and any client/helper images before disconnecting, with evidence of image ID/digest.  
    **FAIL:** It relies on runtime pulls during air-gap execution.

27. [ ] **Air-gap: no public registry access.**  
    **PASS:** The skill explicitly rejects public registry pulls on the high side and requires all image references to resolve from approved private/internal registries.  
    **FAIL:** It leaves `docker.io`, `quay.io`, or `pulp/pulp` pulls in disconnected guidance.

28. [ ] **Air-gap: `PULP_PULL_POLICY=never` is required.**  
    **PASS:** The skill requires `PULP_PULL_POLICY=never` or runtime-equivalent `--pull=never` for offline/repeatability validation and explains when connected-mode exceptions are allowed.  
    **FAIL:** Pull policy is missing, defaults to `missing`, or allows silent remote pulls in air-gap mode.

29. [ ] **Air-gap: private ACR references are supported.**  
    **PASS:** The skill describes using private Azure Container Registry references, preferably pinned by digest, for Commercial/Government/AirGap deployments.  
    **FAIL:** It only documents public image names.

30. [ ] **Compose alternative includes when to use compose vs single container.**  
    **PASS:** The skill says single container fits small/non-scaling deployments, while compose is preferable when multiple services, operational separation, or local scale testing are needed.  
    **FAIL:** It presents compose as interchangeable with no tradeoff guidance.

31. [ ] **Compose scaling guidance is included.**  
    **PASS:** The skill mentions compose scaling for API/content services (for example `pulp_api` and `pulp_content`) and cautions that this is not the same as production Kubernetes/operator scaling.  
    **FAIL:** It omits scaling or implies the single bundled container can scale horizontally as-is.

32. [ ] **Compose folder-volume variant is included.**  
    **PASS:** The skill documents the folder-volume compose option and the required ownership preparation for existing directories.  
    **FAIL:** It only references default compose with anonymous/named volumes.

33. [ ] **Anti-pattern: hardcoded hostnames are forbidden.**  
    **PASS:** The skill explicitly warns against hardcoded hostnames in `CONTENT_ORIGIN`, `pulp-cli`, or examples intended for reuse.  
    **FAIL:** It uses a fixed hostname/FQDN without placeholder semantics.

34. [ ] **Anti-pattern: skipping password reset is forbidden.**  
    **PASS:** The skill lists skipping `reset-admin-password` as a review failure.  
    **FAIL:** Password reset is optional or absent.

35. [ ] **Anti-pattern: `latest` tag is forbidden in automation.**  
    **PASS:** The skill makes `latest`/implicit stable usage a failure for automation and air-gap validation.  
    **FAIL:** It uses unpinned images in automation snippets.

36. [ ] **Anti-pattern: ignoring SELinux flags is forbidden.**  
    **PASS:** The skill tells reviewers to fail SELinux-capable guidance that lacks `:Z` or an explicit no-SELinux rationale.  
    **FAIL:** SELinux volume labeling is treated as incidental.

37. [ ] **Anti-pattern: pulling images in air-gap mode is forbidden.**  
    **PASS:** The skill marks public or implicit pulls in disconnected mode as a validation failure.  
    **FAIL:** It lets a missing local image trigger network access.

38. [ ] **Anti-pattern: readiness from health check alone is forbidden.**  
    **PASS:** The skill repeats that `/status/` must be combined with deploy check, worker state, CLI auth, plugin setup, and at least a workflow smoke before ready.  
    **FAIL:** It calls the deployment ready after a successful curl.

39. [ ] **Edge case: port conflict on 8080/443.**  
    **PASS:** The skill includes a preflight for occupied ports, a documented alternate host port strategy, and required updates to `CONTENT_ORIGIN` and CLI config when ports change.  
    **FAIL:** It assumes 8080 and 443 are always free.

40. [ ] **Edge case: volume mount permission issues.**  
    **PASS:** The skill includes symptoms, diagnostic commands, SELinux vs ownership distinction, and safe remediation without deleting persistent data.  
    **FAIL:** It tells operators to chmod broadly or recreate volumes without preserving data.

41. [ ] **Edge case: container name conflict.**  
    **PASS:** The skill checks whether a container named `pulp` already exists and gives safe choices: inspect/reuse intentionally, stop/remove only when disposable, or choose a unique name.  
    **FAIL:** It runs `--name pulp` and leaves conflict errors unexplained.

42. [ ] **Edge case: database migrations on version upgrades.**  
    **PASS:** The skill warns that image upgrades can trigger database migrations, requires backups of `settings`, `pulp_storage`, and `pgsql`, recommends reading release notes, and runs deploy checks after upgrade.  
    **FAIL:** It treats image tag changes as a simple restart with no migration/rollback planning.

43. [ ] **Edge case: disk space requirements.**  
    **PASS:** The skill requires preflight disk checks for content storage, PostgreSQL, container build/temp paths, and transfer/import growth, plus failure handling for full disks.  
    **FAIL:** It ignores storage sizing and cleanup evidence.

44. [ ] **Edge case: FUSE device unavailable.**  
    **PASS:** The skill checks for `/dev/fuse`, documents host/runtime limitations, and fails clearly when required container workflows cannot run.  
    **FAIL:** It assumes every runtime exposes FUSE.

45. [ ] **Validation evidence expectations are defined.**  
    **PASS:** The skill tells reviewers/operators what evidence to keep: exact pinned image reference, rendered settings with secrets redacted, run command, status JSON, deploy-check output, worker status, CLI verification, plugin setup confirmation, bundle import smoke evidence, and negative-test notes.  
    **FAIL:** It provides no audit trail beyond command transcripts.

46. [ ] **Manual handoff and disconnected workflow readiness are testable.**  
    **PASS:** The skill connects the deployed container to a repeatable low-to-high import target check, including manifest checksum validation and no high-to-low feedback.  
    **FAIL:** It validates only connected local use and never proves the deployment can receive an air-gap bundle.

47. [ ] **Failure-mode language is concrete enough for review.**  
    **PASS:** Each required path names what “good” looks like and what error/symptom should block readiness.  
    **FAIL:** The skill uses aspirational wording such as “verify as needed” without executable or repeatable criteria.
