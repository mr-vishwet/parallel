import 'dart:convert';

import 'package:http/http.dart' as http;

/// Client for the PARALLEL sync sketch (see `server/`).
///
/// v0.1: the client speaks the sketch's HTTP contract — health check plus
/// whole-workspace push/pull — against a base URL the user enters in
/// Settings (default: unset, sync off). There is no deployed server; the
/// stub runs locally with `dart server/sync_stub.dart`. Auth is a bearer
/// token the stub accepts as-is; real auth is a phase-2 item.
class SyncException implements Exception {
  const SyncException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SyncClient {
  SyncClient({required String baseUrl, this.token = 'local-demo-token'})
      : _base = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl;

  final String _base;
  final String token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// GET /health — true when the stub answers.
  Future<bool> checkHealth() async {
    try {
      final res = await http
          .get(Uri.parse('$_base/health'))
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// POST /v1/sync — pushes the whole workspace document.
  Future<void> pushWorkspace(Map<String, dynamic> workspaceJson) async {
    final res = await http
        .post(
          Uri.parse('$_base/v1/sync'),
          headers: _headers,
          body: jsonEncode({'workspace': workspaceJson}),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw SyncException('Sync server answered ${res.statusCode}.');
    }
  }

  /// GET /v1/sync — pulls the workspace document the server holds.
  /// Returns null when the server has nothing stored yet.
  Future<Map<String, dynamic>?> pullWorkspace() async {
    final res = await http
        .get(Uri.parse('$_base/v1/sync'), headers: _headers)
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) {
      throw SyncException('Sync server answered ${res.statusCode}.');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final workspace = body['workspace'];
    if (workspace == null) return null;
    return workspace as Map<String, dynamic>;
  }

  /// GET /v1/projects — lists the projects the server knows about.
  Future<List<Map<String, dynamic>>> listProjects() async {
    final res = await http
        .get(Uri.parse('$_base/v1/projects'), headers: _headers)
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw SyncException('Sync server answered ${res.statusCode}.');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final projects = body['projects'] as List<dynamic>? ?? [];
    return projects.map((e) => e as Map<String, dynamic>).toList();
  }
}
