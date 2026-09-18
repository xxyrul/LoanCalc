import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/calculator_models.dart';

class ShareService {
  static final _curr = NumberFormat('#,##0', 'en_US');

  static String _fmt(double num) => 'RM ${_curr.format(num.round())}';

  static String _buildAgentSignature(AgentProfile? agent) {
    if (agent == null || agent.name.trim().isEmpty) {
      return '\n\n---------------------------------\n📲 *Dikira dengan LoanCalc*';
    }
    String cleanPhone = agent.phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.startsWith('01')) {
      cleanPhone = '6$cleanPhone';
    }
    return '\n\n---------------------------------\n'
        '👤 *Disediakan oleh / Prepared by:*\n'
        '*${agent.name}* ${agent.renNumber.isNotEmpty ? '(${agent.renNumber})' : ''}\n'
        '${agent.agency.isNotEmpty ? '🏢 ${agent.agency}\n' : ''}'
        '${cleanPhone.isNotEmpty ? '📞 WhatsApp: wa.me/$cleanPhone' : ''}';
  }

  static String formatMortgageWhatsApp({
    required MortgageResult res,
    required String lang,
    AgentProfile? agent,
  }) {
    final sig = _buildAgentSignature(agent);

    if (lang == 'zh') {
      return '🏡 *【马来西亚房屋贷款与购房预算】*\n\n'
          '💰 *房产价格:* ${_fmt(res.propertyPrice)}\n'
          '💵 *首付款 (${res.downPaymentPercent.toInt()}%):* ${_fmt(res.downPaymentAmount)}\n'
          '🏦 *房贷总额:* ${_fmt(res.loanAmount)}\n'
          '---------------------------------\n'
          '📊 *每月还款估算*\n'
          '• *每月供款额:* *${_fmt(res.monthlyInstallment)}/月*\n'
          '${res.isInsuranceFinanced && res.mrttEstimate > 0 ? '• 含 MRTT 贷款供款: *${_fmt(res.monthlyInstallmentWithInsurance)}/月*\n' : ''}'
          '• 建议家庭最低净月入: ${_fmt(res.recommendedIncome)}\n'
          '---------------------------------\n'
          '💼 *前期头期现金总开销 (Entry Cost)*\n'
          '• 现金首付款: ${_fmt(res.downPaymentAmount)}\n'
          '• 印花税 (SPA): ${_fmt(res.stampDuty)} ${res.stampDuty < res.originalStampDuty ? '*(首购已节省 ${_fmt(res.originalStampDuty - res.stampDuty)})*' : ''}\n'
          '• 律师费估算: ${_fmt(res.legalFees)}\n'
          '• 估价费估算: ${_fmt(res.valuationFee)}\n'
          '${res.fireInsuranceAnnual > 0 ? '• 房屋火险 (第1年): ${_fmt(res.fireInsuranceAnnual)}\n' : ''}'
          '${!res.isInsuranceFinanced && res.mrttEstimate > 0 ? '• MRTT 寿险 (自付): ${_fmt(res.mrttEstimate)}\n' : ''}'
          '👉 *头期现金总开销:* *${_fmt(res.totalUpfrontWithInsurance)}*'
          '$sig';
    }

    if (lang == 'en') {
      return '🏡 *[PROPERTY FINANCING & ENTRY COST ESTIMATION]*\n\n'
          '💰 *Property Price:* ${_fmt(res.propertyPrice)}\n'
          '💵 *Downpayment (${res.downPaymentPercent.toInt()}%):* ${_fmt(res.downPaymentAmount)}\n'
          '🏦 *Loan Amount:* ${_fmt(res.loanAmount)}\n'
          '---------------------------------\n'
          '📊 *MONTHLY ESTIMATION*\n'
          '• *Monthly Installment:* *${_fmt(res.monthlyInstallment)}/month*\n'
          '${res.isInsuranceFinanced && res.mrttEstimate > 0 ? '• With Financed MRTT: *${_fmt(res.monthlyInstallmentWithInsurance)}/month*\n' : ''}'
          '• Min. Recommended Household Net Income: ${_fmt(res.recommendedIncome)}\n'
          '---------------------------------\n'
          '💼 *INITIAL CASH REQUIRED (ENTRY COST)*\n'
          '• Cash Downpayment: ${_fmt(res.downPaymentAmount)}\n'
          '• SPA Stamp Duty: ${_fmt(res.stampDuty)} ${res.stampDuty < res.originalStampDuty ? '*(Saved ${_fmt(res.originalStampDuty - res.stampDuty)} 1st Home)*' : ''}\n'
          '• Legal Fees (SRO): ${_fmt(res.legalFees)}\n'
          '• Valuation Fee: ${_fmt(res.valuationFee)}\n'
          '${res.fireInsuranceAnnual > 0 ? '• Fire Insurance (1st yr): ${_fmt(res.fireInsuranceAnnual)}\n' : ''}'
          '${!res.isInsuranceFinanced && res.mrttEstimate > 0 ? '• MRTT Insurance (Cash): ${_fmt(res.mrttEstimate)}\n' : ''}'
          '👉 *TOTAL INITIAL CASH:* *${_fmt(res.totalUpfrontWithInsurance)}*'
          '$sig';
    }

    // Default: BM
    return '🏡 *[ANGGARAN PINJAMAN RUMAH & KOS MASUK]*\n\n'
        '💰 *Harga Hartanah:* ${_fmt(res.propertyPrice)}\n'
        '💵 *Deposit Tunai (${res.downPaymentPercent.toInt()}%):* ${_fmt(res.downPaymentAmount)}\n'
        '🏦 *Jumlah Pinjaman:* ${_fmt(res.loanAmount)}\n'
        '---------------------------------\n'
        '📊 *ANGGARAN BULANAN*\n'
        '• *Ansuran Bulanan:* *${_fmt(res.monthlyInstallment)}/bulan*\n'
        '${res.isInsuranceFinanced && res.mrttEstimate > 0 ? '• Termasuk MRTT: *${_fmt(res.monthlyInstallmentWithInsurance)}/bulan*\n' : ''}'
        '• Cadangan Gaji Bersih Minimum: ${_fmt(res.recommendedIncome)}\n'
        '---------------------------------\n'
        '💼 *TUNAI DIPERLUKAN (KOS MASUK)*\n'
        '• Deposit Tunai: ${_fmt(res.downPaymentAmount)}\n'
        '• Duti Setem SPA: ${_fmt(res.stampDuty)} ${res.stampDuty < res.originalStampDuty ? '*(Jimat ${_fmt(res.originalStampDuty - res.stampDuty)} Rumah Pertama)*' : ''}\n'
        '• Yuran Guaman: ${_fmt(res.legalFees)}\n'
        '• Yuran Penilaian: ${_fmt(res.valuationFee)}\n'
        '${res.fireInsuranceAnnual > 0 ? '• Insurans Kebakaran (Thn 1): ${_fmt(res.fireInsuranceAnnual)}\n' : ''}'
        '${!res.isInsuranceFinanced && res.mrttEstimate > 0 ? '• Insurans MRTT (Tunai): ${_fmt(res.mrttEstimate)}\n' : ''}'
        '👉 *TOTAL TUNAI KOS MASUK:* *${_fmt(res.totalUpfrontWithInsurance)}*'
        '$sig';
  }

  static String formatDsrWhatsApp({
    required DsrResult res,
    required String lang,
    AgentProfile? agent,
  }) {
    final sig = _buildAgentSignature(agent);
    final statusEmoji = res.status == DsrStatus.healthy
        ? '🟢'
        : res.status == DsrStatus.moderate
            ? '🟡'
            : '🔴';

    if (lang == 'zh') {
      return '📊 *【DSR 供款比率与还款能力评估】*\n\n'
          '💼 *平均净月入:* ${_fmt(res.averageIncome)}\n'
          '💳 *现有每月总负债:* ${_fmt(res.totalCommitments)}\n'
          '---------------------------------\n'
          '📈 *DSR 审核指标*\n'
          '• *当前 DSR 比率:* *${res.currentDsrPercent.toStringAsFixed(1)}%* (银行上限: ${res.dsrLimitPercent.toInt()}%)\n'
          '• *批贷状态评级:* $statusEmoji *${res.status == DsrStatus.healthy ? '健康 (几率极高)' : res.status == DsrStatus.moderate ? '正常 (符合标准)' : '警戒 (拒贷风险)'}*\n'
          '---------------------------------\n'
          '🎯 *最高借贷能力估算*\n'
          '• *剩余每月可借贷供款:* *${_fmt(res.maxEligibleMonthlyInstallment)}/月*\n'
          '• *最高可购买房产总价:* *${_fmt(res.maxEligiblePropertyPrice)}*\n'
          '• *最高预估房贷额度:* *${_fmt(res.maxEligibleLoanAmount)}*'
          '$sig';
    }

    if (lang == 'en') {
      return '📊 *[DEBT SERVICE RATIO (DSR) ASSESSMENT]*\n\n'
          '💼 *Average Net Income:* ${_fmt(res.averageIncome)}\n'
          '💳 *Total Monthly Commitments:* ${_fmt(res.totalCommitments)}\n'
          '---------------------------------\n'
          '📈 *DSR RESULT*\n'
          '• *Current DSR:* *${res.currentDsrPercent.toStringAsFixed(1)}%* (Limit: ${res.dsrLimitPercent.toInt()}%)\n'
          '• *Health Status:* $statusEmoji *${res.status.name.toUpperCase()}*\n'
          '---------------------------------\n'
          '🎯 *MAXIMUM CAPACITY*\n'
          '• *Remaining Monthly Capacity:* *${_fmt(res.maxEligibleMonthlyInstallment)}/month*\n'
          '• *Max. Estimated Property Price:* *${_fmt(res.maxEligiblePropertyPrice)}*\n'
          '• *Max. Estimated Loan Amount:* *${_fmt(res.maxEligibleLoanAmount)}*'
          '$sig';
    }

    return '📊 *[ANALISIS KELAYAKAN PINJAMAN & DSR]*\n\n'
        '💼 *Purata Gaji Bersih Sebulan:* ${_fmt(res.averageIncome)}\n'
        '💳 *Jumlah Komitmen Semasa:* ${_fmt(res.totalCommitments)}\n'
        '---------------------------------\n'
        '📈 *KEPUTUSAN DSR*\n'
        '• *Kadar DSR Semasa:* *${res.currentDsrPercent.toStringAsFixed(1)}%* (Had Bank: ${res.dsrLimitPercent.toInt()}%)\n'
        '• *Status Kelulusan:* $statusEmoji *${res.status == DsrStatus.healthy ? 'SIHAT' : res.status == DsrStatus.moderate ? 'SEDERHANA' : 'TINGGI'}*\n'
        '---------------------------------\n'
        '🎯 *KAPASITI MAKSIMUM*\n'
        '• *Baki Had Ansuran Baru:* *${_fmt(res.maxEligibleMonthlyInstallment)}/bulan*\n'
        '• *Anggaran Harga Rumah Layak:* *${_fmt(res.maxEligiblePropertyPrice)}*\n'
        '• *Anggaran Pinjaman Maksimum:* *${_fmt(res.maxEligibleLoanAmount)}*'
        '$sig';
  }

  static String formatLppsaWhatsApp({
    required LppsaResult res,
    required String lang,
    AgentProfile? agent,
  }) {
    final sig = _buildAgentSignature(agent);
    final statusEmoji = res.isEligible ? '✅' : '⚠️';

    if (lang == 'zh') {
      return '🏛️ *【公务员房屋贷款 (LPPSA) 评估】*\n\n'
          '👤 *申请方案:* ${res.scheme == 'skim1' ? '方案一 (首次贷款)' : '方案二 (第二次贷款)'}\n'
          '💼 *符合资格总薪资:* ${_fmt(res.qualifyingIncome)}\n'
          '⚖️ *最高允许每月扣款上限:* ${_fmt(res.maxAllowableMonthlyDeduction)}\n'
          '---------------------------------\n'
          '📊 *评估结果: $statusEmoji ${res.isEligible ? '完全符合申请资格' : '超出规定上限'}*\n'
          '• *每月供款额:* *${_fmt(res.monthlyInstallment)}/月*\n'
          '• *法定年利率:* 4.0%\n'
          '• *最长贷款年限:* ${res.maxTenureYears} 年\n'
          '• *最高可申请贷款额度:* *${_fmt(res.maxEligibleLoanAmount)}*\n'
          '• *扣除新房贷后每月净薪:* *${_fmt(res.netTakeHomeAfterLoan)}/月*\n'
          '${res.rejectionReason != null ? '\n⚠️ *诊断提示:* ${res.rejectionReason}\n' : ''}'
          '$sig';
    }

    if (lang == 'en') {
      return '🏛️ *[LPPSA GOVERNMENT HOUSING LOAN ASSESSMENT]*\n\n'
          '👤 *Financing Scheme:* ${res.scheme == 'skim1' ? 'Scheme 1 (First Loan)' : 'Scheme 2 (Second Loan)'}\n'
          '💼 *Qualifying Income:* ${_fmt(res.qualifyingIncome)}\n'
          '⚖️ *Max. Allowable Monthly Deduction:* ${_fmt(res.maxAllowableMonthlyDeduction)}\n'
          '---------------------------------\n'
          '📊 *APPLICATION STATUS: $statusEmoji ${res.isEligible ? 'ELIGIBLE TO APPLY' : 'EXCEEDS CEILING'}*\n'
          '• *Requested Monthly Installment:* *${_fmt(res.monthlyInstallment)}/month*\n'
          '• *Fixed Interest Rate:* 4.0% p.a.\n'
          '• *Max Loan Tenure:* ${res.maxTenureYears} Years\n'
          '• *Max. Eligible Loan Capacity:* *${_fmt(res.maxEligibleLoanAmount)}*\n'
          '• *Estimated Net Take-Home Pay:* *${_fmt(res.netTakeHomeAfterLoan)}/month*\n'
          '${res.rejectionReason != null ? '\n⚠️ *Diagnostic:* ${res.rejectionReason}\n' : ''}'
          '$sig';
    }

    return '🏛️ *[SEMAKAN KELAYAKAN PINJAMAN KERAJAAN (LPPSA)]*\n\n'
        '👤 *Skim Dimohon:* ${res.scheme == 'skim1' ? 'Skim 1 (Pinjaman Pertama)' : 'Skim 2 (Pinjaman Kedua)'}\n'
        '💼 *Gaji Kelayakan:* ${_fmt(res.qualifyingIncome)}\n'
        '⚖️ *Had Potongan Bulanan Dibenarkan:* ${_fmt(res.maxAllowableMonthlyDeduction)}\n'
        '---------------------------------\n'
        '📊 *STATUS KELAYAKAN: $statusEmoji ${res.isEligible ? 'LAYAK MEMOHON' : 'MELEBIHI HAD KELAYAKAN'}*\n'
        '• *Ansuran Bulanan Hartanah:* *${_fmt(res.monthlyInstallment)}/bulan*\n'
        '• *Kadar Faedah Tetap:* 4.0% setahun\n'
        '• *Tempoh Maksimum Pinjaman:* ${res.maxTenureYears} Tahun\n'
        '• *Kelayakan Pinjaman Maksimum:* *${_fmt(res.maxEligibleLoanAmount)}*\n'
        '• *Anggaran Gaji Bersih Selepas Pinjaman:* *${_fmt(res.netTakeHomeAfterLoan)}/bulan*\n'
        '${res.rejectionReason != null ? '\n⚠️ *Sebab / Nota:* ${res.rejectionReason}\n' : ''}'
        '$sig';
  }

  static Future<void> launchWhatsApp(String text, [String? targetPhone]) async {
    String cleanPhone = targetPhone?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    if (cleanPhone.startsWith('01')) {
      cleanPhone = '6$cleanPhone';
    }
    final encoded = Uri.encodeComponent(text);

    // If target phone is provided, use direct phone chat
    // If no phone, use whatsapp://send?text= to open WhatsApp contact chooser
    final List<Uri> urisToTry = [];

    if (cleanPhone.isNotEmpty) {
      urisToTry.add(Uri.parse('whatsapp://send?phone=$cleanPhone&text=$encoded'));
      urisToTry.add(Uri.parse('https://wa.me/$cleanPhone?text=$encoded'));
    } else {
      urisToTry.add(Uri.parse('whatsapp://send?text=$encoded'));
      urisToTry.add(Uri.parse('https://api.whatsapp.com/send?text=$encoded'));
    }

    bool launched = false;
    for (final uri in urisToTry) {
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          launched = true;
          break;
        }
      } catch (_) {}
    }

    if (!launched) {
      // Fallback: Copy to clipboard
      await Clipboard.setData(ClipboardData(text: text));
    }
  }
}
