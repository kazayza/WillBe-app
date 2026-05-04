import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class GeneralIncomeScreen extends StatefulWidget {
  const GeneralIncomeScreen({super.key});

  @override
  State<GeneralIncomeScreen> createState() => _GeneralIncomeScreenState();
}

class _GeneralIncomeScreenState extends State<GeneralIncomeScreen>
    with TickerProviderStateMixin {
  
  // ═══════════════════════════════════════════════════════════════
  // Controllers
  // ═══════════════════════════════════════════════════════════════
  
  final _amountController = TextEditingController();
  final _receiptController = TextEditingController();
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _kindSearchController = TextEditingController();
  String _kindSearchQuery = '';

  // ═══════════════════════════════════════════════════════════════
  // Animation Controllers
  // ═══════════════════════════════════════════════════════════════
  
  late AnimationController _headerAnimController;
  late AnimationController _contentAnimController;
  late Animation<double> _headerAnimation;
  late Animation<double> _contentAnimation;

  // ═══════════════════════════════════════════════════════════════
  // Data
  // ═══════════════════════════════════════════════════════════════
  
  List<dynamic> _sessions = [];
  List<dynamic> _children = [];
  List<dynamic> _filteredChildren = [];
  List<dynamic> _incomeKinds = [];
  List<dynamic> _branches = [];
  Map<String, List<dynamic>> _groupedKinds = {};

  int? _selectedSessionId;
  int? _selectedKindId;
  int? _selectedBranchId;
  String? _selectedKindGroup;
  Map<String, dynamic>? _selectedChild;
  
  // ✅ تاريخ بدون وقت
  DateTime _payDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  // ═══════════════════════════════════════════════════════════════
  // State
  // ═══════════════════════════════════════════════════════════════
  
  bool _isLoadingData = true;
  bool _isSaving = false;
  bool _showChildSearch = false;

  // ═══════════════════════════════════════════════════════════════
  // Colors
  // ═══════════════════════════════════════════════════════════════
  
  static const _primaryColor = Color(0xFF6366F1);
  static const _successColor = Color(0xFF10B981);
  static const _errorColor = Color(0xFFEF4444);

  // ═══════════════════════════════════════════════════════════════
  // Formatters
  // ═══════════════════════════════════════════════════════════════
  
  final _currencyFormat = NumberFormat('#,###', 'ar_EG');
  final _dateFormat = DateFormat('dd/MM/yyyy', 'ar_EG');

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadInitialData();
  }

  void _setupAnimations() {
    _headerAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _contentAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _headerAnimation = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOutCubic,
    );

    _contentAnimation = CurvedAnimation(
      parent: _contentAnimController,
      curve: Curves.easeOutCubic,
    );

    _headerAnimController.forward();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _receiptController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _headerAnimController.dispose();
    _contentAnimController.dispose();
    _kindSearchController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // تحميل البيانات الأولية
  // ═══════════════════════════════════════════════════════════════

  Future<void> _loadInitialData() async {
    try {
 // بنحمل كل البيانات دفعة واحدة (بما فيهم الأطفال)
      final results = await Future.wait([
        ApiService.get('general/sessions'),
        ApiService.get('incomes/kinds'),
        ApiService.get('general/branches'),
        ApiService.get('children'), // 👈 الجديد: حملنا الأطفال هنا
      ]);

      final sessions = results[0];
      final kinds = results[1];
      final branches = results[2];
      final children = results[3]; // 👈

      // تجميع الأنواع حسب المجموعة
      Map<String, List<dynamic>> grouped = {};
      for (var kind in kinds) {
        String group = kind['kindGroup'] ?? 'أخرى';
        // استبعاد اشتراك الدراسة والباص
        if (group != 'اشتراك' && group != 'اشتراك الباص') {
          if (!grouped.containsKey(group)) {
            grouped[group] = [];
          }
          grouped[group]!.add(kind);
        }
      }

      if (mounted) {
        setState(() {
          _sessions = sessions;
          _incomeKinds = kinds;
          _branches = branches;
          _groupedKinds = grouped;
          _children = children; // 👈 حفظنا القائمة
          _filteredChildren = children.take(20).toList(); // جهزنا أول 20 للبحث
          
          if (_branches.isNotEmpty) {
            _selectedBranchId = _branches[0]['IDbranch']; // فرع افتراضي
          }
          
          _isLoadingData = false;
        });
        _contentAnimController.forward();
      }
    } catch (e) {
      setState(() => _isLoadingData = false);
      _showSnackBar('فشل تحميل البيانات: $e', isError: true);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // تحميل الأطفال
  // ═══════════════════════════════════════════════════════════════

  Future<void> _loadChildren(int sessionId) async {
    try {
      final children = await ApiService.get('children?sessionId=$sessionId');
      setState(() {
        _children = children;
        _filteredChildren = children;
        _selectedChild = null;
        _searchController.clear();
      });
    } catch (e) {
      _showSnackBar('فشل تحميل الأطفال: $e', isError: true);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // فلترة الأطفال
  // ═══════════════════════════════════════════════════════════════

  void _filterChildren(String query) {
    if (query.isEmpty) {
      setState(() => _filteredChildren = _children);
    } else {
      setState(() {
        _filteredChildren = _children.where((child) {
          final name = (child['FullNameArabic'] ?? '').toString().toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // اختيار طفل
  // ═══════════════════════════════════════════════════════════════

void _selectChild(Map<String, dynamic> child) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedChild = child;
      _showChildSearch = false;
      _searchController.text = child['FullNameArabic'] ?? '';

      // 1. الذكاء: ملء الفرع تلقائياً
      if (child['Branch'] != null) {
        _selectedBranchId = child['Branch'];
      }

      // 2. الذكاء: ملء العام المالي
      // لو الطفل عنده سنة مسجلة (مثلاً LastSessionID) نختارها
      // لو لأ، نختار "آخر سنة" في القائمة (السنة الحالية غالباً)
     // 2. تحديد العام المالي (بناءً على طلبك الجديد)
      
      // أولوية 1: لو الطفل عنده سنة مسجلة في بياناته، نختارها
      if (child['LastSessionID'] != null) {
         _selectedSessionId = child['LastSessionID'];
      } 
      // أولوية 2: لو معندوش، نصفر الاختيار عشان نجبر المستخدم يختار
      else {
         _selectedSessionId = null; 
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // اختيار تاريخ الدفع
  // ═══════════════════════════════════════════════════════════════

  Future<void> _selectPayDate() async {
    HapticFeedback.lightImpact();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _payDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              surface: _isDark ? const Color(0xFF1E1E2E) : Colors.white,
              onSurface: _isDark ? Colors.white : Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // ✅ تاريخ بدون وقت
      setState(() {
        _payDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // تحصيل المبلغ
  // ═══════════════════════════════════════════════════════════════

  Future<void> _submitPayment() async {
    // Validation
    if (_selectedSessionId == null) {
      _showSnackBar('اختر العام المالي', isError: true);
      return;
    }
    if (_selectedChild == null) {
      _showSnackBar('اختر الطفل', isError: true);
      return;
    }
    if (_selectedKindId == null) {
      _showSnackBar('اختر نوع الإيراد', isError: true);
      return;
    }
    if (_selectedBranchId == null) {
      _showSnackBar('اختر الفرع', isError: true);
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showSnackBar('أدخل مبلغ صحيح', isError: true);
      return;
    }

    // الحصول على اسم نوع الإيراد
    String kindName = '';
    for (var kind in _incomeKinds) {
      if (kind['ID'] == _selectedKindId) {
        kindName = kind['incomeKind'] ?? '';
        break;
      }
    }

    // ✅ عرض Bottom Sheet للتأكيد
    final confirm = await _showPaymentConfirmation(amount, kindName);
    if (confirm != true) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final user = Provider.of<AuthProvider>(context, listen: false)
              .user
              ?.fullName ??
          'System';

      // ✅ تاريخ بدون وقت
      final payDateOnly = DateTime(
        _payDate.year,
        _payDate.month,
        _payDate.day,
      );

      final result = await ApiService.addGeneralIncome(
        amount: amount,
        childId: _selectedChild!['ID_Child'],
        branchId: _selectedBranchId!,
        kindId: _selectedKindId!,
        sessionId: _selectedSessionId!,
        receiptNo:
            _receiptController.text.isEmpty ? null : _receiptController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        userAdd: user,
        addTime: DateTime.now(),
        payDate: payDateOnly,
      );

      setState(() => _isSaving = false);

      if (result['success'] == true) {
        HapticFeedback.heavyImpact();
        _showSnackBar(result['message'] ?? 'تم التحصيل بنجاح');
        _clearForm();
      } else {
        _showSnackBar(result['message'] ?? 'فشل التحصيل', isError: true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showSnackBar('فشل التحصيل: $e', isError: true);
    }
  }

  void _clearForm() {
    _amountController.clear();
    _receiptController.clear();
    _notesController.clear();
    setState(() {
      _selectedKindId = null;
      _selectedKindGroup = null;
      _payDate = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // Bottom Sheet للتأكيد
  // ═══════════════════════════════════════════════════════════════

  Future<bool?> _showPaymentConfirmation(double amount, String kindName) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),

            // Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _successColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.payments_rounded,
                color: _successColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'تأكيد التحصيل',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 24),

            // Details Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _isDark ? Colors.grey[800] : Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildConfirmRow(
                    'الطفل',
                    _selectedChild!['FullNameArabic'] ?? '',
                    Icons.child_care_rounded,
                  ),
                  const Divider(height: 24),
                  _buildConfirmRow(
                    'نوع الإيراد',
                    kindName,
                    Icons.category_rounded,
                  ),
                  const Divider(height: 24),
                  _buildConfirmRow(
                    'المبلغ',
                    '${_currencyFormat.format(amount)} ج.م',
                    Icons.attach_money_rounded,
                    valueColor: _successColor,
                  ),
                  const Divider(height: 24),
                  _buildConfirmRow(
                    'تاريخ الدفع',
                    _dateFormat.format(_payDate),
                    Icons.calendar_today_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          _isDark ? Colors.grey[400] : Colors.grey[600],
                      side: BorderSide(
                        color: _isDark ? Colors.grey[600]! : Colors.grey[300]!,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text(
                      'تأكيد التحصيل',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _successColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _primaryColor, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: _isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor ?? (_isDark ? Colors.white : Colors.black87),
              fontSize: 14,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SnackBar
  // ═══════════════════════════════════════════════════════════════

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? _errorColor : _successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
// Helper Methods
// ═══════════════════════════════════════════════════════════════

IconData _getGroupIcon(String group) {
  switch (group) {
    case 'كورس':
      return Icons.menu_book_rounded;
    case 'انشطة':
      return Icons.sports_rounded;
    case 'مبيعات':
      return Icons.storefront_rounded;
    case 'رصيد مرحل':
      return Icons.swap_horiz_rounded;
    case 'رصيد افتتاحي لاكاديميه':
    case 'رصيد افتتاجي لاكاديميه':
      return Icons.account_balance_wallet_rounded;
    default:
      return Icons.folder_rounded;
  }
}

List<Color> _getGroupGradient(String group) {
  switch (group) {
    case 'كورس':
      return [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)];
    case 'انشطة':
      return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
    case 'مبيعات':
      return [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)];
    case 'رصيد مرحل':
      return [const Color(0xFF14B8A6), const Color(0xFF0D9488)];
    case 'رصيد افتتاحي لاكاديميه':
    case 'رصيد افتتاجي لاكاديميه':
      return [const Color(0xFF10B981), const Color(0xFF059669)];
    default:
      return [const Color(0xFF64748B), const Color(0xFF475569)];
  }
}

IconData _getKindIcon(String kindName) {
  final name = kindName.toLowerCase();
  
  // === لغات ===
  if (name.contains('انجلش') || name.contains('english') || name.contains('انجليزي')) {
    return Icons.translate_rounded;
  }
  if (name.contains('عربي') || name.contains('عربى')) {
    return Icons.text_fields_rounded;
  }
  if (name.contains('خط')) {
    return Icons.draw_rounded;
  }
  if (name.contains('قرآن') || name.contains('قران')) {
    return Icons.auto_stories_rounded;
  }
  if (name.contains('فرنسا') || name.contains('french')) {
    return Icons.language_rounded;
  }
  if (name.contains('المان') || name.contains('german')) {
    return Icons.language_rounded;
  }
  
  // === رياضة ===
  if (name.contains('جمباز')) {
    return Icons.sports_gymnastics_rounded;
  }
  if (name.contains('كره') || name.contains('كورة') || name.contains('قدم')) {
    return Icons.sports_soccer_rounded;
  }
  if (name.contains('سباحة')) {
    return Icons.pool_rounded;
  }
  
  // === تكنولوجيا ===
  if (name.contains('ict') || name.contains('icdl') || name.contains('كمبيوتر')) {
    return Icons.computer_rounded;
  }
  if (name.contains('برمج')) {
    return Icons.code_rounded;
  }
  if (name.contains('جرافيك')) {
    return Icons.design_services_rounded;
  }
  if (name.contains('منت') || name.contains('montessori')) {
    return Icons.extension_rounded;
  }
  
  // === مهارات ===
  if (name.contains('تنمي') || name.contains('مهارات')) {
    return Icons.trending_up_rounded;
  }
  if (name.contains('تخاطب')) {
    return Icons.record_voice_over_rounded;
  }
  if (name.contains('تاهيل') || name.contains('تأهيل')) {
    return Icons.accessibility_new_rounded;
  }
  if (name.contains('نفسي')) {
    return Icons.psychology_rounded;
  }
  if (name.contains('رياد') || name.contains('اعمال')) {
    return Icons.business_center_rounded;
  }
  if (name.contains('teaching') || name.contains('learning')) {
    return Icons.school_rounded;
  }
  
  // === أكاديمي ===
  if (name.contains('math') || name.contains('رياضيات') || name.contains('حساب')) {
    return Icons.calculate_rounded;
  }
  if (name.contains('mental')) {
    return Icons.psychology_alt_rounded;
  }
  if (name.contains('تقوي') || name.contains('مجموع')) {
    return Icons.groups_rounded;
  }
  
  // === فنون ===
  if (name.contains('رسم')) {
    return Icons.palette_rounded;
  }
  
  // === صحة ===
  if (name.contains('تغذي') || name.contains('فتنس') || name.contains('fitness')) {
    return Icons.fitness_center_rounded;
  }
  
  // === أنشطة ===
  if (name.contains('camp') || name.contains('كامب')) {
    return Icons.cabin_rounded;
  }
  if (name.contains('استضاف')) {
    return Icons.home_rounded;
  }
  if (name.contains('رحل')) {
    return Icons.directions_bus_rounded;
  }
  if (name.contains('حفل')) {
    return Icons.celebration_rounded;
  }
  if (name.contains('ورش')) {
    return Icons.handyman_rounded;
  }
  if (name.contains('ايجار') || name.contains('قاع')) {
    return Icons.meeting_room_rounded;
  }
  if (name.contains('تصوير')) {
    return Icons.camera_alt_rounded;
  }
  
  // === مبيعات - ملابس ===
  if (name.contains('تيشيرت') || name.contains('شيرت')) {
    return Icons.checkroom_rounded;
  }
  if (name.contains('بنطلون')) {
    return Icons.checkroom_rounded;
  }
  if (name.contains('ترنج')) {
    return Icons.checkroom_rounded;
  }
  if (name.contains('فستان')) {
    return Icons.checkroom_rounded;
  }
  if (name.contains('سويت')) {
    return Icons.checkroom_rounded;
  }
  if (name.contains('شورت')) {
    return Icons.checkroom_rounded;
  }
  
  // === مبيعات - أخرى ===
  if (name.contains('كتب') || name.contains('كتاب')) {
    return Icons.menu_book_rounded;
  }
  if (name.contains('ادوات') || name.contains('مكتب') || name.contains('قرطاسي')) {
    return Icons.edit_rounded;
  }
  if (name.contains('ملف')) {
    return Icons.folder_rounded;
  }
  if (name.contains('كراس')) {
    return Icons.book_rounded;
  }
  
  // === رصيد ===
  if (name.contains('رصيد')) {
    return Icons.account_balance_wallet_rounded;
  }
  
  // === Default ===
  return Icons.receipt_long_rounded;
}

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          _isDark ? const Color(0xFF0F0F1E) : const Color(0xFFF8FAFC),
      body: _isLoadingData ? _buildLoadingWidget() : _buildContent(),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.2),
                  blurRadius: 30,
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'جاري تحميل البيانات...',
            style: TextStyle(
              color: _isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildSliverAppBar(),
        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildHeader(),
              FadeTransition(
                opacity: _contentAnimation,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  child: Column(
                    children: [
                      _buildIncomeTypesCard(),
                      const SizedBox(height: 16),
                      _buildPaymentForm(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SLIVER APP BAR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: _isDark ? const Color(0xFF1A1A2E) : Colors.white,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: _isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
      title: Text(
        'تحصيل إيرادات',
        style: TextStyle(
          color: _isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _headerAnimation,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1),
              Color(0xFF8B5CF6),
              Color(0xFFA855F7),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // 1. الأيقونة
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.payments_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),

            // 2. البحث عن الطفل (بقى فوق) ⬆️
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    enabled: true, // حررنا البحث
                    style: TextStyle(color: Colors.grey[800]),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن الطفل...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                      suffixIcon: _selectedChild != null
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey[500]),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _selectedChild = null;
                                  _searchController.clear();
                                  _filteredChildren = _children;
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onTap: () => setState(() => _showChildSearch = true),
                    onChanged: (value) {
                      _filterChildren(value);
                      setState(() => _showChildSearch = true);
                    },
                  ),

                  // قائمة نتائج البحث (جزء من نفس الـ Container)
                  if (_showChildSearch && _filteredChildren.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14)),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        separatorBuilder: (ctx, i) => Divider(height: 1, color: Colors.grey.shade200),
                        itemCount: _filteredChildren.length,
                        itemBuilder: (context, index) {
                          final child = _filteredChildren[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _primaryColor.withOpacity(0.1),
                              child: Text((child['FullNameArabic'] ?? 'ط')[0], style: const TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(child['FullNameArabic'] ?? '', style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500)),
                            onTap: () => _selectChild(Map<String, dynamic>.from(child)),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),

            // 3. العام المالي (بقى تحت) ⬇️
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedSessionId,
                  hint: Text('اختر العام المالي', style: TextStyle(color: Colors.grey[600])),
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                  style: TextStyle(color: Colors.grey[800], fontSize: 16, fontWeight: FontWeight.w600),
                  items: _sessions.map((s) {
                    return DropdownMenuItem<int>(
                      value: s['IDSession'],
                      child: Text(s['Sessions'] ?? ''),
                    );
                  }).toList(),
                  onChanged: (value) {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedSessionId = value);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

 // ═══════════════════════════════════════════════════════════════
// INCOME TYPES CARD - With Search
// ═══════════════════════════════════════════════════════════════

Widget _buildIncomeTypesCard() {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _isDark ? const Color(0xFF1E1E2E) : Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.category_rounded,
                color: _primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'نوع الإيراد',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _isDark ? Colors.white : Colors.black87,
              ),
            ),
            const Spacer(),
            if (_selectedKindId != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: _successColor, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'تم الاختيار',
                      style: TextStyle(
                        color: _successColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),

        // المجموعات
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: _groupedKinds.keys.toList().asMap().entries.map((entry) {
              final index = entry.key;
              final group = entry.value;
              return _buildGroupExpansionTile(group, index);
            }).toList(),
          ),
        ),
      ],
    ),
  );
}

Widget _buildGroupExpansionTile(String group, int index) {
  final isExpanded = _selectedKindGroup == group;
  final gradient = _getGroupGradient(group);
  final kinds = _groupedKinds[group] ?? [];
  final hasSelectedKind = kinds.any((k) => k['ID'] == _selectedKindId);
  
  // فلترة الأنواع حسب البحث
  List<dynamic> filteredKinds;
  if (isExpanded && _kindSearchQuery.isNotEmpty) {
    filteredKinds = kinds.where((k) {
      final name = (k['incomeKind'] ?? '').toString().toLowerCase();
      return name.contains(_kindSearchQuery.toLowerCase());
    }).toList();
  } else {
    filteredKinds = List.from(kinds);
  }

  // ترتيب أبجدي
  filteredKinds.sort((a, b) => 
      (a['incomeKind'] ?? '').toString().compareTo((b['incomeKind'] ?? '').toString()));

  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Duration(milliseconds: 300 + (index * 80)),
    curve: Curves.easeOutCubic,
    builder: (context, value, child) {
      return Transform.translate(
        offset: Offset(0, 20 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      );
    },
    child: Container(
      margin: EdgeInsets.only(bottom: index < _groupedKinds.length - 1 ? 10 : 0),
      decoration: BoxDecoration(
        color: isExpanded
            ? gradient[0].withOpacity(_isDark ? 0.15 : 0.08)
            : (_isDark ? Colors.grey[800] : Colors.grey[50]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded
              ? gradient[0].withOpacity(0.5)
              : (_isDark ? Colors.grey[700]! : Colors.grey[200]!),
          width: isExpanded ? 2 : 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: gradient[0].withOpacity(0.1),
          highlightColor: gradient[0].withOpacity(0.05),
        ),
        child: ExpansionTile(
          key: Key(group),
          initiallyExpanded: isExpanded,
          onExpansionChanged: (expanded) {
            HapticFeedback.lightImpact();
            setState(() {
              _selectedKindGroup = expanded ? group : null;
              if (!expanded) {
                _kindSearchController.clear();
                _kindSearchQuery = '';
              }
            });
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: gradient[0].withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              _getGroupIcon(group),
              color: Colors.white,
              size: 22,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  group,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: _isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hasSelectedKind
                      ? _successColor.withOpacity(0.15)
                      : gradient[0].withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasSelectedKind) ...[
                      const Icon(Icons.check, size: 14, color: _successColor),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      '${kinds.length}',
                      style: TextStyle(
                        color: hasSelectedKind ? _successColor : gradient[0],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          trailing: AnimatedRotation(
            turns: isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isExpanded
                    ? gradient[0].withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isExpanded
                    ? gradient[0]
                    : (_isDark ? Colors.grey[500] : Colors.grey[600]),
              ),
            ),
          ),
          children: [
            // Search Field
            if (kinds.length > 5) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _isDark ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                child: TextField(
                  controller: _kindSearchController,
                  style: TextStyle(
                    color: _isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن $group...',
                    hintStyle: TextStyle(
                      color: _isDark ? Colors.grey[500] : Colors.grey[500],
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: gradient[0],
                      size: 20,
                    ),
                    suffixIcon: _kindSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: _isDark ? Colors.grey[500] : Colors.grey[600],
                              size: 18,
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _kindSearchController.clear();
                                _kindSearchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _kindSearchQuery = value);
                  },
                ),
              ),
            ],

            // قائمة الأنواع
            if (filteredKinds.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      color: _isDark ? Colors.grey[600] : Colors.grey[400],
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'لا توجد نتائج',
                      style: TextStyle(
                        color: _isDark ? Colors.grey[500] : Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: filteredKinds.length > 4
                      ? const BouncingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  itemCount: filteredKinds.length,
                  itemBuilder: (context, kindIndex) {
                    return _buildKindListTile(
                      filteredKinds[kindIndex],
                      kindIndex,
                      gradient,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildKindListTile(
  Map<String, dynamic> kind,
  int index,
  List<Color> gradient,
) {
  final isSelected = _selectedKindId == kind['ID'];
  final kindName = kind['incomeKind'] ?? '';
  final kindIcon = _getKindIcon(kindName);

  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Duration(milliseconds: 150 + (index * 30)),
    curve: Curves.easeOutCubic,
    builder: (context, value, child) {
      return Transform.translate(
        offset: Offset(15 * (1 - value), 0),
        child: Opacity(opacity: value, child: child),
      );
    },
    child: GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedKindId = kind['ID']);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(colors: gradient) : null,
          color: isSelected
              ? null
              : (_isDark ? Colors.grey[850] : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (_isDark ? Colors.grey[700]! : Colors.grey[200]!),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: gradient[0].withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // أيقونة النوع
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : gradient[0].withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                kindIcon,
                color: isSelected ? Colors.white : gradient[0],
                size: 20,
              ),
            ),
            const SizedBox(width: 14),

            // اسم النوع
            Expanded(
              child: Text(
                kindName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (_isDark ? Colors.white : Colors.black87),
                ),
              ),
            ),

            // Radio indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.white : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? Colors.white
                      : (_isDark ? Colors.grey[600]! : Colors.grey[400]!),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Icon(
                        Icons.check_rounded,
                        color: gradient[0],
                        size: 16,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    ),
  );
}









  // ═══════════════════════════════════════════════════════════════
  // PAYMENT FORM
  // ═══════════════════════════════════════════════════════════════

  Widget _buildPaymentForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.payment_rounded,
                  color: _primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'بيانات التحصيل',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // الفرع
          _buildDropdownField(
            label: 'الفرع',
            icon: Icons.location_city_rounded,
            value: _selectedBranchId,
            items: _branches.map((b) {
              return DropdownMenuItem<int>(
                value: b['IDbranch'],
                child: Text(b['branchName'] ?? ''),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedBranchId = value);
            },
          ),
          const SizedBox(height: 16),

          // تاريخ الدفع
          InkWell(
            onTap: _selectPayDate,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isDark ? Colors.grey[800] : Colors.grey[50],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      color: _primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تاريخ الدفع',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _dateFormat.format(_payDate),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    color: _isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // المبلغ
          _buildTextField(
            controller: _amountController,
            label: 'المبلغ',
            icon: Icons.attach_money_rounded,
            suffix: 'ج.م',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // رقم الإيصال
          _buildTextField(
            controller: _receiptController,
            label: 'رقم الإيصال (اختياري)',
            icon: Icons.receipt_rounded,
          ),
          const SizedBox(height: 16),

          // ملاحظات
          _buildTextField(
            controller: _notesController,
            label: 'ملاحظات (اختياري)',
            icon: Icons.notes_rounded,
            maxLines: 2,
          ),
          const SizedBox(height: 24),

          // زر التحصيل
          GestureDetector(
            onTap: _isSaving ? null : _submitPayment,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primaryColor, Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.payments_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'تأكيد التحصيل',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? suffix,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
        color: _isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: _isDark ? Colors.grey[500] : Colors.grey[600],
        ),
        prefixIcon: Icon(
          icon,
          color: _isDark ? Colors.grey[500] : Colors.grey[600],
        ),
        suffixText: suffix,
        suffixStyle: TextStyle(
          color: _isDark ? Colors.grey[500] : Colors.grey[600],
        ),
        filled: true,
        fillColor: _isDark ? Colors.grey[800] : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required int? value,
    required List<DropdownMenuItem<int>> items,
    required ValueChanged<int?> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      style: TextStyle(
        color: _isDark ? Colors.white : Colors.black87,
      ),
      dropdownColor: _isDark ? const Color(0xFF1E1E2E) : Colors.white,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: _isDark ? Colors.grey[500] : Colors.grey[600],
        ),
        prefixIcon: Icon(
          icon,
          color: _isDark ? Colors.grey[500] : Colors.grey[600],
        ),
        filled: true,
        fillColor: _isDark ? Colors.grey[800] : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primaryColor, width: 2),
        ),
      ),
    );
  }
}