class PayrollModel {
  final int empId;
  final String empName;
  final String? mobile1;
  final String? job;
  final int? branchId;
  final String? branchName;
  final int? workerTypeId;
  final String? workerTypeName;

  // البنود القابلة للتعديل
  double baseSalary;
  double extraTime;      // الإضافي
  double badal;          // البدل
  double reward;         // المكافأة
  double penalty;        // الجزاءات (اشراف + تاخير)
  double busSub;         // اشتراك الباص
  double qstSolfa;       // قسط السلفة
  double solfa;          // السلفة المصروفة
  int absenceDays;       // عدد أيام الغياب
  double absenceAmount;  // مبلغ الغياب
  String? notes;         // ملاحظات

  bool isSelected;

  PayrollModel({
    required this.empId,
    required this.empName,
    this.mobile1,
    this.job,
    this.branchId,
    this.branchName,
    this.workerTypeId,
    this.workerTypeName,
    required this.baseSalary,
    required this.extraTime,
    required this.badal,
    required this.reward,
    required this.penalty,
    required this.busSub,
    required this.qstSolfa,
    required this.solfa,
    required this.absenceDays,
    required this.absenceAmount,
    this.notes,
    this.isSelected = true,
  });

  // ======== إجمالي الاستحقاقات ========
  double get totalAdditions => baseSalary + extraTime + badal + reward;

  // ======== إجمالي الاستقطاعات ========
  double get totalDeductions => penalty + busSub + absenceAmount + qstSolfa;

  // ======== صافي الموظف (للواتساب) ========
  double get netForEmployee => totalAdditions - totalDeductions;

  // ======== صافي التسجيل (للـ DB - يشمل السلفة) ========
  double get netForDB => netForEmployee + solfa;

  // ======== من JSON (من الباك إند) ========
  factory PayrollModel.fromJson(Map<String, dynamic> json) {
    return PayrollModel(
      empId: json['EmpID'] ?? 0,
      empName: json['empName'] ?? 'بدون اسم',
      mobile1: json['mobile1'],
      job: json['job'],
      branchId: json['BranchID'],
      branchName: json['branchName'],
      workerTypeId: json['workerTypeId'],
      workerTypeName: json['workdescription'],
      baseSalary: _toDouble(json['BaseSalary']),
      extraTime: _toDouble(json['extraTime']),
      badal: _toDouble(json['badal']),
      reward: _toDouble(json['Reward']),
      penalty: _toDouble(json['penalty']),
      busSub: _toDouble(json['busSub']),
      qstSolfa: _toDouble(json['qstSolfa']),
      solfa: _toDouble(json['Solfa']),
      absenceDays: json['AbsenceDays'] ?? 0,
      absenceAmount: _toDouble(json['absenceAmount']),
      notes: json['Notes'],
    );
  }

  // ======== إلى JSON (للباك إند) ========
  Map<String, dynamic> toJson() {
    return {
      'EmpID': empId,
      'empName': empName,
      'mobile1': mobile1,
      'job': job,
      'BranchID': branchId,
      'workerTypeId': workerTypeId,
      'BaseSalary': baseSalary,
      'extraTime': extraTime,
      'badal': badal,
      'Reward': reward,
      'penalty': penalty,
      'busSub': busSub,
      'qstSolfa': qstSolfa,
      'Solfa': solfa,
      'AbsenceDays': absenceDays,
      'absenceAmount': absenceAmount,
      'netForEmployee': netForEmployee,
      'netForDB': netForDB,
      'Notes': notes ?? '',
    };
  }

  // ======== Helper: تحويل آمن لـ double ========
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

// ======== موديل الاستجابة من الباك إند ========
class PayrollResponse {
  final String status; // 'approved' أو 'draft'
  final int? expenseId;
  final List<PayrollModel> data;

  PayrollResponse({
    required this.status,
    this.expenseId,
    required this.data,
  });

  factory PayrollResponse.fromJson(Map<String, dynamic> json) {
    List<dynamic> dataList = json['data'] ?? [];
    return PayrollResponse(
      status: json['status'] ?? 'draft',
      expenseId: json['expenseId'],
      data: dataList.map((e) => PayrollModel.fromJson(e)).toList(),
    );
  }

  // هل الرواتب معتمدة؟
  bool get isApproved => status == 'approved';

  // هل مسودة؟
  bool get isDraft => status == 'draft';
}