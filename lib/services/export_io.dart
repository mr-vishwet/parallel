import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Native file export: writes into the app documents directory.
bool get canSaveFile => true;

/// Saves the export JSON to a file and returns its path.
Future<String> saveExportFile(String json, String fileName) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsString(json);
  return file.path;
}
