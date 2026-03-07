// ==================== LEAD MODEL ====================
class Lead {
  final int? leadId;
  final String fullName;
  final String phone;
  final String? email;
  final int? childAge;
  final String? leadSource;
  final int? sourceId;
  final String? interestedProgram;
  final int? branchId;
  final int? assignedTo;
  final String? branchName;
  final String? sourceName;
  final String? assignedToName;
  final String status;
  final String? notes;
  final DateTime? nextFollowUp;
  final DateTime? contactDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? conversionDate;
  final int? convertedToCustomerId;
  final String? userAdd;
  final DateTime? addTime;
  final String? useredit;
  final DateTime? editTime;

  Lead({
    this.leadId,
    required this.fullName,
    required this.phone,
    this.email,
    this.childAge,
    this.leadSource,
    this.sourceId,
    this.interestedProgram,
    this.branchId,
    this.assignedTo,
    this.branchName,
    this.sourceName,
    this.assignedToName,
    required this.status,
    this.notes,
    this.nextFollowUp,
    this.contactDate,
    this.createdAt,
    this.updatedAt,
    this.conversionDate,
    this.convertedToCustomerId,
    this.userAdd,
    this.addTime,
    this.useredit,
    this.editTime,
  });

  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
      leadId: json['LeadID'],
      fullName: json['FullName'] ?? '',
      phone: json['Phone'] ?? '',
      email: json['Email'],
      childAge: json['ChildAge'],
      leadSource: json['LeadSource'],
      sourceId: json['SourceID'],
      interestedProgram: json['InterestedProgram'],
      branchId: json['BranchPreference'],
      assignedTo: json['AssignedTo'],
      branchName: json['BranchName'],
      sourceName: json['SourceName'],
      assignedToName: json['AssignedToName'],
      status: json['Status'] ?? 'New',
      notes: json['Notes'],
      nextFollowUp: json['NextFollowUp'] != null 
          ? DateTime.tryParse(json['NextFollowUp']) 
          : null,
      contactDate: json['ContactDate'] != null 
          ? DateTime.tryParse(json['ContactDate']) 
          : null,
      createdAt: json['CreatedAt'] != null 
          ? DateTime.tryParse(json['CreatedAt']) 
          : null,
      updatedAt: json['UpdatedAt'] != null 
          ? DateTime.tryParse(json['UpdatedAt']) 
          : null,
      conversionDate: json['ConversionDate'] != null 
          ? DateTime.tryParse(json['ConversionDate']) 
          : null,
      convertedToCustomerId: json['ConvertedToCustomerID'],
      userAdd: json['userAdd'],
      addTime: json['Addtime'] != null 
          ? DateTime.tryParse(json['Addtime']) 
          : null,
      useredit: json['useredit'],
      editTime: json['editTime'] != null 
          ? DateTime.tryParse(json['editTime']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'FullName': fullName,
      'Phone': phone,
      'Email': email,
      'ChildAge': childAge,
      'LeadSource': leadSource,
      'SourceID': sourceId,
      'InterestedProgram': interestedProgram,
      'BranchPreference': branchId,
      'AssignedTo': assignedTo,
      'Status': status,
      'Notes': notes,
      'NextFollowUp': nextFollowUp?.toIso8601String(),
      'userAdd': userAdd,
      'clientTime': DateTime.now().toIso8601String(),
    };
  }

  // هل هذا Lead متحول؟
  bool get isConverted => status == 'Converted';
  
  // هل فات ميعاد المتابعة؟
  bool get isOverdue {
    if (nextFollowUp == null) return false;
    return nextFollowUp!.isBefore(DateTime.now());
  }
}

// ==================== SOURCE MODEL ====================
class Source {
  final int? sourceId;
  final String sourceName;
  final String? sourceIcon;
  final String? sourceColor;
  final bool? isActive;
  final int? sortOrder;

  Source({
    this.sourceId,
    required this.sourceName,
    this.sourceIcon,
    this.sourceColor,
    this.isActive,
    this.sortOrder,
  });

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      sourceId: json['SourceID'],
      sourceName: json['SourceName'] ?? '',
      sourceIcon: json['SourceIcon'],
      sourceColor: json['SourceColor'],
      isActive: json['IsActive'] == true,
      sortOrder: json['SortOrder'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'SourceID': sourceId,
      'SourceName': sourceName,
      'SourceIcon': sourceIcon,
      'SourceColor': sourceColor,
      'IsActive': isActive,
      'SortOrder': sortOrder,
    };
  }
}

// ==================== CUSTOMER MODEL ====================
class Customer {
  final int? customerId;
  final String fullName;
  final String phone;
  final String? secondaryPhone;
  final String? email;
  final String? address;
  final int? childId;
  final String? childName;
  final String? relationship;
  final DateTime? nextFollowUpDate;
  final String? preferredContactMethod;
  final String? notes;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? userAdd;
  final DateTime? addTime;
  final String? useredit;
  final DateTime? editTime;

  Customer({
    this.customerId,
    required this.fullName,
    required this.phone,
    this.secondaryPhone,
    this.email,
    this.address,
    this.childId,
    this.childName,
    this.relationship,
    this.nextFollowUpDate,
    this.preferredContactMethod,
    this.notes,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.userAdd,
    this.addTime,
    this.useredit,
    this.editTime,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      customerId: json['CustomerID'],
      fullName: json['FullName'] ?? '',
      phone: json['Phone'] ?? '',
      secondaryPhone: json['SecondaryPhone'],
      email: json['Email'],
      address: json['Address'],
      childId: json['ChildID'],
      childName: json['ChildName'],
      relationship: json['Relationship'],
      nextFollowUpDate: json['NextFollowUpDate'] != null 
          ? DateTime.tryParse(json['NextFollowUpDate']) 
          : null,
      preferredContactMethod: json['PreferredContactMethod'],
      notes: json['Notes'],
      status: json['Status'] ?? 'Active',
      createdAt: json['CreatedAt'] != null 
          ? DateTime.tryParse(json['CreatedAt']) 
          : null,
      updatedAt: json['UpdatedAt'] != null 
          ? DateTime.tryParse(json['UpdatedAt']) 
          : null,
      userAdd: json['userAdd'],
      addTime: json['Addtime'] != null 
          ? DateTime.tryParse(json['Addtime']) 
          : null,
      useredit: json['useredit'],
      editTime: json['editTime'] != null 
          ? DateTime.tryParse(json['editTime']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'FullName': fullName,
      'Phone': phone,
      'SecondaryPhone': secondaryPhone,
      'Email': email,
      'Address': address,
      'ChildID': childId,
      'Relationship': relationship,
      'NextFollowUpDate': nextFollowUpDate?.toIso8601String(),
      'PreferredContactMethod': preferredContactMethod,
      'Notes': notes,
      'Status': status,
      'userAdd': userAdd,
      'clientTime': DateTime.now().toIso8601String(),
    };
  }

  bool get IsActive => status == 'Active';
}

// ==================== INTERACTION MODEL ====================
class Interaction {
  final int? interactionId;
  final int? customerId;
  final int? leadId