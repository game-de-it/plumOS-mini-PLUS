# Frontend and emulator lifecycle

[日本語](frontend-emulators.ja.md) | [Developer guide](README.md)

The catalog is package/frontend-mini-plus/plumos/config/frontend/systems.json; runtime-coverage.json records routes. Keep common menu entries, systems, cores and launch profiles visible. Unimplemented features need explicit unsupported status and a tracked reason, not silent removal.

Launch through the FE. It must release display ownership before another renderer starts and return once the child exits. SIGSTOP alone does not release /dev/fb0 or /dev/dri/card*. Concurrent rendering risks flicker and LCD image retention.

The release gate checks both directions: every packaged core reaches a route or explicit unsupported state, and every public route resolves to a real launcher/core. Run:

```sh
sh tests/test-mini-plus-runtime-coverage.sh
python3 scripts/summarize-mini-plus-runtime-validation.py --verify
```

Text/Graphic are UI modes; Gallery is entered with X. GGFE is a separate app. [User controls](../user/emulators.md) define menu/exit behavior; [runtime limits](../validation/2026-10-31-mini-plus-runtime-limitations.md) retain untested routes.
