# hack/scripts

Maintenance utilities for the `openCenter-gitops-base` repository.

## Available scripts

| Script | Purpose |
|---|---|
| `convert_adoc_to_md.py` | Convert any remaining Antora `docs/modules/ROOT/pages/**/*.adoc` pages to Diátaxis Markdown with Docusaurus frontmatter. Idempotent; skip-existing by default. Requires `downdoc` (`npm i -g downdoc`). |
| `audit_doc_frontmatter.py` | Verify every `docs/**/*.md` page has the required Diátaxis frontmatter and that `doc_type` is one of `tutorial`, `how-to`, `reference`, `explanation`. Exits non-zero on failure for CI use. |
| `refresh_docs.py` | Repair stale link/path patterns left over from the AsciiDoc-to-Markdown migration. Reports any link that still does not resolve. Idempotent. |
| `add_purpose_line.py` | Insert the steering-rule-mandated `**Purpose:**` line on pages that are missing one. Idempotent. |

## Usage

```bash
python3 hack/scripts/convert_adoc_to_md.py
python3 hack/scripts/audit_doc_frontmatter.py
python3 hack/scripts/refresh_docs.py
python3 hack/scripts/add_purpose_line.py
```

## Repository implementation and limitations

- Source path: `hack/scripts/`; each command is a standalone Python utility in this directory.
- The scripts operate on repository documentation, primarily `docs/**/*.md`; they do not alter service manifests or deploy cluster resources.
- Run commands from the repository root. Review the working tree after any repair script because the scripts can rewrite documentation in place; `convert_adoc_to_md.py` additionally requires the external `downdoc` executable when conversion is needed.

## Validation

Use `python3 hack/scripts/audit_doc_frontmatter.py` as the non-mutating documentation audit. For the mutating utilities, use their idempotent behavior and inspect `git diff` before accepting changes.
