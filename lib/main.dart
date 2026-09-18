import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/calculator_models.dart';
import 'i18n/app_strings.dart';
import 'screens/mortgage_tab.dart';
import 'screens/dsr_tab.dart';
import 'screens/lppsa_tab.dart';
import 'screens/updater_screen.dart';
import 'widgets/agent_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LoanCalcApp());
}

class LoanCalcApp extends StatefulWidget {
  const LoanCalcApp({super.key});

  @override
  State<LoanCalcApp> createState() => _LoanCalcAppState();
}

class _LoanCalcAppState extends State<LoanCalcApp> {
  ThemeMode _themeMode = ThemeMode.system;
  String _lang = 'bm';
  AgentProfile _agentProfile = const AgentProfile();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('app_language');
    final savedAgent = prefs.getString('agent_profile');
    final savedTheme = prefs.getString('app_theme');

    setState(() {
      if (savedLang != null) _lang = savedLang;
      if (savedAgent != null) {
        try {
          _agentProfile = AgentProfile.fromJson(jsonDecode(savedAgent));
        } catch (_) {}
      }
      if (savedTheme == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (savedTheme == 'light') {
        _themeMode = ThemeMode.light;
      }
    });
  }

  Future<void> _setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', lang);
    setState(() => _lang = lang);
  }

  Future<void> _toggleTheme() async {
    final newMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme', newMode == ThemeMode.dark ? 'dark' : 'light');
    setState(() => _themeMode = newMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LoanCalc',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFE11D48), // Ruby Red
        brightness: Brightness.light,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFE11D48),
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
      ),
      home: MainHomeScreen(
        lang: _lang,
        agentProfile: _agentProfile,
        onLanguageChanged: _setLanguage,
        onThemeToggled: _toggleTheme,
        isDarkMode: _themeMode == ThemeMode.dark,
        onAgentSaved: (profile) => setState(() => _agentProfile = profile),
      ),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  final String lang;
  final AgentProfile agentProfile;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback onThemeToggled;
  final bool isDarkMode;
  final ValueChanged<AgentProfile> onAgentSaved;

  const MainHomeScreen({
    super.key,
    required this.lang,
    required this.agentProfile,
    required this.onLanguageChanged,
    required this.onThemeToggled,
    required this.isDarkMode,
    required this.onAgentSaved,
  });

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openAgentDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AgentDialog(
        lang: widget.lang,
        currentProfile: widget.agentProfile,
        onSaved: widget.onAgentSaved,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = widget.isDarkMode;
    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: theme.colorScheme.surface,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          appBar: AppBar(
            elevation: 1.5,
            scrolledUnderElevation: 3,
            backgroundColor: theme.colorScheme.surface,
            surfaceTintColor: theme.colorScheme.surfaceTint,
            titleSpacing: 16,
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/icon/app_logo.png',
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 9),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Loan',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 19,
                        letterSpacing: -0.5,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Calc',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 19,
                        letterSpacing: -0.5,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              // Language Switcher Menu
              PopupMenuButton<String>(
                tooltip: 'Change Language',
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.language, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      widget.lang == 'zh' ? 'CN' : widget.lang.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
                onSelected: widget.onLanguageChanged,
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'bm', child: Text('🇲🇾 Bahasa Melayu (BM)')),
                  const PopupMenuItem(value: 'en', child: Text('🇬🇧 English (EN)')),
                  const PopupMenuItem(value: 'zh', child: Text('🇨🇳 中文 (CN)')),
                ],
              ),

              // Agent Profile Button
              IconButton(
                tooltip: AppStrings.tr('agentSettings', widget.lang),
                icon: const Icon(Icons.badge_outlined),
                onPressed: _openAgentDialog,
              ),

              // In-App Updater Page Button
              IconButton(
                tooltip: AppStrings.tr('appUpdater', widget.lang),
                icon: const Icon(Icons.system_update_alt_rounded),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => UpdaterScreen(lang: widget.lang),
                    ),
                  );
                },
              ),

              // Theme Toggle Button
              IconButton(
                tooltip: 'Toggle Dark/Light Mode',
                icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode_outlined),
                onPressed: widget.onThemeToggled,
              ),
            ],
            bottom: TabBar(
              onTap: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              controller: _tabController,
              labelPadding: const EdgeInsets.symmetric(horizontal: 2),
              dividerColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              dividerHeight: 1,
              indicatorColor: theme.colorScheme.primary,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              tabs: [
                Tab(
                  icon: const Icon(Icons.home_work_outlined, size: 18),
                  text: AppStrings.tr('tabMortgage', widget.lang),
                ),
                Tab(
                  icon: const Icon(Icons.speed_outlined, size: 18),
                  text: AppStrings.tr('tabDsr', widget.lang),
                ),
                Tab(
                  icon: const Icon(Icons.account_balance_outlined, size: 18),
                  text: AppStrings.tr('tabLppsa', widget.lang),
                ),
              ],
            ),
          ),
          body: SafeArea(
            bottom: true,
            child: TabBarView(
              controller: _tabController,
              children: [
                MortgageTab(lang: widget.lang, agentProfile: widget.agentProfile),
                DsrTab(lang: widget.lang, agentProfile: widget.agentProfile),
                LppsaTab(lang: widget.lang, agentProfile: widget.agentProfile),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
