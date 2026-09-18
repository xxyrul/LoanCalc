import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/calculator_models.dart';
import '../utils/calculator_engine.dart';
import '../utils/currency_formatter.dart';
import '../utils/share_service.dart';
import '../i18n/app_strings.dart';

class MortgageTab extends StatefulWidget {
  final String lang;
  final AgentProfile? agentProfile;

  const MortgageTab({
    super.key,
    required this.lang,
    this.agentProfile,
  });

  @override
  State<MortgageTab> createState() => _MortgageTabState();
}

class _MortgageTabState extends State<MortgageTab> {
  final _curr = NumberFormat('#,##0', 'en_US');
  final _priceController = TextEditingController(text: '500,000');

  double _price = 500000;
  double _downPaymentPercent = 10;
  int _tenureYears = 30;
  double _interestRate = 4.2;
  bool _isFirstHome = true;
  bool _includeInsurance = true;
  bool _includeMrtt = true;
  bool _includeFireInsurance = true;
  bool _financeMrtt = true;
  int _borrowerAge = 30;

  @override
  void initState() {
    super.initState();
    _priceController.addListener(_onPriceChanged);
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _onPriceChanged() {
    final clean = _priceController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final val = double.tryParse(clean) ?? 0;
    if (val != _price) {
      setState(() {
        _price = val;
      });
    }
  }

  void _addPrice(double delta) {
    HapticFeedback.lightImpact();
    final newPrice = (_price + delta).clamp(50000, 20000000).toDouble();
    _priceController.text = _curr.format(newPrice.round());
  }

  MortgageResult get _result => CalculatorEngine.calculateMortgage(
        propertyPrice: _price,
        downPaymentPercent: _downPaymentPercent,
        interestRateAnnual: _interestRate,
        tenureYears: _tenureYears,
        isFirstHomeBuyer: _isFirstHome,
        borrowerAge: _borrowerAge,
        includeInsurance: _includeInsurance,
        includeMrtt: _includeMrtt,
        includeFireInsurance: _includeFireInsurance,
        financeMrtt: _financeMrtt,
      );

  String _fmt(double val) => 'RM ${_curr.format(val.round())}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final res = _result;

    // Determine displayed primary installment
    final primaryInstallment = (res.isInsuranceFinanced && res.mrttEstimate > 0)
        ? res.monthlyInstallmentWithInsurance
        : res.monthlyInstallment;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Property Price Card
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
                      AppStrings.tr('propertyPrice', widget.lang),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [ThousandsSeparatorInputFormatter()],
                      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        prefixText: 'RM ',
                        prefixStyle: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Quick add steppers with Wrap
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _stepperButton('+RM 10k', () => _addPrice(10000)),
                        _stepperButton('+RM 50k', () => _addPrice(50000)),
                        _stepperButton('+RM 100k', () => _addPrice(100000)),
                        _stepperButton('+RM 500k', () => _addPrice(500000)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 2. Loan Parameters Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Downpayment Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppStrings.tr('downPayment', widget.lang)),
                        Text(
                          '${_downPaymentPercent.toInt()}% (${_fmt(res.downPaymentAmount)})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Slider(
                      value: _downPaymentPercent,
                      min: 0,
                      max: 30,
                      divisions: 6,
                      label: '${_downPaymentPercent.toInt()}%',
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        setState(() => _downPaymentPercent = val);
                      },
                    ),

