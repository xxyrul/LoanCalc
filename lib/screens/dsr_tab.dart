import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/calculator_models.dart';
import '../utils/calculator_engine.dart';
import '../utils/currency_formatter.dart';
import '../utils/share_service.dart';
import '../i18n/app_strings.dart';

class DsrTab extends StatefulWidget {
  final String lang;
  final AgentProfile? agentProfile;

  const DsrTab({
    super.key,
    required this.lang,
    this.agentProfile,
  });

  @override
  State<DsrTab> createState() => _DsrTabState();
}

class _DsrTabState extends State<DsrTab> {
  final _curr = NumberFormat('#,##0', 'en_US');

  final _incomeController = TextEditingController(text: '6,000');
  final _carController = TextEditingController(text: '600');
  final _housingController = TextEditingController(text: '1,200');
  final _creditCardController = TextEditingController(text: '150');
  final _personalLoanController = TextEditingController(text: '0');
  final _ptptnController = TextEditingController(text: '150');

  double _income = 6000;
  double _car = 600;
  double _housing = 1200;
  double _creditCard = 150;
  double _personal = 0;
  double _ptptn = 150;

  double _dsrLimitPercent = 70;

  @override
  void initState() {
    super.initState();
    _incomeController.addListener(() => _updateNum(_incomeController, (v) => _income = v));
    _carController.addListener(() => _updateNum(_carController, (v) => _car = v));
    _housingController.addListener(() => _updateNum(_housingController, (v) => _housing = v));
    _creditCardController.addListener(() => _updateNum(_creditCardController, (v) => _creditCard = v));
    _personalLoanController.addListener(() => _updateNum(_personalLoanController, (v) => _personal = v));
    _ptptnController.addListener(() => _updateNum(_ptptnController, (v) => _ptptn = v));
  }

  void _updateNum(TextEditingController ctrl, void Function(double) setter) {
    final clean = ctrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final val = double.tryParse(clean) ?? 0;
    setState(() => setter(val));
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _carController.dispose();
    _housingController.dispose();
    _creditCardController.dispose();
    _personalLoanController.dispose();
    _ptptnController.dispose();
    super.dispose();
  }

  DsrResult get _result => CalculatorEngine.calculateDsr(
        averageIncome: _income,
        dsrLimitPercent: _dsrLimitPercent,
        carLoan: _car,
        housingLoan: _housing,
        creditCard: _creditCard,
        personalLoan: _personal,
        ptptnOther: _ptptn,
      );

  String _fmt(double val) => 'RM ${_curr.format(val.round())}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final res = _result;

    final isDark = theme.brightness == Brightness.dark;

    Color bgContainerColor;
    Color borderStrokeColor;
    Color statusTextColor;
    Color statusDetailColor;
    Color percentageColor;
    String statusText;
    IconData statusIcon;

