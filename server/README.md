# PARALLEL sync sketch

A **sketch**, not a deployed backend. PARALLEL is the only phase-1 app with
a backend piece, and the piece is deliberately small: an API contract
(`openapi.yaml`) plus a minimal in-memory server stub (`sync_stub.dart`)
that the Flutter client can talk to during development.

## Run the stub

Needs only the Dart SDK — no pub dependencies, no database.

```sh
dart server/sync_stub.dart            # http://127.0.0.1:8080
dart server/sync_stub.dart --port 9090
```

Then in the app: Settings → Sync → enter the URL → **Sync now**. The app
pushes its whole workspace document to `POST /v1/sync` and reports the
result. With no URL set, sync is off and everything stays local.

## What the stub does

- Holds projects, branches, snapshots and events **in memory** (lost on
  restart).
- Serves the resource endpoints in `openapi.yaml`: projects, branches,
  snapshots (`?branch=` and `?since=` filters), merges, events, plus
  whole-workspace `GET`/`POST /v1/sync` (what the v0.1 client uses).
- Enforces the append-only rule: POSTing a snapshot id that already
  exists returns **409**. History only grows, on the server too.
- Accepts any non-empty `Authorization: Bearer <token>`. `/health` needs
  no auth.
- Answers CORS preflights so the web build can reach it during dev.

## What it deliberately does not do

Persistence, real auth, multi-user conflict resolution, media storage,
rate limiting, or anything production-shaped. Those are phase-2 decisions,
not v0.1 accidents.

## Design notes

- **Local-first.** The device is the source of truth; the server is a
  mirror. The client never blocks on the network — sync is a manual,
  reported action in v0.1.
- **Same JSON shape everywhere.** The wire types are the app's model
  types (`lib/engine/models.dart`) serialized as-is. The stub indexes
  pushed workspaces into its resource endpoints so both access patterns
  stay consistent.
- **Merges are plans, not acts.** The client applies a merge locally
  (engine + review state) and then records the completed plan —
  applied changes, left-behind changes, conflict resolutions — with
  `POST /v1/projects/{id}/merges`. Nothing about a merge is implicit.
- **Conflicts stay explicit.** The stub never auto-merges; conflict
  detection lives in the client's engine, and resolutions are recorded
  per change (`source` or `target`).
