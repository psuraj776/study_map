import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Utility class for asset-related operations
class AssetUtils {
  static const String assetsPath = 'assets';
  static const String layersPath = '$assetsPath/layers';
  static const String offlineDataPath = '$assetsPath/offline_data';
  
  // Layer file paths
  static const String indiaCompositeGeoJson = '$layersPath/india-composite.geojson';
  static const String indiaStatesGeoJson = '$layersPath/india_states.geojson';
  static const String rajasthanRiversGeoJson = '$layersPath/rajasthan_rivers.geojson';
  
  // Helper method to get state-specific river file
  static String getRiverFileForState(String stateId) {
    return '$layersPath/${stateId}_rivers.geojson';
  }
  
  // Helper method to get district/taluk file
  static String getOfflineDataFile(String regionId) {
    return '$offlineDataPath/$regionId.geojson';
  }
}

/// Copy an asset file to the app's documents directory (more persistent than temp)
Future<File> copyAssetToFile(String assetPath) async {
  try {
    final byteData = await rootBundle.load(assetPath);
    final bytes = byteData.buffer.asUint8List();
    
    // Use documents directory instead of temp for better persistence
    final appDocDir = await getApplicationDocumentsDirectory();
    final fileName = path.basename(assetPath);
    final file = File(path.join(appDocDir.path, fileName));
    
    // Create directory if it doesn't exist
    await file.parent.create(recursive: true);
    
    // Only copy if file doesn't exist or is different size
    if (!await file.exists() || await file.length() != bytes.length) {
      print('Copying asset $assetPath to ${file.path}');
      await file.writeAsBytes(bytes);
      print('Asset copied successfully. File size: ${await file.length()} bytes');
    } else {
      print('Asset already exists at ${file.path}. File size: ${await file.length()} bytes');
    }
    
    return file;
  } catch (e) {
    print('Error copying asset $assetPath: $e');
    rethrow;
  }
}

/// Check if asset exists in bundle
Future<bool> assetExists(String assetPath) async {
  try {
    await rootBundle.load(assetPath);
    return true;
  } catch (e) {
    return false;
  }
}