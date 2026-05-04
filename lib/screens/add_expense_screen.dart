import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _byanController = TextEditingController();

  // Data
  List<Map<String, dynamic>> _kinds = [];
  List<Map<String, dynamic>> _branches = [];
  List<String> _kindGroups = [];

  // Selected Values
  int? _selectedKindId;
  int? _selectedBranchId;
  String? _selectedKindGroup;
  DateTime _selectedDate = DateTime.now();

  // State
  bool _isLoading = false;
  bool _isLoadingData = true;
  String? _loadError;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _loadDropdowns();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  Future<void> _loadDropdowns() async {
    setState(() {
      _isLoadingData = true;
      _loadError = null;
    });

    try {
      // جلب البيانات
      final kindsResponse = await ApiService.getExpenseKinds();
      final branchesResponse = await ApiService.getBranches();

      debugPrint('📦 Kinds Response: $kindsResponse');
      debugPrint('📦 Branches Response: $branchesResponse');

      if (mounted) {
        setState(() {
          // تحويل الأنواع
          _kinds = (kindsResponse).map((k) {
            return {
              'ID': k['ID'],
              'expenseKind': k['expenseKind'] ?? '',
              'KindGroup': k['KindGroup'] ?? '',
            };
          }).toList().cast<Map<String, dynamic>>();

          // تحويل الفروع
          _branches = (branchesResponse).map((b) {
            return {
              'IDbranch': b['IDbranch'],
              'branchName': b['branchName'] ?? '',
            };
          }).toList().cast<Map<String, dynamic>>();

          // استخراج المجموعات الفريدة
          _kindGroups = _kinds
              .map((k) => k['KindGroup']?.toString() ?? '')
              .where((g) => g.isNotEmpty)
              .toSet()
              .toList();

          _isLoadingData = false;

          debugPrint('✅ Kinds loaded: ${_kinds.length}');
          debugPrint('✅ Branches loaded: ${_branches.length}');
          debugPrint('✅ Kind Groups: $_kindGroups');
        });

        _animationController.forward();
      }
    } catch (e) {
      debugPrint('❌ Error loading dropdowns: $e');
      if (mounted) {
        setState(() {
          _isLoadingData = false;
          _loadError = 'فشل تحميل البيانات: $e';
        });
      }
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    // التحقق من الاختيارات
    if (_selectedKindId == null) {
      _showErrorSnackBar('الرجاء اختيار نوع المصروف');
      return;
    }
    if (_selectedBranchId == null) {
      _showErrorSnackBar('الرجاء اختيار الفرع');
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    final user = Provider.of<AuthProvider>(context, listen: false).user?.fullName ?? 'Unknown';

    final data = {
      "amount": double.parse(_amountController.text.replaceAll(',', '')),
      "byan": _byanController.text.trim(),
      "date": _selectedDate.toIso8601String(),
      "kindId": _selectedKindId,
      "branchId": _selectedBranchId,
      "user": user,
    };

    debugPrint('📤 Sending data: $data');

    try {
      await ApiService.addExpense(data);
      if (mounted) {
        HapticFeedback.mediumImpact();
        _showSuccessSnackBar('تم حفظ المصروف بنجاح ✅');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        _showErrorSnackBar('فشل الحفظ: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFEF5350),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
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
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _byanController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
      appBar: _buildAppBar(isDark),
      body: _buildBody(isDark),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      title: const Text(
        'إضافة مصروف جديد',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: const Color(0xFFEF5350),
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        if (_loadError != null)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDropdowns,
            tooltip: 'إعادة التحميل',
          ),
      ],
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoadingData) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFEF5350)),
            SizedBox(height: 16),
            Text('جاري تحميل البيانات...'),
          ],
        ),
      );
    }

    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDropdowns,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF5350),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // المبلغ
              _buildAmountField(isDark),
              const SizedBox(height: 20),

              // التاريخ
              _buildDateField(isDark),
              const SizedBox(height: 20),

              

              // نوع المصروف
              _buildKindDropdown(isDark),
              const SizedBox(height: 20),

              // الفرع
              _buildBranchDropdown(isDark),
              const SizedBox(height: 20),

              // البيان
              _buildNotesField(isDark),
              const SizedBox(height: 32),

              // زر الحفظ
              _buildSaveButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ============ AMOUNT FIELD ============
  Widget _buildAmountField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('المبلغ *', Icons.payments_rounded, const Color(0xFFEF5350), isDark),
        const SizedBox(height: 10),
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: '0.00',
            hintStyle: TextStyle(color: Colors.grey[400]),
            suffixText: 'ج.م',
            suffixStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFEF5350),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF252836) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFEF5350), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'المبلغ مطلوب';
            final amount = double.tryParse(v.replaceAll(',', ''));
            if (amount == null || amount <= 0) return 'أدخل مبلغ صحيح';
            return null;
          },
        ),
      ],
    );
  }

  // ============ DATE FIELD ============
  Widget _buildDateField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('التاريخ', Icons.calendar_today_rounded, const Color(0xFF3B82F6), isDark),
        const SizedBox(height: 10),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252836) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.event_rounded, color: Colors.grey[500]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    DateFormat('EEEE، d MMMM yyyy', 'ar').format(_selectedDate),
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[500]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // أزرار سريعة
        Row(
          children: [
            Expanded(child: _buildQuickDateBtn('اليوم', DateTime.now(), isDark)),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickDateBtn(
                'أمس',
                DateTime.now().subtract(const Duration(days: 1)),
                isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickDateBtn(String label, DateTime date, bool isDark) {
    final isSelected = DateUtils.isSameDay(_selectedDate, date);
    return InkWell(
      onTap: () => setState(() => _selectedDate = date),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3B82F6).withOpacity(0.1)
              : (isDark ? const Color(0xFF252836) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3B82F6)
                : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? const Color(0xFF3B82F6)
                  : (isDark ? Colors.white : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }

  // ============ KIND GROUP DROPDOWN ============
  Widget _buildKindGroupDropdown(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('مجموعة المصروفات', Icons.folder_rounded, const Color(0xFF8B5CF6), isDark),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252836) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedKindGroup,
              isExpanded: true,
              hint: Row(
                children: [
                  Icon(Icons.folder_open, size: 20, color: Colors.grey[400]),
                  const SizedBox(width: 12),
                  Text('اختر المجموعة', style: TextStyle(color: Colors.grey[400])),
                ],
              ),
              dropdownColor: isDark ? const Color(0xFF252836) : Colors.white,
              items: _kindGroups.map((group) {
                return DropdownMenuItem<String>(
                  value: group,
                  child: Row(
                    children: [
                      const Icon(Icons.folder, size: 20, color: Color(0xFF8B5CF6)),
                      const SizedBox(width: 12),
                      Text(
                        group,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedKindGroup = value;
                  _selectedKindId = null; // Reset kind when group changes
                });
              },
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[500]),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  // ============ KIND DROPDOWN ============
  Widget _buildKindDropdown(bool isDark) {
    // فلترة الأنواع حسب المجموعة
   final filteredKinds = _kinds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('نوع المصروف *', Icons.category_rounded, const Color(0xFFF59E0B), isDark),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252836) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _selectedKindId == null
                  ? (isDark ? Colors.grey[700]! : Colors.grey[300]!)
                  : const Color(0xFFF59E0B),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedKindId,
              isExpanded: true,
              hint: Row(
                children: [
                  Icon(Icons.category_outlined, size: 20, color: Colors.grey[400]),
                  const SizedBox(width: 12),
                  Text(
                    filteredKinds.isEmpty ? 'لا توجد أنواع' : 'اختر نوع المصروف',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),
              dropdownColor: isDark ? const Color(0xFF252836) : Colors.white,
              items: filteredKinds.map((kind) {
                return DropdownMenuItem<int>(
                  value: kind['ID'] as int,
                  child: Row(
                    children: [
                      const Icon(Icons.label, size: 20, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          kind['expenseKind'] ?? '',
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: filteredKinds.isEmpty
                  ? null
                  : (value) => setState(() => _selectedKindId = value),
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[500]),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        
      ],
    );
  }

  // ============ BRANCH DROPDOWN ============
  Widget _buildBranchDropdown(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('الفرع *', Icons.store_rounded, const Color(0xFF10B981), isDark),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252836) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _selectedBranchId == null
                  ? (isDark ? Colors.grey[700]! : Colors.grey[300]!)
                  : const Color(0xFF10B981),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedBranchId,
              isExpanded: true,
              hint: Row(
                children: [
                  Icon(Icons.store_outlined, size: 20, color: Colors.grey[400]),
                  const SizedBox(width: 12),
                  Text(
                    _branches.isEmpty ? 'لا توجد فروع' : 'اختر الفرع',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),
              dropdownColor: isDark ? const Color(0xFF252836) : Colors.white,
              items: _branches.map((branch) {
                return DropdownMenuItem<int>(
                  value: branch['IDbranch'] as int,
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, size: 20, color: Color(0xFF10B981)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          branch['branchName'] ?? '',
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: _branches.isEmpty
                  ? null
                  : (value) => setState(() => _selectedBranchId = value),
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[500]),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        // Debug info
        if (_branches.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'تحميل الفروع...',
              style: TextStyle(fontSize: 12, color: Colors.orange[600]),
            ),
          ),
      ],
    );
  }

  // ============ NOTES FIELD ============
  Widget _buildNotesField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('البيان / ملاحظات', Icons.notes_rounded, const Color(0xFFEC4899), isDark),
        const SizedBox(height: 10),
        TextFormField(
          controller: _byanController,
          maxLines: 4,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: 'أدخل تفاصيل أو ملاحظات عن المصروف...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: isDark ? const Color(0xFF252836) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFEC4899), width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  // ============ LABEL HELPER ============
  Widget _buildLabel(String text, IconData icon, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  // ============ SAVE BUTTON ============
  Widget _buildSaveButton() {
    final canSave = _selectedKindId != null && _selectedBranchId != null;

    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        gradient: _isLoading || !canSave
            ? LinearGradient(colors: [Colors.grey[400]!, Colors.grey[500]!])
            : const LinearGradient(
                colors: [Color(0xFFEF5350), Color(0xFFC62828)],
              ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: _isLoading || !canSave
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFFEF5350).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading || !canSave ? null : _saveExpense,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'جاري الحفظ...',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_rounded, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'حفظ المصروف',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}