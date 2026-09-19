import 'dart:math';
import '../models/calculator_models.dart';

class CalculatorEngine {
  /// Calculates standard Malaysian commercial and Islamic housing loans,
  /// supporting Pre/New Launch developer packages, Subsale entry costs,
  /// capitalized CLTT/MRTT and LTHT (Fire Takaful) as seen in Bank Letters of Offer.
  static MortgageResult calculateMortgage({
    required double propertyPrice,
    PropertyCategory category = PropertyCategory.newLaunch,
    double downPaymentPercent = 10.0,
    double interestRateAnnual = 4.2,
    int tenureYears = 30,
    bool isFirstHomeBuyer = false,
    int borrowerAge = 30,
    double developerDiscountPercent = 0.0,
    bool freeSpaLegal = false,
    bool freeSpaMot = false,
    bool freeLoanLegal = false,
    bool freeLoanStampDuty = false,
    bool financeLoanDoc = false,
    bool financeValuation = false,
    bool includeInsurance = true,
    bool includeMrtt = true,
    bool includeFireInsurance = true,
    bool financeMrtt = true,
    double? customMrttAmount,
    double? customLthtAmount,
    bool financeLtht = false,
    String insuranceType = 'CLTT',
    String insuranceCoverageRemark = '',
    String facilityName = 'Standard Housing Loan',
    String loanType = 'Islamic Loan',
    String flexiType = 'Semi Flexi Loan',
    String lockInPeriod = 'No lock-in period',
    String rateRemark = '',
    String? applicantNames,
    double? areaSqft,
    double? monthlyRental,
    double? monthlyUtilities,
  }) {
    if (propertyPrice <= 0) {
      return const MortgageResult(
        propertyPrice: 0,
        downPaymentPercent: 0,
        downPaymentAmount: 0,
        loanAmount: 0,
        effectiveLoanAmount: 0,
        monthlyInstallment: 0,
        monthlyInstallmentWithInsurance: 0,
        totalPayment: 0,
        totalInterest: 0,
        stampDuty: 0,
        originalStampDuty: 0,
        legalFees: 0,
        valuationFee: 0,
        totalUpfront: 0,
        totalUpfrontWithInsurance: 0,
        recommendedIncome: 0,
        mrttEstimate: 0,
        fireInsuranceAnnual: 0,
        fireInsuranceMonthly: 0,
        isInsuranceFinanced: false,
        monthlyMrttDelta: 0,
        includeMrtt: false,
        includeFireInsurance: false,
      );
    }

    // Developer Rebate / Discount
    final double discountAmount = category == PropertyCategory.newLaunch && developerDiscountPercent > 0
        ? propertyPrice * (developerDiscountPercent / 100)
        : 0.0;
    final double netPurchasePrice = max(0.0, propertyPrice - discountAmount);

    final double downPaymentAmount = propertyPrice * (downPaymentPercent / 100);
    final double baseLoanAmount = max(0.0, propertyPrice - downPaymentAmount);

    final double monthlyRate = interestRateAnnual / 100 / 12;
    final int totalMonths = max(1, tenureYears * 12);

    // Standard Malaysian Tiered Stamp Duty on SPA (MOT):
    // 1% first 100k, 2% up to 500k, 3% up to 1M, 4% above 1M
    double standardSpaStampDuty = 0;
    if (propertyPrice > 1000000) {
      standardSpaStampDuty = (100000 * 0.01) +
          (400000 * 0.02) +
          (500000 * 0.03) +
          ((propertyPrice - 1000000) * 0.04);
    } else if (propertyPrice > 500000) {
      standardSpaStampDuty = (100000 * 0.01) +
          (400000 * 0.02) +
          ((propertyPrice - 500000) * 0.03);
    } else if (propertyPrice > 100000) {
      standardSpaStampDuty = (100000 * 0.01) + ((propertyPrice - 100000) * 0.02);
    } else {
      standardSpaStampDuty = propertyPrice * 0.01;
    }

    // First-Time Home Buyer exemption (MOT):
    // 100% exemption <= RM500k, 75% remission from RM500k - RM1M
    double calculatedSpaStampDuty = standardSpaStampDuty;
    if (isFirstHomeBuyer) {
      if (propertyPrice <= 500000) {
        calculatedSpaStampDuty = 0;
      } else if (propertyPrice <= 1000000) {
        calculatedSpaStampDuty = standardSpaStampDuty * 0.25;
      }
    }
    final double effectiveSpaStampDuty = freeSpaMot ? 0.0 : calculatedSpaStampDuty;

    // Scale of Legal Fees for SPA (Solicitors' Remuneration Order ~1.1% of value, min RM2,500)
    final double standardSpaLegal = max(2500.0, propertyPrice * 0.011);
    final double effectiveSpaLegal = freeSpaLegal ? 0.0 : standardSpaLegal;

    // Loan Agreement Legal Fees (~1.0% of loan, min RM2,000)
    final double standardLoanLegal = baseLoanAmount > 0 ? max(2000.0, baseLoanAmount * 0.01) : 0.0;
    final double effectiveLoanLegal = freeLoanLegal ? 0.0 : standardLoanLegal;

    // Loan Agreement Stamp Duty (0.5% of loan amount)
    final double standardLoanStampDuty = baseLoanAmount > 0 ? baseLoanAmount * 0.005 : 0.0;
    final double effectiveLoanStampDuty = freeLoanStampDuty ? 0.0 : standardLoanStampDuty;

    // Bank Valuation Fee estimation (~0.3% of value, min RM1,000) - Only applicable for Subsale
    final double standardValuationFee = category == PropertyCategory.newLaunch
        ? 0.0
        : max(1000.0, propertyPrice * 0.003);

    // --- INSURANCE & TAKAFUL CALCULATIONS (CLTT / MRTT & LTHT / FIRE) ---
    final int clampedAge = min(65, max(20, borrowerAge));
    final double ageFactor = 0.012 + max(0, clampedAge - 25) * 0.0009;
    final double tenureFactor = max(0.5, tenureYears / 30.0);
    final double autoMrttRate = ageFactor * tenureFactor;

    final bool hasMrtt = includeInsurance && includeMrtt;
    final double autoMrtt = baseLoanAmount > 0 ? baseLoanAmount * autoMrttRate : 0.0;
    final double clttMrttAmount = hasMrtt
        ? (customMrttAmount != null && customMrttAmount > 0 ? customMrttAmount : autoMrtt)
        : 0.0;

    // Houseowner / Fire Takaful / Insurance (Tarif standard BNM ~0.115% per annum)
    final bool hasFire = includeInsurance && includeFireInsurance;
    final double fireInsuranceAnnual = hasFire && propertyPrice > 0 ? propertyPrice * 0.00115 : 0.0;
    final double fireInsuranceMonthly = fireInsuranceAnnual / 12.0;
    final double lthtFireAmount = (customLthtAmount != null && customLthtAmount > 0)
        ? customLthtAmount
        : fireInsuranceAnnual;

    // Financed insurance flags
    final bool isClttFinanced = hasMrtt && financeMrtt && clttMrttAmount > 0;
    final bool isLthtFinanced = hasFire && financeLtht && lthtFireAmount > 0;

    // Financed fees (Loan documentation & Valuation)
    final double financedDocAmount = financeLoanDoc ? (effectiveLoanLegal + effectiveLoanStampDuty) : 0.0;
    final double financedValuationAmount = financeValuation ? standardValuationFee : 0.0;

    // TOTAL FINANCED LOAN (Jumlah Pembiayaan - matches real bank Letters of Offer!)
    final double totalFinancedLoan = baseLoanAmount +
        (isClttFinanced ? clttMrttAmount : 0.0) +
        (isLthtFinanced ? lthtFireAmount : 0.0) +
        financedDocAmount +
        financedValuationAmount;

    // Calculate amortized monthly installment on base loan vs total financed loan
    double baseMonthlyInstallment = 0;
    if (monthlyRate > 0 && totalMonths > 0) {
      final double compound = pow(1 + monthlyRate, totalMonths).toDouble();
      baseMonthlyInstallment = (baseLoanAmount * (monthlyRate * compound)) / (compound - 1);
    } else if (totalMonths > 0) {
      baseMonthlyInstallment = baseLoanAmount / totalMonths;
    }

    double totalMonthlyInstallment = baseMonthlyInstallment;
    if (totalFinancedLoan > 0 && monthlyRate > 0 && totalMonths > 0) {
      final double compound = pow(1 + monthlyRate, totalMonths).toDouble();
      totalMonthlyInstallment = (totalFinancedLoan * (monthlyRate * compound)) / (compound - 1);
    }

    final double monthlyMrttDelta = max(0.0, totalMonthlyInstallment - baseMonthlyInstallment);
    final double totalPayment = totalMonthlyInstallment * totalMonths;
    final double totalInterest = max(0.0, totalPayment - totalFinancedLoan);

    // Initial Cash Required (Entry Cost):
    // Buyer cash downpayment after applying developer rebate
    final double netCashDownPayment = max(0.0, downPaymentAmount - discountAmount);

    final double upfrontSpaCost = effectiveSpaStampDuty + effectiveSpaLegal;
    final double upfrontLoanCost = (financeLoanDoc ? 0.0 : (effectiveLoanLegal + effectiveLoanStampDuty));
    final double upfrontValuationCost = (category == PropertyCategory.newLaunch || financeValuation)
        ? 0.0
        : standardValuationFee;
    final double upfrontInsuranceCost = (isClttFinanced ? 0.0 : clttMrttAmount) +
        (isLthtFinanced ? 0.0 : (customLthtAmount != null && customLthtAmount > 0 ? customLthtAmount : fireInsuranceAnnual));

    final double totalUpfront = netCashDownPayment +
        upfrontSpaCost +
        upfrontLoanCost +
        upfrontValuationCost;

    final double totalUpfrontWithInsurance = totalUpfront + upfrontInsuranceCost;

    // Recommended Min. Net Household Income (assume 60% DSR)
    final double recommendedIncome = totalMonthlyInstallment / 0.60;

    // Investment / Cashflow Metrics
    double? pricePsf;
    if (areaSqft != null && areaSqft > 0) {
      pricePsf = propertyPrice / areaSqft;
    }

    double? rentalYield;
    double? netCashflow;
    if (monthlyRental != null && monthlyRental > 0) {
      rentalYield = (monthlyRental * 12) / propertyPrice * 100;
      final utilities = monthlyUtilities ?? 0.0;
      netCashflow = monthlyRental - totalMonthlyInstallment - utilities;
    }

    return MortgageResult(
      category: category,
      propertyPrice: propertyPrice,
      developerDiscountPercent: developerDiscountPercent,
      developerDiscountAmount: discountAmount,
      netPurchasePrice: netPurchasePrice,
      downPaymentPercent: downPaymentPercent,
      downPaymentAmount: downPaymentAmount,
      loanAmount: baseLoanAmount,
      effectiveLoanAmount: totalFinancedLoan,
      totalFinancedLoan: totalFinancedLoan,
      monthlyInstallment: baseMonthlyInstallment,
      monthlyInstallmentWithInsurance: totalMonthlyInstallment,
      totalPayment: totalPayment,
      totalInterest: totalInterest,
      stampDuty: effectiveSpaStampDuty,
      originalStampDuty: standardSpaStampDuty,
      legalFees: effectiveSpaLegal,
      loanLegalFees: effectiveLoanLegal,
      loanStampDuty: effectiveLoanStampDuty,
      valuationFee: standardValuationFee,
      freeSpaLegal: freeSpaLegal,
      freeSpaMot: freeSpaMot,
      freeLoanLegal: freeLoanLegal,
      freeLoanStampDuty: freeLoanStampDuty,
      financeLoanDoc: financeLoanDoc,
      financeValuation: financeValuation,
      totalUpfront: totalUpfront,
      totalUpfrontWithInsurance: totalUpfrontWithInsurance,
      recommendedIncome: recommendedIncome,
      mrttEstimate: clttMrttAmount,
      clttMrttAmount: clttMrttAmount,
      clttMrttFinanced: isClttFinanced,
      lthtFireAmount: lthtFireAmount,
      lthtFireFinanced: isLthtFinanced,
      fireInsuranceAnnual: fireInsuranceAnnual,
      fireInsuranceMonthly: fireInsuranceMonthly,
      isInsuranceFinanced: isClttFinanced,
      monthlyMrttDelta: monthlyMrttDelta,
      includeMrtt: hasMrtt,
      includeFireInsurance: hasFire,
      insuranceType: insuranceType,
      insuranceCoverageRemark: insuranceCoverageRemark,
      facilityName: facilityName,
      loanType: loanType,
      flexiType: flexiType,
      lockInPeriod: lockInPeriod,
      rateRemark: rateRemark,
      applicantNames: applicantNames,
      areaSqft: areaSqft,
      pricePsf: pricePsf,
      monthlyRental: monthlyRental,
      rentalYield: rentalYield,
      monthlyUtilities: monthlyUtilities,
      netCashflow: netCashflow,
    );
  }

