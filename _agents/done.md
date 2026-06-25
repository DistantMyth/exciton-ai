# done.md — changelog of completed work

> Append a one-line summary when you move a task from BACKLOG to done. Newest at top.
> Format: `YYYY-MM-DD task-id — one-line summary — @handle — (PR #/commit)`

---

- 2026-06-24 CONTRACT-002 — plasma-dbus.xml finalized (org.kde.PlasmaShell.Introspect: listContainments/appletInfo/appletActions/appletCapabilities/appletDescribe/appletTransform/globalCapabilities; JSON error model; depth enum) — @anuj — (PR #5)
- 2026-06-24 CONTRACT-006 — capability-registry.schema.json finalized (root JSON-Schema draft 2020-12; cap:/act: stable ids; appletActions↔get_actions alignment) — @anuj — (PR #5)
- 2026-06-24 CONTRACT-001 v0.2.0 — amended grammar to add `cap:` type + two-form `act:`; reconciled with CONTRACT-006 — @tarun — (PR #5, ADR-0003)
- 2026-06-24 ADR-0003 — element-ID grammar: add `cap:` type + clarify two-form `act:` — @tarun
- 2026-06-21 ADR-0002 — moved coordination hub out of Exciton into separate exciton-ai repo; Exciton reverted to clean plasma-desktop fork — @tarun
