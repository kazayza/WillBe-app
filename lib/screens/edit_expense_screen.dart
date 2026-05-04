import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class EditExpenseScreen extends StatefulWidget {
  final Map<String, dynamic> expense;

  const EditExpenseScreen({super.key, required this.expense});

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _byanController = TextEditingController();

  // Data
  List<Map<String, dynamic>> _kinds = [];
  List<Map<String, dynamic>> _branches = [];
  List<String> _kindGroups = [];

  // Selected Values (int مش String)
  int? _selectedKindId;
  int? _selectedBranchId;
  String? _selectedKindGroup;
  DateTime _selectedDate = DateTime.now();

  // Original Values
  double _originalAmount = 0;
  String _originalByan = '';
  String? _originalKindName;
  String? _originalBranchName;
  DateTime? _originalDate;

  // State
  bool _isLoading = false;
  bool _isLoadingData = true;
  bool _hasChanges = false;
  String? _loadError;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _initializeOriginalData();
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

  void _initializeOriginalData() {
    // حفظ البيانات الأصلية
    _originalAmount = double.tryParse(widget.expense['expenseAmount']?.toString() ?? '0') ?? 0;
    _originalByan = widget.expense['Byan'] ?? '';
    _originalKindName = widget.expense['KindName'];
    _originalBranchName = widget.expense['branchName'];

    // تعبئة الحقول
    _amountController.text = _originalAmount.toStringAsFixed(0);
    _byanController.text = _originalByan;

    // التاريخ
    try {
      if (widget.expense['expenseDate'] != null) {
        _selectedDate = DateTime.parse(widget.expense['expenseDate']);
        _originalDate = _selectedDate;
      }
    } catch (_) {
      _selectedDate = DateTime.now();
      _originalDate = _selectedDate;
    }

    // Listen for changes
    _amountController.addListener(_checkChanges);
    _byanController.addListener(_checkChanges);
  }

  void _checkChanges() {
    final currentAmount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    
    final hasChanges = currentAmount != _originalAmount ||
        _byanController.text != _originalByan ||
        !_isSameDay(_selectedDate, _originalDate) ||
        _hasKindChanged() ||
        _hasBranchChanged();

    if (hasChanges != _hasChanges) {
      setState(() => _hasChanges = hasChanges);
    }
  }

  bool _isSameDay(DateTime? date1, DateTime? date2) {
    if (date1 == null || date2 == null) return false;
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }

  bool _hasKindChanged() {
    if (_selectedKindId == null) return false;
    final selectedKind = _kinds.firstWhere(
      (k) => k['ID'] == _selectedKindId,
      orElse: () => {'expenseKind': ''},
    );
    return selectedKind['expenseKind'] != _originalKindName;
  }

  bool _hasBranchChanged() {
    if (_selectedBranchId == null) return false;
    final selectedBranch = _branches.firstWhere(
      (b) => b['IDbranch'] == _selectedBranchId,
      orElse: () => {'branchName': ''},
    );
    return selectedBranch['branchName'] != _originalBranchName;
  }

  Future<void> _loadDropdowns() async {
    setState(() {
      _isLoadingData = true;
      _loadError = null;
    });

    try {
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

          // تحديد القيم الحالية من البيانات الأصلية
          _setCurrentSelections();

          _isLoadingData = false;

          debugPrint('✅ Kinds loaded: ${_kinds.length}');
          debugPrint('✅ Branches loaded: ${_branches.length}');
          debugPrint('✅ Selected Kind ID: $_selectedKindId');
          debugPrint('✅ Selected Branch ID: $_selectedBranchId');
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

  void _setCurrentSelections() {
    // تحديد النوع الحالي من اسم النوع
    if (_originalKindName != null && _originalKindName!.isNotEmpty) {
      final kind = _kinds.firstWhere(
        (k) => k['expenseKind'] == _originalKindName,
        orElse: () => <String, dynamic>{},
      );
      if (kind.isNotEmpty) {
        _selectedKindId = kind['ID'] as int;
        _selectedKindGroup = kind['KindGroup'] as String?;
        debugPrint('✅ Found kind: $_originalKindName -> ID: $_selectedKindId');
      }
    }

    // تحديد الفرع الحالي من اسم الفرع
    if (_originalBranchName != null && _originalBranchName!.isNotEmpty) {
      final branch = _branches.firstWhere(
        (b) => b['branchName'] == _originalBranchName,
        orElse: () => <String, dynamic>{},
      );
      if (branch.isNotEmpty) {
        _selectedBranchId = branch['IDbranch'] as int;
        debugPrint('✅ Found branch: $_originalBranchName -> ID: $_selectedBranchId');
      }
    }
  }

  Future<void> _updateExpense() async {
    if (!_formKey.currentState!.validate()) return;

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
    final expenseId = widget.expense['ID'];

    final data = {
      "amount": double.parse(_amountController.text.replaceAll(',', '')),
      "byan": _byanController.text.trim(),
      "date": _selectedDate.toIso8601String(),
      "kindId": _selectedKindId,
      "branchId": _selectedBranchId,
      "user": user,
    };

    debugPrint('📤 Updating expense $expenseId with: $data');

    try {
      await ApiService.updateExpense(expenseId, data);
      if (mounted) {
        HapticFeedback.mediumImpact();
        _showSuccessSnackBar('تم تحديث المصروف بنجاح ✅');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        _showErrorSnackBar('فشل التحديث: $e');
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
              primary: Color(0xFF3B82F6),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _checkChanges();
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_rounded, color: Color(0xFFF59E0B)),
            ),
            const SizedBox(width: 12),
            const Text("تجاهل التغييرات؟"),
          ],
        ),
        content: const Text("لديك تغييرات غير محفوظة. هل تريد تجاهلها؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("متابعة التعديل"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("تجاهل", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    return result ?? false;
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

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
        appBar: _buildAppBar(isDark),
        body: _buildBody(isDark),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      title: const Text(
        'تعديل المصروف',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: const Color(0xFF3B82F6),
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new),
        onPressed: () async {
          if (await _onWillPop()) {
            Navigator.pop(context);
          }
        },
      ),
      actions: [
        if (_hasChanges)
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text(
                  "تم التعديل",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        if (_loadError != null)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDropdowns,
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
            CircularProgressIndicator(color: Color(0xFF3B82F6)),
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
                backgroundColor: const Color(0xFF3B82F6),
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
              // Original Info Card
              _buildOriginalInfoCard(isDark),
              const SizedBox(height: 20),

              // المبلغ
              _buildAmountField(isDark),
              const SizedBox(height: 20),

              // التاريخ
              _buildDateField(isDark),
              const SizedBox(height: 20),

              // مجموعة المصروفات
              if (_kindGroups.isNotEmpty) ...[
                _buildKindGroupDropdown(isDark),
                const SizedBox(height: 20),
              ],

              // نوع المصروف
              _buildKindDropdown(isDark),
              const SizedBox(height: 20),

              // الفرع
              _buildBranchDropdown(isDark),
              const SizedBox(height: 20),

              // البيان
              _buildNotesField(isDark),
              const SizedBox(height: 32),

              // أزرار الحفظ والإلغاء
              _buildActionButtons(isDark),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
    // ============ ORIGINAL INFO CARD ============
  Widget _buildOriginalInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF252836).withOpacity(0.5)
            : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF3B82F6).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF3B82F6),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "البيانات الأصلية",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B82F6),
                ),
              ),
              const Spacer(),
              Text(
                "#${widget.expense['ID']}",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  "المبلغ",
                  "${NumberFormat('#,##0').format(_originalAmount)} ج.م",
                  Icons.payments_rounded,
                  const Color(0xFFEF5350),
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoItem(
                  "النوع",
                  _originalKindName ?? 'غير محدد',
                  Icons.category_rounded,
                  const Color(0xFFF59E0B),
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  "الفرع",
                  _originalBranchName ?? 'غير محدد',
                  Icons.store_rounded,
                  const Color(0xFF10B981),
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoItem(
                  "التاريخ",
                  _originalDate != null
                      ? DateFormat('d/M/yyyy').format(_originalDate!)
                      : 'غير محدد',
                  Icons.calendar_today_rounded,
                  const Color(0xFF8B5CF6),
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ AMOUNT FIELD ============
  Widget _buildAmountField(bool isDark) {
    final currentAmount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    final isChanged = currentAmount != _originalAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('المبلغ *', Icons.payments_rounded, const Color(0xFF3B82F6), isDark, isChanged),
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
              color: Color(0xFF3B82F6),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF252836) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
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
    final isChanged = !_isSameDay(_selectedDate, _originalDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('التاريخ', Icons.calendar_today_rounded, const Color(0xFF8B5CF6), isDark, isChanged),
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
                color: isChanged 
                    ? const Color(0xFF10B981) 
                    : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                width: isChanged ? 2 : 1,
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
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickDateBtn(
                'الأصلي',
                _originalDate ?? DateTime.now(),
                isDark,
                isOriginal: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickDateBtn(String label, DateTime date, bool isDark, {bool isOriginal = false}) {
    final isSelected = _isSameDay(_selectedDate, date);
    return InkWell(
      onTap: () {
        setState(() => _selectedDate = date);
        _checkChanges();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isOriginal ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFF8B5CF6).withOpacity(0.1))
              : (isDark ? const Color(0xFF252836) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isOriginal ? const Color(0xFF10B981) : const Color(0xFF8B5CF6))
                : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? (isOriginal ? const Color(0xFF10B981) : const Color(0xFF8B5CF6))
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
        _buildLabel('مجموعة المصروفات', Icons.folder_rounded, const Color(0xFFF59E0B), isDark, false),
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
                      const Icon(Icons.folder, size: 20, color: Color(0xFFF59E0B)),
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
                  _selectedKindId = null;
                });
                _checkChanges();
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
    final filteredKinds = _selectedKindGroup != null
        ? _kinds.where((k) => k['KindGroup'] == _selectedKindGroup).toList()
        : _kinds;

    final isChanged = _hasKindChanged();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('نوع المصروف *', Icons.category_rounded, const Color(0xFFF59E0B), isDark, isChanged),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252836) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isChanged
                  ? const Color(0xFF10B981)
                  : (_selectedKindId == null
                      ? (isDark ? Colors.grey[700]! : Colors.grey[300]!)
                      : const Color(0xFFF59E0B)),
              width: isChanged ? 2 : 1,
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
                  : (value) {
                      setState(() => _selectedKindId = value);
                      _checkChanges();
                    },
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
    final isChanged = _hasBranchChanged();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('الفرع *', Icons.store_rounded, const Color(0xFF10B981), isDark, isChanged),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252836) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isChanged
                  ? const Color(0xFF10B981)
                  : (_selectedBranchId == null
                      ? (isDark ? Colors.grey[700]! : Colors.grey[300]!)
                      : const Color(0xFF10B981)),
              width: isChanged ? 2 : 1,
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
                  : (value) {
                      setState(() => _selectedBranchId = value);
                      _checkChanges();
                    },
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[500]),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  // ============ NOTES FIELD ============
  Widget _buildNotesField(bool isDark) {
    final isChanged = _byanController.text != _originalByan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('البيان / ملاحظات', Icons.notes_rounded, const Color(0xFFEC4899), isDark, isChanged),
        const SizedBox(height: 10),
        TextFormField(
          controller: _byanController,
          maxLines: 4,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: 'أدخل تفاصيل أو ملاحظات...',
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
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isChanged
                    ? const Color(0xFF10B981)
                    : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                width: isChanged ? 2 : 1,
              ),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  // ============ LABEL HELPER ============
  Widget _buildLabel(String text, IconData icon, Color color, bool isDark, bool isChanged) {
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
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        if (isChanged)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit, size: 12, color: Color(0xFF10B981)),
                SizedBox(width: 4),
                Text(
                  "معدّل",
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ============ ACTION BUTTONS ============
  Widget _buildActionButtons(bool isDark) {
    return Row(
      children: [
        // زر الإلغاء
        Expanded(
          child: OutlinedButton(
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.pop(context);
              }
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              side: BorderSide(color: isDark ? Colors.grey[600]! : Colors.grey[400]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              "إلغاء",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // زر الحفظ
        Expanded(
          flex: 2,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: (_isLoading || !_hasChanges)
                  ? LinearGradient(colors: [Colors.grey[400]!, Colors.grey[500]!])
                  : const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: (_isLoading || !_hasChanges)
                  ? null
                  : [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
            ),
            child: ElevatedButton(
              onPressed: (_isLoading || !_hasChanges) ? null : _updateExpense,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save_rounded, color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          _hasChanges ? 'حفظ التعديلات' : 'لا توجد تغييرات',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}