import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/calculator_models.dart';
import '../utils/calculator_engine.dart';
import '../utils/currency_formatter.dart';
import '../utils/share_service.dart';
import '../i18n/app_strings.dart';

class LppsaTab extends StatefulWidget {
  final String lang;
  final AgentProfile? agentProfile;

  const LppsaTab({
    super.key,
    required this.lang,
    this.agentProfile,
  });

  @override
  State<LppsaTab> createState() => _LppsaTabState();
}

class _LppsaTabState extends State<LppsaTab> {
  final _curr = NumberFormat('#,##0', 'en_US');

  final _basicSalaryCtrl = TextEditingController(text: '4,500');
  final _allowancesCtrl = TextEditingController(text: '1,150');
  final _deductionsCtrl = TextEditingController(text: '800');
  final _priceCtrl = TextEditingController(text: '400,000');

  double _basicSalary = 4500;
  double _allowances = 1150;
  double _deductions = 800;
  double _price = 400000;
  int _borrowerAge = 32;
  String _scheme = 'skim1';

  @override
  void initState() {
    super.initState();
    _basicSalaryCtrl.addListener(() => _updateNum(_basicSalaryCtrl, (v) => _basicSalary = v));
    _allowancesCtrl.addListener(() => _updateNum(_allowancesCtrl, (v) => _allowances = v));
    _deductionsCtrl.addListener(() => _updateNum(_deductionsCtrl, (v) => _deductions = v));
    _priceCtrl.addListener(() => _updateNum(_priceCtrl, (v) => _price = v));
  }

  void _updateNum(TextEditingController ctrl, void Function(double) setter) {
    final clean = ctrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final val = double.tryParse(clean) ?? 0;
    setState(() => setter(val));
  }

