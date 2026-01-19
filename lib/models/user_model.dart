class User {
  final int userId;
  final String fullName;
  final String role;
  final int? empId;

  User({
    required this.userId,
    required this.fullName,
    required this.role,
    this.empId,
  });

  // دالة بتحول الـ JSON اللي جاي من السيرفر لـ User Object
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['UserId'] ?? 0, // لو الرقم مش موجود حط 0
      fullName: json['FullName'] ?? '', // لو الاسم مش موجود حط فاضي
      role: json['Role'] ?? '',
      empId: json['EmpID'],
    );
  }

  // دالة بتحول الـ User Object لـ JSON (لو حبينا نحفظه)
  Map<String, dynamic> toJson() {
    return {
      'UserId': userId,
      'FullName': fullName,
      'Role': role,
      'EmpID': empId,
    };
  }
}

// كلاس الصلاحيات (عشان نعرف نخفي الزراير)
class Permission {
  final String screenName;
  final bool canAdd;
  final bool canEdit;
  final bool canDelete;
  final bool canView;

  Permission({
    required this.screenName,
    required this.canAdd,
    required this.canEdit,
    required this.canDelete,
    required this.canView,
  });

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      screenName: json['fname'] ?? '',
      canAdd: json['canAdd'] ?? false,
      canEdit: json['canEdit'] ?? false,
      canDelete: json['canDelete'] ?? false,
      canView: json['canview'] ?? false, // لاحظ الـ v صغيرة زي الباك اند
    );
  }
}