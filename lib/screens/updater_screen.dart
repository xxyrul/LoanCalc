import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../i18n/app_strings.dart';
import '../services/update_service.dart';

enum UpdaterStatus {
  idle,
  checking,
  upToDate,
  updateAvailable,
  downloading,
  downloaded,
  error,
}

class UpdaterScreen extends StatefulWidget {
  final String lang;

  const UpdaterScreen({
    super.key,
    required this.lang,
  });

  @override
  State<UpdaterScreen> createState() => _UpdaterScreenState();
}

class _UpdaterScreenState extends State<UpdaterScreen> {
  String _currentVersion = '1.0.0';
  String _currentBuildNumber = '1';

  UpdaterStatus _status = UpdaterStatus.idle;
  UpdateReleaseInfo? _updateInfo;
  double _downloadProgress = 0.0;
  double _downloadedMb = 0.0;
  double _totalMb = 0.0;
  File? _downloadedFile;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _currentVersion = info.version;
          _currentBuildNumber = info.buildNumber;
        });
      }
    } catch (_) {}
  }

  Future<void> _checkForUpdates() async {
    HapticFeedback.lightImpact();
    setState(() {
      _status = UpdaterStatus.checking;
      _errorMessage = null;
    });

    try {
      final info = await UpdateService.checkForUpdate();
      if (!mounted) return;

      if (info != null) {
        setState(() {
          _status = UpdaterStatus.updateAvailable;
          _updateInfo = info;
        });
      } else {
        setState(() {
          _status = UpdaterStatus.upToDate;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = UpdaterStatus.error;
        _errorMessage = 'Could not retrieve releases from GitHub: $e';
      });
    }
  }

  Future<void> _startDownload() async {
    if (_updateInfo == null) return;
    HapticFeedback.selectionClick();

    setState(() {
      _status = UpdaterStatus.downloading;
      _downloadProgress = 0.0;
      _downloadedMb = 0.0;
      _totalMb = _updateInfo!.fileSizeBytes > 0
          ? _updateInfo!.fileSizeBytes / (1024 * 1024)
          : 0.0;
    });

    try {
      final file = await UpdateService.downloadApk(
        downloadUrl: _updateInfo!.downloadUrl,
        fileName: _updateInfo!.fileName,
        onProgress: (progress, received, total) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
              _downloadedMb = received / (1024 * 1024);
              if (total > 0) {
                _totalMb = total / (1024 * 1024);
              }
            });
          }
        },
      );

      if (!mounted) return;

      if (file != null) {
        setState(() {
          _status = UpdaterStatus.downloaded;
          _downloadedFile = file;
        });
        _installApk();
      } else {
        setState(() {
          _status = UpdaterStatus.error;
          _errorMessage = 'Download failed. Please check internet connection.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = UpdaterStatus.error;
        _errorMessage = 'Download error: $e';
      });
    }
  }

  Future<void> _installApk() async {
    if (_downloadedFile == null) return;
    HapticFeedback.heavyImpact();
    try {
      await UpdateService.installApk(_downloadedFile!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Installation prompt error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.tr('appUpdater', widget.lang),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Current App Version Card
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        'assets/icon/app_logo.png',
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'LoanCalc for Android',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${AppStrings.tr('currentVersion', widget.lang)}: v$_currentVersion (Build $_currentBuildNumber)',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Standalone APK Edition',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 2. Official Update Channel Badge (Locked & Read-only)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.security_update_good_rounded, size: 20, color: theme.colorScheme.onPrimaryContainer),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.tr('githubRepo', widget.lang),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            UpdateService.defaultRepo,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 12,
                            color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF14532D),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Official',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF14532D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 3. Status & Action Section
            _buildStatusCard(theme, isDark),

            const SizedBox(height: 16),

            // 4. Primary Action Button
            if (_status == UpdaterStatus.idle || _status == UpdaterStatus.upToDate || _status == UpdaterStatus.error)
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _checkForUpdates,
                icon: const Icon(Icons.sync_rounded),
                label: Text(
                  AppStrings.tr('checkForUpdates', widget.lang),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

            if (_status == UpdaterStatus.updateAvailable)
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _startDownload,
                icon: const Icon(Icons.download_rounded),
                label: Text(
                  AppStrings.tr('downloadAndUpdate', widget.lang),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

            if (_status == UpdaterStatus.downloaded)
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _installApk,
                icon: const Icon(Icons.install_mobile_rounded),
                label: Text(
                  AppStrings.tr('installNow', widget.lang),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

            const SizedBox(height: 20),

            // 5. Release Instructions Info Card
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        const Text(
                          'How GitHub Releases Work',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Bump version in code (e.g. 1.1.0).\n'
                      '2. Build release APK with "flutter build apk --release".\n'
                      '3. On GitHub, create a release tagged "v1.1.0" and attach "LoanCalc.apk".\n'
                      '4. Users open this page and tap "Check for Updates" to install automatically.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme, bool isDark) {
    switch (_status) {
      case UpdaterStatus.idle:
        return const SizedBox.shrink();

      case UpdaterStatus.checking:
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  AppStrings.tr('checkingUpdates', widget.lang),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );

      case UpdaterStatus.upToDate:
        final bg = isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFDCFCE7);
        final border = isDark ? const Color(0xFF059669).withValues(alpha: 0.6) : const Color(0xFF86EFAC);
        final fg = isDark ? const Color(0xFF86EFAC) : const Color(0xFF14532D);
        final detail = isDark ? const Color(0xFFBBF7D0) : const Color(0xFF166534);

        return Card(
          elevation: 1,
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: border, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: fg, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppStrings.tr('upToDate', widget.lang),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: fg,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.tr('upToDateDesc', widget.lang),
                  style: TextStyle(
                    fontSize: 13,
                    color: detail,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );

      case UpdaterStatus.updateAvailable:
        final info = _updateInfo!;
        return Card(
          elevation: 2,
          color: theme.colorScheme.primaryContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.new_releases_rounded, color: theme.colorScheme.primary, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.tr('updateAvailable', widget.lang),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        info.versionTag,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  info.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                if (info.fileSizeBytes > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Package Size: ${(info.fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
                ],
                const Divider(height: 20),
                Text(
                  AppStrings.tr('changelog', widget.lang),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    info.changelog,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

      case UpdaterStatus.downloading:
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.tr('downloading', widget.lang),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _downloadProgress > 0 ? _downloadProgress : null,
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_downloadedMb.toStringAsFixed(1)} MB / ${_totalMb > 0 ? '${_totalMb.toStringAsFixed(1)} MB' : '...'}',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const Text('Streaming APK...', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        );

      case UpdaterStatus.downloaded:
        return Card(
          elevation: 1,
          color: const Color(0xFFDCFCE7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFF86EFAC), width: 1.5),
          ),
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF15803D), size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Download Complete!',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF14532D),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tap "Install Now" to upgrade the app.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF166534)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

      case UpdaterStatus.error:
        final bg = isDark ? const Color(0xFF450A0A).withValues(alpha: 0.4) : const Color(0xFFFEE2E2);
        final border = isDark ? const Color(0xFFDC2626).withValues(alpha: 0.6) : const Color(0xFFFECACA);
        final fg = isDark ? const Color(0xFFFCA5A5) : const Color(0xFF7F1D1D);
        final detail = isDark ? const Color(0xFFFECDD3) : const Color(0xFF991B1B);

        return Card(
          elevation: 1,
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: border, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: fg, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Update Check Notice',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: fg),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _errorMessage ?? 'No releases found on GitHub repository.',
                  style: TextStyle(fontSize: 12, color: detail, height: 1.4),
                ),
              ],
            ),
          ),
        );
    }
  }
}
