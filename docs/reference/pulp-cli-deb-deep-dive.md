# Pulp CLI Debian Plugin Deep Dive

Research source: <https://github.com/pulp/pulp-cli-deb>, cloned into
NAS-backed research storage during the `feature/pulp-cli-apt-sandbox` work. The
examined upstream commit was `6f0b68e`.

## Plugin Shape

`pulp-cli-deb` registers the `deb` plugin through the `pulp_cli.plugins` entry
point. It mounts five apt-focused command groups:

1. `pulp deb remote`
2. `pulp deb repository`
3. `pulp deb publication`
4. `pulp deb distribution`
5. `pulp deb content`

The plugin depends on `pulp-cli` and `pulp-glue-deb`, and the glue layer defines
the resource names, href fields, plugin requirements, preprocessing, and
capabilities used by the CLI commands.

## Apt Remote Contract

Remote type defaults to `apt`.

| Option | Behavior |
| --- | --- |
| `--name` | Required by generic create behavior. |
| `--url` | Required by generic remote create behavior. |
| `--distribution` | Required on create and repeatable. At least one non-empty value is required. |
| `--component` | Repeatable. Empty string means sync all available components. |
| `--architecture` | Repeatable. Empty string means sync all available architectures. |
| `--policy` | `immediate`, `on_demand`, or `streamed`. |
| `--gpgkey` | Public key string or `@file`, used to verify upstream Release signatures. |

The glue layer converts repeated `distribution`, `component`, and `architecture`
values into whitespace-separated strings. Empty `component` or `architecture`
becomes `null`; empty `distribution` is rejected because a remote must have at
least one distribution.

Current harness alignment:

```bash
pulp deb remote create \
  --name "$PULP_REMOTE_NAME" \
  --url "$REMOTE_URL" \
  --distribution "$APT_DISTRIBUTION" \
  --component "$APT_COMPONENT" \
  --architecture "$FIXTURE_ARCHITECTURE" \
  --policy immediate
```

Required next steps:

1. Add optional `gpgkey` support before signed upstream repository validation.
2. Model repeatable distributions, components, and architectures in the solution
   schema instead of one scalar each.
3. Treat empty component/architecture as intentional "all" values, not missing
   configuration.

## Apt Repository Contract

Repository type defaults to `apt`.

| Option | Behavior |
| --- | --- |
| `--name` | Required on create. |
| `--remote` | Optional default remote by name or href. |
| `--description` | Optional repository metadata. |
| `--retain-repo-versions` | Controls retained repository versions. |

Important repository commands:

| Command | Behavior |
| --- | --- |
| `sync` | Calls Pulp repository sync. Uses repository default remote unless `--remote` is provided. |
| `version` | Generic repository version commands. |
| `task` | Generic repository task commands. |
| `content add/remove/modify/list` | Add, remove, or list deb content by package href or JSON list. |

Sync options:

| Option | Behavior |
| --- | --- |
| `--remote` | Overrides repository default remote. Required if repository has no default remote. |
| `--mirror` / `--no-mirror` | Mirror removes content no longer present upstream; no-mirror is additive. |
| `--optimize` / `--no-optimize` | Requires `pulp_deb >= 2.20.0`; skips metadata processing when checksums are unchanged. |

Current harness alignment:

```bash
pulp deb repository create \
  --name "$PULP_REPOSITORY_NAME" \
  --remote "$PULP_REMOTE_NAME" \
  --retain-repo-versions 3

pulp deb repository sync \
  --name "$PULP_REPOSITORY_NAME" \
  --remote "$PULP_REMOTE_NAME" \
  --mirror \
  --no-optimize
```

Required next steps:

1. Make sync mode explicit in solution files: mirror vs additive.
2. Gate `--optimize` use on detected plugin version.
3. Capture repository version href after sync as a first-class workflow output.
4. Add idempotent "show-or-create/update" behavior instead of assuming an empty
   Pulp instance.

## Apt Publication Contract

Publication type defaults to `apt`; `verbatim` is also available.

| Option | Behavior |
| --- | --- |
| `--repository` | Repository name or href. |
| `--version` | Optional repository version number; glue expands it to a repository-version href. |
| `--simple` | Apt-only simple publishing mode. |
| `--structured` / `--no-structured` | Apt-only structured publishing mode. |
| `--signing-service` | Apt signing service name or href. |
| `--checkpoint` | Requires `pulp_deb >= 3.6.0`; creates a checkpoint publication. |

`verbatim` publications reject apt-only fields such as `simple`, `structured`,
and `signing_service`.

Current harness alignment:

```bash
pulp deb publication create \
  --repository "$PULP_REPOSITORY_NAME" \
  --structured
```

Required next steps:

1. Add publication mode to the solution schema: structured, simple, or server
   default.
2. Add signing-service support before production apt publishing.
3. Add checkpoint support only after plugin version discovery proves support.
4. Preserve publication href in evidence and downstream distribution creation.

## Apt Distribution Contract

Distribution type defaults to `apt`.

| Option | Behavior |
| --- | --- |
| `--name` | Required on create. |
| `--base-path` | Content path under `/pulp/content/`. |
| `--publication` | Publication href to serve. |
| `--repository` | Repository name or href for auto-distribution. |
| `--checkpoint` / `--not-checkpoint` | Requires `pulp_deb >= 3.6.0`. |

Current harness alignment:

```bash
pulp deb distribution create \
  --name "$PULP_DISTRIBUTION_NAME" \
  --base-path "$APT_BASE_PATH" \
  --publication "$PUBLICATION_HREF"
```

Required next steps:

1. Decide publication-pinned distributions vs repository auto-distribution per
   environment.
2. Add update semantics for existing distributions.
3. Add base-path collision checks and evidence.

## Deb Content Contract

Default content type is `package`. Other list/show content types include
`generic_content`, `installer_file_index`, `installer_package`,
`package_release_component`, `release_architecture`, `release_component`,
`release_file`, and `release`.

| Command | Behavior |
| --- | --- |
| `pulp deb content upload --file FILE` | Uploads a deb package content unit. |
| `pulp deb content upload --file FILE --repository REPO --distribution DIST --component COMP` | Uploads a package and adds it to a repository with release-component metadata. |
| `pulp deb repository content add --repository REPO --package-href HREF` | Adds existing package content. |
| `pulp deb repository content remove --repository REPO --package-href HREF` | Removes package content. |
| `pulp deb repository content modify --repository REPO --add-content JSON` | Bulk add by `pulp_href`. |
| `pulp deb content --type release_component create --distribution DIST --component COMP` | Creates release-component content. |

Required next steps:

1. Keep sync/publish as the default flow for mirrored repositories.
2. Use `content upload` for curated/manual package injection workflows.
3. Add content list/show evidence after sync so tests can prove expected package,
   release, architecture, and component metadata.

## Export and Import Implications

`pulp-cli-deb` does not define dedicated `deb export` or `deb import` commands.
The glue layer marks apt repositories as supporting the generic `pulpexport`
capability when `pulp_deb >= 2.20.0`. Export/import orchestration should use
Pulp core exporter/importer commands against apt repositories instead of a
deb-specific wrapper.

Required next steps:

1. Research Pulp core exporter/importer CLI commands separately.
2. Verify apt repository export/import with a low-side/high-side disposable flow.
3. Include repository version href, export href, manifest path, checksums, import
   task output, and high-side publication evidence in the air-gap workflow.

