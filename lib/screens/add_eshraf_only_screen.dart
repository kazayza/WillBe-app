import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';

class AddEshrafOnlyScreen extends StatefulWidget {
  const AddEshrafOnlyScreen({Key? key}) : super(key: key);

  @override
  State<AddEshrafOnlyScreen> createState() => _AddEshrafOnlyScreenState();
}

class _AddEshrafOnlyScreenState extends State<AddEshrafOnlyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  int? _selectedEmployeeId;
  String? _selectedEmployeeName;
  String? _selectedEmployeeJob;
  
  // ✅ النوع ثابت: إشراف فقط
  final String _fixedTypeId = 'اشراف';  // 👈 غيّر الـ ID حسب الموجود عندك
  final String _fixedTypeName = 'إشراف';
  final bool _isDeduction = true; // أو false حسب نوع الإشراف عندك
  
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());

  bool _isLoading = false;
  bool _isLoadingEmployees = false;
  List<dynamic> _employees = [];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoadingEmployees = true);
    try {
      final employees = await ApiService.getEmployees();
      setState(() {
        _employees = employees;
        _isLoadingEmployees = false;
      });
    } catch (e) {
      setState(() => _isLoadingEmployees = false);
      _showErrorSnackbar('فشل تحميل الموظفين');
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = DateUtils.dateOnly(picked));
    }
  }

  Future<void> _saveEshraf() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployeeId == null) {
      _showErrorSnackbar('اختر الموظف');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);

      await ApiService.addEshraf({
        'empId': _selectedEmployeeId,
        'amount': double.parse(_amountController.text),
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'kind': _fixedTypeId, // ✅ النوع الثابت
        'notes': _notesController.text.trim(),
        'user': auth.user?.fullName ?? 'Unknown',
      });

      setState(() => _isLoading = false);
      _showSuccessDialog('تم تسجيل الإشراف بنجاح ✅');
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('خطأ: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 60),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('حسناً'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetForm();
            },
            child: const Text('إضافة آخر'),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _selectedEmployeeId = null;
      _selectedEmployeeName = null;
      _selectedEmployeeJob = null;
      _amountController.clear();
      _notesController.clear();
      _selectedDate = DateUtils.dateOnly(DateTime.now());
    });
  }

  void _showEmployeeBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Provider.of<ThemeProvider>(context).isDark;
        String searchQuery = '';

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filteredEmployees = searchQuery.isEmpty
                ? _employees
                : _employees.where((e) {
                    final name = (e['empName'] ?? '').toString().toLowerCase();
                    final job = (e['job'] ?? '').toString().toLowerCase();
                    return name.contains(searchQuery.toLowerCase()) ||
                        job.contains(searchQuery.toLowerCase());
                  }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'بحث عن موظف...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: isDark ? Colors.black12 : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        setSheetState(() => searchQuery = value);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'عدد النتائج: ${filteredEmployees.length}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: _isLoadingEmployees
                        ? const Center(child: CircularProgressIndicator())
                        : filteredEmployees.isEmpty
                            ? const Center(child: Text('لا يوجد موظفين'))
                            : ListView.builder(
                                itemCount: filteredEmployees.length,
                                itemBuilder: (context, index) {
                                  final emp = filteredEmployees[index];
                                  final isSelected = _selectedEmployeeId == emp['ID'];

                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isSelected
                                          ? Colors.blue
                                          : Colors.orange.shade100,
                                      child: Text(
                                        (emp['empName'] ?? '?')[0].toUpperCase(),
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      emp['empName'] ?? '',
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isDark ? Colors.white : Colors.black,
                                      ),
                                    ),
                                    subtitle: Text(emp['job'] ?? ''),
                                    trailing: isSelected
                                        ? const Icon(Icons.check_circle, color: Colors.blue)
                                        : null,
                                    onTap: () {
                                      setState(() {
                                        _selectedEmployeeId = emp['ID'];
                                        _selectedEmployeeName = emp['empName'];
                                        _selectedEmployeeJob = emp['job'];
                                      });
                                      Navigator.pop(context);
                                      HapticFeedback.selectionClick();
                                    },
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    final auth = Provider.of<AuthProvider>(context);

    // التحقق من الصلاحية
    //if (!auth.canAdd('eshraf')) {
      //return Scaffold(
        //appBar: AppBar(title: const Text('غير مصرح')),
        //body: const Center(
          //child: Text('ليس لديك صلاحية للإضافة', style: TextStyle(fontSize: 18)),
        //),
      //);
    //}

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1E) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('تسجيل إشراف'), // ✅ عنوان ثابت
        backgroundColor: Colors.orange, // ✅ لون مميز للإشراف
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // ✅ بطاقة توضيحية للنوع الثابت
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.orange.shade600],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.supervisor_account,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'نوع المعاملة',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _fixedTypeName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.lock_outline,
                      color: Colors.white54,
                      size: 20,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // اختيار الموظف
              InkWell(
                onTap: _showEmployeeBottomSheet,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedEmployeeName ?? 'اختر الموظف',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: _selectedEmployeeName != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: _selectedEmployeeName != null
                                    ? (isDark ? Colors.white : Colors.black87)
                                    : Colors.grey,
                              ),
                            ),
                            if (_selectedEmployeeJob != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                _selectedEmployeeJob!,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // التاريخ
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.orange),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('dd/MM/yyyy').format(_selectedDate),
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // المبلغ
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'المبلغ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                  suffixText: 'ج.م',
                  prefixIcon: Icon(Icons.attach_money, color: Colors.orange),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'أدخل المبلغ';
                  if (double.tryParse(value) == null) return 'رقم غير صحيح';
                  if (double.parse(value) <= 0) return 'يجب أن يكون أكبر من صفر';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ملاحظات
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'ملاحظات (اختياري)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 50),
                    child: Icon(Icons.notes, color: Colors.orange),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // زر الحفظ
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveEshraf,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'حفظ الإشراف',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}