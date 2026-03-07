import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../providers/debt_provider.dart';
import '../providers/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class DebtDetailsScreen extends StatefulWidget {
  final int childId;
  final String childName;
  final int sessionId;

  const DebtDetailsScreen({
    super.key,
    required this.childId,
    required this.childName,
    required this.sessionId,
  });

  @override
  State<DebtDetailsScreen> createState() => _DebtDetailsScreenState();
}

class _DebtDetailsScreenState extends State<DebtDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Provider.of<DebtProvider>(context, listen: false).fetchChildDebtDetails(
      childId: widget.childId,
      sessionId: widget.sessionId,
    );
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      final dateTime = DateTime.parse(date.toString());
      return DateFormat('yyyy/MM/dd').format(dateTime);
    } catch (e) {
      return date.toString();
    }
  }

  String _formatMonth(dynamic date) {
    if (date == null) return '';
    try {
      final dateTime = DateTime.parse(date.toString());
      const months = [
        'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
        'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
      ];
      return '${months[dateTime.month - 1]} ${dateTime.year}';
    } catch (e) {
      return '';
    }
  }

  String _formatCurrency(dynamic amount) {
    double value = double.tryParse(amount?.toString() ?? '0') ?? 0;
    return '${value.toStringAsFixed(0)} ج.م';
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final debtProvider = Provider.of<DebtProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    final details = debtProvider.childDebtDetails;

    // حساب الإجماليات
    double totalAmount = 0;
    double totalPaid = 0;
    double totalRemaining = 0;
    bool hasOverdue = false;
    String? fatherPhone;
    String? motherPhone;
    String? fatherName;
    String? motherName;
    String? branchName;
    String? className;

    for (var detail in details) {
      final summary = detail['summary'];
      totalAmount += double.tryParse(summary['totalAmount']?.toString() ?? '0') ?? 0;
      totalPaid += double.tryParse(summary['totalPaid']?.toString() ?? '0') ?? 0;
      totalRemaining += double.tryParse(summary['remaining']?.toString() ?? '0') ?? 0;

      final finance = detail['finance'];
      fatherPhone ??= finance['FatherMobile1'];
      motherPhone ??= finance['MotherMobile1'];
      fatherName ??= finance['FatherName'];
      motherName ??= finance['MotherName'];
      branchName ??= finance['branchName'];
      className ??= finance['ClassName'];

      // فحص التأخير
      final installments = detail['installments'] as List? ?? [];
      for (var inst in installments) {
        if ((inst['PaymentDone'] == false || inst['PaymentDone'] == 0) &&
            DateTime.tryParse(inst['MonthPayment']?.toString() ?? '')
                ?.isBefore(DateTime.now()) == true) {
          hasOverdue = true;
        }
      }
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
      floatingActionButton: totalRemaining > 0
          ? FloatingActionButton.extended(
              heroTag: "collect_payment_fab",
              onPressed: () {
                // TODO: فتح شاشة التحصيل
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("سيتم إضافة شاشة التحصيل قريباً"),
                    backgroundColor: const Color(0xFF6366F1),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              },
              backgroundColor: const Color(0xFF10B981),
              icon: const Icon(Icons.payments_rounded, color: Colors.white),
              label: const Text("تحصيل",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFF6366F1),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            _buildSliverAppBar(isDark, fatherPhone, motherPhone),

            if (debtProvider.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
              )
            else if (details.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text("لا توجد اشتراكات لهذا الطفل",
                        style: TextStyle(fontSize: 18, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                    ],
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // تنبيه التأخير
                      if (hasOverdue) _buildOverdueBanner(isDark),

                      if (hasOverdue) const SizedBox(height: 16),

                      // معلومات الطفل
                      _buildChildInfoCard(isDark, branchName, className,
                          fatherName, fatherPhone, motherName, motherPhone),

                      const SizedBox(height: 16),

                      // الملخص الدائري
                      _buildCircularSummary(isDark, totalAmount, totalPaid, totalRemaining),

                      const SizedBox(height: 16),

                      // الاشتراكات
                      ...details.map((detail) {
                        return Column(
                          children: [
                            _buildSubscriptionCard(detail, isDark),
                            const SizedBox(height: 16),
                            _buildInstallmentsTimeline(detail, isDark),
                            const SizedBox(height: 16),
                            _buildPaymentsCard(detail, isDark),
                            const SizedBox(height: 16),
                          ],
                        );
                      }).toList(),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==================== AppBar ====================

  Widget _buildSliverAppBar(bool isDark, String? fatherPhone, String? motherPhone) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
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
      actions: [
        if (fatherPhone != null || motherPhone != null)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.phone_rounded, color: Colors.white, size: 20),
            ),
            onPressed: () => _showCallDialog(fatherPhone, motherPhone),
          ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
          ),
          onPressed: _refresh,
        ),
        const SizedBox(width: 8),
      ],
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
              Positioned(right: -50, top: -50,
                child: Container(width: 200, height: 200,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)))),
              Positioned(left: -30, bottom: 30,
                child: Container(width: 100, height: 100,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)))),
              Positioned(
                bottom: 30, left: 20, right: 20,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(widget.childName,
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text("تفاصيل المديونية",
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
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

  // ==================== تنبيه التأخير ====================

  Widget _buildOverdueBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.red.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.warning_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("تنبيه تأخر في السداد!",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text("يوجد أقساط متأخرة يرجى المتابعة",
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== معلومات الطفل ====================

  Widget _buildChildInfoCard(bool isDark, String? branchName, String? className,
      String? fatherName, String? fatherPhone, String? motherName, String? motherPhone) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info_rounded, color: Color(0xFF6366F1), size: 20),
              ),
              const SizedBox(width: 10),
              Text("معلومات الطفل",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
          const SizedBox(height: 16),

          // الفرع والفصل
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.store_rounded,
                  label: "الفرع",
                  value: branchName ?? "غير محدد",
                  color: const Color(0xFF6366F1),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.meeting_room_rounded,
                  label: "الفصل",
                  value: className ?? "غير مسكن",
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ولي الأمر
          Row(
            children: [
              if (fatherName != null)
                Expanded(
                  child: _buildContactItem(
                    icon: Icons.male_rounded,
                    name: fatherName,
                    phone: fatherPhone,
                    color: const Color(0xFF3B82F6),
                    isDark: isDark,
                  ),
                ),
              if (fatherName != null && motherName != null)
                const SizedBox(width: 12),
              if (motherName != null)
                Expanded(
                  child: _buildContactItem(
                    icon: Icons.female_rounded,
                    name: motherName,
                    phone: motherPhone,
                    color: const Color(0xFFEC4899),
                    isDark: isDark,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon, required String label, required String value,
    required Color color, required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87),
                  overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon, required String name, String? phone,
    required Color color, required bool isDark,
  }) {
    return GestureDetector(
      onTap: phone != null ? () => _makeCall(phone) : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87),
                    overflow: TextOverflow.ellipsis),
                  if (phone != null)
                    Text(phone, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ),
            ),
            if (phone != null)
              Icon(Icons.call_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  // ==================== الملخص الدائري ====================

  Widget _buildCircularSummary(bool isDark, double totalAmount, double totalPaid, double remaining) {
    double progress = totalAmount > 0 ? (totalPaid / totalAmount).clamp(0.0, 1.0) : 0.0;
    Color progressColor = progress >= 1.0
        ? const Color(0xFF10B981)
        : progress >= 0.5
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.pie_chart_rounded, color: Color(0xFF6366F1), size: 20),
              ),
              const SizedBox(width: 10),
              Text("ملخص السداد",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
          const SizedBox(height: 20),

          // الدائرة
          SizedBox(
            width: 160, height: 160,
            child: CustomPaint(
              painter: _CircularProgressPainter(
                progress: progress,
                progressColor: progressColor,
                backgroundColor: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("${(progress * 100).toStringAsFixed(0)}%",
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: progressColor)),
                    Text("مدفوع", style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // التفاصيل
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  label: "المطلوب",
                  value: _formatCurrency(totalAmount),
                  color: const Color(0xFF6366F1),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryItem(
                  label: "المدفوع",
                  value: _formatCurrency(totalPaid),
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSummaryItem(
                  label: "المتبقي",
                  value: _formatCurrency(remaining),
                  color: remaining > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label, required String value, required Color color, required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ],
      ),
    );
  }

  // ==================== كارت الاشتراك ====================

  Widget _buildSubscriptionCard(dynamic detail, bool isDark) {
    final finance = detail['finance'];
    final summary = detail['summary'];
    final String kind = finance['Kind_subscrip'] ?? '';
    final double amountBase = double.tryParse(finance['amountBase']?.toString() ?? '0') ?? 0;
    final double discount = double.tryParse(finance['discount']?.toString() ?? '0') ?? 0;
    final double totalAmount = double.tryParse(summary['totalAmount']?.toString() ?? '0') ?? 0;
    bool isStudy = kind.contains('الدراسة');
    Color color = isStudy ? const Color(0xFF6366F1) : const Color(0xFFF59E0B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(isStudy ? Icons.school_rounded : Icons.directions_bus_rounded,
                  color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(kind,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAmountColumn("المبلغ الأصلي", amountBase, Colors.grey[600]!, isDark),
              if (discount > 0)
                _buildAmountColumn("الخصم", discount, const Color(0xFF10B981), isDark),
              _buildAmountColumn("المطلوب", totalAmount, color, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountColumn(String label, double amount, Color color, bool isDark) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        const SizedBox(height: 4),
        Text(_formatCurrency(amount),
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  // ==================== Timeline الأقساط ====================

  Widget _buildInstallmentsTimeline(dynamic detail, bool isDark) {
    final installments = detail['installments'] as List? ?? [];
    if (installments.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18), topRight: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.timeline_rounded, color: Color(0xFFF59E0B), size: 20),
                ),
                const SizedBox(width: 10),
                Text("الأقساط (${installments.length})",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: List.generate(installments.length, (index) {
                final inst = installments[index];
                final bool isPaid = inst['PaymentDone'] == true || inst['PaymentDone'] == 1;
                final double amount = double.tryParse(inst['amountPyment']?.toString() ?? '0') ?? 0;
                final String monthStr = _formatMonth(inst['MonthPayment']);
                final String? notes = inst['PaymentNotes'];
                final bool isLast = index == installments.length - 1;

                final bool isOverdue = !isPaid &&
                    DateTime.tryParse(inst['MonthPayment']?.toString() ?? '')
                        ?.isBefore(DateTime.now()) == true;

                final bool isNext = !isPaid && !isOverdue;

                Color dotColor = isPaid
                    ? const Color(0xFF10B981)
                    : isOverdue
                        ? const Color(0xFFEF4444)
                        : Colors.grey[400]!;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline dots
                    Column(
                      children: [
                        Container(
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: dotColor.withOpacity(0.3), blurRadius: 6),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              isPaid ? Icons.check : isOverdue ? Icons.close : Icons.circle,
                              color: Colors.white, size: 12),
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 2, height: 60,
                            color: isPaid ? const Color(0xFF10B981).withOpacity(0.3) : Colors.grey.withOpacity(0.2),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),

                    // Content
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isPaid
                              ? const Color(0xFF10B981).withOpacity(0.05)
                              : isOverdue
                                  ? const Color(0xFFEF4444).withOpacity(0.05)
                                  : (isDark ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[50]),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isPaid
                                ? const Color(0xFF10B981).withOpacity(0.2)
                                : isOverdue
                                    ? const Color(0xFFEF4444).withOpacity(0.2)
                                    : Colors.grey.withOpacity(0.15),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_formatCurrency(amount),
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: dotColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isPaid ? "مدفوع ✅" : isOverdue ? "متأخر ⚠️" : "قادم",
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: dotColor),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey[500]),
                                const SizedBox(width: 6),
                                Text(monthStr,
                                  style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                                if (isOverdue) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    "متأخر ${DateTime.now().difference(DateTime.parse(inst['MonthPayment'].toString())).inDays} يوم",
                                    style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ],
                            ),
                            if (notes != null && notes.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(notes, style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== المدفوعات ====================

  Widget _buildPaymentsCard(dynamic detail, bool isDark) {
    final payments = detail['payments'] as List? ?? [];
    if (payments.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18), topRight: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.payments_rounded, color: Color(0xFF10B981), size: 20),
                ),
                const SizedBox(width: 10),
                Text("سجل المدفوعات (${payments.length})",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final payment = payments[index];
              final double amount = double.tryParse(payment['incomeAmount']?.toString() ?? '0') ?? 0;
              final String date = _formatDate(payment['date_Pay']);
              final String? receiptNo = payment['ReceiptNumber'];
              final String? notes = payment['Notes'];
              final String? user = payment['userAdd'];

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatCurrency(amount),
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87)),
                              if (receiptNo != null && receiptNo.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text("إيصال: $receiptNo",
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF6366F1), fontWeight: FontWeight.w600)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 6),
                              Text(date, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                              if (user != null) ...[
                                const SizedBox(width: 12),
                                Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(user,
                                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                    overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ],
                          ),
                          if (notes != null && notes.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(notes, style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==================== Dialog الاتصال ====================

  void _showCallDialog(String? fatherPhone, String? motherPhone) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252836) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text("اتصال بولي الأمر",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 20),

              if (fatherPhone != null)
                _buildCallOption(
                  icon: Icons.male_rounded,
                  label: "الأب",
                  phone: fatherPhone,
                  color: const Color(0xFF3B82F6),
                  isDark: isDark,
                ),
              if (fatherPhone != null && motherPhone != null)
                const SizedBox(height: 12),
              if (motherPhone != null)
                _buildCallOption(
                  icon: Icons.female_rounded,
                  label: "الأم",
                  phone: motherPhone,
                  color: const Color(0xFFEC4899),
                  isDark: isDark,
                ),

              SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCallOption({
    required IconData icon, required String label, required String phone,
    required Color color, required bool isDark,
  }) {
    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          _makeCall(phone);
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87)),
                    Text(phone, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                  ],
                ),
              ),
              Icon(Icons.call_rounded, color: color, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== Circular Progress Painter ====================

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;

  _CircularProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 10;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}