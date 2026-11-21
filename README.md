# PARALLEL — Git for creative work

> **v0.1 build — Build Specification.** Branch a project, compare visually,
> merge only the changes you pick, restore any decision. Local-first; one
> Flutter codebase for iOS, Android and web.

A film is not one timeline but several: the locked cut, the warmer cut, the
quieter cut, the wild cut. PARALLEL treats a whole creative project like
code — branches you can live in, a visual diff in human language, merges
that take only what you pick, and history that only grows.

## Run it

```sh
flutter pub get
flutter run                 # phone / emulator
flutter run -d chrome       # web
flutter test                # unit tests (engine, diff, models, auth)
flutter analyze             # lint
```

Requires Dart SDK `>=3.6` and Flutter `>=3.27`.

### The sync sketch server (optional)

```sh
dart server/sync_stub.dart  # http://127.0.0.1:8080, in-memory only
```

Then set the URL in the app: Settings → Sync → Sync server URL → **Sync
now**. With no URL set, sync is off and everything stays local. See
[`server/README.md`](server/README.md) — the server is a **sketch**, not a
deployed backend.

## What is built (phase 1)

**All 60 V7 screens, as 30 adaptive routes.** Each route renders the phone
layout below 720 px and the desktop shell (sidebar + wide content) above
it, so the 30 routes cover the 30 mobile + 30 web screens from the V7
inventory. No route is a placeholder.

| # | Screen | Route |
|---|--------|-------|
| 01 | Projects | `/projects` |
| 02 | Branch map (glowing rails + snapshot stepper) | `/branch-map` |
| 03–05 | Branch detail: cinematic / minimal / experimental | `/branch` |
| 06 | New branch (name + fork-from picker) | `/new-branch` |
| 07 | Snapshots on a branch, newest first | `/snapshots` |
| 08 | Snapshot detail (message, author, time, changes) | `/snapshot` |
| 09 | Visual diff in human language | `/diff` |
| 10 | One change up close | `/change` |
| 11 | Compare any two branches | `/compare` |
| 12 | Restore one decision (scope: returns / stays changed) | `/restore` |
| 13 | Restored | `/restored` |
| 14 | Merge review | `/merge` |
| 15 | Conflict: two versions, you pick | `/conflict` |
| 16 | Merged (with what was left behind, on purpose) | `/merged` |
| 17 | Timeline: 14 scenes, last-changed marks | `/timeline` |
| 18 | Search across branches | `/search` |
| 19 | Activity feed | `/activity` |
| 20 | Settings (project, sharing, sync, danger zone) | `/settings` |
| 21 | Welcome (guest-first) | `/welcome` |
| 22 | Guest mode explainer (view-only) | `/guest` |
| 23 | Sign in | `/sign-in` |
| 24 | Create account | `/create-account` |
| 25 | Verify (6-digit code) | `/verify` |
| 26 | Upgrade prompt (guest hits a gated action) | `/upgrade` |
| 27 | Migrate (0 to move — guests create nothing) | `/migrate` |
| 28 | Account home | `/account` |
| 29 | Connected accounts | `/connected` |
| 30 | Data controls (sign out / export / delete) | `/data-controls` |

**The engine is real.** `lib/engine/branch_engine.dart` is pure Dart (no
I/O, fully tested): branching (pointer, not data copy), snapshot id
allocation, diffing with conflict detection (same scene + same kind after
the fork), merge planning (only picked changes travel; conflicts must be
resolved — the app never guesses), restore (appends a new snapshot;
nothing is rewritten), search, and per-scene last-changed computation.

**Auth model (from the V7 spec).** PARALLEL needs login for its core:
guests browse the demo read-only; branching, merging, restoring,
snapshotting and creating route guests to the upgrade prompt. Accounts
are local-only in v0.1 (SHA-256 hashed passwords in on-device storage;
the verification code is a local demo code shown on the verify screen,
clearly labelled — no email is sent yet). Apple/Google sign-in buttons
explain they are not connected yet instead of pretending.

**Persistence.** The whole workspace is one JSON document in
`shared_preferences` (local-first). Export copies it to the clipboard, or
saves a file on native platforms. Settings → Danger zone can reset the
workspace to the seeded demo.

**Demo data (seeded, labelled as demo).** Harbour Light — a 3:48 short
film, 14 scenes, 4 branches (main 9, cinematic 4, minimal 3, experimental
5 = 21 snapshots), the cinematic→main merge in review with its 1 conflict
(the opening shot). Plus Launch Teaser (2 branches, 8 snapshots) and Field
Notes (1 branch, 5 snapshots): 3 projects, 7 branches, 34 snapshots.
Demo timestamps are relative to first launch so "Today 09:41" stays true.

## Project layout

```
lib/
  main.dart                entry point
  app.dart                 shell: controller, theme, 30 routes
  core/                    theme, constants, format, routes
  engine/                  models, branch/diff/merge engine, demo seed
  services/                local store, auth, sync client, export
  state/                   AppController (ChangeNotifier) + AppScope
  screens/                 the 30 screens
  widgets/                 adaptive shell, branch map, rows, logo
test/                      engine, diff, models, demo data, auth
web/                       index.html, manifest.json
assets/logos/              the 4 PARALLEL logo SVGs
server/                    sync sketch: stub + OpenAPI contract + docs
```

## Honest limits (v0.1)

- **No real backend.** Accounts, data and sync are local-only; the server
  is an in-memory sketch. Nothing is deployed.
- **No social sign-in, no email.** Apple/Google buttons say so; the
  verify code is a local demo code.
- **No video playback.** "Watch" actions open the timeline / branch
  instead. Frame art on diff and snapshot screens is illustrative art
  drawn in code, not stills — real frame thumbnails arrive with the
  media pipeline.
- **Single light theme.** The V7 palette is the one theme, structured
  (`ParallelPalette` tokens) so phase 2 can add a dark variant. No
  dual-theme system is built yet.
- **Storage figures are demo figures.** "2.1 GB on this device" describes
  the seeded demo workspace, not a measurement.
- **The V7 deck's scene marks were illustrative.** The timeline computes
  last-changed-per-scene from real snapshot history, so a few marks differ
  from the deck's frozen map (e.g. scene 4, changed most recently on main
  by m6). The engine is the source of truth.
- **Merge runtime is computed from selected changes.** The deck's merged
  screen says main runs 4:02; the engine lands it at 3:50 with the 3
  canonical selections (opening +2s) and 4:02 only when the runtime change
  is also selected. Computed, not asserted.

## Phase 2 (not built)

- Dual dark/light themes (palette tokens are ready for the swap).
- Real backend + auth (email verification, Apple/Google, multi-device
  sync with conflict resolution) — the sketch contract in `server/` is
  the starting point.
- Media pipeline: real frame thumbnails, in-app playback, EDL/XML export.
- Drift/SQLite if the workspace document outgrows a single JSON doc.
- Per-object merge (the catalog's per-object granularity) beyond the
  current per-change granularity.
- CI: see the appendix — the workflow YAML is included here for adding
  via the GitHub web UI (the app token cannot push workflow files).

## Appendix — CI workflow (add via the GitHub web UI)

Save this as `.github/workflows/flutter.yml` in the repo (web UI → Add
file → Create new file). It is not in the repo itself because the GitHub
App token used for pushes cannot write workflow files.

```yaml
name: Flutter

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.27.0'
          channel: stable
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
      - run: flutter build web --release
```