  /// Calculates Debt Service Ratio (DSR) and maximum loan eligibility
  static DsrResult calculateDsr({
    required double averageIncome,
    required double dsrLimitPercent,
    double carLoan = 0,
    double housingLoan = 0,
    double creditCard = 0,
    double personalLoan = 0,
    double ptptnOther = 0,
  }) {
    final double totalCommitments = max(
      0.0,
      carLoan + housingLoan + creditCard + personalLoan + ptptnOther,
    );

    final double currentDsrPercent = averageIncome > 0
        ? (totalCommitments / averageIncome) * 100.0
        : 0.0;

    final double maxAllowableCommitment =
        averageIncome * (dsrLimitPercent / 100.0);
    final double remainingNetDisposable =
        max(0.0, maxAllowableCommitment - totalCommitments);

    DsrStatus status = DsrStatus.healthy;
    if (currentDsrPercent <= 60.0) {
      status = DsrStatus.healthy;
    } else if (currentDsrPercent <= dsrLimitPercent) {
      status = DsrStatus.moderate;
    } else {
      status = DsrStatus.critical;
    }

    // Maximum loan estimation: 30 years at 4.2% interest
    final double monthlyRate = 0.042 / 12.0;
    const int totalMonths = 30 * 12;
    double maxEligibleLoanAmount = 0;
    if (remainingNetDisposable > 0 && monthlyRate > 0) {
      maxEligibleLoanAmount = (remainingNetDisposable *
              (1 - pow(1 + monthlyRate, -totalMonths))) /
          monthlyRate;
    }

    // Malaysian REN standard rule of thumb: each RM1k disposable affords RM200k property
    final double maxEligiblePropertyPrice = max(0.0, remainingNetDisposable * 200.0);

    return DsrResult(
      averageIncome: averageIncome,
      totalCommitments: totalCommitments,
      currentDsrPercent: currentDsrPercent,
      dsrLimitPercent: dsrLimitPercent,
      maxAllowableCommitment: maxAllowableCommitment,
      remainingNetDisposable: remainingNetDisposable,
      maxEligibleLoanAmount: maxEligibleLoanAmount,
      maxEligiblePropertyPrice: maxEligiblePropertyPrice,
      maxEligibleMonthlyInstallment: remainingNetDisposable,
      status: status,
    );
  }