  @override
  void dispose() {
    _basicSalaryCtrl.dispose();
    _allowancesCtrl.dispose();
    _deductionsCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  LppsaResult get _result => CalculatorEngine.calculateLppsa(
        basicSalary: _basicSalary,
        fixedAllowances: _allowances,
        currentPayslipDeductions: _deductions,
        propertyPrice: _price,
        borrowerAge: _borrowerAge,
        scheme: _scheme,
      );

  String _fmt(double val) => 'RM ${_curr.format(val.round())}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final res = _result;

    final isDark = theme.brightness == Brightness.dark;
    final isEligible = res.isEligible;

    final bgContainerColor = isEligible
        ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFDCFCE7))
        : (isDark ? const Color(0xFF450A0A).withValues(alpha: 0.4) : const Color(0xFFFEE2E2));

    final borderStrokeColor = isEligible
        ? (isDark ? const Color(0xFF059669).withValues(alpha: 0.6) : const Color(0xFF86EFAC))
        : (isDark ? const Color(0xFFDC2626).withValues(alpha: 0.6) : const Color(0xFFFECACA));

    final statusTextColor = isEligible
        ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF14532D))
        : (isDark ? const Color(0xFFFCA5A5) : const Color(0xFF7F1D1D));

    final statusDetailColor = isEligible
        ? (isDark ? const Color(0xFFBBF7D0) : const Color(0xFF166534))
        : (isDark ? const Color(0xFFFECDD3) : const Color(0xFF991B1B));

    final statusIconColor = isEligible
        ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))
        : (isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Scheme Segmented Control
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'skim1',
                  label: Text(
                    AppStrings.tr('skim1', widget.lang),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  icon: const Icon(Icons.looks_one_outlined, size: 16),
                ),
                ButtonSegment(
                  value: 'skim2',
                  label: Text(
                    AppStrings.tr('skim2', widget.lang),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  icon: const Icon(Icons.looks_two_outlined, size: 16),
                ),
              ],
              selected: {_scheme},
              onSelectionChanged: (Set<String> newSelection) {
                HapticFeedback.lightImpact();
                setState(() => _scheme = newSelection.first);
              },
            ),

            const SizedBox(height: 12),

            // 2. Payslip & Property Inputs Card
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
                    _salaryField(AppStrings.tr('basicSalary', widget.lang), _basicSalaryCtrl),
                    _salaryField(AppStrings.tr('fixedAllowances', widget.lang), _allowancesCtrl),
                    _salaryField(AppStrings.tr('payslipDeductions', widget.lang), _deductionsCtrl),
                    const Divider(height: 20),
                    _salaryField(AppStrings.tr('propertyPrice', widget.lang), _priceCtrl),
                    const SizedBox(height: 4),
                    _ageSelector(theme),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 3. LPPSA Result Card (High Contrast)
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
                        Icon(
                          res.isEligible ? Icons.verified_rounded : Icons.warning_amber_rounded,
                          color: statusIconColor,
                          size: 26,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            res.isEligible
                                ? AppStrings.tr('eligible', widget.lang)
                                : AppStrings.tr('ineligible', widget.lang),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: statusTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (res.rejectionReason != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        res.rejectionReason!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusDetailColor,
                        ),
                      ),
                    ],

                    Divider(height: 24, color: borderStrokeColor),

                    // Monthly Installment
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${AppStrings.tr('monthlyInstallment', widget.lang)}:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          _fmt(res.monthlyInstallment),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: statusIconColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    _infoRow(
                      '${AppStrings.tr('qualifyingIncome', widget.lang)}:',
                      _fmt(res.qualifyingIncome),
                    ),
                    _infoRow(
                      '${AppStrings.tr('maxDeduction', widget.lang)} (${_scheme == 'skim1' ? '60%' : '50%'}):',
                      _fmt(res.maxAllowableMonthlyDeduction),
                    ),
                    _infoRow(
                      '${AppStrings.tr('maxEligibleLoan', widget.lang)}:',
                      _fmt(res.maxEligibleLoanAmount),
                    ),
                    _infoRow(
                      '${AppStrings.tr('maxTenure', widget.lang)}:',
                      '${res.maxTenureYears} Years (4.0% Fixed)',
                    ),

                    Divider(height: 20, color: borderStrokeColor),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${AppStrings.tr('netTakeHome', widget.lang)}:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          _fmt(res.netTakeHomeAfterLoan),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

            // 4. Actions
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                final text = ShareService.formatLppsaWhatsApp(
                  res: res,
                  lang: widget.lang,
                  agent: widget.agentProfile,
                );
                ShareService.launchWhatsApp(text);
              },
              icon: const Icon(Icons.send_rounded),
              label: Text(
                AppStrings.tr('shareWhatsApp', widget.lang),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 8),

            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                final text = ShareService.formatLppsaWhatsApp(
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
              label: Text(AppStrings.tr('copyLppsa', widget.lang)),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _salaryField(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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

  Widget _ageSelector(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppStrings.tr('applicantAge', widget.lang),
          style: const TextStyle(fontSize: 13),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                icon: const Icon(Icons.remove_rounded),
                onPressed: _borrowerAge > 20
                    ? () {
                        HapticFeedback.lightImpact();
                        setState(() => _borrowerAge--);
                      }
                    : null,
              ),
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => _pickAgeDirectly(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    '$_borrowerAge yrs',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                icon: const Icon(Icons.add_rounded),
                onPressed: _borrowerAge < 65
                    ? () {
                        HapticFeedback.lightImpact();
                        setState(() => _borrowerAge++);
                      }
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _pickAgeDirectly(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  AppStrings.tr('applicantAge', widget.lang),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              SizedBox(
                height: 250,
                child: ListView.builder(
                  itemCount: 46,
                  itemBuilder: (context, i) {
                    final age = 20 + i;
                    final isSelected = age == _borrowerAge;
                    return ListTile(
                      dense: true,
                      title: Text(
                        '$age yrs',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Theme.of(context).colorScheme.primary : null,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                          : null,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _borrowerAge = age);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
