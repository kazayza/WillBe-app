class Child {
  final int id;
  final String fullNameArabic;
  final num? nationalID;
  final String? birthDate;
  final int? age;
  final bool status; // Active or not
  final int? branchId;

  Child({
    required this.id,
    required this.fullNameArabic,
    this.nationalID,
    this.birthDate,
    this.age,
    required this.status,
    this.branchId,
  });

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: json['ID_Child'] ?? 0,
      fullNameArabic: json['FullNameArabic'] ?? 'بدون اسم',
      nationalID: json['NationalID'],
      birthDate: json['birthDate'] != null 
          ? json['birthDate'].toString().split('T')[0] 
          : null,
      age: json['Age'],
      branchId: json['Branch'],
      status: json['Status'] == true || json['Status'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'FullNameArabic': fullNameArabic,
      'NationalID': nationalID,
      'birthDate': birthDate,
    };
  }
}