    switch (res.status) {
      case DsrStatus.healthy:
        bgContainerColor = isDark
            ? const Color(0xFF064E3B).withValues(alpha: 0.4)
            : const Color(0xFFDCFCE7);
        borderStrokeColor = isDark
            ? const Color(0xFF059669).withValues(alpha: 0.6)
            : const Color(0xFF86EFAC);
        statusTextColor = isDark
            ? const Color(0xFF86EFAC)
            : const Color(0xFF14532D);
        statusDetailColor = isDark
            ? const Color(0xFFBBF7D0)
            : const Color(0xFF166534);
        percentageColor = isDark
            ? const Color(0xFF4ADE80)
            : const Color(0xFF15803D);
        statusText = AppStrings.tr('statusHealthy', widget.lang);
        statusIcon = Icons.check_circle_rounded;
        break;
      case DsrStatus.moderate:
        bgContainerColor = isDark
            ? const Color(0xFF451A03).withValues(alpha: 0.4)
            : const Color(0xFFFEF3C7);
        borderStrokeColor = isDark
            ? const Color(0xFFD97706).withValues(alpha: 0.6)
            : const Color(0xFFFDE68A);
        statusTextColor = isDark
            ? const Color(0xFFFDE047)
            : const Color(0xFF78350F);
        statusDetailColor = isDark
            ? const Color(0xFFFEF08A)
            : const Color(0xFF92400E);
        percentageColor = isDark
            ? const Color(0xFFFBBF24)
            : const Color(0xFFB45309);
        statusText = AppStrings.tr('statusModerate', widget.lang);
        statusIcon = Icons.info_rounded;
        break;
      case DsrStatus.critical:
        bgContainerColor = isDark
            ? const Color(0xFF450A0A).withValues(alpha: 0.4)
            : const Color(0xFFFEE2E2);
        borderStrokeColor = isDark
            ? const Color(0xFFDC2626).withValues(alpha: 0.6)
            : const Color(0xFFFECACA);
        statusTextColor = isDark
            ? const Color(0xFFFCA5A5)
            : const Color(0xFF7F1D1D);
        statusDetailColor = isDark
            ? const Color(0xFFFECDD3)
            : const Color(0xFF991B1B);
        percentageColor = isDark
            ? const Color(0xFFF87171)
            : const Color(0xFFB91C1C);
        statusText = AppStrings.tr('statusCritical', widget.lang);
        statusIcon = Icons.warning_rounded;
        break;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Income Card
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.tr('income', widget.lang),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _incomeController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [ThousandsSeparatorInputFormatter()],
                      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        prefixText: 'RM ',
                        prefixStyle: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 2. Commitments Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.tr('commitments', widget.lang),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _commitmentField(AppStrings.tr('carLoan', widget.lang), _carController),
                    _commitmentField(AppStrings.tr('housingLoan', widget.lang), _housingController),
                    _commitmentField(AppStrings.tr('creditCard', widget.lang), _creditCardController),
                    _commitmentField(AppStrings.tr('personalLoan', widget.lang), _personalLoanController),
                    _commitmentField(AppStrings.tr('ptptn', widget.lang), _ptptnController),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.tr('totalCommitments', widget.lang),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _fmt(res.totalCommitments),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 3. Bank DSR Limit Selector
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.tr('dsrLimit', widget.lang),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_dsrLimitPercent.toInt()}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      AppStrings.tr('bankPresets', widget.lang),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _bankChip('Maybank', 70),
                        _bankChip('CIMB', 60),
                        _bankChip('Public Bank', 65),
                        _bankChip('RHB', 75),
                        _bankChip('Hong Leong', 70),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Slider(
                      value: _dsrLimitPercent,
                      min: 50,
                      max: 85,
                      divisions: 7,
                      label: '${_dsrLimitPercent.toInt()}%',
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        setState(() => _dsrLimitPercent = val);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 4. DSR Gauge & Health Card (High Contrast)
            Card(
              elevation: 2,
              color: bgContainerColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: borderStrokeColor, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(statusIcon, color: percentageColor, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.tr('currentDsr', widget.lang),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: statusTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${res.currentDsrPercent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: percentageColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: statusDetailColor,
                      ),
                    ),

                    Divider(height: 24, color: borderStrokeColor),

                    // Capacity calculations
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.tr('maxInstallment', widget.lang),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          _fmt(res.maxEligibleMonthlyInstallment),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.tr('maxPrice', widget.lang),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          _fmt(res.maxEligiblePropertyPrice),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            color: isDark ? const Color(0xFFFB7185) : theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 5. Actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF128C7E),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: const Color(0xFF128C7E).withValues(alpha: 0.35),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    final text = ShareService.formatDsrWhatsApp(
                      res: res,
                      lang: widget.lang,
                      agent: widget.agentProfile,
                    );
                    ShareService.launchWhatsApp(text);
                  },
                  icon: const Icon(Icons.send_rounded, size: 20),
                  label: Text(
                    AppStrings.tr('shareWhatsApp', widget.lang),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.2),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8), width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    final text = ShareService.formatDsrWhatsApp(
                      res: res,
                      lang: widget.lang,
                      agent: widget.agentProfile,
                    );
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppStrings.tr('copied', widget.lang)),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: Text(
                    AppStrings.tr('copyDsr', widget.lang),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),

            SizedBox(height: max(36.0, MediaQuery.of(context).padding.bottom + 28.0)),
          ],
        ),
      ),
    );
  }

  Widget _commitmentField(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          const SizedBox(width: 8),
          SizedBox(
            width: 145,
            height: 40,
            child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorInputFormatter()],
              onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                prefixText: 'RM ',
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bankChip(String name, double limit) {
    final isSelected = (_dsrLimitPercent == limit);
    final theme = Theme.of(context);
    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      label: Text(
        '$name ${limit.toInt()}%',
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          color: isSelected
              ? theme.colorScheme.onPrimaryContainer
              : theme.colorScheme.onSurface,
        ),
      ),
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      selectedColor: theme.colorScheme.primaryContainer,
      side: BorderSide(
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        width: isSelected ? 1.5 : 1.0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (_) {
        HapticFeedback.selectionClick();
        setState(() => _dsrLimitPercent = limit);
      },
    );
  }
}
