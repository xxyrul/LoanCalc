import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateReleaseInfo {
  final String versionTag;
  final String cleanVersion;
  final String title;
  final String changelog;
  final String downloadUrl;
  final int fileSizeBytes;
  final String fileName;
  final DateTime? publishedAt;

  const UpdateReleaseInfo({
    required this.versionTag,
    required this.cleanVersion,
    required this.title,
    required this.changelog,
    required this.downloadUrl,
    required this.fileSizeBytes,
    required this.fileName,
    this.publishedAt,
  });
}

class UpdateService {
  static const String defaultRepo = 'xxyrul/LoanCalc';
  static const String prefRepoKey = 'github_update_repo';

  static Future<String> getTargetRepo() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(prefRepoKey);
    if (saved == null || saved.contains('norazrul7/')) {
      await prefs.setString(prefRepoKey, defaultRepo);
      return defaultRepo;
    }
    return saved;
  }

  static Future<void> setTargetRepo(String repo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefRepoKey, repo.trim());
  }

  /// Compares semantic version strings (e.g. "1.1.0" > "1.0.0").
  static bool isNewerVersion(String currentVer, String latestTag) {
    try {
      final curParts = currentVer.replaceAll(RegExp(r'[^0-9.]'), '').split('.');
      final latParts = latestTag.replaceAll(RegExp(r'[^0-9.]'), '').split('.');

      for (int i = 0; i < 3; i++) {
        final cur = i < curParts.length ? int.tryParse(curParts[i]) ?? 0 : 0;
        final lat = i < latParts.length ? int.tryParse(latParts[i]) ?? 0 : 0;
        if (lat > cur) return true;
        if (lat < cur) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Checks GitHub Releases API for the latest available release.
  static Future<UpdateReleaseInfo?> checkForUpdate({String? customRepo}) async {
    try {
      final repo = customRepo ?? await getTargetRepo();
      if (repo.isEmpty) return null;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final url = Uri.parse('https://api.github.com/repos/$repo/releases/latest');
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'LoanCalc-App-Updater',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = (data['tag_name'] ?? '') as String;
      final cleanVersion = tagName.replaceAll(RegExp(r'^[vV]'), '');

      // Check if release is strictly newer
      if (!isNewerVersion(currentVersion, cleanVersion)) {
        return null;
      }

      // Find APK asset
      final assets = (data['assets'] as List<dynamic>?) ?? [];
      Map<String, dynamic>? apkAsset;

      for (final a in assets) {
        final name = (a['name'] ?? '').toString().toLowerCase();
        if (name.endsWith('.apk')) {
          apkAsset = a as Map<String, dynamic>;
          break;
        }
      }

      if (apkAsset == null) {
        return null;
      }

      final downloadUrl = (apkAsset['browser_download_url'] ?? '').toString();
      final size = (apkAsset['size'] ?? 0) as int;
      final fileName = (apkAsset['name'] ?? 'LoanCalc.apk').toString();
      final title = (data['name'] ?? 'Version $cleanVersion').toString();
      final body = (data['body'] ?? '').toString();
      DateTime? published;
      if (data['published_at'] != null) {
        published = DateTime.tryParse(data['published_at'].toString());
      }

      return UpdateReleaseInfo(
        versionTag: tagName,
        cleanVersion: cleanVersion,
        title: title,
        changelog: body.isNotEmpty ? body : '• Bug fixes, interest rate adjustments, and general enhancements.',
        downloadUrl: downloadUrl,
        fileSizeBytes: size,
        fileName: fileName,
        publishedAt: published,
      );
    } catch (e) {
      debugPrint('UpdateService check error: $e');
      return null;
    }
  }

  /// Downloads the APK and returns the local File path.
  static Future<File?> downloadApk({
    required String downloadUrl,
    required String fileName,
    required void Function(double progress, int receivedBytes, int totalBytes) onProgress,
  }) async {
    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(downloadUrl));
      request.headers['User-Agent'] = 'LoanCalc-App-Updater';

      final response = await client.send(request);
      final totalBytes = response.contentLength ?? 0;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');

      if (await file.exists()) {
        await file.delete();
      }

      final sink = file.openWrite();
      int receivedBytes = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          onProgress(receivedBytes / totalBytes, receivedBytes, totalBytes);
        } else {
          onProgress(0.5, receivedBytes, 0);
        }
      }

      await sink.flush();
      await sink.close();
      client.close();

      return file;
    } catch (e) {
      debugPrint('UpdateService download error: $e');
      return null;
    }
  }

  /// Triggers Android's PackageInstaller to install the downloaded APK.
  static Future<OpenResult> installApk(File apkFile) async {
    return await OpenFilex.open(
      apkFile.path,
      type: 'application/vnd.android.package-archive',
    );
  }
}
