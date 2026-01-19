class Employee {
  final int id;
  final String empName;
  final String? mobile1;
  final String? job;
  final num? nationalID;
  final bool status; // Active
  final String? branchName;
  final String? managementName;
  final int? branchId;      
  final int? workerTypeId; 

  Employee({
    required this.id,
    required this.empName,
    this.mobile1,
    this.job,
    this.nationalID,
    required this.status,
    this.branchName,
    this.managementName,
    this.branchId,
    this.workerTypeId,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['ID'] ?? 0,
      empName: json['empName'] ?? 'بدون اسم',
      mobile1: json['mobile1'],
      job: json['job'],
      nationalID: json['nationalID'],
      
      // تأمين الـ Boolean (ساعات بيجي 1/0 وساعات true/false)
      status: json['empstatus'] == true || json['empstatus'] == 1,
      
      branchName: json['branchName'],
      managementName: json['ManagmentName'], // تأكد من الاسم في الباك اند
      
      branchId: json['BranchID'],
      workerTypeId: json['workerTypeId'], // الاسم اللي غيرناه في الاستعلام
    );
  }
}