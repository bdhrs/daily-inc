import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class AssetUtils {
  static Future<List<String>> getBellSoundPaths() async {
    final assetManifestString =
        await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> assetManifest = json.decode(assetManifestString);

    final bellSoundPaths = <String>[];
    for (final assetPath in assetManifest.keys) {
      if (assetPath.startsWith('assets/bells/') && assetPath.endsWith('.mp3')) {
        bellSoundPaths.add(assetPath);
      }
    }
    return bellSoundPaths;
  }
}
