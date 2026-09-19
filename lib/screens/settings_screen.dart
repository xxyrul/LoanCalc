import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../i18n/app_strings.dart';
import '../models/calculator_models.dart';
import '../services/notification_service.dart';
import '../services/update_service.dart';
import '../widgets/agent_dialog.dart';
import 'updater_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String lang;
  final bool isDarkMode;
  final AgentProfile? agentProfile;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback onThemeToggled;
  final ValueChanged<AgentProfile> onAgentSaved;
  final UpdateReleaseInfo? availableUpdate;

  const SettingsScreen({
    super.key,
    required this.lang,
    required this.isDarkMode,
    required this.agentProfile,
    required this.onLanguageChanged,
    required this.onThemeToggled,
    required this.onAgentSaved,
    this.availableUpdate,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  String _currentVersion = '1.0.3';
  bool _autoCheckUpdates = true;
  bool _updateNotificationsEnabled = true;
  bool _notificationsAllowed = true;
  int _checkIntervalHours = 4;
  late AgentProfile? _agent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _agent = widget.agentProfile;
    _loadPackageInfo();
    _loadPreferences();
    _checkNotificationStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkNotificationStatus();
    }
  }

  Future<void> _checkNotificationStatus() async {
    final allowed = await NotificationService.areNotificationsEnabled();
    if (mounted) {
      setState(() {
        _notificationsAllowed = allowed;
      });
    }
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _currentVersion = info.version;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _autoCheckUpdates = prefs.getBool('auto_check_updates') ?? true;
        _updateNotificationsEnabled = prefs.getBool('update_notifications_enabled') ?? true;
        _checkIntervalHours = prefs.getInt('update_check_interval_hours') ?? 4;
      });
    }
  }

  Future<void> _setAutoCheckUpdates(bool value) async {
    HapticFeedback.selectionClick();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_check_updates', value);
    setState(() => _autoCheckUpdates = value);
    if (value && _updateNotificationsEnabled) {
      await NotificationService.scheduleBackgroundWorker(intervalHours: _checkIntervalHours);
    } else if (!value) {
      await NotificationService.cancelBackgroundWorker();
    }
  }

  Future<void> _setUpdateNotificationsEnabled(bool value) async {
    HapticFeedback.selectionClick();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('update_notifications_enabled', value);
    setState(() => _updateNotificationsEnabled = value);
    if (value && _autoCheckUpdates) {
      await NotificationService.scheduleBackgroundWorker(intervalHours: _checkIntervalHours);
    } else {
      await NotificationService.cancelBackgroundWorker();
    }
  }

  Future<void> _setCheckInterval(int hours) async {
    HapticFeedback.selectionClick();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('update_check_interval_hours', hours);
    setState(() => _checkIntervalHours = hours);
    if (_autoCheckUpdates && _updateNotificationsEnabled) {
      await NotificationService.scheduleBackgroundWorker(intervalHours: hours);
    }
  }

  Future<void> _sendTestNotification() async {
    HapticFeedback.lightImpact();
    await NotificationService.sendTestNotification(lang: widget.lang);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(AppStrings.tr('testNotificationSent', widget.lang))),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _openSystemNotificationSettings() async {
    HapticFeedback.selectionClick();
    await NotificationService.openNotificationSettings();
  }

  void _openAgentDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AgentDialog(
        lang: widget.lang,
        currentProfile: _agent ?? const AgentProfile(),
        onSaved: (updated) {
          setState(() => _agent = updated);
          widget.onAgentSaved(updated);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = widget.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.tr('settings', widget.lang),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Appearance & Language Card
          _buildCard(
            theme: theme,
            title: AppStrings.tr('appearance', widget.lang),
            icon: Icons.palette_outlined,
            children: [
              // Language Selector
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.tr('language', widget.lang),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: 'bm',
                            label: Text('🇲🇾 Bahasa Melayu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          ButtonSegment(
                            value: 'en',
                            label: Text('🇬🇧 English', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                        selected: {widget.lang},
                        onSelectionChanged: (set) => widget.onLanguageChanged(set.first),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 16),

              // Theme Switcher
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: theme.colorScheme.primary,
                ),
                title: Text(
                  AppStrings.tr('themeMode', widget.lang),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  isDark ? AppStrings.tr('darkMode', widget.lang) : AppStrings.tr('lightMode', widget.lang),
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                ),
                value: isDark,
                onChanged: (_) => widget.onThemeToggled(),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2. REN Real Estate Agent Profile Card
          _buildCard(
            theme: theme,
            title: AppStrings.tr('agentProfileSection', widget.lang),
            icon: Icons.badge_outlined,
            children: [
              if (_agent != null && _agent!.name.isNotEmpty) ...[
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(Icons.person, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _agent!.name,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          if (_agent!.renNumber.isNotEmpty)
                            Text(
                              _agent!.renNumber,
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                            ),
                          if (_agent!.agency.isNotEmpty)
                            Text(
                              _agent!.agency,
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    widget.lang == 'bm'
                        ? 'Tiada profil ejen ditetapkan. Maklumat ejen akan dimasukkan secara automatik ke dalam sebutharga WhatsApp.'
                        : 'No agent profile set. Agent details will automatically appear on shared quotations.',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _openAgentDialog,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(AppStrings.tr('editProfile', widget.lang)),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 3. Notification Settings Card
          _buildCard(
            theme: theme,
            title: AppStrings.tr('notificationSettings', widget.lang),
            icon: Icons.notifications_active_outlined,
            children: [
              // Permission Status Banner
              if (!_notificationsAllowed)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade900.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppStrings.tr('notificationsDisabled', widget.lang),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppStrings.tr('enableNotificationsPrompt', widget.lang),
                        style: TextStyle(fontSize: 11, height: 1.3, color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade800,
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _openSystemNotificationSettings,
                          icon: const Icon(Icons.settings_outlined, size: 16),
                          label: Text(
                            AppStrings.tr('openSettings', widget.lang),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppStrings.tr('notificationsEnabled', widget.lang),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: _openSystemNotificationSettings,
                        child: Text(
                          AppStrings.tr('openSettings', widget.lang),
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),

              // Switch for update push alerts
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(Icons.campaign_outlined, color: theme.colorScheme.primary),
                title: Text(
                  AppStrings.tr('notifyNewUpdates', widget.lang),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  AppStrings.tr('notifyNewUpdatesDesc', widget.lang),
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                ),
                value: _updateNotificationsEnabled,
                onChanged: _setUpdateNotificationsEnabled,
              ),

              if (_updateNotificationsEnabled) ...[
                const Divider(height: 16),
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.tr('checkFrequency', widget.lang),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<int>(
                          showSelectedIcon: false,
                          segments: [
                            ButtonSegment<int>(
                              value: 1,
                              label: Text(
                                AppStrings.tr('freq1Hour', widget.lang),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                            ButtonSegment<int>(
                              value: 4,
                              label: Text(
                                AppStrings.tr('freq4Hours', widget.lang),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                            ButtonSegment<int>(
                              value: 24,
                              label: Text(
                                AppStrings.tr('freqDaily', widget.lang),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                          selected: {_checkIntervalHours},
                          onSelectionChanged: (set) => _setCheckInterval(set.first),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 8),

              // Send Test Notification
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: _sendTestNotification,
                icon: const Icon(Icons.notifications_none_rounded, size: 18),
                label: Text(
                  AppStrings.tr('sendTestNotification', widget.lang),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 4. System & Updates Card
          _buildCard(
            theme: theme,
            title: AppStrings.tr('systemAndUpdates', widget.lang),
            icon: Icons.system_update_alt_rounded,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Badge(
                  isLabelVisible: widget.availableUpdate != null,
                  backgroundColor: theme.colorScheme.primary,
                  smallSize: 8,
                  child: Icon(Icons.cloud_download_outlined, color: theme.colorScheme.primary),
                ),
                title: Text(
                  AppStrings.tr('appUpdater', widget.lang),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  widget.availableUpdate != null
                      ? '🚀 ${widget.availableUpdate!.versionTag} ${AppStrings.tr('updateAvailable', widget.lang)}'
                      : '${AppStrings.tr('currentVersion', widget.lang)}: v$_currentVersion',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.availableUpdate != null ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    fontWeight: widget.availableUpdate != null ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => UpdaterScreen(lang: widget.lang),
                    ),
                  );
                },
              ),

              const Divider(height: 12),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  AppStrings.tr('autoCheckUpdates', widget.lang),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  AppStrings.tr('autoCheckUpdatesDesc', widget.lang),
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                ),
                value: _autoCheckUpdates,
                onChanged: _setAutoCheckUpdates,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 4. About LoanCalc Card
          _buildCard(
            theme: theme,
            title: AppStrings.tr('aboutLoanCalc', widget.lang),
            icon: Icons.info_outline_rounded,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/icon/app_logo.png',
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'LoanCalc for Android',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          'v$_currentVersion • Modern 64-bit Edition (arm64)',
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                widget.lang == 'bm'
                    ? 'Kalkulator pinjaman perumahan pintar untuk pasaran hartanah Malaysia. Mengira pinjaman bank, DSR, dan skim LPPSA.'
                    : 'Smart Malaysian property mortgage calculator engineered for real estate agents and home buyers.',
                style: TextStyle(fontSize: 12, height: 1.4, color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => launchUrl(
                  Uri.parse('https://github.com/${UpdateService.defaultRepo}'),
                  mode: LaunchMode.externalApplication,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.code_rounded, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'github.com/${UpdateService.defaultRepo}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Safe Android Gesture Bar Inset
          SizedBox(height: max(36.0, MediaQuery.of(context).padding.bottom + 28.0)),
        ],
      ),
    );
  }

  Widget _buildCard({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
