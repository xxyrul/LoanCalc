import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calculator_models.dart';
import '../i18n/app_strings.dart';
import '../screens/updater_screen.dart';

class AgentDialog extends StatefulWidget {
  final String lang;
  final AgentProfile currentProfile;
  final ValueChanged<AgentProfile> onSaved;

  const AgentDialog({
    super.key,
    required this.lang,
    required this.currentProfile,
    required this.onSaved,
  });

  @override
  State<AgentDialog> createState() => _AgentDialogState();
}

class _AgentDialogState extends State<AgentDialog> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _agencyController;
  late TextEditingController _renController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentProfile.name);
    _phoneController = TextEditingController(text: widget.currentProfile.phone);
    _agencyController = TextEditingController(text: widget.currentProfile.agency);
    _renController = TextEditingController(text: widget.currentProfile.renNumber);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _agencyController.dispose();
    _renController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final updated = AgentProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      agency: _agencyController.text.trim(),
      renNumber: _renController.text.trim(),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('agent_profile', jsonEncode(updated.toJson()));

    widget.onSaved(updated);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Icon(Icons.badge_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            AppStrings.tr('agentSettings', widget.lang),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: AppStrings.tr('agentName', widget.lang),
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: AppStrings.tr('agentPhone', widget.lang),
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                hintText: '012-345 6789',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _agencyController,
              decoration: InputDecoration(
                labelText: AppStrings.tr('agentAgency', widget.lang),
                prefixIcon: const Icon(Icons.business_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _renController,
              decoration: InputDecoration(
                labelText: AppStrings.tr('agentRen', widget.lang),
                prefixIcon: const Icon(Icons.confirmation_number_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                hintText: 'REN 12345',
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => UpdaterScreen(lang: widget.lang),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    Icon(Icons.system_update_alt_rounded, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppStrings.tr('appUpdater', widget.lang),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.tr('close', widget.lang)),
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.check, size: 18),
          label: Text(AppStrings.tr('save', widget.lang)),
        ),
      ],
    );
  }
}
