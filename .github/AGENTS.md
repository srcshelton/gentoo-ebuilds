# GitHub Actions and repository checks

- Keep workflow YAML declarative; put reusable, deterministic checks and focused tests in `.github/scripts/` rather than duplicating inline logic.
- Derive patch layout, references, pinned versions and documentation checks from actual ebuilds, files and Manifest. Use tests to enforce machine-checkable rules rather than repeating them in agent instructions.
- Preserve source-specific patch application semantics: Gentoo and vendor rules remain distinct from strict maintained-patch qualification. Never hide, skip or downgrade a genuine failure.
- Run lightweight validation on relevant push and pull-request changes, including documentation-only changes; avoid triggering expensive kernel builds for documentation alone. Keep workflow permissions minimal and external inputs explicitly pinned or validated.
- Report actionable diagnostics and rely on source, tests and CI logs for reproducible evidence. Do not generate redundant validation reports or update documentation by guessing at semantic changes.
