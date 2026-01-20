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

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['UserId'] ?? 0,
      fullName: json['FullName'] ?? '',
      role: json['Role'] ?? '',
      empId: json['EmpID'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'UserId': userId,
      'FullName': fullName,
      'Role': role,
      'EmpID': empId,
    };
  }

  // ✅ هل المستخدم مدير؟
  bool get isAdmin =>
      role == 'Admin' || role == 'Manager' || role == 'مدير' || role == 'admin';
}

class Permission {
  final String screenName;
  final bool canAdd;
  final bool canEdit;
  final bool canDelete;
  final bool canView;
  final bool canOpen;

  Permission({
    required this.screenName,
    required this.canAdd,
    required this.canEdit,
    required this.canDelete,
    required this.canView,
    required this.canOpen,
  });

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      screenName: json['fname'] ?? '',
      canAdd: json['canAdd'] == true || json['canAdd'] == 1,
      canEdit: json['canEdit'] == true || json['canEdit'] == 1,
      canDelete: json['canDelete'] == true || json['canDelete'] == 1,
      canView: json['canview'] == true || json['canview'] == 1,
      canOpen: json['canOpen'] == true || json['canOpen'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fname': screenName,
      'canAdd': canAdd,
      'canEdit': canEdit,
      'canDelete': canDelete,
      'canview': canView,
      'canOpen': canOpen,
    };
  }

  @override
  String toString() {
    return 'Permission($screenName: open=$canOpen, view=$canView, add=$canAdd, edit=$canEdit, delete=$canDelete)';
  }
}