  /// Calculates Malaysian LPPSA Government Housing Loan Eligibility
  static LppsaResult calculateLppsa({
    required double basicSalary,
    double fixedAllowances = 0,
    double currentPayslipDeductions = 0,
    required double propertyPrice,
    int borrowerAge = 30,
    String scheme = 'skim1',
  }) {
    final double qualifyingIncome = max(0.0, basicSalary + fixedAllowances);
    const double interestRate = 4.0;
    const double monthlyRate = interestRate / 100.0 / 12.0;

    // Max tenure: up to age 70 or scheme cap (35 yrs for skim 1, 30 yrs for skim 2)
    final int ageCap = max(0, 70 - borrowerAge);
    final int schemeCap = scheme == 'skim1' ? 35 : 30;
    final int maxTenureYears = min(schemeCap, max(5, ageCap));
    final int totalMonths = maxTenureYears * 12;

    // Max allowable deduction: Skim 1 = 60%, Skim 2 = 50%
    final double maxDeductionRate = scheme == 'skim1' ? 0.60 : 0.50;
    final double maxMonthlyFromQualifying = qualifyingIncome * maxDeductionRate;

    // 75% total deduction ceiling constraint
    final double max75Ceiling =
        (qualifyingIncome * 0.75) - currentPayslipDeductions;
    final double maxAllowableMonthlyDeduction = max(
      0.0,
      min(maxMonthlyFromQualifying, max75Ceiling),
    );

    // Monthly installment for requested property price (100% financing)
    double monthlyInstallment = 0;
    if (propertyPrice > 0 && totalMonths > 0) {
      final double compound = pow(1 + monthlyRate, totalMonths).toDouble();
      monthlyInstallment =
          (propertyPrice * (monthlyRate * compound)) / (compound - 1);
    }

    // Maximum loan capacity based on allowable monthly deduction
    double maxEligibleLoanAmount = 0;
    if (maxAllowableMonthlyDeduction > 0 && totalMonths > 0) {
      maxEligibleLoanAmount = (maxAllowableMonthlyDeduction *
              (1 - pow(1 + monthlyRate, -totalMonths))) /
          monthlyRate;
    }

    final double surplusDeficitMonthly =
        maxAllowableMonthlyDeduction - monthlyInstallment;
    final bool isEligible = propertyPrice > 0
        ? monthlyInstallment <= maxAllowableMonthlyDeduction
        : maxEligibleLoanAmount > 0;

    final double netTakeHomeAfterLoan = max(
      0.0,
      qualifyingIncome - currentPayslipDeductions - monthlyInstallment,
    );

    String? rejectionReason;
    if (!isEligible && propertyPrice > 0) {
      if (monthlyInstallment > maxMonthlyFromQualifying) {
        rejectionReason =
            'Monthly installment exceeds ${(maxDeductionRate * 100).toInt()}% qualifying income limit.';
      } else if (monthlyInstallment > max75Ceiling) {
        rejectionReason =
            'Current payslip deductions exceed the 75% total payslip ceiling.';
      }
    }

    return LppsaResult(
      qualifyingIncome: qualifyingIncome,
      maxAllowableMonthlyDeduction: maxAllowableMonthlyDeduction,
      monthlyInstallment: monthlyInstallment,
      maxEligibleLoanAmount: maxEligibleLoanAmount,
      maxTenureYears: maxTenureYears,
      interestRate: interestRate,
      isEligible: isEligible,
      surplusDeficitMonthly: surplusDeficitMonthly,
      netTakeHomeAfterLoan: netTakeHomeAfterLoan,
      rejectionReason: rejectionReason,
      scheme: scheme,
    );
  }
}
