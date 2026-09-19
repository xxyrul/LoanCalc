enum PropertyCategory { newLaunch, subsale }

class MortgageResult {
  final PropertyCategory category;
  final double propertyPrice;
  final double developerDiscountPercent;
  final double developerDiscountAmount;
  final double netPurchasePrice;
  final double downPaymentPercent;
  final double downPaymentAmount;
  final double loanAmount;
  final double effectiveLoanAmount;
  final double totalFinancedLoan;
  final double monthlyInstallment;
  final double monthlyInstallmentWithInsurance;
  final double totalPayment;
  final double totalInterest;
  final double stampDuty;
  final double originalStampDuty;
  final double legalFees;
  final double loanLegalFees;
  final double loanStampDuty;
  final double valuationFee;
  final bool freeSpaLegal;
  final bool freeSpaMot;
  final bool freeLoanLegal;
  final bool freeLoanStampDuty;
  final bool financeLoanDoc;
  final bool financeValuation;
  final double totalUpfront;
  final double totalUpfrontWithInsurance;
  final double recommendedIncome;
  final double mrttEstimate;
  final double clttMrttAmount;
  final bool clttMrttFinanced;
  final double lthtFireAmount;
  final bool lthtFireFinanced;
  final double fireInsuranceAnnual;
  final double fireInsuranceMonthly;
  final bool isInsuranceFinanced;
  final double monthlyMrttDelta;
  final bool includeMrtt;
  final bool includeFireInsurance;
  final String insuranceType;
  final String insuranceCoverageRemark;
  final String facilityName;
  final String loanType;
  final String flexiType;
  final String lockInPeriod;
  final String rateRemark;
  final String? applicantNames;
  final double? areaSqft;
  final double? pricePsf;
  final double? monthlyRental;
  final double? rentalYield;
  final double? monthlyUtilities;
  final double? netCashflow;

  const MortgageResult({
    this.category = PropertyCategory.newLaunch,
    required this.propertyPrice,
    this.developerDiscountPercent = 0.0,
    this.developerDiscountAmount = 0.0,
    double? netPurchasePrice,
    required this.downPaymentPercent,
    required this.downPaymentAmount,
    required this.loanAmount,
    required this.effectiveLoanAmount,
    double? totalFinancedLoan,
    required this.monthlyInstallment,
    required this.monthlyInstallmentWithInsurance,
    required this.totalPayment,
    required this.totalInterest,
    required this.stampDuty,
    required this.originalStampDuty,
    required this.legalFees,
    this.loanLegalFees = 0.0,
    this.loanStampDuty = 0.0,
    required this.valuationFee,
    this.freeSpaLegal = false,
    this.freeSpaMot = false,
    this.freeLoanLegal = false,
    this.freeLoanStampDuty = false,
    this.financeLoanDoc = false,
    this.financeValuation = false,
    required this.totalUpfront,
    required this.totalUpfrontWithInsurance,
    required this.recommendedIncome,
    required this.mrttEstimate,
    this.clttMrttAmount = 0.0,
    this.clttMrttFinanced = true,
    this.lthtFireAmount = 0.0,
    this.lthtFireFinanced = false,
    required this.fireInsuranceAnnual,
    required this.fireInsuranceMonthly,
    required this.isInsuranceFinanced,
    this.monthlyMrttDelta = 0.0,
    this.includeMrtt = true,
    this.includeFireInsurance = true,
    this.insuranceType = 'CLTT',
    this.insuranceCoverageRemark = '',
    this.facilityName = 'Standard Housing Loan',
    this.loanType = 'Islamic Loan',
    this.flexiType = 'Semi Flexi Loan',
    this.lockInPeriod = 'No lock-in period',
    this.rateRemark = '',
    this.applicantNames,
    this.areaSqft,
    this.pricePsf,
    this.monthlyRental,
    this.rentalYield,
    this.monthlyUtilities,
    this.netCashflow,
  })  : netPurchasePrice = netPurchasePrice ?? propertyPrice,
        totalFinancedLoan = totalFinancedLoan ?? effectiveLoanAmount;
}

enum DsrStatus { healthy, moderate, critical }

class DsrResult {
  final double averageIncome;
  final double totalCommitments;
  final double currentDsrPercent;
  final double dsrLimitPercent;
  final double maxAllowableCommitment;
  final double remainingNetDisposable;
  final double maxEligibleLoanAmount;
  final double maxEligiblePropertyPrice;
  final double maxEligibleMonthlyInstallment;
  final DsrStatus status;

  const DsrResult({
    required this.averageIncome,
    required this.totalCommitments,
    required this.currentDsrPercent,
    required this.dsrLimitPercent,
    required this.maxAllowableCommitment,
    required this.remainingNetDisposable,
    required this.maxEligibleLoanAmount,
    required this.maxEligiblePropertyPrice,
    required this.maxEligibleMonthlyInstallment,
    required this.status,
  });
}

class LppsaResult {
  final double qualifyingIncome;
  final double maxAllowableMonthlyDeduction;
  final double monthlyInstallment;
  final double maxEligibleLoanAmount;
  final int maxTenureYears;
  final double interestRate;
  final bool isEligible;
  final double surplusDeficitMonthly;
  final double netTakeHomeAfterLoan;
  final String? rejectionReason;
  final String scheme; // 'skim1' or 'skim2'

  const LppsaResult({
    required this.qualifyingIncome,
    required this.maxAllowableMonthlyDeduction,
    required this.monthlyInstallment,
    required this.maxEligibleLoanAmount,
    required this.maxTenureYears,
    required this.interestRate,
    required this.isEligible,
    required this.surplusDeficitMonthly,
    required this.netTakeHomeAfterLoan,
    this.rejectionReason,
    required this.scheme,
  });
}

class AgentProfile {
  final String name;
  final String phone;
  final String agency;
  final String renNumber;

  const AgentProfile({
    this.name = '',
    this.phone = '',
    this.agency = '',
    this.renNumber = '',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'agency': agency,
    'renNumber': renNumber,
  };

  factory AgentProfile.fromJson(Map<String, dynamic> json) => AgentProfile(
    name: json['name'] ?? '',
    phone: json['phone'] ?? '',
    agency: json['agency'] ?? '',
    renNumber: json['renNumber'] ?? '',
  );
}
