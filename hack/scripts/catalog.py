#!/usr/bin/env python3
"""openCenter service catalog: generator and gates.

Implements the tooling for the catalog described in ``docs/catalog/``:

* ``generate`` — merge every ``applications/base/services/*/catalog.yaml``
  fragment into the committed aggregate ``applications/catalog.lock.yaml``,
  deterministically ordered, with blueprint membership denormalized.
* ``validate`` — run the structural JSON Schema over every fragment.
* ``gate`` — run the four accuracy gates that require reading the manifests
  (coverage, version consistency, orphaned values, aggregate freshness) plus
  the Phase 3 blueprint gate (membership resolves and agrees both ways,
  ``extends`` is acyclic).
* ``docs`` — regenerate ``docs/reference/service-categories.md`` from the
  blueprints and the catalog, so the hand-maintained list can be deleted.

The tool is dependency-light: standard library plus PyYAML (supplied to the
pre-commit hook via ``additional_dependencies`` so CI needs no system install).
JSON Schema validation uses ``jsonschema`` when present and otherwise falls
back to a built-in structural check, so the gate never silently passes.

Exit status is non-zero on any failure, making every subcommand a merge gate.
"""

from __future__ import annotations

import argparse
import io
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

try:
    import yaml
except ModuleNotFoundError:  # pragma: no cover - exercised only without PyYAML
    print(
        "catalog.py requires PyYAML. In CI it is supplied via the pre-commit "
        "hook's additional_dependencies; locally, `pip install pyyaml`.",
        file=sys.stderr,
    )
    raise

API_VERSION = "catalog.opencenter.dev/v1alpha1"
SERVICES_DIR = Path("applications/base/services")
FRAGMENT_NAME = "catalog.yaml"
LOCK_PATH = Path("applications/catalog.lock.yaml")
SCHEMA_PATH = Path("applications/catalog.schema.json")
BLUEPRINTS_DIR = Path("applications/blueprints")
CATEGORIES_DOC = Path("docs/reference/service-categories.md")

# Value files whose basename prefix is an accepted alternative to "values-".
VALUES_PREFIXES = ("values-", "hardened-values-")


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

@dataclass
class Result:
    """Accumulates gate failures with a clean rendered report."""

    errors: list[str] = field(default_factory=list)

    def fail(self, msg: str) -> None:
        self.errors.append(msg)

    @property
    def ok(self) -> bool:
        return not self.errors

    def render(self, header: str) -> str:
        if self.ok:
            return f"OK: {header}"
        body = "\n".join(f"  - {e}" for e in self.errors)
        return f"FAILED: {header}\n{body}"


