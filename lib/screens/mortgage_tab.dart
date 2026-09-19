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
  final _priceController = TextEditingController(text: '500,000');
  double _price = 500000;
  double _downPaymentPercent = 10;
  int _tenureYears = 35;
  double _interestRate = 4.00;
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

  // Insurance & Takaful Controls (MRTT / MLTT / LTHT)
  bool _includeInsurance = false;
  bool _financeMrtt = true;
  bool _isCustomMrtt = false;
  final _customMrttController = TextEditingController();
  final _coverageRemarkController = TextEditingController();
  String _insuranceType = 'MRTT';
  int _borrowerAge = 30;

  // LTHT Fire Insurance
  bool _financeLtht = false;
  final _customLthtController = TextEditingController();

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



            const SizedBox(height: 16),

            // 9. Results Card (Real-World Bank LO Presentation)
            _buildResultsCard(theme, res),

            const SizedBox(height: 16),

            // 10. Actions (Share Approval & Share Quotation)
            _buildActionButtons(theme, res),

            SizedBox(height: max(36.0, MediaQuery.of(context).padding.bottom + 28.0)),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const Divider(height: 18),

              // 1. Full-Width Takaful Type Segmented Button
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: 'CLTT',
                      label: Text('CLTT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    ButtonSegment(
                      value: 'MRTT',
                      label: Text('MRTT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    ButtonSegment(
                      value: 'MRTA',
                      label: Text('MRTA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                  selected: {_insuranceType},
                  onSelectionChanged: (set) => setState(() => _insuranceType = set.first),
                ),
              ),

              const SizedBox(height: 10),

              // 2. Full-Width Calculation Mode Toggle
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: true,
                      label: Text('Exact Bank Quote (RM)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text('Auto-Estimate (Age)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                  selected: {_isCustomMrtt},
                  onSelectionChanged: (set) => setState(() => _isCustomMrtt = set.first),
                ),
              ),

              const SizedBox(height: 12),

              if (_isCustomMrtt) ...[
                TextField(
                  controller: _customMrttController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  decoration: InputDecoration(
                    labelText: '$_insuranceType Contribution (RM)',
                    prefixText: 'RM ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _coverageRemarkController,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr('coverageRemark', widget.lang),
                    hintText: 'e.g. Cover 50% seorang up to 35 years',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ] else ...[
                _ageSelector(theme),
              ],

              const SizedBox(height: 12),

              // 3. Clean Financed Switch Tile
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  title: Text(
                    'Finance $_insuranceType into Loan',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _financeMrtt
                        ? 'Included in loan installment (RM0 upfront cash at SPA)'
                        : 'Paid as cash at SPA signing',
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  value: _financeMrtt,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    setState(() => _financeMrtt = v);
                  },
                ),
              ),

              const SizedBox(height: 8),

              // 4. Clean Expandable LTHT Fire Takaful (Lump-Sum)
              Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                  childrenPadding: const EdgeInsets.symmetric(vertical: 6),
                  leading: Icon(Icons.local_fire_department_outlined, size: 20, color: theme.colorScheme.primary),
                  title: const Text(
                    'LTHT Fire Takaful (Optional)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    _customLthtController.text.isNotEmpty && _customLthtController.text != '0'
                        ? 'RM ${_customLthtController.text} (${_financeLtht ? 'Financed' : 'Cash'})'
                        : 'Add lump-sum fire takaful (e.g. Bank Islam)',
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  children: [
                    TextField(
                      controller: _customLthtController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [ThousandsSeparatorInputFormatter()],
                      decoration: InputDecoration(
                        labelText: 'LTHT Fire Takaful Amount (RM)',
                        hintText: 'e.g. 7,015',
                        prefixText: 'RM ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 6),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Finance LTHT into Loan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Adds into Total Loan amount', style: TextStyle(fontSize: 11)),
                      value: _financeLtht,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        setState(() => _financeLtht = v);
                      },
                    ),
                  ],
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
                  ' / ${AppStrings.tr('perMonth', widget.lang)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // FORMULA SUMMARY BREAKDOWN
            _breakdownRow(
              widget.lang == 'bm' ? 'Harga Hartanah (SPA)' : 'SPA Property Price',
              _fmt(res.propertyPrice),
            ),
            if (res.developerDiscountAmount > 0)
              _breakdownRow(
                widget.lang == 'bm'
                    ? 'Rebat Pemaju (${res.developerDiscountPercent.toInt()}%)'
                    : 'Developer Rebate (${res.developerDiscountPercent.toInt()}%)',
                '-${_fmt(res.developerDiscountAmount)}',
              ),
            _breakdownRow(
              widget.lang == 'bm'
                  ? 'Margin Pinjaman ${res.downPaymentPercent == 0 ? "100%" : "${(100 - res.downPaymentPercent).toInt()}%"}'
                  : '${res.downPaymentPercent == 0 ? "100%" : "${(100 - res.downPaymentPercent).toInt()}%"} Loan Margin',
              _fmt(res.loanAmount),
            ),
            if (res.clttMrttAmount > 0 && res.clttMrttFinanced)
              _breakdownRow(
                '${res.insuranceType} Contribution',
                '+${_fmt(res.clttMrttAmount)}',
                widget.lang == 'bm' ? 'Dimasukkan' : 'Financed',
              ),
            if (res.lthtFireAmount > 0 && res.lthtFireFinanced)
              _breakdownRow(
                widget.lang == 'bm' ? 'LTHT Kebakaran' : 'LTHT Fire Takaful',
                '+${_fmt(res.lthtFireAmount)}',
                widget.lang == 'bm' ? 'Dimasukkan' : 'Financed',
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
                    AppStrings.tr('totalFinancedLoan', widget.lang),
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
              widget.lang == 'bm' ? 'Kadar & Tempoh' : 'Rate & Tenure',
              '${_interestRate.toStringAsFixed(2)}% | $_tenureYears ${widget.lang == 'bm' ? 'thn' : 'yrs'}',
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
              widget.lang == 'bm' ? 'Deposit Tunai Bersih' : 'Cash Downpayment',
              _fmt(max(0.0, res.downPaymentAmount - res.developerDiscountAmount)),
            ),
            _breakdownRow(
              widget.lang == 'bm' ? 'Yuran Guaman SPA' : 'SPA Legal Fee',
              res.freeSpaLegal ? 'RM 0' : _fmt(res.legalFees),
              res.freeSpaLegal ? (widget.lang == 'bm' ? 'Percuma' : 'Free') : null,
            ),
            _breakdownRow(
              widget.lang == 'bm' ? 'Duti Setem MOT' : 'SPA Stamp Duty (MOT)',
              res.freeSpaMot ? 'RM 0' : _fmt(res.stampDuty),
              res.freeSpaMot ? (widget.lang == 'bm' ? 'Percuma' : 'Free') : null,
            ),
            _breakdownRow(
              widget.lang == 'bm' ? 'Guaman & Duti Pinjaman' : 'Loan Legal & Stamp Duty',
              (res.freeLoanLegal || res.financeLoanDoc)
                  ? 'RM 0'
                  : _fmt(res.loanLegalFees + res.loanStampDuty),
              res.financeLoanDoc
                  ? (widget.lang == 'bm' ? 'Dimasukkan' : 'Financed')
                  : (res.freeLoanLegal ? (widget.lang == 'bm' ? 'Percuma' : 'Free') : null),
            ),
            _breakdownRow(
              widget.lang == 'bm' ? 'Yuran Penilaian' : 'Valuation Fee',
              (res.financeValuation || res.category == PropertyCategory.newLaunch)
                  ? 'RM 0'
                  : _fmt(res.valuationFee),
              res.financeValuation
                  ? (widget.lang == 'bm' ? 'Dimasukkan' : 'Financed')
                  : (res.category == PropertyCategory.newLaunch ? (widget.lang == 'bm' ? 'Percuma' : 'Free') : null),
            ),
            if (res.clttMrttAmount > 0 && !res.clttMrttFinanced)
              _breakdownRow(
                '${res.insuranceType} Contribution',
                _fmt(res.clttMrttAmount),
              ),
            if (res.lthtFireAmount > 0 && !res.lthtFireFinanced)
              _breakdownRow(
                widget.lang == 'bm' ? 'LTHT Kebakaran' : 'LTHT Fire Takaful',
                _fmt(res.lthtFireAmount),
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary Action: WhatsApp Quotation (Direct 1-Tap)
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
            final text = ShareService.formatMortgageWhatsApp(
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

        // Secondary Action: Copy Quotation (Direct 1-Tap)
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8), width: 1.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          label: Text(
            AppStrings.tr('copyQuotation', widget.lang),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
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
