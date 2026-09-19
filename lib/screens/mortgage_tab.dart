import 'dart:math';
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

  // Mode: Pre/New Launch vs Subsale
  PropertyCategory _category = PropertyCategory.newLaunch;

  // Property Inputs
  final _priceController = TextEditingController(text: '274,360');
  double _price = 274360;
  double _downPaymentPercent = 0; // Default 100% Loan from Maybank SJKP case
  int _tenureYears = 35;
  double _interestRate = 4.55;
  bool _isFirstHome = true;

  // New Launch Developer Package Controls
  double _developerDiscountPercent = 0.0;
  bool _freeSpaLegal = true;
  bool _freeSpaMot = true;
  bool _freeLoanLegal = true;
  bool _freeLoanStampDuty = true;
  bool _financeLoanDoc = false;

  // Subsale Controls
  bool _financeValuation = false;

  // Insurance & Takaful Controls (CLTT / MRTT / LTHT)
  bool _includeInsurance = true;
  bool _financeMrtt = true;
  bool _isCustomMrtt = true;
  final _customMrttController = TextEditingController(text: '21,983');
  final _coverageRemarkController = TextEditingController(text: 'Cover 50% seorang up to 35 years');
  String _insuranceType = 'CLTT';
  int _borrowerAge = 30;

  // LTHT Fire Insurance
  bool _financeLtht = false;
  final _customLthtController = TextEditingController();

  // Facility & Product Attributes
  final _applicantNameController = TextEditingController(text: 'Ahmad Faisal & Nor Azilah');
  final _rateRemarkController = TextEditingController(text: 'subject to HQ approval');
  String _facilityName = 'SJKP';
  String _loanType = 'Islamic Loan';
  String _flexiType = 'Semi Flexi Loan';
  String _lockInPeriod = 'No lock-in period';

  // Investment & Rental Metrics ("Other")
  final _areaSqftController = TextEditingController();
  final _rentalController = TextEditingController();
  final _utilitiesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _priceController.addListener(_onPriceChanged);
  }

  @override
  void dispose() {
    _priceController.dispose();
    _customMrttController.dispose();
    _coverageRemarkController.dispose();
    _customLthtController.dispose();
    _applicantNameController.dispose();
    _rateRemarkController.dispose();
    _areaSqftController.dispose();
    _rentalController.dispose();
    _utilitiesController.dispose();
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
    final newPrice = (_price + delta).clamp(10000, 20000000).toDouble();
    _priceController.text = _curr.format(newPrice.round());
  }

  MortgageResult get _result {
    final customMrtt = _isCustomMrtt
        ? double.tryParse(_customMrttController.text.replaceAll(RegExp(r'[^0-9.]'), ''))
        : null;
    final customLtht = double.tryParse(_customLthtController.text.replaceAll(RegExp(r'[^0-9.]'), ''));
    final areaSqft = double.tryParse(_areaSqftController.text.replaceAll(RegExp(r'[^0-9.]'), ''));
    final monthlyRental = double.tryParse(_rentalController.text.replaceAll(RegExp(r'[^0-9.]'), ''));
    final monthlyUtilities = double.tryParse(_utilitiesController.text.replaceAll(RegExp(r'[^0-9.]'), ''));

    return CalculatorEngine.calculateMortgage(
      propertyPrice: _price,
      category: _category,
      downPaymentPercent: _downPaymentPercent,
      interestRateAnnual: _interestRate,
      tenureYears: _tenureYears,
      isFirstHomeBuyer: _isFirstHome,
      borrowerAge: _borrowerAge,
      developerDiscountPercent: _developerDiscountPercent,
      freeSpaLegal: _category == PropertyCategory.newLaunch && _freeSpaLegal,
      freeSpaMot: _category == PropertyCategory.newLaunch && _freeSpaMot,
      freeLoanLegal: _category == PropertyCategory.newLaunch && _freeLoanLegal,
      freeLoanStampDuty: _category == PropertyCategory.newLaunch && _freeLoanStampDuty,
      financeLoanDoc: _financeLoanDoc,
      financeValuation: _category == PropertyCategory.subsale && _financeValuation,
      includeInsurance: _includeInsurance,
      includeMrtt: _includeInsurance,
      includeFireInsurance: customLtht != null && customLtht > 0,
      financeMrtt: _financeMrtt,
      customMrttAmount: customMrtt,
      customLthtAmount: customLtht,
      financeLtht: _financeLtht,
      insuranceType: _insuranceType,
      insuranceCoverageRemark: _coverageRemarkController.text.trim(),
      facilityName: _facilityName,
      loanType: _loanType,
      flexiType: _flexiType,
      lockInPeriod: _lockInPeriod,
      rateRemark: _rateRemarkController.text.trim(),
      applicantNames: _applicantNameController.text.trim(),
      areaSqft: areaSqft,
      monthlyRental: monthlyRental,
      monthlyUtilities: monthlyUtilities,
    );
  }

  String _fmt(double val) => 'RM ${_curr.format(val.round())}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final res = _result;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Segmented Switch: Pre/New Launch vs Subsale
            _buildCategorySelector(theme),

            const SizedBox(height: 12),

            // 2. Property Price Card
            _buildPriceCard(theme),

            const SizedBox(height: 12),

            // 3. Financing Terms Card (Tenure, Rate & Presets)
            _buildFinancingTermsCard(theme),

            const SizedBox(height: 12),

            // 4. Down Payment & Loan Margin Card
            _buildDownpaymentCard(theme, res),

            const SizedBox(height: 12),

            // 5. Developer Freebies or Subsale Package Card
            _buildPackageTogglesCard(theme),

            const SizedBox(height: 12),

            // 6. Insurance & Takaful (CLTT / MRTT / LTHT) Card
            _buildInsuranceCard(theme, res),

            const SizedBox(height: 12),

            // 7. Property & Investment Metrics ("Other" section)
            _buildInvestmentMetricsCard(theme, res),

            const SizedBox(height: 12),

            // 8. Loan Facility & Approval Details (Expandable)
            _buildApprovalDetailsCard(theme),

            const SizedBox(height: 16),

            // 9. Results Card (Real-World Bank LO Presentation)
            _buildResultsCard(theme, res),

            const SizedBox(height: 16),

            // 10. Actions (Share Approval & Share Quotation)
            _buildActionButtons(theme, res),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildCategorySelector(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _categoryButton(
              title: AppStrings.tr('preNewLaunch', widget.lang),
              icon: Icons.apartment_rounded,
              selected: _category == PropertyCategory.newLaunch,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _category = PropertyCategory.newLaunch;
                  _freeSpaLegal = true;
                  _freeSpaMot = true;
                  _freeLoanLegal = true;
                  _freeLoanStampDuty = true;
                });
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _categoryButton(
              title: AppStrings.tr('subsale', widget.lang),
              icon: Icons.home_work_outlined,
              selected: _category == PropertyCategory.subsale,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _category = PropertyCategory.subsale;
                  _freeSpaLegal = false;
                  _freeSpaMot = false;
                  _freeLoanLegal = false;
                  _freeLoanStampDuty = false;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryButton({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? theme.colorScheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.tr('propertyPrice', widget.lang),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _category == PropertyCategory.newLaunch ? 'SPA Price' : 'Subsale Price',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
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
    );
  }

  Widget _buildFinancingTermsCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tenure Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.tr('tenure', widget.lang),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  '$_tenureYears ${AppStrings.tr('perYear', widget.lang)} (${_tenureYears * 12} bln)',
                  style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                ),
              ],
            ),
            Slider(
              value: _tenureYears.toDouble(),
              min: 5,
              max: 35,
              divisions: 30,
              onChanged: (val) {
                HapticFeedback.selectionClick();
                setState(() => _tenureYears = val.round());
              },
            ),

            const SizedBox(height: 6),

            // Interest / Profit Rate
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.tr('interestRate', widget.lang),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  '${_interestRate.toStringAsFixed(2)}% p.a.',
                  style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                ),
              ],
            ),
            Slider(
              value: _interestRate,
              min: 2.5,
              max: 7.0,
              divisions: 90,
              onChanged: (val) {
                HapticFeedback.selectionClick();
                setState(() => _interestRate = double.parse(val.toStringAsFixed(2)));
              },
            ),

            // Bank Presets
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _rateChip('Maybank 4.55%', 4.55),
                  _rateChip('CIMB 4.20%', 4.20),
                  _rateChip('Public 4.15%', 4.15),
                  _rateChip('RHB 4.25%', 4.25),
                  _rateChip('HLB 4.10%', 4.10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rateChip(String label, double rate) {
    final isSelected = (_interestRate - rate).abs() < 0.01;
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: (_) {
        HapticFeedback.selectionClick();
        setState(() => _interestRate = rate);
      },
      selectedColor: theme.colorScheme.primaryContainer,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildDownpaymentCard(ThemeData theme, MortgageResult res) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.tr('downPayment', widget.lang),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  '${_downPaymentPercent.toInt()}% (${_fmt(res.downPaymentAmount)})',
                  style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Quick Loan Margin Chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _marginChip('100% Loan (0% Dep)', 0.0),
                _marginChip('90% Loan (10% Dep)', 10.0),
                _marginChip('85% Loan (15% Dep)', 15.0),
                _marginChip('80% Loan (20% Dep)', 20.0),
              ],
            ),

            Slider(
              value: _downPaymentPercent,
              min: 0,
              max: 30,
              divisions: 30,
              onChanged: (val) {
                HapticFeedback.selectionClick();
                setState(() => _downPaymentPercent = val.roundToDouble());
              },
            ),

            // Developer Discount / Rebate (In Pre/New Launch Mode)
            if (_category == PropertyCategory.newLaunch) ...[
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.tr('developerDiscount', widget.lang),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Text(
                    '${_developerDiscountPercent.toInt()}% (-${_fmt(res.developerDiscountAmount)})',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
              Slider(
                value: _developerDiscountPercent,
                min: 0,
                max: 15,
                divisions: 15,
                activeColor: Colors.green,
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  setState(() => _developerDiscountPercent = val.roundToDouble());
                },
              ),
              if (_developerDiscountPercent > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'Nett Purchase Price: ${_fmt(res.netPurchasePrice)}',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _marginChip(String label, double dpPercent) {
    final isSelected = (_downPaymentPercent - dpPercent).abs() < 0.1;
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      selected: isSelected,
      onSelected: (_) {
        HapticFeedback.selectionClick();
        setState(() => _downPaymentPercent = dpPercent);
      },
      selectedColor: theme.colorScheme.primaryContainer,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildPackageTogglesCard(ThemeData theme) {
    final isNewLaunch = _category == PropertyCategory.newLaunch;
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isNewLaunch ? Icons.card_giftcard_rounded : Icons.real_estate_agent_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  isNewLaunch ? 'Developer Package & Freebies' : 'Subsale Package & Waivers',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (isNewLaunch) ...[
              _switchRow(AppStrings.tr('freeSpaLegal', widget.lang), _freeSpaLegal, (v) => setState(() => _freeSpaLegal = v)),
              _switchRow(AppStrings.tr('freeSpaMot', widget.lang), _freeSpaMot, (v) => setState(() => _freeSpaMot = v)),
              _switchRow(AppStrings.tr('freeLoanLegal', widget.lang), _freeLoanLegal, (v) => setState(() => _freeLoanLegal = v)),
              _switchRow(AppStrings.tr('freeLoanStampDuty', widget.lang), _freeLoanStampDuty, (v) => setState(() => _freeLoanStampDuty = v)),
              _switchRow(AppStrings.tr('financeLoanDoc', widget.lang), _financeLoanDoc, (v) => setState(() => _financeLoanDoc = v)),
            ] else ...[
              _switchRow(AppStrings.tr('financeLoanDocValuation', widget.lang), _financeValuation, (v) => setState(() => _financeValuation = v)),
              _switchRow(AppStrings.tr('firstHome', widget.lang), _isFirstHome, (v) => setState(() => _isFirstHome = v)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _switchRow(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          Switch(
            value: value,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInsuranceCard(ThemeData theme, MortgageResult res) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.tr('insuranceOptions', widget.lang),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                Switch(
                  value: _includeInsurance,
                  onChanged: (v) {
                    HapticFeedback.lightImpact();
                    setState(() => _includeInsurance = v);
                  },
                ),
              ],
            ),

            if (_includeInsurance) ...[
              const Divider(height: 16),

              // Insurance Type (CLTT / MRTT / MRTA)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Takaful Type:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'CLTT', label: Text('CLTT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      ButtonSegment(value: 'MRTT', label: Text('MRTT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      ButtonSegment(value: 'MRTA', label: Text('MRTA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                    ],
                    selected: {_insuranceType},
                    onSelectionChanged: (set) => setState(() => _insuranceType = set.first),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Auto vs Exact Quote Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isCustomMrtt ? 'Exact Bank Quote:' : 'Estimate Mode:',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('Exact RM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      ButtonSegment(value: false, label: Text('Auto Calc', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                    ],
                    selected: {_isCustomMrtt},
                    onSelectionChanged: (set) => setState(() => _isCustomMrtt = set.first),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              if (_isCustomMrtt) ...[
                TextField(
                  controller: _customMrttController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  decoration: InputDecoration(
                    labelText: '$_insuranceType Contribution (RM)',
                    prefixText: 'RM ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _coverageRemarkController,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr('coverageRemark', widget.lang),
                    hintText: 'e.g. Cover 50% seorang up to 35 years',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ] else ...[
                _ageSelector(theme),
              ],

              const SizedBox(height: 12),

              // Financed into Loan Switch
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Finance $_insuranceType into Loan',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _financeMrtt ? 'Adds to Total Loan (Zero cash at SPA)' : 'Pay cash at SPA signing',
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _financeMrtt,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        setState(() => _financeMrtt = v);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Optional LTHT Fire Takaful
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('LTHT Fire Takaful (Optional):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Row(
                    children: [
                      const Text('Finance', style: TextStyle(fontSize: 11)),
                      Switch(
                        value: _financeLtht,
                        onChanged: (v) => setState(() => _financeLtht = v),
                      ),
                    ],
                  ),
                ],
              ),
              TextField(
                controller: _customLthtController,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                decoration: InputDecoration(
                  labelText: 'LTHT Fire Takaful Amount (RM)',
                  hintText: 'e.g. 7,014.73',
                  prefixText: 'RM ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInvestmentMetricsCard(ThemeData theme, MortgageResult res) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Icon(Icons.analytics_outlined, color: theme.colorScheme.primary),
        title: Text(
          AppStrings.tr('otherSection', widget.lang),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _areaSqftController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr('areaSqft', widget.lang),
                    hintText: 'e.g. 850',
                    suffixText: 'sqft',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _rentalController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr('monthlyRentalIncome', widget.lang),
                    hintText: 'e.g. 1,600',
                    prefixText: 'RM ',
                    suffixText: '/ mo',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _utilitiesController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr('monthlyUtilitiesFees', widget.lang),
                    hintText: 'e.g. 200',
                    prefixText: 'RM ',
                    suffixText: '/ mo',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),

                if (res.pricePsf != null || res.rentalYield != null || res.netCashflow != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        if (res.pricePsf != null)
                          _breakdownRow(AppStrings.tr('pricePsf', widget.lang), 'RM ${res.pricePsf!.toStringAsFixed(1)} / sqft'),
                        if (res.rentalYield != null)
                          _breakdownRow(AppStrings.tr('rentalYield', widget.lang), '${res.rentalYield!.toStringAsFixed(2)}%'),
                        if (res.netCashflow != null)
                          _breakdownRow(
                            AppStrings.tr('netCashflow', widget.lang),
                            _fmt(res.netCashflow!),
                            res.netCashflow! >= 0 ? '+ Positive' : '- Deficit',
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalDetailsCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Icon(Icons.verified_outlined, color: theme.colorScheme.primary),
        title: Text(
          AppStrings.tr('loanFacility', widget.lang),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                TextField(
                  controller: _applicantNameController,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr('applicantNames', widget.lang),
                    hintText: 'e.g. Ahmad Faisal & Nor Azilah',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _facilityName,
                        decoration: InputDecoration(
                          labelText: 'Facility',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'SJKP', child: Text('SJKP Scheme')),
                          DropdownMenuItem(value: 'Standard Housing Loan', child: Text('Standard Loan')),
                          DropdownMenuItem(value: 'First Home Scheme', child: Text('First Home')),
                        ],
                        onChanged: (v) => setState(() => _facilityName = v ?? 'SJKP'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _loanType,
                        decoration: InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Islamic Loan', child: Text('Islamic Loan')),
                          DropdownMenuItem(value: 'Conventional Loan', child: Text('Conventional')),
                        ],
                        onChanged: (v) => setState(() => _loanType = v ?? 'Islamic Loan'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _flexiType,
                        decoration: InputDecoration(
                          labelText: 'Flexibility',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Semi Flexi Loan', child: Text('Semi Flexi')),
                          DropdownMenuItem(value: 'Full Flexi Loan', child: Text('Full Flexi')),
                          DropdownMenuItem(value: 'Term Loan', child: Text('Term Loan')),
                        ],
                        onChanged: (v) => setState(() => _flexiType = v ?? 'Semi Flexi Loan'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _lockInPeriod,
                        decoration: InputDecoration(
                          labelText: 'Lock-in',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'No lock-in period', child: Text('No Lock-in')),
                          DropdownMenuItem(value: '3 Years Lock-in', child: Text('3 Years')),
                          DropdownMenuItem(value: '5 Years Lock-in', child: Text('5 Years')),
                        ],
                        onChanged: (v) => setState(() => _lockInPeriod = v ?? 'No lock-in period'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _rateRemarkController,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr('rateRemark', widget.lang),
                    hintText: 'e.g. subject to HQ approval',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsCard(ThemeData theme, MortgageResult res) {
    return Card(
      elevation: 2,
      color: theme.colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.tr('monthlyInstallment', widget.lang),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.85),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Selepas Muqasah',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _fmt(res.monthlyInstallmentWithInsurance),
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  ' / mo',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // FORMULA SUMMARY BREAKDOWN (Matching Real Bank Letter of Offer)
            _breakdownRow(
              'SPA Property Price',
              _fmt(res.propertyPrice),
            ),
            _breakdownRow(
              res.downPaymentPercent == 0 ? '100% Loan Margin' : '${(100 - res.downPaymentPercent).toInt()}% Loan Margin',
              _fmt(res.loanAmount),
            ),
            if (res.clttMrttAmount > 0 && res.clttMrttFinanced)
              _breakdownRow(
                '${res.insuranceType} Contribution',
                '+${_fmt(res.clttMrttAmount)}',
                'Financed',
              ),
            if (res.lthtFireAmount > 0 && res.lthtFireFinanced)
              _breakdownRow(
                'LTHT Fire Takaful',
                '+${_fmt(res.lthtFireAmount)}',
                'Financed',
              ),

            Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Loan (Jumlah Pembiayaan)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    _fmt(res.totalFinancedLoan),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),

            _breakdownRow(
              'Rate & Tenure',
              '${_interestRate.toStringAsFixed(2)}% | $_tenureYears yrs',
            ),

            const Divider(height: 20),

            // Entry Cost Cash Breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.tr('entryCost', widget.lang),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
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
            const SizedBox(height: 6),
            _breakdownRow(
              'Cash Downpayment',
              _fmt(max(0.0, res.downPaymentAmount - res.developerDiscountAmount)),
            ),
            _breakdownRow(
              'SPA Legal Fee',
              res.freeSpaLegal ? 'RM -' : _fmt(res.legalFees),
              res.freeSpaLegal ? 'Free' : null,
            ),
            _breakdownRow(
              'SPA Stamp Duty (MOT)',
              res.freeSpaMot ? 'RM -' : _fmt(res.stampDuty),
              res.freeSpaMot ? 'Free' : null,
            ),
            _breakdownRow(
              'Valuation Fee',
              res.financeValuation ? 'RM -' : _fmt(res.valuationFee),
              res.financeValuation ? 'Financed' : null,
            ),

            Divider(
              height: 20,
              color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.2),
            ),

            // Min Recommended Income
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
    );
  }

  Widget _buildActionButtons(ThemeData theme, MortgageResult res) {
    return Column(
      children: [
        // Primary Action: WhatsApp Share Choice
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () => _showShareChoiceModal(context, res),
          icon: const Icon(Icons.send_rounded),
          label: Text(
            AppStrings.tr('shareWhatsApp', widget.lang),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),

        // Secondary Action: Copy Quotation
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () {
            final text = ShareService.formatLoanApprovalWhatsApp(
              res: res,
              interestRate: _interestRate,
              tenureYears: _tenureYears,
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
      ],
    );
  }

  void _showShareChoiceModal(BuildContext context, MortgageResult res) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Pilih Format WhatsApp / Share Options',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFDCFCE7),
                    child: Icon(Icons.celebration_rounded, color: Color(0xFF14532D)),
                  ),
                  title: const Text('Surat Kelulusan Pinjaman (Approval Letter)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Format ucapan tahniah rasmi dengan formula Total Loan & ansuran bulanan.'),
                  onTap: () {
                    Navigator.pop(ctx);
                    final text = ShareService.formatLoanApprovalWhatsApp(
                      res: res,
                      interestRate: _interestRate,
                      tenureYears: _tenureYears,
                      lang: widget.lang,
                      agent: widget.agentProfile,
                    );
                    ShareService.launchWhatsApp(text);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEFF6FF),
                    child: Icon(Icons.receipt_long_rounded, color: Color(0xFF1D4ED8)),
                  ),
                  title: const Text('Sebutharga Lengkap (Full Quotation)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Pecahan terperinci kos permulaan, rebat pemaju, dan metrik pelaburan.'),
                  onTap: () {
                    Navigator.pop(ctx);
                    final text = ShareService.formatMortgageWhatsApp(
                      res: res,
                      lang: widget.lang,
                      agent: widget.agentProfile,
                    );
                    ShareService.launchWhatsApp(text);
                  },
                ),
              ],
            ),
          ),
        );
      },
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  '$_borrowerAge yrs',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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
}
