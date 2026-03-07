import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../providers/auth_provider.dart';
enum SubscriptionType { study, bus }

class SubscriptionPaymentScreen extends StatefulWidget {
  final SubscriptionType type;
  
  const SubscriptionPaymentScreen({
    super.key,
    this.type = SubscriptionType.study,
  });

  @override
  State<SubscriptionPaymentScreen> createState() =>
      _SubscriptionPaymentScreenState();
}

class _SubscriptionPaymentScreenState extends State<SubscriptionPaymentScreen>
    with TickerProviderStateMixin {
  
  // ═══════════════════════════════════════════════════════════════
  // Controllers
  // ═══════════════════════════════════════════════════════════════
  
  final _amountController = TextEditingController();
  final _receiptController = TextEditingController();
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

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

  int? _selectedSessionId;
  Map<String, dynamic>? _selectedChild;
  int? _selectedInstallmentId;
  
  // ✅ تاريخ بدون وقت
  DateTime _payDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  Map<String, dynamic>? _subscriptionData;
  List<dynamic> _installments = [];

  // ═══════════════════════════════════════════════════════════════
  // State
  // ═══════════════════════════════════════════════════════════════
  
  bool _isLoadingData = true;
  bool _isLoadingSubscription = false;
  bool _isSaving = false;
  bool _showChildSearch = false;

  // ═══════════════════════════════════════════════════════════════
  // Colors
  // ═══════════════════════════════════════════════════════════════
  
  static const _primaryColor = Color(0xFF6366F1);
  static const _successColor = Color(0xFF10B981);
  static const _warningColor = Color(0xFFF59E0B);
  static const _errorColor = Color(0xFFEF4444);
  static const _infoColor = Color(0xFF3B82F6);

  // ═══════════════════════════════════════════════════════════════
  // Formatters
  // ═══════════════════════════════════════════════════════════════
  
  final _currencyFormat = NumberFormat('#,###', 'ar_EG');
  final _dateFormat = DateFormat('dd/MM/yyyy', 'ar_EG');

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  // ═══════════════════════════════════════════════════════════════
// Subscription Type Helpers
// ═══════════════════════════════════════════════════════════════

bool get _isBus => widget.type == SubscriptionType.bus;
String get _typeKey => _isBus ? 'bus' : 'study';
int get _kindId => _isBus ? 7 : 6;
String get _screenTitle => _isBus ? 'تحصيل اشتراك الباص' : 'تحصيل اشتراك الدراسة';
IconData get _screenIcon => _isBus ? Icons.directions_bus_rounded : Icons.payments_rounded;

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
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // تحميل البيانات الأولية
  // ═══════════════════════════════════════════════════════════════

  Future<void> _loadInitialData() async {
    try {
      final sessions = await ApiService.get('general/sessions');
      setState(() {
        _sessions = sessions;
        _isLoadingData = false;
      });
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
        _subscriptionData = null;
        _installments = [];
        _searchController.clear();
      });
    } catch (e) {
      _showSnackBar('فشل تحميل الأطفال: $e', isError: true);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // فلترة الأطفال
  // ═══════════════════════════════════════════════════════════════

String _normalizeArabic(String text) {
  return text
      .replaceAll('ة', 'ه')
      .replaceAll('إ', 'ا')
      .replaceAll('أ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ي')
      .replaceAll('ى', 'ي')
      .replaceAll('َ', '')   // فتحة
      .replaceAll('ُ', '')   // ضمة
      .replaceAll('ِ', '')   // كسرة
      .replaceAll('ّ', '')   // شدة
      .replaceAll('ً', '')   // تنوين فتح
      .replaceAll('ٌ', '')   // تنوين ضم
      .replaceAll('ٍ', '')   // تنوين كسر
      .replaceAll('ْ', '')   // سكون
      .toLowerCase()
      .trim();
}

void _filterChildren(String query) {
  if (query.isEmpty) {
    setState(() => _filteredChildren = _children);
  } else {
    final normalizedQuery = _normalizeArabic(query);
    setState(() {
      _filteredChildren = _children.where((child) {
        final name = _normalizeArabic(
          (child['FullNameArabic'] ?? '').toString(),
        );
        return name.contains(normalizedQuery);
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
    });
    _loadSubscriptionDetails();
  }

  // ═══════════════════════════════════════════════════════════════
  // تحميل بيانات الاشتراك
  // ═══════════════════════════════════════════════════════════════

  Future<void> _loadSubscriptionDetails() async {
    if (_selectedChild == null || _selectedSessionId == null) return;

    setState(() {
      _isLoadingSubscription = true;
      _subscriptionData = null;
      _installments = [];
      _selectedInstallmentId = null;
      _amountController.clear();
    });

    try {
      final childId = _selectedChild!['ID_Child'];
      final result = await ApiService.getChildSubscriptionDetails(
        childId: childId,
        sessionId: _selectedSessionId!,
        type: _typeKey,
      );

      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _subscriptionData = result['data'];
          _installments = result['data']['installments'] ?? [];
          _isLoadingSubscription = false;
        });
        _contentAnimController.reset();
        _contentAnimController.forward();
      } else {
        setState(() {
          _subscriptionData = null;
          _isLoadingSubscription = false;
        });
        _showSnackBar(result['message'] ?? 'لا يوجد اشتراك لهذا الطفل', isError: true);
      }
    } catch (e) {
      setState(() => _isLoadingSubscription = false);
      _showSnackBar('فشل تحميل بيانات الاشتراك: $e', isError: true);
    }
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
  // اختيار قسط
  // ═══════════════════════════════════════════════════════════════

  void _selectInstallment(Map<String, dynamic> installment) {
    final isPaid = installment['PaymentDone'] == true || 
                   installment['PaymentDone'] == 1;
    if (isPaid) return;

    HapticFeedback.lightImpact();

    setState(() {
      if (_selectedInstallmentId == installment['ID']) {
        _selectedInstallmentId = null;
        _amountController.clear();
      } else {
        _selectedInstallmentId = installment['ID'];
        _amountController.text = 
            (installment['amountPyment'] ?? 0).toStringAsFixed(0);
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // تحصيل المبلغ
  // ═══════════════════════════════════════════════════════════════

  Future<void> _submitPayment() async {
    if (_selectedChild == null) {
      _showSnackBar('اختر الطفل أولاً', isError: true);
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showSnackBar('أدخل مبلغ صحيح', isError: true);
      return;
    }

    // ✅ عرض Bottom Sheet للتأكيد
    final confirm = await _showPaymentConfirmation(amount);
    if (confirm != true) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final user = Provider.of<AuthProvider>(context, listen: false)
              .user
              ?.fullName ??
          'System';
      final branchId = _selectedChild!['Branch'] ?? 1;

      // ✅ تاريخ بدون وقت
      final payDateOnly = DateTime(
        _payDate.year,
        _payDate.month,
        _payDate.day,
      );

      final result = await ApiService.addSubscriptionPayment(
        amount: amount,
        childId: _selectedChild!['ID_Child'],
        branchId: branchId,
        sessionId: _selectedSessionId!,
        kindId: _kindId,
        receiptNo: _receiptController.text.isEmpty 
            ? null 
            : _receiptController.text,
        notes: _notesController.text.isEmpty 
            ? null 
            : _notesController.text,
        installmentId: _selectedInstallmentId,
        userAdd: user,
        addTime: DateTime.now(),
        payDate: payDateOnly,
      );

      setState(() => _isSaving = false);

      if (result['success'] == true) {
        HapticFeedback.heavyImpact();
        _showSnackBar(result['message'] ?? 'تم التحصيل بنجاح');
        _loadSubscriptionDetails();
        _clearPaymentForm();
      } else {
        _showSnackBar(result['message'] ?? 'فشل التحصيل', isError: true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showSnackBar('فشل التحصيل: $e', isError: true);
    }
  }

  void _clearPaymentForm() {
    _amountController.clear();
    _receiptController.clear();
    _notesController.clear();
    _selectedInstallmentId = null;
    _payDate = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Bottom Sheet للتأكيد
  // ═══════════════════════════════════════════════════════════════

  Future<bool?> _showPaymentConfirmation(double amount) {
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
                Icons.payment_rounded,
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
                  _buildConfirmationRow(
                    'الطفل',
                    _selectedChild!['FullNameArabic'] ?? '',
                    Icons.child_care_rounded,
                  ),
                  const Divider(height: 24),
                  _buildConfirmationRow(
                    'المبلغ',
                    '${_currencyFormat.format(amount)} ج.م',
                    Icons.attach_money_rounded,
                    valueColor: _successColor,
                  ),
                  const Divider(height: 24),
                  _buildConfirmationRow(
                    'تاريخ الدفع',
                    _dateFormat.format(_payDate),
                    Icons.calendar_today_rounded,
                  ),
                  if (_selectedInstallmentId != null) ...[
                    const Divider(height: 24),
                    _buildConfirmationRow(
                      'القسط',
                      'سيتم تحديث حالة القسط تلقائياً',
                      Icons.check_circle_rounded,
                      valueColor: _infoColor,
                    ),
                  ],
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
                      foregroundColor: _isDark ? Colors.grey[400] : Colors.grey[600],
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

  Widget _buildConfirmationRow(
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
  // BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDark ? const Color(0xFF0F0F1E) : const Color(0xFFF8FAFC),
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
              if (_isLoadingSubscription)
                _buildSubscriptionLoading()
              else if (_subscriptionData != null)
                FadeTransition(
                  opacity: _contentAnimation,
                  child: _buildSubscriptionContent(),
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
        _screenTitle,
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
            // أيقونة
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _screenIcon,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),

            // العام المالي
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedSessionId,
                  hint: Text(
                    'اختر العام المالي',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  items: _sessions.map((s) {
                    return DropdownMenuItem<int>(
                      value: s['IDSession'],
                      child: Text(s['Sessions'] ?? ''),
                    );
                  }).toList(),
                  onChanged: (value) {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedSessionId = value;
                      _selectedChild = null;
                      _subscriptionData = null;
                    });
                    if (value != null) {
                      _loadChildren(value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // البحث عن الطفل
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    enabled: _selectedSessionId != null,
                    style: TextStyle(color: Colors.grey[800]),
                    decoration: InputDecoration(
                      hintText: _selectedSessionId == null
                          ? 'اختر العام المالي أولاً'
                          : 'ابحث عن الطفل...',
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
                                  _subscriptionData = null;
                                  _filteredChildren = _children;
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onTap: () {
                      if (_selectedSessionId != null) {
                        setState(() => _showChildSearch = true);
                      }
                    },
                    onChanged: (value) {
                      _filterChildren(value);
                      setState(() => _showChildSearch = true);
                    },
                  ),

                  // قائمة نتائج البحث
                  if (_showChildSearch && _filteredChildren.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(14),
                          bottomRight: Radius.circular(14),
                        ),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredChildren.length,
                        itemBuilder: (context, index) {
                          final child = _filteredChildren[index];
                          return ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _primaryColor.withOpacity(0.8),
                                    _primaryColor,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  (child['FullNameArabic'] ?? 'ط')[0],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              child['FullNameArabic'] ?? '',
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onTap: () => _selectChild(
                              Map<String, dynamic>.from(child),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SUBSCRIPTION LOADING
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSubscriptionLoading() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            'جاري تحميل بيانات الاشتراك...',
            style: TextStyle(
              color: _isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SUBSCRIPTION CONTENT
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSubscriptionContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: Column(
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 16),
          if (_installments.isNotEmpty) _buildInstallmentsCard(),
          const SizedBox(height: 16),
          _buildPaymentForm(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SUMMARY CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSummaryCard() {
    final summary = _subscriptionData!['summary'];
    final totalAmount = (summary?['totalAmount'] ?? 0).toDouble();
    final totalPaid = (summary?['totalPaid'] ?? 0).toDouble();
    final remaining = (summary?['remaining'] ?? 0).toDouble();
    final progress = totalAmount > 0 ? (totalPaid / totalAmount) : 0.0;

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
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: _primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedChild?['FullNameArabic'] ?? '',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
  _subscriptionData!['finance']?['SessionName'] ?? '',
  style: TextStyle(
    color: _isDark ? Colors.grey[500] : Colors.grey[600],
    fontSize: 13,
  ),
),
if (_isBus && _subscriptionData!['finance']?['BusLineName'] != null)
  Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.directions_bus_rounded,
          size: 14,
          color: _warningColor,
        ),
        const SizedBox(width: 4),
        Text(
          _subscriptionData!['finance']?['BusLineName'] ?? '',
          style: TextStyle(
            color: _warningColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'المطلوب',
                  _currencyFormat.format(totalAmount),
                  Icons.request_quote_rounded,
                  _infoColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatItem(
                  'المدفوع',
                  _currencyFormat.format(totalPaid),
                  Icons.check_circle_rounded,
                  _successColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatItem(
                  'المتبقي',
                  _currencyFormat.format(remaining),
                  Icons.pending_rounded,
                  _errorColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress Bar
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'نسبة السداد',
                    style: TextStyle(
                      fontSize: 13,
                      color: _isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (progress >= 1 ? _successColor : _primaryColor)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: progress >= 1 ? _successColor : _primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 12,
                      backgroundColor:
                          _isDark ? Colors.grey[800] : Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(
                        progress >= 1 ? _successColor : _primaryColor,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          Text(
            'ج.م',
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // INSTALLMENTS CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildInstallmentsCard() {
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
                  color: _warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: _warningColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'الأقساط',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_installments.length}',
                  style: const TextStyle(
                    color: _warningColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على القسط لتحديده',
            style: TextStyle(
              fontSize: 12,
              color: _isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),

          // Installments List
          ...List.generate(_installments.length, (index) {
            return _buildInstallmentItem(_installments[index], index);
          }),
        ],
      ),
    );
  }

  Widget _buildInstallmentItem(Map<String, dynamic> inst, int index) {
    final isPaid = inst['PaymentDone'] == true || inst['PaymentDone'] == 1;
    final isSelected = _selectedInstallmentId == inst['ID'];

    DateTime? instDate;
    if (inst['MonthPayment'] != null) {
      instDate = DateTime.parse(inst['MonthPayment'].toString());
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(20 * (1 - value), 0),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTap: () => _selectInstallment(inst),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isPaid
                ? _successColor.withOpacity(_isDark ? 0.15 : 0.08)
                : isSelected
                    ? _primaryColor.withOpacity(_isDark ? 0.15 : 0.08)
                    : (_isDark ? Colors.grey[800] : Colors.grey[50]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPaid
                  ? _successColor.withOpacity(0.5)
                  : isSelected
                      ? _primaryColor
                      : Colors.transparent,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Number / Check
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isPaid
                        ? [_successColor, const Color(0xFF059669)]
                        : isSelected
                            ? [_primaryColor, const Color(0xFF8B5CF6)]
                            : [_warningColor, const Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: isPaid
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 22)
                      : Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_currencyFormat.format(inst['amountPyment'] ?? 0)} ج.م',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        decoration: isPaid ? TextDecoration.lineThrough : null,
                        color: isPaid
                            ? (_isDark ? Colors.grey[500] : Colors.grey)
                            : (_isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    if (instDate != null)
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color:
                                _isDark ? Colors.grey[500] : Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _dateFormat.format(instDate),
                            style: TextStyle(
                              fontSize: 12,
                              color: _isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Status
              if (isPaid)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _successColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'مدفوع',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else if (isSelected)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: _primaryColor,
                    size: 22,
                  ),
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
            label: 'المبلغ المدفوع',
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
                            Icons.payment_rounded,
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
}