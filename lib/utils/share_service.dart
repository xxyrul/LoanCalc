import 'dart:math';
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
    final isNewLaunch = res.category == PropertyCategory.newLaunch;
    final catHeader = isNewLaunch
        ? (lang == 'zh' ? '【新楼盘/发展商项目报价】' : lang == 'en' ? '[PRE / NEW LAUNCH PACKAGE]' : '[PAKEJ PROJEK BARU / UNDERCON]')
        : (lang == 'zh' ? '【二手房产/Subsale 买卖报价】' : lang == 'en' ? '[SUBSALE PROPERTY QUOTATION]' : '[SEBUTHARGA HARTANAH SUBSALE]');

    if (lang == 'zh') {
      return '🏡 *$catHeader*\n\n'
          '💰 *房产价格 (SPA):* ${_fmt(res.propertyPrice)}\n'
          '${res.developerDiscountAmount > 0 ? '🎁 *发展商回扣 (${res.developerDiscountPercent.toInt()}%):* -${_fmt(res.developerDiscountAmount)}\n' : ''}'
          '💵 *实际需付首付:* ${_fmt(max(0.0, res.downPaymentAmount - res.developerDiscountAmount))}\n'
          '🏦 *房贷额 (Base):* ${_fmt(res.loanAmount)}\n'
          '${res.totalFinancedLoan > res.loanAmount ? '💳 *房贷总额 (含保险/杂费):* *${_fmt(res.totalFinancedLoan)}*\n' : ''}'
          '---------------------------------\n'
          '📊 *每月供款估算*\n'
          '• *每月供款额:* *${_fmt(res.monthlyInstallmentWithInsurance)}/月*\n'
          '• 建议家庭最低净月入: ${_fmt(res.recommendedIncome)}\n'
          '${res.pricePsf != null ? '• 尺价 (PSF): RM ${res.pricePsf!.toStringAsFixed(1)}/sqft\n' : ''}'
          '${res.rentalYield != null ? '• 预估租金回报率: ${res.rentalYield!.toStringAsFixed(2)}%\n' : ''}'
          '---------------------------------\n'
          '💼 *置产前期头期现金 (Entry Cost)*\n'
          '• 现金头期: ${_fmt(max(0.0, res.downPaymentAmount - res.developerDiscountAmount))}\n'
          '• 买卖合约印花税 (MOT): ${res.freeSpaMot ? 'RM 0 *(发展商全免)*' : _fmt(res.stampDuty)}\n'
          '• 买卖律师费: ${res.freeSpaLegal ? 'RM 0 *(发展商全免)*' : _fmt(res.legalFees)}\n'
          '• 贷款律师费与印花税: ${res.freeLoanLegal || res.financeLoanDoc ? (res.financeLoanDoc ? 'RM 0 *(计入房贷)*' : 'RM 0 *(免除)*') : _fmt(res.loanLegalFees + res.loanStampDuty)}\n'
          '• 估价费: ${res.financeValuation ? 'RM 0 *(计入房贷)*' : _fmt(res.valuationFee)}\n'
          '${res.clttMrttAmount > 0 ? '• ${res.insuranceType} 寿险: ${res.clttMrttFinanced ? 'RM 0 *(已计入房贷)*' : _fmt(res.clttMrttAmount)}\n' : ''}'
          '👉 *总计需准备现金:* *${_fmt(res.totalUpfrontWithInsurance)}*'
          '$sig';
    }

    if (lang == 'en') {
      return '🏡 *$catHeader*\n\n'
          '💰 *Property Price (SPA):* ${_fmt(res.propertyPrice)}\n'
          '${res.developerDiscountAmount > 0 ? '🎁 *Developer Rebate (${res.developerDiscountPercent.toInt()}%):* -${_fmt(res.developerDiscountAmount)}\n' : ''}'
          '💵 *Net Cash Downpayment:* ${_fmt(max(0.0, res.downPaymentAmount - res.developerDiscountAmount))}\n'
          '🏦 *Base Loan Amount:* ${_fmt(res.loanAmount)}\n'
          '${res.totalFinancedLoan > res.loanAmount ? '💳 *Total Financed Loan:* *${_fmt(res.totalFinancedLoan)}*\n' : ''}'
          '---------------------------------\n'
          '📊 *MONTHLY ESTIMATION*\n'
          '• *Monthly Instalment:* *${_fmt(res.monthlyInstallmentWithInsurance)}/month*\n'
          '• Min. Recommended Household Net Income: ${_fmt(res.recommendedIncome)}\n'
          '${res.pricePsf != null ? '• Price PSF: RM ${res.pricePsf!.toStringAsFixed(1)}/sqft\n' : ''}'
          '${res.rentalYield != null ? '• Gross Rental Yield: ${res.rentalYield!.toStringAsFixed(2)}%\n' : ''}'
          '---------------------------------\n'
          '💼 *INITIAL CASH REQUIRED (ENTRY COST)*\n'
          '• Cash Downpayment: ${_fmt(max(0.0, res.downPaymentAmount - res.developerDiscountAmount))}\n'
          '• SPA Stamp Duty (MOT): ${res.freeSpaMot ? 'RM 0 *(Free / Absorbed)*' : _fmt(res.stampDuty)}\n'
          '• SPA Legal Fees: ${res.freeSpaLegal ? 'RM 0 *(Free / Absorbed)*' : _fmt(res.legalFees)}\n'
          '• Loan Legal & Stamp Duty: ${res.freeLoanLegal || res.financeLoanDoc ? (res.financeLoanDoc ? 'RM 0 *(Financed)*' : 'RM 0 *(Free)*') : _fmt(res.loanLegalFees + res.loanStampDuty)}\n'
          '• Valuation Fee: ${res.financeValuation ? 'RM 0 *(Financed)*' : _fmt(res.valuationFee)}\n'
          '${res.clttMrttAmount > 0 ? '• ${res.insuranceType}: ${res.clttMrttFinanced ? 'RM 0 *(Financed into Loan)*' : _fmt(res.clttMrttAmount)}\n' : ''}'
          '👉 *TOTAL INITIAL CASH:* *${_fmt(res.totalUpfrontWithInsurance)}*'
          '$sig';
    }

    // Default: BM
    return '🏡 *$catHeader*\n\n'
        '💰 *Harga Hartanah (SPA):* ${_fmt(res.propertyPrice)}\n'
        '${res.developerDiscountAmount > 0 ? '🎁 *Rebat Pemaju (${res.developerDiscountPercent.toInt()}%):* -${_fmt(res.developerDiscountAmount)}\n' : ''}'
        '💵 *Deposit Bersih Tunai:* ${_fmt(max(0.0, res.downPaymentAmount - res.developerDiscountAmount))}\n'
        '🏦 *Pinjaman Asas:* ${_fmt(res.loanAmount)}\n'
        '${res.totalFinancedLoan > res.loanAmount ? '💳 *Jumlah Pinjaman Dibiayai:* *${_fmt(res.totalFinancedLoan)}*\n' : ''}'
        '---------------------------------\n'
        '📊 *ANGGARAN BULANAN*\n'
        '• *Ansuran Bulanan:* *${_fmt(res.monthlyInstallmentWithInsurance)}/bulan*\n'
        '• Cadangan Gaji Bersih Minimum: ${_fmt(res.recommendedIncome)}\n'
        '${res.pricePsf != null ? '• Harga Sekaki (PSF): RM ${res.pricePsf!.toStringAsFixed(1)}/sqft\n' : ''}'
        '${res.rentalYield != null ? '• Hasil Sewaan Kasar (Yield): ${res.rentalYield!.toStringAsFixed(2)}%\n' : ''}'
        '---------------------------------\n'
        '💼 *TUNAI DIPERLUKAN (KOS MASUK)*\n'
        '• Deposit Tunai: ${_fmt(max(0.0, res.downPaymentAmount - res.developerDiscountAmount))}\n'
        '• Duti Setem MOT: ${res.freeSpaMot ? 'RM 0 *(Ditanggung Pemaju)*' : _fmt(res.stampDuty)}\n'
        '• Yuran Guaman SPA: ${res.freeSpaLegal ? 'RM 0 *(Ditanggung Pemaju)*' : _fmt(res.legalFees)}\n'
        '• Guaman & Duti Pinjaman: ${res.freeLoanLegal || res.financeLoanDoc ? (res.financeLoanDoc ? 'RM 0 *(Dimasukkan Pinjaman)*' : 'RM 0 *(Percuma)*') : _fmt(res.loanLegalFees + res.loanStampDuty)}\n'
        '• Yuran Penilaian: ${res.financeValuation ? 'RM 0 *(Dimasukkan Pinjaman)*' : _fmt(res.valuationFee)}\n'
        '${res.clttMrttAmount > 0 ? '• ${res.insuranceType}: ${res.clttMrttFinanced ? 'RM 0 *(Dimasukkan Pinjaman)*' : _fmt(res.clttMrttAmount)}\n' : ''}'
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
