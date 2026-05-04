import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';

class ViewInstallmentsScreen extends StatefulWidget {
  final int financeId;
  final String childName;
  final double totalAmount;
  final String currentUser;

  const ViewInstallmentsScreen({
    super.key,
    required this.financeId,
    required this.childName,
    required this.totalAmount,
    required this.currentUser,
  });

  @override
  State<ViewInstallmentsScreen> createState() => _ViewInstallmentsScreenState();
}

class _ViewInstallmentsScreenState extends State<ViewInstallmentsScreen>
    with SingleTickerProviderStateMixin {
  
  // ═══════════════════════════════════════════════════════════════
  // المتغيرات
  // ═══════════════════════════════════════════════════════════════

  List<Map<String, dynamic>> _installments = [];
  bool _isLoading = true;

  late AnimationController _animController;

  // Formatters
  final _currencyFormat = NumberFormat('#,###', 'ar_EG');
  final _dateFormat = DateFormat('dd/MM/yyyy', 'ar_EG');

  // Colors
  static const _primaryColor = Color(0xFF6366F1);
  static const _successColor = Color(0xFF10B981);
  static const _warningColor = Color(0xFFF59E0B);
  static const _errorColor = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadInstallments();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  // ═══════════════════════════════════════════════════════════════
  // تحميل الأقساط
  // ═══════════════════════════════════════════════════════════════

  Future<void> _loadInstallments() async {
    setState(() => _isLoading = true);

    try {
      final response =
          await ApiService.getInstallmentsByFinanceId(widget.financeId);
      setState(() {
        _installments =
            response.map((item) => Map<String, dynamic>.from(item)).toList();
        _isLoading = false;
      });
      _animController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading installments: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // الحسابات
  // ═══════════════════════════════════════════════════════════════

  double get _paidAmount {
    double total = 0;
    for (var inst in _installments) {
      if (inst['PaymentDone'] == true || inst['PaymentDone'] == 1) {
        total += (inst['amountPyment'] ?? 0).toDouble();
      }
    }
    return total;
  }

  double get _remainingAmount => widget.totalAmount - _paidAmount;

  double get _progressValue {
    if (widget.totalAmount == 0) return 0;
    return (_paidAmount / widget.totalAmount).clamp(0.0, 1.0);
  }

  int get _paidCount {
    return _installments
        .where((i) => i['PaymentDone'] == true || i['PaymentDone'] == 1)
        .length;
  }

  // ═══════════════════════════════════════════════════════════════
  // تعديل قسط
  // ═══════════════════════════════════════════════════════════════

  Future<void> _editInstallment(Map<String, dynamic> installment) async {
    final amountController = TextEditingController(
      text: (installment['amountPyment'] ?? 0).toStringAsFixed(0),
    );
    final notesController = TextEditingController(
      text: installment['PaymentNotes'] ?? '',
    );

    DateTime selectedDate = DateTime.now();
    if (installment['MonthPayment'] != null) {
      selectedDate = DateTime.parse(installment['MonthPayment'].toString());
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Container(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
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
                        Icons.edit_rounded,
                        color: _primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'تعديل القسط',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // المبلغ
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: _isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'المبلغ',
                    suffixText: 'ج.م',
                    filled: true,
                    fillColor: _isDark ? Colors.grey[800] : Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: _primaryColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // التاريخ
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isDark ? Colors.grey[800] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _dateFormat.format(selectedDate),
                          style: TextStyle(
                            color: _isDark ? Colors.white : Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                        Icon(
                          Icons.calendar_today_rounded,
                          color: _isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ملاحظات
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  style: TextStyle(
                    color: _isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'ملاحظات',
                    filled: true,
                    fillColor: _isDark ? Colors.grey[800] : Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: _primaryColor, width: 2),
                    ),
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
                            color:
                                _isDark ? Colors.grey[600]! : Colors.grey[300]!,
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
                      child: ElevatedButton(
                        onPressed: () async {
                          final updateResult = await ApiService.updateInstallment(
                            id: installment['ID'],
                            amount:
                                double.tryParse(amountController.text) ?? 0,
                            date: selectedDate,
                            notes: notesController.text,
                            userEdit: widget.currentUser,
                            editTime: DateTime.now(),
                          );
                          Navigator.pop(
                              context, updateResult['success'] == true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'حفظ التعديلات',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    if (result == true) {
      _showSnackBar('تم تعديل القسط بنجاح ✅');
      _loadInstallments();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // حذف قسط
  // ═══════════════════════════════════════════════════════════════

  Future<void> _deleteInstallment(Map<String, dynamic> installment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDark ? const Color(0xFF1E1E2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline, color: _errorColor),
            ),
            const SizedBox(width: 12),
            Text(
              'تأكيد الحذف',
              style: TextStyle(
                color: _isDark ? Colors.white : Colors.black87,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'هل تريد حذف القسط بمبلغ ${(installment['amountPyment'] ?? 0).toStringAsFixed(0)} ج.م؟',
          style: TextStyle(
            color: _isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'إلغاء',
              style: TextStyle(
                color: _isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _errorColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await ApiService.deleteInstallment(installment['ID']);

      if (result['success'] == true) {
        _showSnackBar(result['message']);
        _loadInstallments();
      } else {
        _showSnackBar(result['message'], isError: true);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // تسجيل دفع قسط
  // ═══════════════════════════════════════════════════════════════

  Future<void> _payInstallment(Map<String, dynamic> installment) async {
    final notesController = TextEditingController();

    final confirm = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
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
              'تأكيد الدفع',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: _successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                '${_currencyFormat.format(installment['amountPyment'] ?? 0)} ج.م',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _successColor,
                ),
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: notesController,
              style: TextStyle(
                color: _isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                labelText: 'ملاحظات (اختياري)',
                filled: true,
                fillColor: _isDark ? Colors.grey[800] : Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          _isDark ? Colors.grey[400] : Colors.grey[600],
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
                      'تأكيد الدفع',
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
          ],
        ),
      ),
    );

    if (confirm == true) {
      final result = await ApiService.payInstallment(
        id: installment['ID'],
        notes: notesController.text,
        userEdit: widget.currentUser,
        editTime: DateTime.now(),
      );

      if (result['success'] == true) {
        HapticFeedback.heavyImpact();
        _showSnackBar(result['message']);
        _loadInstallments();
      } else {
        _showSnackBar(result['message'], isError: true);
      }
    }
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
      backgroundColor:
          _isDark ? const Color(0xFF0F0F1E) : const Color(0xFFF8FAFC),
      body: _isLoading ? _buildLoadingWidget() : _buildContent(),
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
            'جاري تحميل الأقساط...',
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
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildSliverAppBar(),
        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildHeader(),
              _buildProgressSection(),
              _buildInstallmentsList(),
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
        'أقساط الاشتراك',
        style: TextStyle(
          color: _isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: _loadInstallments,
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.refresh_rounded,
              size: 18,
              color: _primaryColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Container(
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.childName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeaderStat(
                'المطلوب',
                _currencyFormat.format(widget.totalAmount),
                Icons.account_balance_wallet_rounded,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildHeaderStat(
                'المدفوع',
                _currencyFormat.format(_paidAmount),
                Icons.check_circle_rounded,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildHeaderStat(
                'المتبقي',
                _currencyFormat.format(_remainingAmount),
                Icons.pending_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PROGRESS SECTION
  // ═══════════════════════════════════════════════════════════════

  Widget _buildProgressSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'نسبة السداد',
                style: TextStyle(
                  fontSize: 14,
                  color: _isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_paidCount / ${_installments.length} أقساط',
                  style: const TextStyle(
                    color: _successColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: _progressValue),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 14,
                  backgroundColor:
                      _isDark ? Colors.grey[800] : Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation(_successColor),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${(_progressValue * 100).toStringAsFixed(0)}% مكتمل',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // INSTALLMENTS LIST
  // ═══════════════════════════════════════════════════════════════

  Widget _buildInstallmentsList() {
    if (_installments.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: _isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: _isDark ? Colors.grey[700] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد أقساط مسجلة',
              style: TextStyle(
                fontSize: 16,
                color: _isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.list_alt_rounded,
                  color: _primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'تفاصيل الأقساط',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._installments.asMap().entries.map((entry) {
            return _buildInstallmentCard(entry.value, entry.key);
          }),
        ],
      ),
    );
  }

  Widget _buildInstallmentCard(Map<String, dynamic> installment, int index) {
    final isPaid =
        installment['PaymentDone'] == true || installment['PaymentDone'] == 1;

    DateTime? installmentDate;
    if (installment['MonthPayment'] != null) {
      installmentDate = DateTime.parse(installment['MonthPayment'].toString());
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPaid
              ? _successColor.withOpacity(_isDark ? 0.15 : 0.08)
              : (_isDark ? const Color(0xFF1E1E2E) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPaid
                ? _successColor.withOpacity(0.3)
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isPaid
                  ? _successColor.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Number / Check
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPaid
                      ? [_successColor, const Color(0xFF059669)]
                      : [_warningColor, const Color(0xFFD97706)],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: (isPaid ? _successColor : _warningColor)
                        .withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: isPaid
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 26)
                    : Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_currencyFormat.format(installment['amountPyment'] ?? 0)} ج.م',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isDark ? Colors.white : Colors.black87,
                      decoration:
                          isPaid ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (installmentDate != null)
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color:
                              _isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _dateFormat.format(installmentDate),
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                _isDark ? Colors.grey[500] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  if (installment['PaymentNotes'] != null &&
                      installment['PaymentNotes'].toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      installment['PaymentNotes'],
                      style: TextStyle(
                        fontSize: 12,
                        color: _isDark ? Colors.grey[600] : Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Status / Actions
            if (isPaid)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _successColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, color: Colors.white, size: 16),
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
            else
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'pay':
                      _payInstallment(installment);
                      break;
                    case 'edit':
                      _editInstallment(installment);
                      break;
                    case 'delete':
                      _deleteInstallment(installment);
                      break;
                  }
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: _isDark ? const Color(0xFF1E1E2E) : Colors.white,
                itemBuilder: (context) => [
                  _buildPopupMenuItem(
                    'pay',
                    'تسجيل دفع',
                    Icons.payment_rounded,
                    _successColor,
                  ),
                  _buildPopupMenuItem(
                    'edit',
                    'تعديل',
                    Icons.edit_rounded,
                    _primaryColor,
                  ),
                  _buildPopupMenuItem(
                    'delete',
                    'حذف',
                    Icons.delete_rounded,
                    _errorColor,
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.more_vert_rounded,
                    color: _isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
    String value,
    String text,
    IconData icon,
    Color color,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: _isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}