def load_yaml(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as fh:
        return yaml.safe_load(fh)


def repo_root(explicit: str | None) -> Path:
    if explicit:
        return Path(explicit).resolve()
    # Walk up until we find applications/base/services.
    here = Path.cwd().resolve()
    for candidate in [here, *here.parents]:
        if (candidate / SERVICES_DIR).is_dir():
            return candidate
    return here


def fragment_paths(root: Path) -> list[Path]:
    base = root / SERVICES_DIR
    return sorted(p for p in base.glob(f"*/{FRAGMENT_NAME}"))


def service_dirs(root: Path) -> list[Path]:
    base = root / SERVICES_DIR
    return sorted(p for p in base.iterdir() if p.is_dir())


def dump_yaml(data: Any) -> str:
    """Deterministic YAML dump: keys in insertion order, stable indent.

    Uses a dumper that indents block sequences under their parent key so the
    output satisfies yamllint's default ``indentation`` rule (sequences
    indented, mapping indent of 2) rather than PyYAML's flush-left sequences.
    """

    class _IndentedDumper(yaml.SafeDumper):
        def increase_indent(self, flow=False, indentless=False):
            return super().increase_indent(flow=flow, indentless=False)

    buf = io.StringIO()
    yaml.dump(
        data,
        buf,
        Dumper=_IndentedDumper,
        sort_keys=False,
        default_flow_style=False,
        indent=2,
        width=100,
        allow_unicode=True,
    )
    return buf.getvalue()


# ---------------------------------------------------------------------------
# Schema validation
# ---------------------------------------------------------------------------

def validate_fragments(root: Path) -> Result:
    res = Result()
    schema = None
    schema_path = root / SCHEMA_PATH
    if schema_path.is_file():
        import json

        schema = json.loads(schema_path.read_text(encoding="utf-8"))

    validator = None
    try:
        import jsonschema

        validator = jsonschema.Draft7Validator(schema) if schema else None
    except ModuleNotFoundError:
        validator = None

    for frag_path in fragment_paths(root):
        try:
            doc = load_yaml(frag_path)
        except yaml.YAMLError as exc:
            res.fail(f"{frag_path}: invalid YAML: {exc}")
            continue
        if not isinstance(doc, dict):
            res.fail(f"{frag_path}: fragment is not a mapping")
            continue
        if validator is not None:
            for err in sorted(validator.iter_errors(doc), key=lambda e: e.path):
                loc = "/".join(str(p) for p in err.path) or "(root)"
                res.fail(f"{frag_path}: {loc}: {err.message}")
        else:
            _structural_check(frag_path, doc, res)
    return res


def _structural_check(path: Path, doc: dict, res: Result) -> None:
    """Fallback structural validation when jsonschema is unavailable."""
    if doc.get("apiVersion") != API_VERSION:
        res.fail(f"{path}: apiVersion must be {API_VERSION}")
    if doc.get("kind") != "ServiceEntry":
        res.fail(f"{path}: kind must be ServiceEntry")
    for req in ("name", "path", "packaging"):
        if req not in doc:
            res.fail(f"{path}: missing required key {req}")
    packaging = doc.get("packaging")
    valid_pkg = {
        "helmRepository", "ociHelm", "gitRepository",
        "olmSubscription", "remoteKustomize", "composite",
    }
    if packaging not in valid_pkg:
        res.fail(f"{path}: packaging '{packaging}' not in {sorted(valid_pkg)}")
    if packaging == "composite":
        if not doc.get("subcomponents"):
            res.fail(f"{path}: composite requires subcomponents")
    else:
        if not doc.get("version"):
            res.fail(f"{path}: non-composite requires version")
    if packaging in {"helmRepository", "ociHelm", "gitRepository"}:
        if "source" not in doc:
            res.fail(f"{path}: {packaging} requires source")
        if "namespace" not in doc:
            res.fail(f"{path}: {packaging} requires namespace")
    wv = doc.get("versionWaiver")
    if wv is not None and not str(wv).strip():
        res.fail(f"{path}: versionWaiver present but empty")


# ---------------------------------------------------------------------------
# Aggregate generation
# ---------------------------------------------------------------------------

def build_aggregate(root: Path) -> dict:
    entries = [load_yaml(p) for p in fragment_paths(root)]
    entries.sort(key=lambda e: e.get("name", ""))
    # Denormalize: nothing to inherit for entries yet (blueprints denormalized
    # separately below), but we keep the entry list stable and sorted.
    blueprints = load_blueprints(root)
    resolved = {name: resolve_extends(name, blueprints) for name in blueprints}

    # Denormalize blueprint membership onto each entry (union of self-declared
    # and blueprint-declared membership), for single-fetch consumers.
    member_index: dict[str, list[dict]] = {}
    for bp_name, bp in resolved.items():
        for member in bp.get("members", []):
            member_index.setdefault(member, []).append({"name": bp_name, "tier": member_tier(bp, member)})

    for entry in entries:
        declared = {b["name"]: b for b in entry.get("blueprints", [])}
        for m in member_index.get(entry["name"], []):
            declared.setdefault(m["name"], m)
        if declared:
            entry["blueprints"] = [declared[k] for k in sorted(declared)]

    aggregate = {
        "apiVersion": API_VERSION,
        "kind": "Catalog",
        "generated": "This file is generated by hack/scripts/catalog.py. Do not edit by hand.",
        "services": entries,
        "blueprints": [resolved[name] for name in sorted(resolved)],
    }
    return aggregate


def member_tier(bp: dict, member: str) -> str:
    # Tier is authored on the ServiceEntry side; blueprint files list names.
    # Default to "optional" when not otherwise known.
    return "optional"


def generate(root: Path, check: bool) -> int:
    aggregate = build_aggregate(root)
    text = "---\n" + dump_yaml(aggregate)
    lock = root / LOCK_PATH
    if check:
        current = lock.read_text(encoding="utf-8") if lock.is_file() else ""
        if current != text:
            print(
                f"FAILED: {LOCK_PATH} is stale. Run "
                f"`python3 hack/scripts/catalog.py generate` and commit.",
                file=sys.stderr,
            )
            return 1
        print(f"OK: {LOCK_PATH} matches the fragments.")
        return 0
    lock.write_text(text, encoding="utf-8")
    print(f"Wrote {LOCK_PATH} ({len(aggregate['services'])} services, "
          f"{len(aggregate['blueprints'])} blueprints).")
    return 0


# ---------------------------------------------------------------------------
# Blueprints
# ---------------------------------------------------------------------------

def load_blueprints(root: Path) -> dict[str, dict]:
    d = root / BLUEPRINTS_DIR
    out: dict[str, dict] = {}
    if not d.is_dir():
        return out
    for p in sorted(d.glob("*.yaml")):
        doc = load_yaml(p)
        if isinstance(doc, dict) and doc.get("kind") == "Blueprint":
            out[doc["name"]] = doc
    return out


def resolve_extends(name: str, blueprints: dict[str, dict], _seen: tuple = ()) -> dict:
    if name in _seen:
        raise ValueError(f"extends cycle: {' -> '.join([*_seen, name])}")
    bp = dict(blueprints[name])
    parent = bp.get("extends")
    members = list(bp.get("members", []))
    choices = list(bp.get("choices", []) or [])
    if parent:
        parent_bp = resolve_extends(parent, blueprints, (*_seen, name))
        merged = list(dict.fromkeys([*parent_bp.get("members", []), *members]))
        bp["members"] = merged
        # Inherit parent choices not already redefined by this blueprint.
        own_choice_names = {c.get("name") for c in choices}
        inherited = [c for c in parent_bp.get("choices", []) or [] if c.get("name") not in own_choice_names]
        if inherited or choices:
            bp["choices"] = [*inherited, *choices]
    return bp


# ---------------------------------------------------------------------------
# Gates (Phase 2 + Phase 3)
# ---------------------------------------------------------------------------

def gate(root: Path) -> int:
    fragments = {p.parent.name: load_yaml(p) for p in fragment_paths(root)}
    res = Result()
    gate_coverage(root, fragments, res)
    gate_version_consistency(root, fragments, res)
    gate_orphaned_values(root, res)
    gate_aggregate_fresh(root, res)
    gate_blueprints(root, fragments, res)
    print(res.render("catalog gates"))
    return 0 if res.ok else 1


def gate_coverage(root: Path, fragments: dict[str, dict], res: Result) -> None:
    """Gate 1: every service dir has a fragment; every path resolves."""
    dirs = {p.name for p in service_dirs(root)}
    have = set(fragments)
    for missing in sorted(dirs - have):
        res.fail(f"coverage: {missing}/ has no {FRAGMENT_NAME}")
    for extra in sorted(have - dirs):
        res.fail(f"coverage: fragment {extra} has no matching directory")
    for name, frag in fragments.items():
        path = frag.get("path", "")
        if not (root / path).is_dir():
            res.fail(f"coverage: {name}: path '{path}' does not resolve")


def _values_file_versions(root: Path, svc_dir: Path) -> set[str]:
    """Version strings extractable from helm-values/values-<v>.yaml filenames."""
    out: set[str] = set()
    hv = svc_dir / "helm-values"
    if hv.is_dir():
        for f in hv.glob("*.yaml"):
            stem = f.name[:-5] if f.name.endswith(".yaml") else f.name
            for prefix in VALUES_PREFIXES:
                if stem.startswith(prefix):
                    out.add(stem[len(prefix):])
    return out


def gate_version_consistency(root: Path, fragments: dict[str, dict], res: Result) -> None:
    """Gate 2: version == HelmRelease chart version == values filename ==
    every declared CRD component version. Waivable via versionWaiver."""
    for name, frag in fragments.items():
        _check_entry_versions(root, name, frag, root / frag.get("path", ""), res)
        for sub in frag.get("subcomponents", []) or []:
            if not sub.get("deployable"):
                continue
            sub_dir = (root / frag.get("path", "")) / sub.get("path", "")
            label = f"{name}/{sub.get('name')}"
            _check_entry_versions(root, label, sub, sub_dir, res)


def _check_entry_versions(root: Path, label: str, entry: dict, svc_dir: Path, res: Result) -> None:
    if entry.get("versionWaiver"):
        return
    version = entry.get("version")
    if version is None:
        return  # composite parent; nothing to check at this level
    # Values filename must contain the version.
    vfiles = _values_file_versions(root, svc_dir)
    if vfiles and version not in vfiles:
        res.fail(
            f"version: {label}: version '{version}' has no matching "
            f"helm-values/values-{version}.yaml (found: {sorted(vfiles)})"
        )
    # HelmRelease chart version, if a helmrelease*.yaml exists.
    hr_versions = _helmrelease_versions(svc_dir)
    main_hr = hr_versions.get("main")
    if main_hr is not None and main_hr != version:
        res.fail(
            f"version: {label}: version '{version}' != HelmRelease chart "
            f"version '{main_hr}'"
        )
    # Declared CRD components.
    for comp in entry.get("components", []) or []:
        if comp.get("versionWaiver"):
            continue
        cv = comp.get("version", version)
        crd_hr = hr_versions.get(comp["name"])
        if crd_hr is not None and crd_hr != cv:
            res.fail(
                f"version: {label}: component '{comp['name']}' version "
                f"'{cv}' != its HelmRelease version '{crd_hr}'"
            )


def _helmrelease_versions(svc_dir: Path) -> dict[str, str]:
    """Map of {'main': v, '<crd-hr-name>': v} from helmrelease*.yaml files.

    The main HelmRelease is the one in helmrelease.yaml; split CRD releases
    live in helmrelease-crd(s).yaml and are keyed by their metadata.name.
    """
    out: dict[str, str] = {}
    if not svc_dir.is_dir():
        return out
    for hr in sorted(svc_dir.glob("helmrelease*.yaml")):
        try:
            docs = list(yaml.safe_load_all(hr.read_text(encoding="utf-8")))
        except yaml.YAMLError:
            continue
        for doc in docs:
            if not isinstance(doc, dict) or doc.get("kind") != "HelmRelease":
                continue
            version = (
                doc.get("spec", {})
                .get("chart", {})
                .get("spec", {})
                .get("version")
            )
            if version is None:
                continue
            version = str(version)
            meta_name = doc.get("metadata", {}).get("name", "")
            if hr.name == "helmrelease.yaml":
                out["main"] = version
            else:
                out[meta_name] = version
    return out


def gate_orphaned_values(root: Path, res: Result) -> None:
    """Gate 3: every file under helm-values/ is referenced by a
    secretGenerator in the sibling kustomization.yaml."""
    for kust in (root / SERVICES_DIR).rglob("kustomization.yaml"):
        hv = kust.parent / "helm-values"
        if not hv.is_dir():
            continue
        referenced = set()
        try:
            text = kust.read_text(encoding="utf-8")
        except OSError:
            continue
        for line in text.splitlines():
            line = line.strip()
            if "helm-values/" in line:
                # extract the path token after '=' or after 'helm-values/'
                token = line.split("helm-values/", 1)[1]
                token = token.split()[0].strip("\"'")
                referenced.add(f"helm-values/{token}")
        for f in sorted(hv.glob("*.yaml")):
            rel = f"helm-values/{f.name}"
            if rel not in referenced:
                svc = f.relative_to(root / SERVICES_DIR)
                res.fail(f"orphaned-values: {svc} is referenced by no secretGenerator")


def gate_aggregate_fresh(root: Path, res: Result) -> None:
    """Gate 4: catalog.lock.yaml matches what the generator produces."""
    expected = "---\n" + dump_yaml(build_aggregate(root))
    lock = root / LOCK_PATH
    current = lock.read_text(encoding="utf-8") if lock.is_file() else ""
    if current != expected:
        res.fail(f"aggregate: {LOCK_PATH} is stale; run `catalog.py generate`")


def gate_blueprints(root: Path, fragments: dict[str, dict], res: Result) -> None:
    """Phase 3 gate: members resolve, membership agrees both ways, no cycles."""
    blueprints = load_blueprints(root)
    if not blueprints:
        return
    # Buildable target set: service names + deployable <parent>/<sub>.
    targets: set[str] = set()
    for name, frag in fragments.items():
        targets.add(name)
        for sub in frag.get("subcomponents", []) or []:
            if sub.get("deployable"):
                targets.add(f"{name}/{sub['name']}")

    # extends acyclic + resolves.
    for name in blueprints:
        try:
            resolve_extends(name, blueprints)
        except ValueError as exc:
            res.fail(f"blueprint: {exc}")
        parent = blueprints[name].get("extends")
        if parent and parent not in blueprints:
            res.fail(f"blueprint: {name} extends unknown blueprint '{parent}'")

    # Every member resolves.
    for name, bp in blueprints.items():
        choice_members = {
            m for c in bp.get("choices", []) or [] for m in c.get("oneOf", [])
        }
        for member in bp.get("members", []):
            if member not in targets:
                res.fail(f"blueprint: {name} member '{member}' resolves to no catalog entry")
        for cm in choice_members:
            if cm not in targets:
                res.fail(f"blueprint: {name} choice '{cm}' resolves to no catalog entry")

    # Two-way agreement: a ServiceEntry claiming blueprint X must be a member
    # of blueprint X (directly, via an extends chain, or as a choice member),
    # and every directly-listed member must claim the blueprint back.
    resolved = {}
    for name in blueprints:
        try:
            resolved[name] = resolve_extends(name, blueprints)
        except ValueError:
            resolved[name] = blueprints[name]

    def effective_members(bp_name: str) -> set[str]:
        bp = resolved.get(bp_name, {})
        members = set(bp.get("members", []))
        for c in bp.get("choices", []) or []:
            members.update(c.get("oneOf", []))
        return members

    direct_members = {n: set(bp.get("members", [])) for n, bp in blueprints.items()}
    for name, frag in fragments.items():
        for claim in frag.get("blueprints", []) or []:
            bp_name = claim["name"]
            if bp_name not in blueprints:
                res.fail(f"blueprint: {name} claims unknown blueprint '{bp_name}'")
                continue
            if name not in effective_members(bp_name):
                res.fail(
                    f"blueprint: {name} claims '{bp_name}' but is not an "
                    f"(inherited/choice) member of {bp_name}.yaml"
                )
    # Reverse direction: a directly-listed, non-choice, top-level member must
    # claim the blueprint on its own ServiceEntry.
    for bp_name in blueprints:
        choice_members = {
            m for c in blueprints[bp_name].get("choices", []) or [] for m in c.get("oneOf", [])
        }
        for member in direct_members[bp_name]:
            if "/" in member or member in choice_members:
                continue  # subcomponent or choice membership is one-directional
            frag = fragments.get(member)
            if frag is None:
                continue  # resolution already checked above
            claims = {c["name"] for c in frag.get("blueprints", []) or []}
            if bp_name not in claims:
                res.fail(
                    f"blueprint: {bp_name}.yaml lists '{member}' but its "
                    f"ServiceEntry does not claim '{bp_name}'"
                )


# ---------------------------------------------------------------------------
# Generated documentation
# ---------------------------------------------------------------------------

CATEGORY_ORDER = [
    ("minimal", "Minimal"),
    ("enterprise", "Enterprise"),
    ("ai-ml", "AI/ML"),
    ("observability", "Observability"),
    ("storage", "Storage"),
    ("networking", "Networking"),
    ("security-policy", "Security & Policy"),
    ("data-messaging", "Data & Messaging"),
    ("cloud-provider-integration", "Cloud Provider Integration"),
    ("hpc-batch", "HPC & Batch"),
    ("operator-infrastructure", "Operator Infrastructure"),
]


def _entry_version(entry: dict) -> str:
    if entry.get("packaging") == "olmSubscription":
        return "OLM"
    if entry.get("packaging") == "composite":
        return "—"
    return entry.get("version", "—")


def gen_docs(root: Path) -> int:
    fragments = {p.parent.name: load_yaml(p) for p in fragment_paths(root)}
    blueprints = load_blueprints(root)
    resolved = {n: resolve_extends(n, blueprints) for n in blueprints}

    # Index deployable subcomponents so a member like observability/loki renders.
    sub_index: dict[str, dict] = {}
    for name, frag in fragments.items():
        for sub in frag.get("subcomponents", []) or []:
            if sub.get("deployable"):
                sub_index[f"{name}/{sub['name']}"] = sub

    lines: list[str] = []
    lines.append("---")
    lines.append("id: service-categories")
    lines.append('title: "Service Categories"')
    lines.append("sidebar_label: Service Categories")
    lines.append(
        "description: Generated service inventory organized by deployment "
        "blueprint. Generated from applications/blueprints and the catalog by "
        "hack/scripts/catalog.py."
    )
    lines.append("doc_type: reference")
    lines.append('audience: "platform engineers, operators, architects"')
    lines.append("tags: [catalog, services, blueprints, reference, inventory]")
    lines.append("---")
    lines.append("")
    lines.append("# openCenter-gitops-base — Service Categories")
    lines.append("")
    lines.append(
        "> **Generated file.** Produced by `hack/scripts/catalog.py docs` from "
        "`applications/blueprints/*.yaml` and the per-service `catalog.yaml` "
        "fragments. Do not edit by hand — edit the blueprints or fragments and "
        "regenerate."
    )
    lines.append("")
    lines.append(
        "Service inventory organized by deployment blueprint. Services repeat "
        "across blueprints where they serve multiple profiles."
    )
    lines.append("")

    for key, title in CATEGORY_ORDER:
        bp = resolved.get(key)
        if bp is None:
            continue
        lines.append("---")
        lines.append("")
        lines.append(f"## {title}")
        lines.append("")
        if bp.get("description"):
            lines.append(bp["description"])
            lines.append("")
        choice_members = {
            m for c in bp.get("choices", []) or [] for m in c.get("oneOf", [])
        }
        lines.append("| Service | Version | Purpose |")
        lines.append("|---------|---------|---------|")
        for member in bp.get("members", []):
            if member in choice_members:
                continue
            entry = fragments.get(member) or sub_index.get(member)
            if entry is None:
                continue
            purpose = entry.get("description", "")
            lines.append(f"| {member} | {_entry_version(entry)} | {purpose} |")
        lines.append("")
        for choice in bp.get("choices", []) or []:
            lines.append(f"**{choice.get('description', choice['name'])} (choose one):**")
            lines.append("")
            lines.append("| Service | Version | Purpose |")
            lines.append("|---------|---------|---------|")
            for member in choice.get("oneOf", []):
                entry = fragments.get(member) or sub_index.get(member)
                if entry is None:
                    continue
                purpose = entry.get("description", "")
                lines.append(f"| {member} | {_entry_version(entry)} | {purpose} |")
            lines.append("")

    text = "\n".join(lines).rstrip() + "\n"
    (root / CATEGORIES_DOC).write_text(text, encoding="utf-8")
    print(f"Wrote {CATEGORIES_DOC} from {len(resolved)} blueprints.")
    return 0


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="openCenter catalog tooling.")
    parser.add_argument("--repo-root", default=None)
    sub = parser.add_subparsers(dest="cmd", required=True)
    sub.add_parser("validate", help="JSON Schema over every fragment")
    g = sub.add_parser("generate", help="write catalog.lock.yaml")
    g.add_argument("--check", action="store_true", help="fail if stale, do not write")
    sub.add_parser("gate", help="run the four accuracy gates + blueprint gate")
    sub.add_parser("docs", help="regenerate reference/service-categories.md")
    sub.add_parser("reformat", help="rewrite every fragment through the canonical dumper")
    sub.add_parser("all", help="validate + generate --check + gate")
    args = parser.parse_args(argv)

    root = repo_root(args.repo_root)

    if args.cmd == "validate":
        res = validate_fragments(root)
        print(res.render("schema validation"))
        return 0 if res.ok else 1
    if args.cmd == "generate":
        return generate(root, check=args.check)
    if args.cmd == "gate":
        return gate(root)
    if args.cmd == "docs":
        return gen_docs(root)
    if args.cmd == "reformat":
        n = 0
        for p in fragment_paths(root):
            doc = load_yaml(p)
            p.write_text("---\n" + dump_yaml(doc), encoding="utf-8")
            n += 1
        print(f"Reformatted {n} fragments.")
        return 0
    if args.cmd == "all":
        res = validate_fragments(root)
        print(res.render("schema validation"))
        rc = 0 if res.ok else 1
        rc |= generate(root, check=True)
        rc |= gate(root)
        return rc
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
