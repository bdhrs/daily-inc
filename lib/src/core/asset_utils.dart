import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AssetUtils {
  static Future<List<String>> getBellSoundPaths() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final bellSoundPaths = <String>[];

      final assetPaths = manifest.listAssets();
      for (final path in assetPaths) {
        if (path.startsWith('assets/bells/') && path.endsWith('.mp3')) {
          bellSoundPaths.add(path);
        }
      }

      return bellSoundPaths..sort();
    } catch (e, stackTrace) {
      debugPrint('AssetUtils: Error loading asset manifest: $e');
      debugPrint('AssetUtils: StackTrace: $stackTrace');
      return [];
    }
  }
}
