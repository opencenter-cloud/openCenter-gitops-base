# hack/scripts

Maintenance utilities for the `openCenter-gitops-base` repository.

## Available scripts

| Script | Purpose |
|---|---|
| `audit_doc_frontmatter.py` | Verify every `docs/**/*.md` page has the required Diátaxis frontmatter and that `doc_type` is one of `tutorial`, `how-to`, `reference`, `explanation`. Exits non-zero on failure for CI use. |
| `refresh_docs.py` | Repair stale link/path patterns left over from the AsciiDoc-to-Markdown migration. Reports any link that still does not resolve. Idempotent. |
| `add_purpose_line.py` | Insert the steering-rule-mandated `**Purpose:**` line on pages that are missing one. Idempotent. |
| `convert_adoc_to_md.py` | Convert any remaining Antora `docs/modules/ROOT/pages/**/*.adoc` pages to Diátaxis Markdown with Docusaurus frontmatter. Idempotent; skip-existing by default. Requires `downdoc` (`npm i -g downdoc`). |

## Usage

```bash
python3 hack/scripts/refresh_docs.py
python3 hack/scripts/add_purpose_line.py
python3 hack/scripts/audit_doc_frontmatter.py
```
