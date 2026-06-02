# hack/scripts

Maintenance utilities for the `openCenter-gitops-base` repository.

## Available scripts

| Script | Purpose |
|---|---|
| `convert_adoc_to_md.py` | Convert any remaining Antora `docs/modules/ROOT/pages/**/*.adoc` pages to Diátaxis Markdown with Docusaurus frontmatter. Idempotent; skip-existing by default. Requires `downdoc` (`npm i -g downdoc`). |
| `audit_doc_frontmatter.py` | Verify every `docs/**/*.md` page has the required Diátaxis frontmatter and that `doc_type` is one of `tutorial`, `how-to`, `reference`, `explanation`. Exits non-zero on failure for CI use. |

## Usage

```bash
python3 hack/scripts/convert_adoc_to_md.py
python3 hack/scripts/audit_doc_frontmatter.py
```
