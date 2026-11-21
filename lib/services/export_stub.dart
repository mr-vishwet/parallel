/// Web export stub: no local file target in v0.1, so saving a file is
/// unsupported and the UI falls back to clipboard copy.
bool get canSaveFile => false;

Future<String> saveExportFile(String json, String fileName) async {
  throw UnsupportedError(
    'Saving a file is not available on web in v0.1 — copy instead.',
  );
}
