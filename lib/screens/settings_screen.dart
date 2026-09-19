import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../i18n/app_strings.dart';
import '../models/calculator_models.dart';
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

class _SettingsScreenState extends State<SettingsScreen> {
  String _currentVersion = '1.0.2';
  bool _autoCheckUpdates = true;
  late AgentProfile? _agent;

  @override
  void initState() {
    super.initState();
    _agent = widget.agentProfile;
    _loadPackageInfo();
    _loadPreferences();
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
      });
    }
  }

  Future<void> _setAutoCheckUpdates(bool value) async {
    HapticFeedback.selectionClick();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_check_updates', value);
    setState(() => _autoCheckUpdates = value);
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

          // 3. System & Updates Card
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
