import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

class ChildFinanceScreen extends StatefulWidget {
  final int childId;
  final String childName;

  const ChildFinanceScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<ChildFinanceScreen> createState() => _ChildFinanceScreenState();
}

class _ChildFinanceScreenState extends State<ChildFinanceScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _amountBaseController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _amountSubController = TextEditingController();
  final _dateController = TextEditingController();

  List<dynamic> _sessions = [];
  List<dynamic> _busLines = [];
  List<dynamic> _history = [];

  int? _selectedSession;
  int? _selectedBusLine;
  String? _selectedKind;
  int? _editingId; // 👈 لتتبع التعديل

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isFormExpanded = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Summary Data
  double _totalSubscriptions = 0;
  double _totalPaid = 0;
  int _activeSubscriptions = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _dateController.text = DateTime.now().toString().split(' ')[0];
    _loadData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  void _loadData() async {
    try {
      final sessions = await ApiService.get('general/sessions');
      final buses = await ApiService.get('bus-lines');
      final history = await ApiService.getChildFinance(widget.childId);

      if (mounted) {
        setState(() {
          _sessions = sessions;
          _busLines = buses;
          _history = history;
          _isLoading = false;
          _calculateSummary();
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _calculateSummary() {
    _totalSubscriptions = 0;
    _totalPaid = 0;
    _activeSubscriptions = _history.length;

    for (var item in _history) {
      _totalSubscriptions += (item['amountBase'] ?? 0).toDouble();
      _totalPaid += (item['amount_Sub'] ?? 0).toDouble();
    }
  }

  void _calculateNet() {
    double base = double.tryParse(_amountBaseController.text) ?? 0;
    double discount = double.tryParse(_discountController.text) ?? 0;
    _amountSubController.text = (base - discount).toStringAsFixed(2);
  }

  Future<void> _pickDate() async {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDark;

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF10B981),
              onPrimary: Colors.white,
              surface: isDark ? const Color(0xFF252836) : Colors.white,
              onSurface: isDark ? Colors.white : Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateController.text = picked.toString().split(' ')[0]);
    }
  }

  void _resetForm() {
    setState(() {
      _editingId = null;
      _selectedSession = null;
      _selectedBusLine = null;
      _selectedKind = null;
      _amountBaseController.clear();
      _discountController.text = '0';
      _amountSubController.clear();
      _dateController.text = DateTime.now().toString().split(' ')[0];
    });
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final user =
        Provider.of<AuthProvider>(context, listen: false).user?.fullName ??
            "System";

    final data = {
      'childId': widget.childId,
      'sessionId': _selectedSession,
      'kindSubscription': _selectedKind,
      'subDate': _dateController.text,
      'amountBase': double.parse(_amountBaseController.text),
      'amountSub': double.parse(_amountSubController.text),
      'discount': double.parse(_discountController.text),
      'busLineId': _selectedBusLine,
      'user': user,
    };

    try {
      await ApiService.post('child-finance', data);
      _showSuccessSnackBar(
          _editingId != null ? 'تم التعديل بنجاح ✅' : 'تم الحفظ بنجاح ✅');
      _resetForm();
      _loadData();
      setState(() => _isFormExpanded = false);
    } catch (e) {
      _showErrorSnackBar('خطأ: $e');
    }
    setState(() => _isSaving = false);
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Text(message),
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
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
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
    _animationController.dispose();
    _amountBaseController.dispose();
    _discountController.dispose();
    _amountSubController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF10B981)),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 🎨 App Bar
                _buildSliverAppBar(isDark),

                // 📊 Summary Cards
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildSummaryCards(isDark),
                  ),
                ),

                // ➕ Add/Edit Form
                SliverToBoxAdapter(
                  child: _buildFormSection(isDark),
                ),

                // 📋 History Header
                SliverToBoxAdapter(
                  child: _buildSectionHeader(isDark),
                ),

                // 📋 History List
                _history.isEmpty
                    ? SliverToBoxAdapter(child: _buildEmptyState(isDark))
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration:
                                    Duration(milliseconds: 400 + (index * 50)),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Transform.translate(
                                    offset: Offset(0, 30 * (1 - value)),
                                    child: Opacity(opacity: value, child: child),
                                  );
                                },
                                child: _buildHistoryCard(_history[index], isDark, index),
                              );
                            },
                            childCount: _history.length,
                          ),
                        ),
                      ),

                // Bottom Padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),

      // ➕ FAB
      floatingActionButton: _buildFAB(),
    );
  }

  // 🎨 Sliver App Bar
  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF10B981),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
          ),
          onPressed: () {
            setState(() => _isLoading = true);
            _loadData();
          },
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: Colors.white, size: 20),
          ),
          onPressed: () {
            // TODO: Export or Print
          },
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF10B981), Color(0xFF059669)],
            ),
          ),
          child: Stack(
            children: [
              // Decorative Elements
              Positioned(
                right: -60,
                top: -60,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                left: -40,
                bottom: 30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),

              // Content
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "الإدارة المالية",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.childName,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 📊 Summary Cards
  Widget _buildSummaryCards(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              title: "الاشتراكات",
              value: _activeSubscriptions.toString(),
              icon: Icons.receipt_rounded,
              color: const Color(0xFF6366F1),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              title: "الإجمالي",
              value: "${_totalSubscriptions.toStringAsFixed(0)} ج",
              icon: Icons.payments_rounded,
              color: const Color(0xFF10B981),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              title: "المدفوع",
              value: "${_totalPaid.toStringAsFixed(0)} ج",
              icon: Icons.check_circle_rounded,
              color: const Color(0xFFF59E0B),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // ➕ Form Section
  Widget _buildFormSection(bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isFormExpanded
              ? const Color(0xFF10B981)
              : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _isFormExpanded
                ? const Color(0xFF10B981).withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: _isFormExpanded ? 20 : 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header (Always Visible)
          GestureDetector(
            onTap: () => setState(() => _isFormExpanded = !_isFormExpanded),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _editingId != null
                          ? Icons.edit_rounded
                          : Icons.add_rounded,
                      color: const Color(0xFF10B981),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _editingId != null
                              ? "تعديل الاشتراك"
                              : "إضافة اشتراك جديد",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "اضغط للتوسيع",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isFormExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Form Content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildFormContent(isDark),
            crossFadeState: _isFormExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent(bool isDark) {
    return Column(
      children: [
        Divider(
          height: 1,
          color: isDark ? Colors.grey[800] : Colors.grey[200],
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Session Dropdown
                _buildModernDropdown(
                  value: _selectedSession,
                  label: "السنة الدراسية",
                  icon: Icons.calendar_today_rounded,
                  isDark: isDark,
                  items: _sessions
                      .map((s) => DropdownMenuItem<int>(
                            value: s['IDSession'],
                            child: Text(s['Sessions']),
                          ))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _selectedSession = val as int?),
                  validator: (v) => v == null ? "مطلوب" : null,
                ),

                const SizedBox(height: 14),

                // Kind Dropdown
                _buildModernDropdown(
                  value: _selectedKind,
                  label: "نوع الاشتراك",
                  icon: Icons.category_rounded,
                  isDark: isDark,
                  items: const [
                    DropdownMenuItem(
                      value: "اشتراك الدراسة السنوى",
                      child: Row(
                        children: [
                          Icon(Icons.school_rounded,
                              size: 18, color: Color(0xFF6366F1)),
                          SizedBox(width: 8),
                          Text("اشتراك دراسة"),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: "اشتراك الباص",
                      child: Row(
                        children: [
                          Icon(Icons.directions_bus_rounded,
                              size: 18, color: Color(0xFFF59E0B)),
                          SizedBox(width: 8),
                          Text("اشتراك باص"),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (val) =>
                      setState(() => _selectedKind = val as String?),
                  validator: (v) => v == null ? "مطلوب" : null,
                ),

                // Bus Line (Conditional)
                if (_selectedKind == "اشتراك الباص") ...[
                  const SizedBox(height: 14),
                  _buildModernDropdown(
                    value: _selectedBusLine,
                    label: "خط الباص",
                    icon: Icons.route_rounded,
                    isDark: isDark,
                    color: const Color(0xFFF59E0B),
                    items: _busLines
                        .map((b) => DropdownMenuItem<int>(
                              value: b['ID'],
                              child: Text(b['BusLine']),
                            ))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedBusLine = val as int?),
                    validator: (v) => v == null ? "مطلوب" : null,
                  ),
                ],

                const SizedBox(height: 14),

                // Date
                _buildModernTextField(
                  controller: _dateController,
                  label: "تاريخ الاشتراك",
                  icon: Icons.event_rounded,
                  isDark: isDark,
                  readOnly: true,
                  onTap: _pickDate,
                ),

                const SizedBox(height: 14),

                // Amount Row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildModernTextField(
                        controller: _amountBaseController,
                        label: "المبلغ",
                        icon: Icons.attach_money_rounded,
                        isDark: isDark,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _calculateNet(),
                        validator: (v) => v!.isEmpty ? "مطلوب" : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildModernTextField(
                        controller: _discountController,
                        label: "الخصم",
                        icon: Icons.discount_rounded,
                        isDark: isDark,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _calculateNet(),
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Net Amount
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calculate_rounded,
                          color: Color(0xFF10B981),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "الصافي المستحق",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${_amountSubController.text.isEmpty ? '0.00' : _amountSubController.text} ج.م",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    if (_editingId != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _resetForm();
                            setState(() => _isFormExpanded = false);
                          },
                          icon: const Icon(Icons.close_rounded),
                          label: const Text("إلغاء"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[600],
                            side: BorderSide(color: Colors.grey[400]!),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    if (_editingId != null) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _save,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  _editingId != null
                                      ? Icons.save_rounded
                                      : Icons.add_rounded,
                                ),
                          label: Text(
                            _editingId != null ? "حفظ التعديلات" : "إضافة الاشتراك",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 📋 Section Header
  Widget _buildSectionHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: Color(0xFF6366F1),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "سجل الاشتراكات",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${_history.length}",
              style: const TextStyle(
                color: Color(0xFF6366F1),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 📋 History Card
  Widget _buildHistoryCard(Map<String, dynamic> item, bool isDark, int index) {
    String dateStr = "---";
    if (item['SubDate'] != null) {
      dateStr = item['SubDate'].toString().split('T')[0];
    }

    bool isBus = item['Kind_subscrip'] == "اشتراك الباص" ||
        item['BusLineName'] != null;

    final color = isBus ? const Color(0xFFF59E0B) : const Color(0xFF6366F1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Side Accent
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [color, color.withOpacity(0.5)],
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isBus
                              ? Icons.directions_bus_rounded
                              : Icons.school_rounded,
                          color: color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['Kind_subscrip'] ?? "اشتراك",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 14,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Edit Button
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _editingId = item['ID'];
                            _selectedSession = item['SessionID'];
                            _selectedBusLine = item['BusLine'];
                            _selectedKind = item['Kind_subscrip'];
                            _dateController.text = dateStr;
                            _amountBaseController.text =
                                item['amountBase'].toString();
                            _discountController.text =
                                item['discount'].toString();
                            _amountSubController.text =
                                item['amount_Sub'].toString();
                            _isFormExpanded = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF3B82F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Color(0xFF3B82F6),
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Details Row
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey[800]!.withOpacity(0.3)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildDetailItem(
                            icon: Icons.attach_money_rounded,
                            label: "المبلغ",
                            value: "${item['amountBase'] ?? 0}",
                            isDark: isDark,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: isDark
                              ? Colors.grey[700]
                              : Colors.grey[300],
                        ),
                        Expanded(
                          child: _buildDetailItem(
                            icon: Icons.discount_rounded,
                            label: "الخصم",
                            value: "${item['discount'] ?? 0}",
                            isDark: isDark,
                            valueColor: const Color(0xFFEF4444),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: isDark
                              ? Colors.grey[700]
                              : Colors.grey[300],
                        ),
                        Expanded(
                          child: _buildDetailItem(
                            icon: Icons.check_circle_rounded,
                            label: "الصافي",
                            value: "${item['amount_Sub'] ?? 0}",
                            isDark: isDark,
                            valueColor: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Session Badge
                  if (item['SessionName'] != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.school_rounded,
                            size: 14,
                            color: Color(0xFF8B5CF6),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item['SessionName'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8B5CF6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor ?? (isDark ? Colors.white : Colors.black87),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  // 📭 Empty State
  Widget _buildEmptyState(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              size: 50,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "لا يوجد اشتراكات",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "اضغط على + لإضافة اشتراك جديد",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () =>
                setState(() => _isFormExpanded = true),
            icon: const Icon(Icons.add_rounded),
            label: const Text("إضافة اشتراك"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ➕ FAB
  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          _resetForm();
          setState(() => _isFormExpanded = true);
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(
          Icons.add_rounded,
          size: 28,
          color: Colors.white,
        ),
      ),
    );
  }

  // 🔤 Modern Text Field
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    void Function()? onTap,
    TextInputType? keyboardType,
    bool readOnly = false,
    Color color = const Color(0xFF10B981),
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      onTap: onTap,
      keyboardType: keyboardType,
      readOnly: readOnly,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[500],
          fontSize: 14,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  // 🔽 Modern Dropdown
  Widget _buildModernDropdown<T>({
    required T? value,
    required String label,
    required IconData icon,
    required bool isDark,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?)? onChanged,
    String? Function(T?)? validator,
    Color color = const Color(0xFF10B981),
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      dropdownColor: isDark ? const Color(0xFF252836) : Colors.white,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[500],
          fontSize: 14,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}