# Kernel patch integration and qualification

- Treat each supported kernel version and relevant USE-flag combination as a separate integration target; the ebuild defines the effective patch order.
- Apply inherited Gentoo genpatches using `kernel-2` semantics and vendor patches using their established rules. Require zero fuzz, zero offsets, no silent skips, and checked postimages for maintained patches.
- Keep byte-identical patches used by both kernel lines directly under `files/`; put line-specific variants under `files/<major>.<minor>.x/`, never patchlevel directories. Name a new patch `<number>-<description>.patch`; add the *first affected kernel version* only when a replacement must coexist with an older variant in the same line. Name profile-specific variants explicitly.
- Run the repository's patch-layout/documentation checks after relevant changes; update ebuild references, Manifest and patch descriptions together. Preserve patch order and resulting source when moving files or refreshing context.
- Validate substantive patch changes against the complete ordered stack with existing deterministic replay, regression and targeted build checks. Reuse applicable evidence; do not create parallel qualification mechanisms.
- Distinguish static checks, host tests, native compilation and target-hardware qualification. Retain only irreproducible observations and essential decisions; avoid redundant investigation reports or handoff documents.
