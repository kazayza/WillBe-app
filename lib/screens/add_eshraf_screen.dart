import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';

class AddEshrafScreen extends StatefulWidget {
  const AddEshrafScreen({Key? key}) : super(key: key);

  @override
  State<AddEshrafScreen> createState() => _AddEshrafScreenState();
}

class _AddEshrafScreenState extends State<AddEshrafScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  int? _selectedEmployeeId;
  String? _selectedEmployeeName;
  String? _selectedEmployeeJob;
  String? _selectedTypeId;
  String? _selectedTypeName;
  bool _isDeduction = true;
  DateTime _selectedDate =  DateUtils.dateOnly(DateTime.now());

  bool _isLoading = false;
  bool _isLoadingEmployees = false;
  bool _isLoadingTypes = false;
  List<dynamic> _employees = [];
  List<dynamic> _allTypes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadEmployees(),
      _loadTypes(),
    ]);
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

  Future<void> _loadTypes() async {
    setState(() => _isLoadingTypes = true);
    try {
      final types = await ApiService.getEshrafTypes();
      setState(() {
        _allTypes = types;
        _isLoadingTypes = false;
      });
    } catch (e) {
      setState(() => _isLoadingTypes = false);
    }
  }

  List<dynamic> get _filteredTypes {
    return _allTypes.where((type) {
      return _isDeduction
          ? type['type'] == 'deduction'
          : type['type'] == 'addition';
    }).toList();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // ✅ دالة الحفظ الرئيسية
  Future<void> _saveEshraf() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployeeId == null) {
      _showErrorSnackbar('اختر الموظف');
      return;
    }
    if (_selectedTypeId == null) {
      _showErrorSnackbar('اختر النوع');
      return;
    }

    // 🆕 لو النوع "سلفه" → نفتح Dialog الأقساط
    if (_selectedTypeId == 'سلفه') {
      _showLoanInstallmentsDialog();
      return;
    }

    // غير كده → نسجل عادي
    await _saveNormalTransaction();
  }

  // ✅ حفظ معاملة عادية (غير سلفة)
  Future<void> _saveNormalTransaction() async {
    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);

      await ApiService.addEshraf({
        'empId': _selectedEmployeeId,
        'amount': double.parse(_amountController.text),
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'kind': _selectedTypeId,
        'notes': _notesController.text.trim(),
        'user': auth.user?.fullName ?? 'Unknown',
      });

      setState(() => _isLoading = false);
      _showSuccessDialog('تم التسجيل بنجاح ✅');
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('خطأ: $e');
    }
  }

    // 🆕 Dialog الأقساط للسلفة
