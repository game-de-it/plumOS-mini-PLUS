# Libretro cores and catalog

[日本語](libretro-cores.ja.md) | [Developer guide](README.md)

The package tracks 114 libretro cores. Catalog scope (97 entries / 196 routes) differs from the generated user table's 88 supported systems: do not infer missing packages from those different counts.

Keep package/frontend-mini-plus/plumos/config/frontend/systems.json, runtime-coverage.json and configs/mini-plus-runtime-validation.json consistent. Regenerate user tables after catalog changes:

```sh
python3 scripts/generate-mini-plus-supported-systems-doc.py
python3 scripts/generate-mini-plus-supported-systems-doc.py --check
python3 scripts/summarize-mini-plus-runtime-validation.py --verify
```

A packaged core may need BIOS, a specific content format or another renderer. Missing content is a validation limit, not automatically unsupported hardware. Preserve explicit unsupported entries such as 3DS rather than silently pruning the catalog. Review [frontend routing](frontend-emulators.md) and [limits](../validation/2026-10-31-mini-plus-runtime-limitations.md).
