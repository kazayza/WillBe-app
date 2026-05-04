import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/payroll_model.dart';
import '../services/payroll_api_service.dart';
import '../services/api_service.dart';
import '../services/payroll_pdf_service.dart';
import '../services/payroll_excel_service.dart';
import '../theme/app_colors.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({Key? key}) : super(key: key);

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  final PayrollApiService _apiService = PayrollApiService();
  final TextEditingController _searchController = TextEditingController();

  // ======== البيانات ========
  List<PayrollModel> _employees = [];
  List<PayrollModel> _previousMonthEmployees = []; // للمقارنة
  List<Map<String, dynamic>> _branches = [];
  List<Map<String, dynamic>> _workerTypes = [];

  // ======== حالة الشاشة ========
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isExporting = false;
  String _status = '';
  int? _expenseId;
  String _searchQuery = '';
  bool _hasUnsavedChanges = false;
  bool _isStatsExpanded = true;
  bool _isFiltersExpanded = true;
  bool _showComparison = false;

  // ======== الترتيب ========
  String _sortBy = 'name';
  bool _sortAscending = true;

  // ======== الفلاتر ========
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  int? _selectedBranchId;
  int? _selectedWorkerTypeId;

  final List<String> _monthNames = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==============================================================
  // 📊 الخصائص المحسوبة
  // ==============================================================
  List<PayrollModel> get _filteredEmployees {
    List<PayrollModel> list = _employees;
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((emp) =>
              emp.empName.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    list = List.from(list);
    switch (_sortBy) {
      case 'name':
        list.sort((a, b) => _sortAscending
            ? a.empName.compareTo(b.empName)
            : b.empName.compareTo(a.empName));
        break;
      case 'code':
        list.sort((a, b) => _sortAscending
            ? a.empId.compareTo(b.empId)
            : b.empId.compareTo(a.empId));
        break;
      case 'net':
        list.sort((a, b) => _sortAscending
            ? a.netForEmployee.compareTo(b.netForEmployee)
            : b.netForEmployee.compareTo(a.netForEmployee));
        break;
      case 'absence':
        list.sort((a, b) => _sortAscending
            ? a.absenceDays.compareTo(b.absenceDays)
            : b.absenceDays.compareTo(a.absenceDays));
        break;
    }
    return list;
  }

  bool get _isApproved => _status == 'approved';
  int get _selectedCount => _employees.where((e) => e.isSelected).length;
  bool get _isAllSelected =>
      _filteredEmployees.isNotEmpty &&
      _filteredEmployees.every((e) => e.isSelected);

  double get _totalAdditions => _employees
      .where((e) => e.isSelected)
      .fold(0.0, (sum, emp) => sum + emp.totalAdditions);

  double get _totalDeductions => _employees
      .where((e) => e.isSelected)
      .fold(0.0, (sum, emp) => sum + emp.totalDeductions);

  double get _totalSolfa => _employees
      .where((e) => e.isSelected)
      .fold(0.0, (sum, emp) => sum + emp.solfa);

  double get _totalNetForEmployee => _employees
      .where((e) => e.isSelected)
      .fold(0.0, (sum, emp) => sum + emp.netForEmployee);

  int get _absentEmployeesCount =>
      _employees.where((e) => e.absenceDays > 0).length;
  int get _loanEmployeesCount =>
      _employees.where((e) => e.solfa > 0 || e.qstSolfa > 0).length;
  int get _negativeNetCount =>
      _employees.where((e) => e.netForEmployee < 0).length;

  // ==============================================================
  // 🔔 عرض رسالة
  // ==============================================================
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ==============================================================
  // 🔄 تحميل البيانات المرجعية
  // ==============================================================
  Future<void> _loadLookups() async {
    try {
      final branchesResponse = await ApiService.get('/general/branches');
      if (branchesResponse != null && branchesResponse is List) {
        setState(() => _branches = List<Map<String, dynamic>>.from(branchesResponse));
      }
      final workerTypesResponse = await ApiService.get('/general/worker-types');
      if (workerTypesResponse != null && workerTypesResponse is List) {
        setState(() => _workerTypes = List<Map<String, dynamic>>.from(workerTypesResponse));
      }
    } catch (e) {
      print('خطأ في تحميل البيانات المرجعية: $e');
    }
  }

  // ==============================================================
  // 📥 جلب الرواتب
  // ==============================================================
  Future<void> _fetchPayroll() async {
    if (_hasUnsavedChanges) {
      final confirm = await _showUnsavedChangesDialog();
      if (confirm == null) return;
      if (confirm == true) await _saveDraft();
    }

    setState(() {
      _isLoading = true;
      _employees = [];
      _status = '';
      _expenseId = null;
      _searchQuery = '';
      _searchController.clear();
      _hasUnsavedChanges = false;
      _showComparison = false;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
final userName = auth.user?.fullName ?? 'System';

final response = await _apiService.fetchPayroll(
  month: _selectedMonth,
  year: _selectedYear,
  branchId: _selectedBranchId,
  workerTypeId: _selectedWorkerTypeId,
  user: userName,
);

      setState(() {
        _employees = response.data;
        _status = response.status;
        _expenseId = response.expenseId;
        _isFiltersExpanded = false;
      });

      // تنبيه الصافي السالب
      final negativeCount = _employees.where((e) => e.netForEmployee < 0).length;
      if (negativeCount > 0) {
        _showNegativeAlert(negativeCount);
      }

      if (mounted) {
        _showSnackBar(
          _isApproved ? '📂 رواتب معتمدة' : '📝 تم تحميل المسودة',
          _isApproved ? AppColors.payrollApproved : AppColors.primary,
        );
      }
    } catch (e) {
      if (mounted) _showSnackBar('❌ خطأ: $e', AppColors.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ==============================================================
  // 🔔 تنبيه الصافي السالب
  // ==============================================================
  void _showNegativeAlert(int count) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.getCard(context),
        icon: const Icon(Icons.warning_amber, color: AppColors.error, size: 48),
        title: Text(
          '⚠️ تنبيه مهم',
          style: TextStyle(color: AppColors.getText(context), fontWeight: FontWeight.bold),
        ),
        content: Text(
          'يوجد $count موظف/ين لديهم صافي راتب سالب!\n'
          'يرجى مراجعة بياناتهم قبل الاعتماد.',
          style: TextStyle(color: AppColors.getText(context)),
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حسناً', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // 📊 جلب بيانات المقارنة الشهرية
  // ==============================================================
  Future<void> _fetchComparison() async {
  final prevMonth = _selectedMonth == 1 ? 12 : _selectedMonth - 1;
  final prevYear = _selectedMonth == 1 ? _selectedYear - 1 : _selectedYear;

  try {
    final response = await _apiService.fetchPayroll(
      month: prevMonth,
      year: prevYear,
      branchId: _selectedBranchId,
      workerTypeId: _selectedWorkerTypeId,
      user: Provider.of<AuthProvider>(context, listen: false).user?.fullName ?? 'System',
    );

    // ✅ نستخدم بيانات المقارنة فقط لو كانت معتمدة
    if (response.status == 'approved') {
      setState(() {
        _previousMonthEmployees = response.data;
        _showComparison = true;
      });
    } else {
      // ❌ لو مش معتمدة، مش نعرض مقارنة
      _showSnackBar(
        '⚠️ لا توجد رواتب معتمدة للشهر السابق (${_monthNames[prevMonth - 1]} $prevYear)',
        AppColors.warning,
      );
    }
  } catch (e) {
    _showSnackBar('❌ فشل جلب بيانات المقارنة', AppColors.error);
  }
}

  // ==============================================================
  // 💾 حفظ التعديلات
  // ==============================================================
  Future<void> _saveDraft() async {
    if (_isSaving || _expenseId == null) return;
    final selectedEmployees = _employees.where((e) => e.isSelected).toList();
    if (selectedEmployees.isEmpty) {
      _showSnackBar('⚠️ حدد موظف واحد على الأقل', AppColors.warning);
      return;
    }
    setState(() => _isSaving = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
final userName = auth.user?.fullName ?? 'System';

final success = await _apiService.updateDraft(
  expenseId: _expenseId!,
  user: userName,
  payrollList: selectedEmployees,
);
      if (success) {
        setState(() => _hasUnsavedChanges = false);
        _showSnackBar('💾 تم حفظ التعديلات', AppColors.success);
      } else {
        _showSnackBar('❌ فشل الحفظ', AppColors.error);
      }
    } catch (e) {
      _showSnackBar('❌ خطأ: $e', AppColors.error);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ==============================================================
  // ✅ اعتماد الرواتب
  // ==============================================================
  Future<void> _approvePayroll() async {
    if (_isSaving || _expenseId == null) return;
    final selectedEmployees = _employees.where((e) => e.isSelected).toList();
    if (selectedEmployees.isEmpty) {
      _showSnackBar('⚠️ حدد موظف واحد على الأقل', AppColors.warning);
      return;
    }

    // تحذير إضافي لو فيه صافي سالب
    final negativeEmps = selectedEmployees.where((e) => e.netForEmployee < 0).toList();
    if (negativeEmps.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.getCard(context),
          icon: const Icon(Icons.warning_amber, color: AppColors.error, size: 40),
          title: Text('تحذير: صافي سالب',
              style: TextStyle(color: AppColors.getText(context))),
          content: Text(
            '${negativeEmps.length} موظف/ين لديهم صافي سالب:\n'
            '${negativeEmps.map((e) => e.empName).join('\n')}\n\n'
            'هل تريد المتابعة؟',
            style: TextStyle(color: AppColors.getText(context)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('متابعة', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.getCard(context),
        title: Text('⚠️ تأكيد الاعتماد النهائي',
            style: TextStyle(color: AppColors.getText(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('شهر: ${_monthNames[_selectedMonth - 1]} $_selectedYear',
                style: TextStyle(color: AppColors.getText(context))),
            const SizedBox(height: 8),
            Text('عدد الموظفين: ${selectedEmployees.length}',
                style: TextStyle(color: AppColors.getText(context))),
            Text('إجمالي الاستحقاقات: ${_totalAdditions.toStringAsFixed(2)} ج',
                style: TextStyle(color: AppColors.getText(context))),
            Text('إجمالي الاستقطاعات: ${_totalDeductions.toStringAsFixed(2)} ج',
                style: TextStyle(color: AppColors.getText(context))),
            Text('إجمالي السلف: ${_totalSolfa.toStringAsFixed(2)} ج',
                style: TextStyle(color: AppColors.getText(context))),
            Divider(color: AppColors.getBorder(context)),
            Text(
              'صافي المطلوب: ${_totalNetForEmployee.toStringAsFixed(2)} ج',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.getText(context)),
            ),
            const SizedBox(height: 12),
            const Text('⚠️ بعد الاعتماد لن تتمكن من التعديل!',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('اعتماد نهائي', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() { _isSaving = true; _isLoading = true; });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
final userName = auth.user?.fullName ?? 'System';

await _apiService.updateDraft(
  expenseId: _expenseId!,
  user: userName,
  payrollList: selectedEmployees,
);
      final success = await _apiService.approvePayroll(
  expenseId: _expenseId!,
  month: _selectedMonth,
  year: _selectedYear,
  user: userName,
);
      if (success) {
        setState(() => _hasUnsavedChanges = false);
        _showSnackBar('✅ تم الاعتماد بنجاح', AppColors.success);
        await _sendApprovalNotification(selectedEmployees);
        await _fetchPayroll();
      } else {
        _showSnackBar('❌ فشل الاعتماد', AppColors.error);
      }
    } catch (e) {
      _showSnackBar('❌ خطأ: $e', AppColors.error);
    } finally {
      setState(() { _isSaving = false; _isLoading = false; });
    }
  }
   // ==============================================================
  // 📲 إرسال إشعار واتساب للإدارة بعد الاعتماد
  // ==============================================================
  Future<void> _sendApprovalNotification(List<PayrollModel> selectedEmployees) async {
    const String adminPhone = '+201556700816';

    final double totalNet = selectedEmployees.fold(
        0.0, (sum, emp) => sum + emp.netForEmployee);
    final double totalSolfa = selectedEmployees.fold(
        0.0, (sum, emp) => sum + emp.solfa);
    final double totalExpense = totalNet + totalSolfa;

    final String message = '''
📋 *تقرير صرف رواتب — ${_monthNames[_selectedMonth - 1]} $_selectedYear*
ـــــــــــــــــــــــــــــــــ
▸ عدد الموظفين: ${selectedEmployees.length}
▸ إجمالي صافي الرواتب: ${_formatNumber(totalNet)} ج
▸ إجمالي السلف: ${_formatNumber(totalSolfa)} ج
ـــــــــــــــــــــــــــــــــ
💰 *إجمالي المنصرف: ${_formatNumber(totalExpense)} ج*
ـــــــــــــــــــــــــــــــــ
🏢 *إدارة الحسابات*
''';

    try {
      final Uri url = Uri.parse(
          "https://wa.me/$adminPhone?text=${Uri.encodeComponent(message)}");
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('❌ فشل فتح واتساب', AppColors.error);
      }
    } catch (e) {
      _showSnackBar('❌ خطأ في إرسال الإشعار: $e', AppColors.error);
    }
  }

  String _formatNumber(double number) {
    String numStr = number.toStringAsFixed(0);
    String result = '';
    int count = 0;
    for (int i = numStr.length - 1; i >= 0; i--) {
      count++;
      result = numStr[i] + result;
      if (count % 3 == 0 && i != 0 && numStr[i] != '-') {
        result = ',$result';
      }
    }
    return result;
  }

  // ==============================================================
  // 📄 تصدير PDF - كشف كامل
  // ==============================================================
  Future<void> _exportFullPDF() async {
    final selectedEmps = _employees.where((e) => e.isSelected).toList();
    if (selectedEmps.isEmpty) {
      _showSnackBar('⚠️ حدد موظف واحد على الأقل', AppColors.warning);
      return;
    }

    setState(() => _isExporting = true);
    try {
      final pdfBytes = await PayrollPdfService.generatePayrollSheet(
        employees: _employees,
        month: _selectedMonth,
        year: _selectedYear,
        monthName: _monthNames[_selectedMonth - 1],
      );

      await Printing.layoutPdf(
        onLayout: (_) => pdfBytes,
        name: 'كشف_رواتب_${_monthNames[_selectedMonth - 1]}_$_selectedYear',
      );
    } catch (e) {
      _showSnackBar('❌ خطأ في إنشاء PDF: $e', AppColors.error);
    } finally {
      setState(() => _isExporting = false);
    }
  }

  // ==============================================================
  // 📄 تصدير PDF - مشاركة
  // ==============================================================
  Future<void> _sharePDF() async {
    final selectedEmps = _employees.where((e) => e.isSelected).toList();
    if (selectedEmps.isEmpty) {
      _showSnackBar('⚠️ حدد موظف واحد على الأقل', AppColors.warning);
      return;
    }

    setState(() => _isExporting = true);
    try {
      final pdfBytes = await PayrollPdfService.generatePayrollSheet(
        employees: _employees,
        month: _selectedMonth,
        year: _selectedYear,
        monthName: _monthNames[_selectedMonth - 1],
      );

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/payroll_${_selectedMonth}_$_selectedYear.pdf');
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'كشف رواتب شهر ${_monthNames[_selectedMonth - 1]} $_selectedYear',
      );
    } catch (e) {
      _showSnackBar('❌ خطأ في المشاركة: $e', AppColors.error);
    } finally {
      setState(() => _isExporting = false);
    }
  }

  // ==============================================================
  // 📊 تصدير Excel
  // ==============================================================
  Future<void> _exportExcel() async {
    final selectedEmps = _employees.where((e) => e.isSelected).toList();
    if (selectedEmps.isEmpty) {
      _showSnackBar('⚠️ حدد موظف واحد على الأقل', AppColors.warning);
      return;
    }

    setState(() => _isExporting = true);
    try {
      final filePath = await PayrollExcelService.generatePayrollExcel(
        employees: _employees,
        month: _selectedMonth,
        year: _selectedYear,
        monthName: _monthNames[_selectedMonth - 1],
      );

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'كشف رواتب Excel - ${_monthNames[_selectedMonth - 1]} $_selectedYear',
      );

      _showSnackBar('✅ تم تصدير Excel بنجاح', AppColors.success);
    } catch (e) {
      _showSnackBar('❌ خطأ في Excel: $e', AppColors.error);
    } finally {
      setState(() => _isExporting = false);
    }
  }

  // ==============================================================
  // 🧾 شريط قبض PDF لموظف واحد
  // ==============================================================
  Future<void> _generatePaySlip(PayrollModel emp) async {
    setState(() => _isExporting = true);
    try {
      final pdfBytes = await PayrollPdfService.generatePaySlip(
        employee: emp,
        month: _selectedMonth,
        year: _selectedYear,
        monthName: _monthNames[_selectedMonth - 1],
      );

      // خيار: طباعة أو مشاركة
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.getCard(context),
          title: Text('شريط قبض - ${emp.empName}',
              style: TextStyle(color: AppColors.getText(context))),
          content: Text('اختر الإجراء:',
              style: TextStyle(color: AppColors.getText(context))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx, 'share'),
              icon: const Icon(Icons.share),
              label: const Text('مشاركة'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx, 'print'),
              icon: const Icon(Icons.print),
              label: const Text('طباعة'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            ),
          ],
        ),
      );

      if (choice == 'print') {
        await Printing.layoutPdf(
          onLayout: (_) => pdfBytes,
          name: 'شريط_قبض_${emp.empName}',
        );
      } else if (choice == 'share') {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/payslip_${emp.empId}.pdf');
        await file.writeAsBytes(pdfBytes);

        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'شريط قبض ${emp.empName} - ${_monthNames[_selectedMonth - 1]} $_selectedYear',
        );
      }
    } catch (e) {
      _showSnackBar('❌ خطأ في إنشاء الشريط: $e', AppColors.error);
    } finally {
      setState(() => _isExporting = false);
    }
  }

  // ==============================================================
  // 📲 واتساب مع PDF
  // ==============================================================
  Future<void> _sendWhatsAppWithPDF(PayrollModel emp) async {
    if (emp.mobile1 == null || emp.mobile1!.isEmpty) {
      _showSnackBar('⚠️ لا يوجد رقم موبايل', AppColors.warning);
      return;
    }

    try {
      // إنشاء PDF
      final pdfBytes = await PayrollPdfService.generatePaySlip(
        employee: emp,
        month: _selectedMonth,
        year: _selectedYear,
        monthName: _monthNames[_selectedMonth - 1],
      );

      // حفظ الملف
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/payslip_${emp.empId}.pdf');
      await file.writeAsBytes(pdfBytes);

      // مشاركة عبر واتساب
      String phone = emp.mobile1!.replaceAll(' ', '').replaceAll('-', '');
      if (phone.startsWith('0')) phone = phone.substring(1);
      if (!phone.startsWith('+20')) phone = '+20$phone';

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '🏢 *${emp.empName}*\nشريط قبض شهر ${_monthNames[_selectedMonth - 1]} $_selectedYear\nصافي: ${emp.netForEmployee.toStringAsFixed(2)} ج',
      );
    } catch (e) {
      _showSnackBar('❌ خطأ: $e', AppColors.error);
    }
  }

  // ==============================================================
  // 📲 إرسال واتساب نصي لموظف
  // ==============================================================
  Future<void> _sendWhatsAppToEmployee(PayrollModel emp) async {
    if (emp.mobile1 == null || emp.mobile1!.isEmpty) {
      _showSnackBar('⚠️ لا يوجد رقم موبايل', AppColors.warning);
      return;
    }

    // خيار: رسالة نصية أو PDF
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.getCard(context),
        title: Text('إرسال لـ ${emp.empName}',
            style: TextStyle(color: AppColors.getText(context))),
        content: Text('اختر طريقة الإرسال:',
            style: TextStyle(color: AppColors.getText(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, 'text'),
            icon: const Icon(Icons.message),
            label: const Text('رسالة نصية'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, 'pdf'),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('PDF'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          ),
        ],
      ),
    );

    if (choice == 'text') {
      await _sendTextWhatsApp(emp);
    } else if (choice == 'pdf') {
      await _sendWhatsAppWithPDF(emp);
    }
  }

  Future<void> _sendTextWhatsApp(PayrollModel emp) async {
    String phone = emp.mobile1!.replaceAll(' ', '').replaceAll('-', '');
    if (phone.startsWith('0')) phone = phone.substring(1);
    if (!phone.startsWith('+20')) phone = '+20$phone';

    String message = _buildWhatsAppMessage(emp);
    bool success = false;
    try {
      Uri url = Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(message)}");
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        success = true;
      }
    } catch (e) {
      success = false;
    }
    if (mounted) {
      _showSnackBar(
        success ? '✅ تم فتح واتساب' : '❌ فشل فتح واتساب',
        success ? AppColors.success : AppColors.error,
      );
    }
  }

  // ==============================================================
  // 📲 إرسال واتساب لكل المحددين
  // ==============================================================
  Future<void> _sendWhatsApp() async {
    final selectedEmployees = _employees.where((e) => e.isSelected).toList();
    if (selectedEmployees.isEmpty) {
      _showSnackBar('⚠️ حدد الموظفين أولاً', AppColors.warning);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.getCard(context),
        title: Text('📲 تأكيد إرسال الواتساب',
            style: TextStyle(color: AppColors.getText(context))),
        content: Text(
          'إرسال لـ ${selectedEmployees.length} موظف.\nالرجاء الضغط على "إرسال" في كل محادثة.',
          style: TextStyle(color: AppColors.getText(context)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('بدء', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    int sentCount = 0;
    int failedCount = 0;

    for (var emp in selectedEmployees) {
      if (emp.mobile1 != null && emp.mobile1!.isNotEmpty) {
        String phone = emp.mobile1!.replaceAll(' ', '').replaceAll('-', '');
        if (phone.startsWith('0')) phone = phone.substring(1);
        if (!phone.startsWith('+20')) phone = '+20$phone';

        try {
          Uri url = Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(_buildWhatsAppMessage(emp))}");
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
            sentCount++;
            await Future.delayed(const Duration(seconds: 3));
          } else {
            failedCount++;
          }
        } catch (e) {
          failedCount++;
        }
      } else {
        failedCount++;
      }
    }

    if (mounted) {
      _showSnackBar(
        '✅ $sentCount تم${failedCount > 0 ? ' | ⚠️ $failedCount فشل' : ''}',
        AppColors.success,
      );
    }
  }

  String _buildWhatsAppMessage(PayrollModel emp) {
    return '''
🏢 *ًWillBe Kindergarten*

أ. *${emp.empName}*،
إشعار صرف راتب شهر ${_monthNames[_selectedMonth - 1]}/$_selectedYear. 💰

🟢 *الاستحقاقات:* ${emp.totalAdditions.toStringAsFixed(2)} ج
   • أساسي: ${emp.baseSalary.toStringAsFixed(2)}
   • إضافي: ${emp.extraTime.toStringAsFixed(2)}
   • بدل: ${emp.badal.toStringAsFixed(2)}
   • مكافأة: ${emp.reward.toStringAsFixed(2)}

🔴 *الاستقطاعات:* ${emp.totalDeductions.toStringAsFixed(2)} ج
   • جزاءات: ${emp.penalty.toStringAsFixed(2)}
   • باص: ${emp.busSub.toStringAsFixed(2)}
   • غياب (${emp.absenceDays} يوم): ${emp.absenceAmount.toStringAsFixed(2)}
   • قسط سلفة: ${emp.qstSolfa.toStringAsFixed(2)}

💵 *صافي الراتب:* *${emp.netForEmployee.toStringAsFixed(2)} ج*

إدراة الموارد البشرية - WillBe Kindergarten
''';
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      for (var emp in _filteredEmployees) {
        emp.isSelected = value ?? false;
      }
    });
  }

  Future<bool?> _showUnsavedChangesDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.getCard(context),
        title: Text('⚠️ تعديلات غير محفوظة',
            style: TextStyle(color: AppColors.getText(context))),
        content: Text('هل تريد حفظ التعديلات؟',
            style: TextStyle(color: AppColors.getText(context))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('تجاهل', style: TextStyle(color: AppColors.error)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.getCard(context),
        title: Text('ترتيب حسب',
            style: TextStyle(color: AppColors.getText(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sortOption('الاسم', 'name', Icons.sort_by_alpha),
            _sortOption('كود الموظف', 'code', Icons.badge),
            _sortOption('الصافي', 'net', Icons.attach_money),
            _sortOption('أيام الغياب', 'absence', Icons.event_busy),
          ],
        ),
      ),
    );
  }

  Widget _sortOption(String label, String value, IconData icon) {
    final isSelected = _sortBy == value;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primary : AppColors.getTextSecondary(context)),
      title: Text(label, style: TextStyle(color: AppColors.getText(context))),
      trailing: isSelected
          ? Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, color: AppColors.primary)
          : null,
      selected: isSelected,
      onTap: () {
        setState(() {
          if (_sortBy == value) {
            _sortAscending = !_sortAscending;
          } else {
            _sortBy = value;
            _sortAscending = true;
          }
        });
        Navigator.pop(context);
      },
    );
  }

  // ==============================================================
  // 📋 شاشة تفاصيل الموظف (Bottom Sheet)
  // ==============================================================
  void _showEmployeeDetails(PayrollModel emp) {
    // البحث عن بيانات الشهر السابق لنفس الموظف
    PayrollModel? prevEmp;
    if (_previousMonthEmployees.isNotEmpty) {
      try {
        prevEmp = _previousMonthEmployees.firstWhere((e) => e.empId == emp.empId);
      } catch (e) {
        prevEmp = null;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.getCard(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: DraggableScrollableSheet(
                initialChildSize: 0.9,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                expand: false,
                builder: (context, scrollController) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: ListView(
                      controller: scrollController,
                      children: [
                        // المقبض
                        Center(
                          child: Container(
                            width: 50, height: 5,
                            decoration: BoxDecoration(
                              color: AppColors.getBorder(context),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // كود + اسم الموظف
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.primary),
                              ),
                              child: Text('#${emp.empId}',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(emp.empName,
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.getText(context))),
                            ),
                          ],
                        ),
                        if (emp.job != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('${emp.job} | ${emp.branchName ?? ''}',
                                style: TextStyle(fontSize: 13, color: AppColors.getTextSecondary(context))),
                          ),

                        // مؤشرات الحالة
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: [
                            if (emp.absenceDays > 0) _statusChip('غياب ${emp.absenceDays} يوم', AppColors.warning),
                            if (emp.solfa > 0) _statusChip('سلفة ${emp.solfa.toStringAsFixed(0)}', AppColors.payrollAdvance),
                            if (emp.netForEmployee < 0) _statusChip('⚠️ صافي سالب', AppColors.error),
                          ],
                        ),

                        // مقارنة بالشهر السابق
                        if (prevEmp != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.infoLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.info),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _comparisonItem('الشهر الحالي',
                                    emp.netForEmployee, AppColors.primary),
                                const Icon(Icons.compare_arrows, color: AppColors.info),
                                _comparisonItem('الشهر السابق',
                                    prevEmp.netForEmployee, AppColors.getTextSecondary(context)),
                                _comparisonDiff(emp.netForEmployee - prevEmp.netForEmployee),
                              ],
                            ),
                          ),
                        ],

                        Divider(height: 24, color: AppColors.getBorder(context)),

                        // ======== الاستحقاقات ========
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: AppColors.getAdditionsCardDecoration(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.arrow_upward, color: AppColors.payrollAdditions, size: 20),
                                  SizedBox(width: 8),
                                  Text('الاستحقاقات',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                                          color: AppColors.payrollAdditions)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildEditableRow('الراتب الأساسي', emp.baseSalary, (val) {
                                setModalState(() => emp.baseSalary = val);
                                setState(() => _hasUnsavedChanges = true);
                              }, AppColors.payrollAdditions),
                              _buildEditableRow('الإضافي', emp.extraTime, (val) {
                                setModalState(() => emp.extraTime = val);
                                setState(() => _hasUnsavedChanges = true);
                              }, AppColors.payrollAdditions),
                              _buildEditableRow('البدل', emp.badal, (val) {
                                setModalState(() => emp.badal = val);
                                setState(() => _hasUnsavedChanges = true);
                              }, AppColors.payrollAdditions),
                              _buildEditableRow('المكافأة', emp.reward, (val) {
                                setModalState(() => emp.reward = val);
                                setState(() => _hasUnsavedChanges = true);
                              }, AppColors.payrollAdditions),
                              const Divider(color: AppColors.payrollAdditions),
                              _buildTotalRow('إجمالي الاستحقاقات', emp.totalAdditions, AppColors.payrollAdditions),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ======== الاستقطاعات ========
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: AppColors.getDeductionsCardDecoration(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.arrow_downward, color: AppColors.payrollDeductions, size: 20),
                                  SizedBox(width: 8),
                                  Text('الاستقطاعات',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                                          color: AppColors.payrollDeductions)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildEditableRow('الجزاءات', emp.penalty, (val) {
                                setModalState(() => emp.penalty = val);
                                setState(() => _hasUnsavedChanges = true);
                              }, AppColors.payrollDeductions),
                              _buildEditableRow('اشتراك الباص', emp.busSub, (val) {
                                setModalState(() => emp.busSub = val);
                                setState(() => _hasUnsavedChanges = true);
                              }, AppColors.payrollDeductions),
                              _buildEditableRow('الغياب (${emp.absenceDays} يوم)', emp.absenceAmount, (val) {
                                setModalState(() => emp.absenceAmount = val);
                                setState(() => _hasUnsavedChanges = true);
                              }, AppColors.payrollDeductions),
                              _buildEditableRow('قسط سلفة', emp.qstSolfa, (val) {
                                setModalState(() => emp.qstSolfa = val);
                                setState(() => _hasUnsavedChanges = true);
                              }, AppColors.payrollDeductions),
                              const Divider(color: AppColors.payrollDeductions),
                              _buildTotalRow('إجمالي الاستقطاعات', emp.totalDeductions, AppColors.payrollDeductions),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // السلفة
                        if (emp.solfa > 0)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: AppColors.getAdvanceCardDecoration(),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, color: AppColors.payrollAdvance),
                                const SizedBox(width: 8),
                                Text('السلفة المصروفة: ${emp.solfa.toStringAsFixed(2)} ج',
                                    style: const TextStyle(color: AppColors.payrollAdvance,
                                        fontWeight: FontWeight.bold, fontSize: 15)),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),

                        // ملاحظات
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.warningLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.warning, width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('📝 ملاحظات',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                              const SizedBox(height: 8),
                              TextFormField(
                                initialValue: emp.notes ?? '',
                                maxLines: 3,
                                readOnly: _isApproved,
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                                decoration: InputDecoration(
                                  hintText: 'أضف ملاحظة...',
                                  hintStyle: const TextStyle(color: Colors.black38),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  filled: true,
                                  fillColor: _isApproved ? Colors.grey.shade200 : Colors.white,
                                ),
                                onChanged: (val) {
                                  emp.notes = val;
                                  _hasUnsavedChanges = true;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // الصافي
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: AppColors.getNetGradient(emp.netForEmployee >= 0),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Text('💵 صافي الموظف',
                                  style: TextStyle(fontSize: 16, color: Colors.white70)),
                              const SizedBox(height: 8),
                              Text('${emp.netForEmployee.toStringAsFixed(2)} ج',
                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // أزرار Bottom Sheet
                        if (!_isApproved)
                          ElevatedButton.icon(
                            onPressed: () { _saveDraft(); Navigator.pop(context); },
                            icon: const Icon(Icons.save),
                            label: const Text('💾 حفظ التعديلات'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.payrollDraft,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        const SizedBox(height: 8),

                        // شريط قبض PDF
                        ElevatedButton.icon(
                          onPressed: _isExporting ? null : () => _generatePaySlip(emp),
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('🧾 شريط قبض PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // واتساب
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _sendWhatsAppToEmployee(emp);
                          },
                          icon: const Icon(Icons.send, color: AppColors.success),
                          label: Text('📲 إرسال لـ ${emp.empName}',
                              style: const TextStyle(color: AppColors.success)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.success),
                            padding: const EdgeInsets.all(14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _comparisonItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: AppColors.getTextSecondary(context))),
        Text('${value.toStringAsFixed(0)} ج',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _comparisonDiff(double diff) {
    final isPositive = diff >= 0;
    return Column(
      children: [
        Icon(isPositive ? Icons.trending_up : Icons.trending_down,
            color: isPositive ? AppColors.success : AppColors.error, size: 20),
        Text('${diff.toStringAsFixed(0)} ج',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                color: isPositive ? AppColors.success : AppColors.error)),
      ],
    );
  }

  Widget _statusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }

  // ======== سطر قابل للتعديل - مع إصلاح الألوان ========
  Widget _buildEditableRow(String label, double value,
      Function(double) onChanged, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
          ),
          Expanded(
            flex: 1,
            child: TextFormField(
              initialValue: value.toStringAsFixed(2),
              keyboardType: TextInputType.number,
              readOnly: _isApproved,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: accentColor),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: accentColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: accentColor, width: 2),
                ),
                filled: true,
                fillColor: _isApproved ? Colors.grey.shade200 : Colors.white,
              ),
              onChanged: (val) {
                double newValue = double.tryParse(val) ?? 0.0;
                onChanged(newValue);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          Text('${value.toStringAsFixed(2)} ج',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildMiniChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }

  // ==============================================================
  // 🎨 بناء الواجهة الرئيسية
  // ==============================================================
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_hasUnsavedChanges) {
          final result = await _showUnsavedChangesDialog();
          if (result == null) return false;
          if (result == true) await _saveDraft();
          return true;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.getBg(context),
        appBar: AppBar(
          title: const Text('إدارة الرواتب'),
          centerTitle: true,
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          actions: [
            if (_employees.isNotEmpty) ...[
              // زر المقارنة
              IconButton(
                icon: Icon(_showComparison ? Icons.compare_arrows : Icons.compare,
                    color: _showComparison ? AppColors.warning : Colors.white),
                tooltip: 'مقارنة بالشهر السابق',
                onPressed: _showComparison
                    ? () => setState(() { _showComparison = false; _previousMonthEmployees = []; })
                    : _fetchComparison,
              ),
              // قائمة التصدير
              PopupMenuButton<String>(
                icon: _isExporting
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.download, color: Colors.white),
                color: AppColors.getCard(context),
                tooltip: 'تصدير',
                onSelected: (value) async {
                  switch (value) {
                    case 'pdf_print': await _exportFullPDF(); break;
                    case 'pdf_share': await _sharePDF(); break;
                    case 'excel': await _exportExcel(); break;
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'pdf_print',
                    child: Row(
                      children: [
                        const Icon(Icons.print, color: AppColors.error),
                        const SizedBox(width: 8),
                        Text('طباعة PDF', style: TextStyle(color: AppColors.getText(context))),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'pdf_share',
                    child: Row(
                      children: [
                        const Icon(Icons.share, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text('مشاركة PDF', style: TextStyle(color: AppColors.getText(context))),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'excel',
                    child: Row(
                      children: [
                        const Icon(Icons.table_chart, color: AppColors.success),
                        const SizedBox(width: 8),
                        Text('تصدير Excel', style: TextStyle(color: AppColors.getText(context))),
                      ],
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.sort, color: Colors.white),
                onPressed: _showSortDialog,
                tooltip: 'ترتيب',
              ),
            ],
          ],
        ),
        body: Column(
          children: [
            _buildCollapsibleFilters(),
            if (_employees.isNotEmpty) _buildStatusBanner(),
            if (_employees.isNotEmpty) _buildCollapsibleStats(),
            if (_employees.isNotEmpty) _buildSearchAndSelectAll(),
            Expanded(child: _buildEmployeeList()),
            if (_employees.isNotEmpty) _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // 🎛️ فلاتر قابلة للطي
  // ==============================================================
  Widget _buildCollapsibleFilters() {
    return Container(
      color: AppColors.getBg(context),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isFiltersExpanded = !_isFiltersExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.primaryDark.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.filter_list, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'الفلاتر: ${_monthNames[_selectedMonth - 1]} $_selectedYear',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.getText(context)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (!_isFiltersExpanded)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: SizedBox(
                            height: 32,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _fetchPayroll,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              child: _isLoading
                                  ? const SizedBox(width: 16, height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('جلب', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ),
                      Icon(
                        _isFiltersExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (_isFiltersExpanded) ...[
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _selectedMonth,
                      decoration: InputDecoration(
                        labelText: 'الشهر',
                        labelStyle: TextStyle(color: AppColors.getTextSecondary(context)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        filled: true,
                        fillColor: AppColors.getCard(context),
                      ),
                      dropdownColor: AppColors.getCard(context),
                      style: TextStyle(color: AppColors.getText(context)),
                      items: List.generate(12, (index) =>
                          DropdownMenuItem(value: index + 1, child: Text(_monthNames[index]))),
                      onChanged: (val) => setState(() => _selectedMonth = val!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _selectedYear,
                      decoration: InputDecoration(
                        labelText: 'السنة',
                        labelStyle: TextStyle(color: AppColors.getTextSecondary(context)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        filled: true,
                        fillColor: AppColors.getCard(context),
                      ),
                      dropdownColor: AppColors.getCard(context),
                      style: TextStyle(color: AppColors.getText(context)),
                      items: [2024, 2025, 2026].map((y) =>
                          DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                      onChanged: (val) => setState(() => _selectedYear = val!),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      initialValue: _selectedBranchId,
                      decoration: InputDecoration(
                        labelText: 'الفرع',
                        labelStyle: TextStyle(color: AppColors.getTextSecondary(context)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        filled: true,
                        fillColor: AppColors.getCard(context),
                      ),
                      dropdownColor: AppColors.getCard(context),
                      style: TextStyle(color: AppColors.getText(context)),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('الكل')),
                        ..._branches.map((b) => DropdownMenuItem<int?>(
                            value: b['IDbranch'], child: Text(b['branchName'] ?? ''))),
                      ],
                      onChanged: (val) => setState(() => _selectedBranchId = val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      initialValue: _selectedWorkerTypeId,
                      decoration: InputDecoration(
                        labelText: 'نوع العمالة',
                        labelStyle: TextStyle(color: AppColors.getTextSecondary(context)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        filled: true,
                        fillColor: AppColors.getCard(context),
                      ),
                      dropdownColor: AppColors.getCard(context),
                      style: TextStyle(color: AppColors.getText(context)),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('الكل')),
                        ..._workerTypes.map((w) => DropdownMenuItem<int?>(
                            value: w['ID'], child: Text(w['workdescription'] ?? ''))),
                      ],
                      onChanged: (val) => setState(() => _selectedWorkerTypeId = val),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _fetchPayroll,
                  icon: _isLoading
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.search),
                  label: const Text('جلب الرواتب'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==============================================================
  // 📊 بانر الحالة
  // ==============================================================
  Widget _buildStatusBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: _isApproved
          ? AppColors.getApprovedCardDecoration()
          : AppColors.getDraftCardDecoration(),
      child: Row(
        children: [
          Icon(
            _isApproved ? Icons.verified : Icons.edit_note,
            color: _isApproved ? AppColors.payrollApproved : AppColors.payrollDraft,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isApproved
                  ? '✅ رواتب معتمدة - للعرض وإرسال الواتساب فقط'
                  : '📝 مسودة - يمكنك التعديل ثم الحفظ أو الاعتماد',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: _isApproved ? AppColors.payrollApproved : AppColors.payrollDraft,
              ),
            ),
          ),
          if (_hasUnsavedChanges && !_isApproved)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(12)),
              child: const Text('غير محفوظ',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  // ==============================================================
  // 📊 إحصائيات قابلة للطي
  // ==============================================================
  Widget _buildCollapsibleStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isStatsExpanded = !_isStatsExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('📊 الإحصائيات والملخص المالي',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.info)),
                  Icon(_isStatsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: AppColors.info),
                ],
              ),
            ),
          ),

          if (_isStatsExpanded) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _buildSummaryCard('الاستحقاقات', _totalAdditions, Icons.arrow_upward,
                    AppColors.payrollAdditions, AppColors.payrollAdditionsLight),
                const SizedBox(width: 8),
                _buildSummaryCard('الاستقطاعات', _totalDeductions, Icons.arrow_downward,
                    AppColors.payrollDeductions, AppColors.payrollDeductionsLight),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildSummaryCard('السلف', _totalSolfa, Icons.money_off,
                    AppColors.payrollAdvance, AppColors.payrollAdvanceLight),
                const SizedBox(width: 8),
                _buildSummaryCard('صافي المطلوب', _totalNetForEmployee, Icons.account_balance_wallet,
                    AppColors.primary, AppColors.infoLight),
                const SizedBox(width: 8),
                _buildCountCard(),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildQuickStat('🟠 غياب', _absentEmployeesCount, AppColors.warning),
                const SizedBox(width: 8),
                _buildQuickStat('🟣 سلف', _loanEmployeesCount, AppColors.payrollAdvance),
                const SizedBox(width: 8),
                _buildQuickStat('🔴 سالب', _negativeNetCount, AppColors.error),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, double value, IconData icon, Color color, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Flexible(child: Text(title,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                    overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(child: Text('${value.toStringAsFixed(0)} ج',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color))),
          ],
        ),
      ),
    );
  }

  Widget _buildCountCard() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: AppColors.getCountCardDecoration(),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people, size: 14, color: AppColors.payrollCount),
                SizedBox(width: 4),
                Text('الموظفين',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.payrollCount)),
              ],
            ),
            const SizedBox(height: 4),
            Text('$_selectedCount / ${_employees.length}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.payrollCount)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(child: Text(label,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color))),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
              child: Text('$count',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // 🔍 البحث وتحديد الكل
  // ==============================================================
  Widget _buildSearchAndSelectAll() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            style: TextStyle(color: AppColors.getText(context)),
            decoration: InputDecoration(
              hintText: 'بحث بالاسم...',
              hintStyle: TextStyle(color: AppColors.getTextSecondary(context)),
              prefixIcon: Icon(Icons.search, size: 20, color: AppColors.getTextSecondary(context)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, size: 20, color: AppColors.getTextSecondary(context)),
                      onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); })
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
              filled: true,
              fillColor: AppColors.getCard(context),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                height: 24, width: 24,
                child: Checkbox(
                  value: _isAllSelected,
                  onChanged: _isApproved ? null : _toggleSelectAll,
                  activeColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text('تحديد الكل',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.getText(context))),
              const Spacer(),
              if (_showComparison)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.warning),
                  ),
                  child: const Text('🔄 وضع المقارنة',
                      style: TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // 📋 كارت الموظف
  // ==============================================================
  Widget _buildEmployeeCard(PayrollModel emp) {
    final isNegative = emp.netForEmployee < 0;
    final hasAbsence = emp.absenceDays > 0;
    final hasLoan = emp.solfa > 0 || emp.qstSolfa > 0;

    Color sideColor = Colors.transparent;
    if (isNegative) {
      sideColor = AppColors.error;
    } else if (hasAbsence) sideColor = AppColors.warning;
    else if (hasLoan) sideColor = AppColors.payrollAdvance;

    // بيانات المقارنة
    PayrollModel? prevEmp;
    if (_showComparison && _previousMonthEmployees.isNotEmpty) {
      try {
        prevEmp = _previousMonthEmployees.firstWhere((e) => e.empId == emp.empId);
      } catch (e) {
        prevEmp = null;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      color: AppColors.getCard(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.getBorder(context)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: sideColor,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                leading: Checkbox(
                  value: emp.isSelected,
                  onChanged: _isApproved ? null : (val) => setState(() => emp.isSelected = val ?? false),
                  activeColor: AppColors.primary,
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(left: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('#${emp.empId}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                    Expanded(
                      child: Text(emp.empName,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.getText(context)),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (isNegative) const Icon(Icons.warning_amber, color: AppColors.error, size: 18),
                    if (_isApproved) Icon(Icons.lock, size: 14, color: AppColors.getTextSecondary(context)),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(emp.job ?? 'بدون وظيفة',
                        style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(context))),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        _buildMiniChip('صافي: ${emp.netForEmployee.toStringAsFixed(0)} ج',
                            isNegative ? AppColors.error : AppColors.primary),
                        if (hasLoan)
                          _buildMiniChip('سلفة: ${emp.solfa.toStringAsFixed(0)}', AppColors.payrollAdvance),
                        if (hasAbsence)
                          _buildMiniChip('غياب: ${emp.absenceDays} يوم', AppColors.warning),
                        // مقارنة الصافي
                        if (prevEmp != null)
                          _buildMiniChip(
                            '${emp.netForEmployee >= prevEmp.netForEmployee ? '▲' : '▼'} ${(emp.netForEmployee - prevEmp.netForEmployee).abs().toStringAsFixed(0)}',
                            emp.netForEmployee >= prevEmp.netForEmployee ? AppColors.success : AppColors.error,
                          ),
                      ],
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.receipt_long, color: AppColors.primary, size: 24),
                  onPressed: () => _showEmployeeDetails(emp),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // 📋 قائمة الموظفين
  // ==============================================================
  Widget _buildEmployeeList() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text('جاري التحميل...', style: TextStyle(color: AppColors.getTextSecondary(context))),
          ],
        ),
      );
    }

    if (_employees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.request_quote_outlined, size: 80, color: AppColors.getTextSecondary(context)),
            const SizedBox(height: 16),
            Text('اختر الشهر والسنة ثم اضغط "جلب"',
                style: TextStyle(fontSize: 16, color: AppColors.getTextSecondary(context))),
          ],
        ),
      );
    }

    final filteredList = _filteredEmployees;
    if (filteredList.isEmpty) {
      return Center(
        child: Text('لا توجد نتائج',
            style: TextStyle(fontSize: 16, color: AppColors.getTextSecondary(context))),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: filteredList.length,
      itemBuilder: (context, index) => _buildEmployeeCard(filteredList[index]),
    );
  }

  // ==============================================================
  // 🔘 أزرار الإجراءات
  // ==============================================================
  Widget _buildActionButtons() {
    if (_isApproved) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : _sendWhatsApp,
          icon: const Icon(Icons.send_rounded),
          label: Text('📲 إرسال واتساب للمحددين ($_selectedCount)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (_isLoading || _isSaving) ? null : _saveDraft,
                  icon: _isSaving
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: const Text('💾 حفظ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.payrollDraft,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (_isLoading || _isSaving) ? null : _approvePayroll,
                  icon: const Icon(Icons.verified),
                  label: const Text('✅ اعتماد'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _sendWhatsApp,
              icon: const Icon(Icons.send_rounded, color: AppColors.success),
              label: Text('📲 إرسال واتساب ($_selectedCount)',
                  style: const TextStyle(color: AppColors.success)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.success),
                padding: const EdgeInsets.all(14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}