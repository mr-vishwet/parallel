/// PARALLEL sync sketch — a minimal in-memory server stub.
///
/// THIS IS A SKETCH, NOT A DEPLOYED BACKEND. It exists so the Flutter
/// client's sync contract (`lib/services/sync_client.dart`) has something
/// real to talk to during development, and so the API shape is nailed
/// down before any real server is built.
///
/// Run it (needs only the Dart SDK, no pub dependencies):
///
/// ```sh
/// dart server/sync_stub.dart            # listens on http://127.0.0.1:8080
/// dart server/sync_stub.dart --port 9090
/// ```
///
/// Then set the same URL in the app: Settings → Sync → Sync server URL,
/// and tap "Sync now".
///
/// What the stub does:
/// - Holds projects, branches, snapshots and events in memory (lost on
///   restart — there is no database).
/// - Enforces the append-only snapshot rule: POSTing a snapshot id that
///   already exists returns 409. History only grows, on the server too.
/// - Accepts any non-empty Bearer token. Real auth is a phase-2 item.
///
/// What it deliberately does NOT do: persistence, real auth, multi-user
/// conflict resolution, media storage, or anything production-shaped.
/// See `openapi.yaml` for the full contract and `README.md` for the
/// design notes.
library;
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  var port = 8080;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--port' && i + 1 < args.length) {
      port = int.tryParse(args[i + 1]) ?? port;
    }
  }
  final server = SyncStubServer();
  final httpServer = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  // ignore: avoid_print
  print('PARALLEL sync sketch listening on http://127.0.0.1:$port');
  // ignore: avoid_print
  print('In-memory only — everything is lost on restart.');
  await for (final request in httpServer) {
    // Errors per request must not kill the server.
    try {
      await server.handle(request);
    } catch (e) {
      try {
        request.response
          ..statusCode = HttpStatus.internalServerError
          ..write(jsonEncode({'ok': false, 'error': 'server error: $e'}));
        await request.response.close();
      } catch (_) {
        // The connection is already gone; nothing left to do.
      }
    }
  }
}

/// The in-memory sketch store + router.
class SyncStubServer {
  /// project id -> project document (same JSON shape as the app model).
  final Map<String, Map<String, dynamic>> projects = {};

  /// project id -> event list (activity feed entries).
  final Map<String, List<Map<String, dynamic>>> events = {};

  /// Whole-workspace document pushed by POST /v1/sync.
  Map<String, dynamic>? workspace;

  Future<void> handle(HttpRequest request) async {
    final response = request.response;
    _cors(response);
    if (request.method == 'OPTIONS') {
      response.statusCode = HttpStatus.noContent;
      await response.close();
      return;
    }
    final path = request.uri.path;
    try {
      if (path == '/health' && request.method == 'GET') {
        _ok(response, {
          'service': 'parallel-sync-sketch',
          'version': '0.1.0',
          'projects': projects.length,
        });
        return;
      }
      if (!_authorized(request)) {
        _error(response, HttpStatus.unauthorized,
            'Missing or empty Authorization: Bearer token.');
        return;
      }
      final segments = request.uri.pathSegments;
      if (segments.length >= 2 && segments[0] == 'v1') {
        if (segments[1] == 'sync') {
          await _handleSync(request);
          return;
        }
        if (segments[1] == 'projects') {
          await _handleProjects(request, segments.sublist(2));
          return;
        }
      }
      _error(response, HttpStatus.notFound, 'Unknown route: $path');
    } on FormatException catch (e) {
      _error(response, HttpStatus.badRequest, 'Bad JSON: ${e.message}');
    }
  }

  bool _authorized(HttpRequest request) {
    final header = request.headers.value(HttpHeaders.authorizationHeader);
    if (header == null) return false;
    if (!header.startsWith('Bearer ')) return false;
    return header.substring('Bearer '.length).trim().isNotEmpty;
  }