                    // Tenure Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppStrings.tr('tenure', widget.lang)),
                        Text(
                          '$_tenureYears ${AppStrings.tr('tenure', widget.lang).contains('Tahun') ? 'Tahun' : 'Years'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Slider(
                      value: _tenureYears.toDouble(),
                      min: 5,
                      max: 35,
                      divisions: 30,
                      label: '$_tenureYears yrs',
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        setState(() => _tenureYears = val.toInt());
                      },
                    ),

                    // Interest Rate Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppStrings.tr('interestRate', widget.lang)),
                        Text(
                          '${_interestRate.toStringAsFixed(2)}% p.a.',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Slider(
                      value: _interestRate,
                      min: 3.0,
                      max: 6.5,
                      divisions: 35,
                      label: '${_interestRate.toStringAsFixed(2)}%',
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        setState(() => _interestRate = val);
                      },
                    ),

                    const Divider(),

                    // First-Time Home Buyer Toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        AppStrings.tr('firstHome', widget.lang),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        AppStrings.tr('firstHomeHint', widget.lang),
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                      ),
                      value: _isFirstHome,
                      onChanged: (val) {
                        HapticFeedback.lightImpact();
                        setState(() => _isFirstHome = val);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 3. Insurance Options Card (Redesigned)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.shield_outlined, color: theme.colorScheme.primary, size: 20),
                    ),
                    title: Text(
                      AppStrings.tr('insuranceOptions', widget.lang),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: res.mrttEstimate > 0 || res.fireInsuranceAnnual > 0
                        ? Text(
                            '${_fmt(res.mrttEstimate + res.fireInsuranceAnnual)} (${_financeMrtt ? AppStrings.tr('financedInLoan', widget.lang) : AppStrings.tr('payCash', widget.lang)})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : Text(
                            AppStrings.tr('includeInsurance', widget.lang),
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                          ),
                    value: _includeInsurance,
                    onChanged: (val) {
                      HapticFeedback.lightImpact();
                      setState(() => _includeInsurance = val);
                    },
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: _includeInsurance
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Divider(height: 1),
                              // Sub-option 1: MRTT / MRTA Takaful
                              SwitchListTile(
                                visualDensity: VisualDensity.compact,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                title: Text(
                                  AppStrings.tr('mrttTakaful', widget.lang),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                subtitle: res.mrttEstimate > 0
                                    ? Text(
                                        '~${_fmt(res.mrttEstimate)}${res.isInsuranceFinanced ? ' (+RM ${res.monthlyMrttDelta.round()}/${AppStrings.tr('perMonth', widget.lang)})' : ''}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      )
                                    : null,
                                value: _includeMrtt,
                                onChanged: (val) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _includeMrtt = val);
                                },
                              ),
                              if (_includeMrtt) ...[
                                // Payment mode: Financed vs Cash Upfront
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                                  child: SegmentedButton<bool>(
                                    segments: [
                                      ButtonSegment<bool>(
                                        value: true,
                                        label: Text(
                                          AppStrings.tr('financedInLoan', widget.lang),
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                        icon: const Icon(Icons.credit_card, size: 14),
                                      ),
                                      ButtonSegment<bool>(
                                        value: false,
                                        label: Text(
                                          AppStrings.tr('payCash', widget.lang),
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                        icon: const Icon(Icons.payments_outlined, size: 14),
                                      ),
                                    ],
                                    selected: {_financeMrtt},
                                    onSelectionChanged: (set) {
                                      HapticFeedback.selectionClick();
                                      setState(() => _financeMrtt = set.first);
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                                  child: Text(
                                    _financeMrtt
                                        ? AppStrings.tr('financedHint', widget.lang)
                                        : AppStrings.tr('cashHint', widget.lang),
                                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                                  child: _ageSelector(theme),
                                ),
                                const SizedBox(height: 4),
                              ],
                              const Divider(height: 1),
                              // Sub-option 2: Fire Insurance
                              SwitchListTile(
                                visualDensity: VisualDensity.compact,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                title: Text(
                                  AppStrings.tr('fireInsuranceLabel', widget.lang),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                subtitle: res.fireInsuranceAnnual > 0
                                    ? Text(
                                        '${_fmt(res.fireInsuranceAnnual)} / ${AppStrings.tr('perYear', widget.lang)}',
                                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                                      )
                                    : null,
                                value: _includeFireInsurance,
                                onChanged: (val) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _includeFireInsurance = val);
                                },
                              ),
                              const SizedBox(height: 6),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 4. Results Card (High Impact)
            Card(
              elevation: 2,
              color: theme.colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.tr('monthlyInstallment', widget.lang),
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _fmt(primaryInstallment),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          ' / mo',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),

                    if (res.isInsuranceFinanced && res.mrttEstimate > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '• ${AppStrings.tr('monthlyWithMrtt', widget.lang)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.85),
                        ),
                      ),
                    ],

                    const Divider(height: 24),

                    // Loan Amount & Repayment Summary
                    _breakdownRow(
                      AppStrings.tr('loanAmount', widget.lang),
                      _fmt(res.effectiveLoanAmount),
                    ),
                    _breakdownRow(
                      AppStrings.tr('totalInterest', widget.lang),
                      _fmt(res.totalInterest),
                    ),
                    _breakdownRow(
                      AppStrings.tr('totalRepayment', widget.lang),
                      _fmt(res.totalPayment),
                    ),

                    const SizedBox(height: 6),

                    // Entry Cost Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            AppStrings.tr('entryCost', widget.lang),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _fmt(res.totalUpfrontWithInsurance),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Breakdown Lines
                    _breakdownRow(
                      AppStrings.tr('stampDuty', widget.lang),
                      _fmt(res.stampDuty),
                      res.stampDuty < res.originalStampDuty
                          ? '(Saved ${_fmt(res.originalStampDuty - res.stampDuty)})'
                          : null,
                    ),
                    _breakdownRow(
                      AppStrings.tr('legalFees', widget.lang),
                      _fmt(res.legalFees),
                    ),
                    _breakdownRow(
                      AppStrings.tr('valuationFee', widget.lang),
                      _fmt(res.valuationFee),
                    ),
                    if (res.fireInsuranceAnnual > 0)
                      _breakdownRow(
                        AppStrings.tr('fireInsurance', widget.lang),
                        _fmt(res.fireInsuranceAnnual),
                      ),
                    if (!res.isInsuranceFinanced && res.mrttEstimate > 0)
                      _breakdownRow(
                        AppStrings.tr('mrttEstimate', widget.lang),
                        _fmt(res.mrttEstimate),
                      ),

                    Divider(
                      height: 20,
                      color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.2),
                    ),

                    // Recommended Income
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            AppStrings.tr('recommendedIncome', widget.lang),
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                        Text(
                          _fmt(res.recommendedIncome),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 5. Actions (WhatsApp Share + Copy)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                final text = ShareService.formatMortgageWhatsApp(
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
                final text = ShareService.formatMortgageWhatsApp(
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
              label: Text(AppStrings.tr('copyQuotation', widget.lang)),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _stepperButton(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _breakdownRow(String label, String value, [String? sub]) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.88),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              if (sub != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark ? const Color(0xFF059669) : const Color(0xFF86EFAC),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    sub,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF14532D),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
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
}
