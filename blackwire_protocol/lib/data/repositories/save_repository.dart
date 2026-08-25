import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/game_save.dart';

/// Persists [GameSave] to a local JSON file. On web, persistence is skipped
/// gracefully (no-op) since this MVP targets desktop/mobile for saves.
class SaveRepository {
  static const _fileName = 'blackwire_save.json';

  Future<File?> _saveFile() async {
    if (kIsWeb) return null;
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<GameSave?> load() async {
    try {
      final file = await _saveFile();
      if (file == null || !await file.exists()) return null;
      final raw = await file.readAsString();
      return GameSave.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(GameSave save) async {
    try {
      final file = await _saveFile();
      if (file == null) return;
      await file.writeAsString(jsonEncode(save.toJson()));
    } catch (_) {
      // Persistence failures should never crash the game.
    }
  }

  Future<void> clear() async {
    try {
      final file = await _saveFile();
      if (file != null && await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