  void _cors(HttpResponse response) {
    response.headers.set('Access-Control-Allow-Origin', '*');
    response.headers.set(
      'Access-Control-Allow-Headers',
      'Authorization, Content-Type',
    );
    response.headers.set(
      'Access-Control-Allow-Methods',
      'GET, POST, OPTIONS',
    );
    response.headers.contentType = ContentType.json;
  }

  void _ok(HttpResponse response, Map<String, dynamic> body,
      [int status = HttpStatus.ok]) {
    response.statusCode = status;
    response.write(jsonEncode({'ok': true, ...body}));
    response.close();
  }

  void _error(HttpResponse response, int status, String message) {
    response.statusCode = status;
    response.write(jsonEncode({'ok': false, 'error': message}));
    response.close();
  }

  Future<Map<String, dynamic>> _readJson(HttpRequest request) async {
    final raw = await utf8.decoder.bind(request).join();
    if (raw.isEmpty) return {};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // ------------------------------------------------------------ /v1/sync

  Future<void> _handleSync(HttpRequest request) async {
    final response = request.response;
    if (request.method == 'GET') {
      final stored = workspace;
      if (stored == null) {
        _error(response, HttpStatus.notFound, 'No workspace stored yet.');
        return;
      }
      _ok(response, {'workspace': stored});
      return;
    }
    if (request.method == 'POST') {
      final body = await _readJson(request);
      final incoming = body['workspace'];
      if (incoming is! Map<String, dynamic>) {
        _error(response, HttpStatus.badRequest,
            'Body must be {"workspace": {...}}.');
        return;
      }
      workspace = incoming;
      // Index the pushed projects for the resource endpoints.
      final pushed = incoming['projects'] as List<dynamic>? ?? [];
      for (final p in pushed) {
        if (p is Map<String, dynamic> && p['id'] is String) {
          projects[p['id'] as String] = p;
        }
      }
      _ok(response, {
        'stored': true,
        'projects': projects.length,
      }, HttpStatus.created);
      return;
    }
    _error(response, HttpStatus.methodNotAllowed, 'Use GET or POST.');
  }

  // ------------------------------------------------------------ /v1/projects

  Future<void> _handleProjects(
    HttpRequest request,
    List<String> rest,
  ) async {
    final response = request.response;
    if (rest.isEmpty) {
      if (request.method == 'GET') {
        _ok(response, {'projects': projects.values.toList()});
        return;
      }
      if (request.method == 'POST') {
        final body = await _readJson(request);
        final id = body['id'];
        if (id is! String || id.isEmpty) {
          _error(response, HttpStatus.badRequest,
              'Project body must carry a string "id".');
          return;
        }
        projects[id] = body;
        _ok(response, {'project': body}, HttpStatus.created);
        return;
      }
      _error(response, HttpStatus.methodNotAllowed, 'Use GET or POST.');
      return;
    }

    final projectId = rest[0];
    final project = projects[projectId];
    if (project == null) {
      _error(response, HttpStatus.notFound, 'Unknown project: $projectId');
      return;
    }
    if (rest.length == 1) {
      if (request.method == 'GET') {
        _ok(response, {'project': project});
        return;
      }
      _error(response, HttpStatus.methodNotAllowed, 'Use GET.');
      return;
    }

    switch (rest[1]) {
      case 'branches':
        await _handleBranches(request, project);
      case 'snapshots':
        await _handleSnapshots(request, project);
      case 'merges':
        await _handleMerges(request, projectId);
      case 'events':
        await _handleEvents(request, projectId);
      default:
        _error(response, HttpStatus.notFound,
            'Unknown sub-resource: ${rest[1]}');
    }
  }

  Future<void> _handleBranches(
    HttpRequest request,
    Map<String, dynamic> project,
  ) async {
    final response = request.response;
    final branches = (project['branches'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    if (request.method == 'GET') {
      _ok(response, {'branches': branches});
      return;
    }
    if (request.method == 'POST') {
      final body = await _readJson(request);
      final id = body['id'];
      if (id is! String || id.isEmpty) {
        _error(response, HttpStatus.badRequest,
            'Branch body must carry a string "id".');
        return;
      }
      if (branches.any((b) => b['id'] == id)) {
        _error(response, HttpStatus.conflict, 'Branch "$id" exists.');
        return;
      }
      branches.add(body);
      project['branches'] = branches;
      _ok(response, {'branch': body}, HttpStatus.created);
      return;
    }
    _error(response, HttpStatus.methodNotAllowed, 'Use GET or POST.');
  }

  Future<void> _handleSnapshots(
    HttpRequest request,
    Map<String, dynamic> project,
  ) async {
    final response = request.response;
    final branches = (project['branches'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final branchFilter = request.uri.queryParameters['branch'];
    final since = request.uri.queryParameters['since'];
    if (request.method == 'GET') {
      final out = <Map<String, dynamic>>[];
      for (final branch in branches) {
        if (branchFilter != null && branch['id'] != branchFilter) continue;
        final snaps = (branch['snapshots'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        for (final snap in snaps) {
          if (since != null) {
            final created = snap['createdAt'] as String? ?? '';
            if (created.compareTo(since) <= 0) continue;
          }
          out.add(snap);
        }
      }
      _ok(response, {'snapshots': out});
      return;
    }
    if (request.method == 'POST') {
      final body = await _readJson(request);
      final id = body['id'];
      final branchId = body['branchId'];
      if (id is! String || id.isEmpty || branchId is! String) {
        _error(response, HttpStatus.badRequest,
            'Snapshot body must carry "id" and "branchId".');
        return;
      }
      Map<String, dynamic>? branch;
      for (final b in branches) {
        if (b['id'] == branchId) branch = b;
      }
      if (branch == null) {
        _error(response, HttpStatus.notFound, 'Unknown branch: $branchId');
        return;
      }
      final snaps = (branch['snapshots'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      if (snaps.any((s) => s['id'] == id)) {
        _error(
          response,
          HttpStatus.conflict,
          'Snapshot "$id" exists — snapshots are append-only.',
        );
        return;
      }
      // Newest first, matching the app model.
      snaps.insert(0, body);
      branch['snapshots'] = snaps;
      _ok(response, {'snapshot': body}, HttpStatus.created);
      return;
    }
    _error(response, HttpStatus.methodNotAllowed, 'Use GET or POST.');
  }

  Future<void> _handleMerges(
    HttpRequest request,
    String projectId,
  ) async {
    final response = request.response;
    if (request.method != 'POST') {
      _error(response, HttpStatus.methodNotAllowed, 'Use POST.');
      return;
    }
    final body = await _readJson(request);
    final source = body['sourceBranchId'];
    final target = body['targetBranchId'];
    final applied = body['appliedChangeIds'];
    if (source is! String || target is! String || applied is! List) {
      _error(response, HttpStatus.badRequest,
          'Merge body needs sourceBranchId, targetBranchId and '
          'appliedChangeIds.');
      return;
    }
    final mergeId = 'merge-${DateTime.now().millisecondsSinceEpoch}';
    final record = {
      'id': mergeId,
      'projectId': projectId,
      'sourceBranchId': source,
      'targetBranchId': target,
      'appliedChangeIds': applied,
      'leftBehindChangeIds': body['leftBehindChangeIds'] ?? [],
      'conflictResolutions': body['conflictResolutions'] ?? {},
      'author': body['author'] ?? 'unknown',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
    events.putIfAbsent(projectId, () => []).insert(0, {
      'id': 'ev-$mergeId',
      'kind': 'merge',
      'text': 'Merged $source into $target',
      'ref': mergeId,
      'at': record['createdAt'],
    });
    _ok(response, {'merge': record}, HttpStatus.created);
  }

  Future<void> _handleEvents(
    HttpRequest request,
    String projectId,
  ) async {
    final response = request.response;
    if (request.method != 'GET') {
      _error(response, HttpStatus.methodNotAllowed, 'Use GET.');
      return;
    }
    _ok(response, {'events': events[projectId] ?? []});
  }
}
