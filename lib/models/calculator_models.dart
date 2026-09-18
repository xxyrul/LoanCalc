class MortgageResult {
  final double propertyPrice;
  final double downPaymentPercent;
  final double downPaymentAmount;
  final double loanAmount;
  final double effectiveLoanAmount;
  final double monthlyInstallment;
  final double monthlyInstallmentWithInsurance;
  final double totalPayment;
  final double totalInterest;
  final double stampDuty;
  final double originalStampDuty;
  final double legalFees;
  final double valuationFee;
  final double totalUpfront;
  final double totalUpfrontWithInsurance;
  final double recommendedIncome;
  final double mrttEstimate;
  final double fireInsuranceAnnual;
  final double fireInsuranceMonthly;
  final bool isInsuranceFinanced;
  final double monthlyMrttDelta;
  final bool includeMrtt;
  final bool includeFireInsurance;

  const MortgageResult({
    required this.propertyPrice,
    required this.downPaymentPercent,
    required this.downPaymentAmount,
    required this.loanAmount,
    required this.effectiveLoanAmount,
    required this.monthlyInstallment,
    required this.monthlyInstallmentWithInsurance,
    required this.totalPayment,
    required this.totalInterest,
    required this.stampDuty,
    required this.originalStampDuty,
    required this.legalFees,
    required this.valuationFee,
    required this.totalUpfront,
    required this.totalUpfrontWithInsurance,
    required this.recommendedIncome,
    required this.mrttEstimate,
    required this.fireInsuranceAnnual,
    required this.fireInsuranceMonthly,
    required this.isInsuranceFinanced,
    this.monthlyMrttDelta = 0.0,
    this.includeMrtt = true,
    this.includeFireInsurance = true,
  });
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
