class ChildFinance {
  final int id;
  final int childId;
  final int sessionId; // السنة الدراسية
  final String kindSubscription; // نوع الاشتراك
  final num amountBase;
  final num amountSub;
  final num discount;
  final int? busLineId;
  final String? busLineName;
  final String? sessionName;

  ChildFinance({
    required this.id,
    required this.childId,
    required this.sessionId,
    required this.kindSubscription,
    required this.amountBase,
    required this.amountSub,
    required this.discount,
    this.busLineId,
    this.busLineName,
    this.sessionName,
  });

  factory ChildFinance.fromJson(Map<String, dynamic> json) {
    return ChildFinance(
      id: json['ID'] ?? 0,
      childId: json['Child_Id'] ?? 0,
      sessionId: json['SessionID'] ?? 0,
      kindSubscription: json['Kind_subscrip'] ?? '',
      amountBase: json['amountBase'] ?? 0,
      amountSub: json['amount_Sub'] ?? 0,
      discount: json['discount'] ?? 0,
      busLineId: json['BusLine'],
      busLineName: json['BusLineName'],
      sessionName: json['SessionName'],
    );
  }
}