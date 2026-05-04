class SessionOverviewModel {
  final int sessionId;
  final String sessionName;
  final int totalRecords;
  final int uniqueChildrenCount;
  final int activeChildrenCount;
  final int withdrawnChildrenCount;
  final int studyCount;
  final int busCount;
  final double studyTotal;
  final double busTotal;
  final DateTime? firstSubDate;
  final DateTime? lastSubDate;

  SessionOverviewModel({
    required this.sessionId,
    required this.sessionName,
    required this.totalRecords,
    required this.uniqueChildrenCount,
    required this.activeChildrenCount,
    required this.withdrawnChildrenCount,
    required this.studyCount,
    required this.busCount,
    required this.studyTotal,
    required this.busTotal,
    required this.firstSubDate,
    required this.lastSubDate,
  });

  factory SessionOverviewModel.fromJson(Map<String, dynamic> json) {
    return SessionOverviewModel(
      sessionId: json['sessionId'] ?? 0,
      sessionName: json['sessionName'] ?? '',
      totalRecords: json['totalRecords'] ?? 0,
      uniqueChildrenCount: json['uniqueChildrenCount'] ?? 0,
      activeChildrenCount: json['activeChildrenCount'] ?? 0,
      withdrawnChildrenCount: json['withdrawnChildrenCount'] ?? 0,
      studyCount: json['studyCount'] ?? 0,
      busCount: json['busCount'] ?? 0,
      studyTotal: (json['studyTotal'] ?? 0).toDouble(),
      busTotal: (json['busTotal'] ?? 0).toDouble(),
      firstSubDate: json['firstSubDate'] != null
          ? DateTime.tryParse(json['firstSubDate'])
          : null,
      lastSubDate: json['lastSubDate'] != null
          ? DateTime.tryParse(json['lastSubDate'])
          : null,
    );
  }
}