import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../services/api_service.dart';

class ChildDebtDetailsScreen extends StatefulWidget {
  final int childId;
  final String childName;
  final int sessionId;
  final String sessionName;

  const ChildDebtDetailsScreen({
    super.key,
    required this.childId,
    required this.childName,
    required this.sessionId,
    required this.sessionName,
  });

  @override
  State<ChildDebtDetailsScreen> createState() => _ChildDebtDetailsScreenState();
}

class _ChildDebtDetailsScreenState extends State<ChildDebtDetailsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<dynamic> _details = [];

  double _totalAmount = 0;
  double _totalPaid = 0;
  double _totalRemaining = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final NumberFormat _currencyFormat = NumberFormat('#,##0.00', 'ar_EG');

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.getChildDebtDetails(
        childId: widget.childId,
        sessionId: widget.sessionId,
      );

      if (mounted && result['success'] == true) {
        final data = result['data'] ?? [];

        double totalAmount = 0;
        double totalPaid = 0;
        double totalRemaining = 0;

        for (var item in data) {
          final summary = item['summary'];
          totalAmount += _toDouble(summary['totalAmount']);
          totalPaid += _toDouble(summary['totalPaid']);
          totalRemaining += _toDouble(summary['remaining']);
        }

        setState(() {
          _details = data;
          _totalAmount = totalAmount;
          _totalPaid = totalPaid;
          _totalRemaining = totalRemaining;
          _isLoading = false;
        });

        _animationController.forward(from: 0);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(isDark),
          if (!_isLoading && _details.isNotEmpty)
            SliverToBoxAdapter(child: _buildSummary(isDark)),
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                  ),
                )
              : _details.isEmpty
                  ? SliverFillRemaining(child: _buildEmptyState(isDark))
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildSubscriptionCard(
                                _details[index],
                                isDark,
                                index,
                              ),
                            );
                          },
                          childCount: _details.length,
                        ),
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 150,
      pinned: true,
      floating: false,
      elevation: 0,
      backgroundColor: const Color(0xFF6366F1),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: 24,
                left: 20,
                right: 20,
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          widget.childName.isNotEmpty ? widget.childName[0] : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.childName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'تفاصيل المديونية - ${widget.sessionName}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
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
        ),
      ),
    );
  }

  Widget _buildSummary(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _summaryCard('الإجمالي', _totalAmount, const Color(0xFF6366F1), Icons.receipt_long_rounded, isDark),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _summaryCard('المدفوع', _totalPaid, const Color(0xFF10B981), Icons.check_circle_rounded, isDark),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _summaryCard('المتبقي', _totalRemaining, const Color(0xFFEF4444), Icons.warning_rounded, isDark),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, double value, Color color, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _currencyFormat.format(value),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(dynamic item, bool isDark, int index) {
    final finance = item['finance'];
    final installments = item['installments'] as List<dynamic>;
    final payments = item['payments'] as List<dynamic>;
    final summary = item['summary'];

    final totalAmount = _toDouble(summary['totalAmount']);
    final totalPaid = _toDouble(summary['totalPaid']);
    final remaining = _toDouble(summary['remaining']);

    final kind = finance['Kind_subscrip'] ?? '';
    final isStudy = kind == 'اشتراك الدراسة السنوى';
    final color = isStudy ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 70)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252836) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            leading: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isStudy ? Icons.school_rounded : Icons.directions_bus_rounded,
                color: color,
                size: 22,
              ),
            ),
            title: Text(
              kind,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'المتبقي: ${_currencyFormat.format(remaining)} ج.م',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: remaining > 0
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
            children: [
              _infoRow('قيمة الاشتراك', totalAmount, isDark),
              _infoRow('المدفوع', totalPaid, isDark, color: const Color(0xFF10B981)),
              _infoRow('المتبقي', remaining, isDark, color: const Color(0xFFEF4444)),

              const SizedBox(height: 14),

              if (installments.isNotEmpty) ...[
                _sectionTitle('الأقساط', Icons.calendar_month_rounded, const Color(0xFF6366F1)),
                const SizedBox(height: 8),
                ...installments.map((inst) => _buildInstallmentRow(inst, isDark)).toList(),
                const SizedBox(height: 14),
              ],

              if (payments.isNotEmpty) ...[
                _sectionTitle('المدفوعات', Icons.payments_rounded, const Color(0xFF10B981)),
                const SizedBox(height: 8),
                ...payments.map((pay) => _buildPaymentRow(pay, isDark)).toList(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, double value, bool isDark, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              )),
          Text(
            '${_currencyFormat.format(value)} ج.م',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color ?? (isDark ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentRow(dynamic inst, bool isDark) {
    final amount = _toDouble(inst['amountPyment']);
    final isPaid = inst['PaymentDone'] == true || inst['PaymentDone'] == 1;
    DateTime? date;
    try {
      date = DateTime.parse(inst['MonthPayment'].toString());
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPaid
            ? const Color(0xFF10B981).withOpacity(0.08)
            : const Color(0xFFF59E0B).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPaid
              ? const Color(0xFF10B981).withOpacity(0.2)
              : const Color(0xFFF59E0B).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPaid ? Icons.check_circle_rounded : Icons.pending_rounded,
            color: isPaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              date != null
                  ? DateFormat('yyyy/MM/dd', 'ar_EG').format(date)
                  : '---',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Text(
            '${_currencyFormat.format(amount)} ج.م',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isPaid
                  ? const Color(0xFF10B981)
                  : const Color(0xFFF59E0B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(dynamic pay, bool isDark) {
    final amount = _toDouble(pay['incomeAmount']);
    DateTime? date;
    try {
      date = DateTime.parse(pay['date_Pay'].toString());
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.payments_rounded, color: Color(0xFF10B981), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date != null
                      ? DateFormat('yyyy/MM/dd', 'ar_EG').format(date)
                      : '---',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (pay['ReceiptNumber'] != null && pay['ReceiptNumber'].toString().isNotEmpty)
                  Text(
                    'إيصال: ${pay['ReceiptNumber']}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${_currencyFormat.format(amount)} ج.م',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_rounded,
              size: 60,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'لا توجد تفاصيل مديونية',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}