void _showLoanInstallmentsDialog() {
  final double loanAmount = double.tryParse(_amountController.text) ?? 0;
  if (loanAmount <= 0) {
    _showErrorSnackbar('أدخل مبلغ السلفة');
    return;
  }

  // ✅ التعديل 1: أول قسط بتاريخ السلفة نفسها
  int numberOfInstallments = 1;
  List<InstallmentData> installments = [
    InstallmentData(
      amount: loanAmount,
      date: _selectedDate, // 👈 تاريخ السلفة مش DateTime.now()
    ),
  ];

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      // ✅ التعديل 3: جلب حالة الـ Dark Mode
      final isDark = Provider.of<ThemeProvider>(context).isDark;
      
      return StatefulBuilder(
        builder: (context, setDialogState) {
          // حساب الإجمالي والمتبقي
          double totalInstallments = installments.fold(0, (sum, i) => sum + i.amount);
          double remaining = loanAmount - totalInstallments;

          return AlertDialog(
            // ✅ التعديل 3: لون خلفية الـ Dialog حسب الوضع
            backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.account_balance_wallet, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Text(
                  'تقسيط السلفة',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ التعديل 3: معلومات السلفة مع دعم Dark Mode
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'مبلغ السلفة:',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          Text(
                            '${NumberFormat('#,##0').format(loanAmount)} ج.م',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // عدد الأقساط
                    Row(
                      children: [
                        Text(
                          'عدد الأقساط:',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: numberOfInstallments > 1
                              ? () {
                                  setDialogState(() {
                                    numberOfInstallments--;
                                    installments.removeLast();
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          color: Colors.red,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.blue.shade900 : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$numberOfInstallments',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: isDark ? Colors.white : Colors.blue.shade700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setDialogState(() {
                              numberOfInstallments++;
                              // ✅ التعديل 1: إضافة قسط جديد بتاريخ الشهر التالي من آخر قسط
                              final lastDate = installments.isNotEmpty
                                  ? installments.last.date
                                  : _selectedDate;
                              installments.add(InstallmentData(
                                amount: 0,
                                date: DateTime(lastDate.year, lastDate.month + 1, lastDate.day),
                              ));
                            });
                          },
                          icon: const Icon(Icons.add_circle_outline),
                          color: Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // قائمة الأقساط
                    Text(
                      'تفاصيل الأقساط:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),

                    ...installments.asMap().entries.map((entry) {
                      final index = entry.key;
                      final installment = entry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade800.withOpacity(0.5) : Colors.white,
                          border: Border.all(
                            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'القسط ${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade400,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // ✅ التعديل 2: حل مشكلة الـ Overflow
                            LayoutBuilder(
                              builder: (context, constraints) {
                                // لو العرض صغير نعمل Column بدل Row
                                if (constraints.maxWidth < 280) {
                                  return Column(
                                    children: [
                                      // المبلغ
                                      TextFormField(
                                        initialValue: installment.amount > 0 
                                            ? installment.amount.toString() 
                                            : '',
                                        keyboardType: TextInputType.number,
                                        style: TextStyle(
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: 'المبلغ',
                                          labelStyle: TextStyle(
                                            color: isDark ? Colors.white60 : Colors.grey,
                                          ),
                                          suffixText: 'ج.م',
                                          suffixStyle: TextStyle(
                                            color: isDark ? Colors.white60 : Colors.grey,
                                          ),
                                          isDense: true,
                                          border: const OutlineInputBorder(),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                                            ),
                                          ),
                                        ),
                                        onChanged: (value) {
                                          setDialogState(() {
                                            installments[index].amount = 
                                                double.tryParse(value) ?? 0;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      // التاريخ
                                      _buildDatePicker(
                                        context: context,
                                        installment: installment,
                                        index: index,
                                        installments: installments,
                                        setDialogState: setDialogState,
                                        isDark: isDark,
                                      ),
                                    ],
                                  );
                                }
                                
                                // العرض الطبيعي
                                return Row(
                                  children: [
                                    // المبلغ
                                    Expanded(
                                      flex: 3,
                                      child: TextFormField(
                                        initialValue: installment.amount > 0 
                                            ? installment.amount.toString() 
                                            : '',
                                        keyboardType: TextInputType.number,
                                        style: TextStyle(
                                          color: isDark ? Colors.white : Colors.black87,
                                          fontSize: 14,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: 'المبلغ',
                                          labelStyle: TextStyle(
                                            color: isDark ? Colors.white60 : Colors.grey,
                                            fontSize: 12,
                                          ),
                                          suffixText: 'ج.م',
                                          suffixStyle: TextStyle(
                                            color: isDark ? Colors.white60 : Colors.grey,
                                            fontSize: 12,
                                          ),
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 12,
                                          ),
                                          border: const OutlineInputBorder(),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: isDark 
                                                  ? Colors.grey.shade600 
                                                  : Colors.grey.shade400,
                                            ),
                                          ),
                                        ),
                                        onChanged: (value) {
                                          setDialogState(() {
                                            installments[index].amount = 
                                                double.tryParse(value) ?? 0;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // التاريخ
                                    Expanded(
                                      flex: 3,
                                      child: _buildDatePicker(
                                        context: context,
                                        installment: installment,
                                        index: index,
                                        installments: installments,
                                        setDialogState: setDialogState,
                                        isDark: isDark,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 16),

                    // ✅ التعديل 3: الإجمالي والمتبقي مع دعم Dark Mode
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: remaining.abs() < 0.01
                            ? (isDark ? Colors.green.shade900.withOpacity(0.3) : Colors.green.shade50)
                            : (isDark ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: remaining.abs() < 0.01 ? Colors.green : Colors.red,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'إجمالي الأقساط:',
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              Text(
                                '${NumberFormat('#,##0').format(totalInstallments)} ج.م',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'المتبقي:',
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              Text(
                                '${NumberFormat('#,##0').format(remaining)} ج.م',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: remaining.abs() < 0.01 
                                      ? Colors.green 
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                          if (remaining.abs() >= 0.01) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.warning,
                                  color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    remaining > 0
                                        ? 'يجب إضافة ${NumberFormat('#,##0').format(remaining)} ج.م للأقساط'
                                        : 'الأقساط أكثر من مبلغ السلفة بـ ${NumberFormat('#,##0').format(remaining.abs())} ج.م',
                                    style: TextStyle(
                                      color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'إلغاء',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.grey,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: remaining.abs() < 0.01
                    ? () {
                        Navigator.pop(context);
                        _saveLoanWithInstallments(installments);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
                child: const Text('تأكيد وحفظ'),
              ),
            ],
          );
        },
      );
    },
  );
}

// ✅ دالة مساعدة لبناء منتقي التاريخ (لتجنب التكرار)
Widget _buildDatePicker({
  required BuildContext context,
  required InstallmentData installment,
  required int index,
  required List<InstallmentData> installments,
  required StateSetter setDialogState,
  required bool isDark,
}) {
  return InkWell(
    onTap: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: installment.date,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
      );
      if (picked != null) {
        setDialogState(() {
          installments[index].date = picked;
        });
      }
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? Colors.grey.shade600 : Colors.grey,
        ),
        borderRadius: BorderRadius.circular(4),
        color: isDark ? Colors.grey.shade800.withOpacity(0.3) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today,
            size: 14,
            color: isDark ? Colors.white60 : Colors.grey,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              DateFormat('dd/MM/yy').format(installment.date),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );
}

  // 🆕 حفظ السلفة مع الأقساط
  Future<void> _saveLoanWithInstallments(List<InstallmentData> installments) async {
    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final double loanAmount = double.parse(_amountController.text);

      // تحويل الأقساط للشكل المطلوب
      final List<Map<String, dynamic>> installmentsData = installments.map((i) => {
        'amount': i.amount,
        'date': DateFormat('yyyy-MM-dd').format(i.date),
      }).toList();

      await ApiService.addLoanWithInstallments(
        empId: _selectedEmployeeId!,
        loanAmount: loanAmount,
        loanDate: _selectedDate,
        user: auth.user?.fullName ?? 'Unknown',
        notes: _notesController.text.trim(),
        installments: installmentsData,
      );

      setState(() => _isLoading = false);
      _showSuccessDialog(
        'تم تسجيل السلفة (${NumberFormat('#,##0').format(loanAmount)} ج) مع ${installments.length} قسط بنجاح ✅',
      );
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
      _selectedTypeId = null;
      _selectedTypeName = null;
      _amountController.clear();
      _notesController.clear();
      _selectedDate = DateTime.now();
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
            final activeEmployees = _employees.where((e) {
  return e['empstatus'] == true || e['empstatus'] == 1;
}).toList();

final filteredEmployees = searchQuery.isEmpty
    ? activeEmployees
    : activeEmployees.where((e) {
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
                                          : (_isDeduction ? Colors.red.shade100 : Colors.green.shade100),
                                      child: Text(
                                        (emp['empName'] ?? '?')[0].toUpperCase(),
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : (_isDeduction ? Colors.red : Colors.green),
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

  

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1E) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(_isDeduction ? 'تسجيل خصم' : 'تسجيل إضافة'),
        backgroundColor: _isDeduction ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        elevation: 0,
      ),
      body: _isLoadingTypes
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Toggle خصم/إضافة
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildToggleButton(
                              label: 'خصم',
                              isSelected: _isDeduction,
                              color: const Color(0xFFEF4444),
                              onTap: () => setState(() {
                                _isDeduction = true;
                                _selectedTypeId = null;
                                _selectedTypeName = null;
                              }),
                            ),
                          ),
                          Expanded(
                            child: _buildToggleButton(
                              label: 'إضافة',
                              isSelected: !_isDeduction,
                              color: const Color(0xFF10B981),
                              onTap: () => setState(() {
                                _isDeduction = false;
                                _selectedTypeId = null;
                                _selectedTypeName = null;
                              }),
                            ),
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
                            Icon(
                              Icons.person_outline,
                              color: _isDeduction ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                            ),
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
                            Icon(
                              Icons.calendar_today,
                              color: _isDeduction ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                            ),
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

                    // النوع
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTypeId,
                      decoration: InputDecoration(
                        labelText: 'النوع',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                      ),
                      dropdownColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                      items: _filteredTypes.map<DropdownMenuItem<String>>((type) {
                        return DropdownMenuItem<String>(
                          value: type['id'].toString(),
                          child: Text(
                            type['name'] ?? type['id'],
                            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedTypeId = value;
                          _selectedTypeName = _filteredTypes
                              .firstWhere((t) => t['id'].toString() == value)['name'];
                        });
                      },
                      validator: (value) => value == null ? 'اختر النوع' : null,
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
                      ),
                    ),

                    // 🆕 تنبيه السلفة
                    if (_selectedTypeId == 'سلفه') ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'عند الحفظ سيتم سؤالك عن تفاصيل الأقساط',
                                style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // زر الحفظ
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveEshraf,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isDeduction ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'حفظ',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

// 🆕 Class لتخزين بيانات القسط
class InstallmentData {
  double amount;
  DateTime date;

  InstallmentData({required this.amount, required this.date});
}
