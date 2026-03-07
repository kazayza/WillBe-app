import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/debt_provider.dart';
import '../providers/children_provider.dart';
import '../providers/theme_provider.dart';
import 'debt_details_screen.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  int? _selectedSessionId;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  Future<void> _initData() async {
    final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);
    await childrenProvider.fetchSessions();

    if (childrenProvider.sessions.isNotEmpty) {
      final currentSession = childrenProvider.sessions.firstWhere(
        (s) => s['IDSession'] == 4,
        orElse: () => childrenProvider.sessions.first,
      );
      setState(() {
        _selectedSessionId = currentSession['IDSession'];
      });
      _loadDebts();
    }
  }

  Future<void> _loadDebts() async {
    if (_selectedSessionId != null) {
      final provider = Provider.of<DebtProvider>(context, listen: false);
      provider.clearFilters();
      _searchController.clear();
      await provider.fetchDebts(_selectedSessionId!);
    }
  }

  Future<void> _refresh() async {
    await _loadDebts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final debtProvider = Provider.of<DebtProvider>(context);
    final childrenProvider = Provider.of<ChildrenProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    final debts = debtProvider.debts;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFF6366F1),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            _buildSliverAppBar(isDark, childrenProvider.sessions),

            if (_selectedSessionId != null && !debtProvider.isLoading && debtProvider.allDebts.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildStatisticsSection(debtProvider, isDark),
                ),
              ),

            if (_selectedSessionId != null && !debtProvider.isLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildFiltersSection(debtProvider, isDark),
                ),
              ),

            if (debtProvider.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                ),
              )
            else if (_selectedSessionId == null)
              SliverFillRemaining(
                child: _buildEmptyState(isDark, Icons.calendar_month_rounded,
                    "اختر العام المالي", "اختر العام المالي من القائمة أعلاه"),
              )
            else if (debts.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(isDark, Icons.account_balance_wallet_outlined,
                    "لا توجد بيانات", "لا توجد اشتراكات بالفلاتر المحددة"),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildDebtCard(debts[index], isDark),
                    childCount: debts.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==================== AppBar ====================

  Widget _buildSliverAppBar(bool isDark, List<dynamic> sessions) {
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
              Positioned(
                right: -30, top: -30,
                child: Container(
                  width: 150, height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                left: 20, bottom: 60,
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: 20, right: 20, left: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 28),
                        SizedBox(width: 10),
                        Text("المديونيات والأقساط",
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedSessionId,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                          dropdownColor: const Color(0xFF6366F1),
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          isExpanded: true,
                          hint: const Text("اختر العام المالي", style: TextStyle(color: Colors.white70)),
                          items: sessions.map<DropdownMenuItem<int>>((session) {
                            return DropdownMenuItem(
                              value: session['IDSession'],
                              child: Text(session['Sessions'] ?? ''),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedSessionId = val);
                              _loadDebts();
                            }
                          },
                        ),
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

  // ==================== الإحصائيات ====================

  Widget _buildStatisticsSection(DebtProvider provider, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // العنوان
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.analytics_rounded, color: Color(0xFF6366F1), size: 20),
              ),
              const SizedBox(width: 10),
              Text("ملخص الاشتراكات",
                style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // عدد اشتراكات الدراسة والباص
Row(
            children: [
              Expanded(
                child: _buildTypeCountCard(
                  icon: Icons.school_rounded,
                  label: "دراسة",
                  count: provider.studyCount,
                  debtorCount: provider.studyDebtorCount,
                  paidCount: provider.studyPaidCount,
                  color: const Color(0xFF6366F1),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTypeCountCard(
                  icon: Icons.directions_bus_rounded,
                  label: "باص",
                  count: provider.busCount,
                  debtorCount: provider.busDebtorCount,
                  paidCount: provider.busPaidCount,
                  color: const Color(0xFFF59E0B),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // شريط التقدم الكلي
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("إجمالي المطلوب",
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                  Text("${provider.totalAmounts.toStringAsFixed(0)} ج.م",
                    style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Stack(
                children: [
                  Container(
                    width: double.infinity, height: 14,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      double progress = provider.totalAmounts > 0
                          ? (provider.totalPaidAll / provider.totalAmounts).clamp(0.0, 1.0)
                          : 0.0;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        width: constraints.maxWidth * progress,
                        height: 14,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          borderRadius: BorderRadius.circular(7),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("المدفوع: ${provider.totalPaidAll.toStringAsFixed(0)} ج.م",
                    style: const TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                  ),
                  Text("${provider.paymentPercentage.toStringAsFixed(0)}%",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87),
                  ),
                  Text("المتبقي: ${provider.totalRemaining.toStringAsFixed(0)} ج.م",
                    style: TextStyle(fontSize: 12,
                      color: provider.totalRemaining > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                      fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ملخص الحالات
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.2)
                  : const Color(0xFF6366F1).withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusCount(
                  icon: "🔴",
                  count: provider.overdueCount,
                  label: "متأخر",
                  color: Colors.red,
                ),
                _buildStatusDivider(isDark),
                _buildStatusCount(
                  icon: "🟡",
                  count: provider.ongoingCount,
                  label: "جاري",
                  color: Colors.orange,
                ),
                _buildStatusDivider(isDark),
                _buildStatusCount(
                  icon: "🟢",
                  count: provider.paidFullCount,
                  label: "مسدد",
                  color: const Color(0xFF10B981),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeCountCard({
    required IconData icon,
    required String label,
    required int count,
    required int debtorCount,
    required int paidCount,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("$count طالب",
                    style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text("🔴", style: TextStyle(fontSize: 10)),
                  const SizedBox(width: 4),
                  Text("$debtorCount مديون",
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text("🟢", style: TextStyle(fontSize: 10)),
                  const SizedBox(width: 4),
                  Text("$paidCount مسدد",
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCount({
    required String icon,
    required int count,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text("$count",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildStatusDivider(bool isDark) {
    return Container(
      width: 1, height: 35,
      color: isDark ? Colors.grey[700] : Colors.grey[300],
    );
  }

  // ==================== الفلاتر ====================

  Widget _buildFiltersSection(DebtProvider provider, bool isDark) {
    return Column(
      children: [
        // Tabs - نوع الاشتراك
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252836) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildTabButton("الكل", Icons.all_inclusive_rounded, provider.selectedType == 'الكل', isDark, () {
                provider.setTypeFilter('الكل');
              }),
              const SizedBox(width: 4),
              _buildTabButton("📚 دراسة", Icons.school_rounded, provider.selectedType == 'دراسة', isDark, () {
                provider.setTypeFilter('دراسة');
              }),
              const SizedBox(width: 4),
              _buildTabButton("🚌 باص", Icons.directions_bus_rounded, provider.selectedType == 'باص', isDark, () {
                provider.setTypeFilter('باص');
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // فلتر الفرع
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252836) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              value: provider.selectedBranchId,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6366F1)),
              dropdownColor: isDark ? const Color(0xFF252836) : Colors.white,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14, fontWeight: FontWeight.w600,
              ),
              isExpanded: true,
              hint: Row(
                children: [
                  Icon(Icons.store_rounded, size: 20, color: Colors.grey[500]),
                  const SizedBox(width: 10),
                  Text("كل الفروع", style: TextStyle(color: Colors.grey[500])),
                ],
              ),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Row(
                    children: [
                      Icon(Icons.store_rounded, size: 20, color: Colors.grey[500]),
                      const SizedBox(width: 10),
                      const Text("كل الفروع"),
                    ],
                  ),
                ),
                ...provider.availableBranches.map<DropdownMenuItem<int?>>((branch) {
                  return DropdownMenuItem<int?>(
                    value: branch['id'],
                    child: Text(branch['name']),
                  );
                }),
              ],
              onChanged: (val) => provider.setBranchFilter(val),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // البحث
        TextField(
          controller: _searchController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: "ابحث عن اسم الطفل...",
            hintStyle: TextStyle(color: Colors.grey[500]),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      provider.setSearchQuery('');
                    },
                    icon: Icon(Icons.clear, size: 20, color: Colors.grey[500]),
                  )
                : null,
            filled: true,
            fillColor: isDark ? const Color(0xFF252836) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
          ),
          onChanged: (val) => provider.setSearchQuery(val),
        ),
        const SizedBox(height: 12),

        // شريط النتائج والفلتر
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text("${provider.debts.length} نتيجة",
                style: const TextStyle(fontSize: 13, color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => provider.toggleShowOnlyDebtors(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: provider.showOnlyDebtors
                      ? const Color(0xFFEF4444)
                      : (isDark ? const Color(0xFF252836) : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: provider.showOnlyDebtors
                        ? const Color(0xFFEF4444)
                        : Colors.grey.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.filter_alt_rounded, size: 18,
                      color: provider.showOnlyDebtors ? Colors.white : Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text("المديونين فقط",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: provider.showOnlyDebtors
                            ? Colors.white
                            : (isDark ? Colors.white : Colors.black87)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabButton(String label, IconData icon, bool isSelected, bool isDark, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== كارت المديونية ====================

  Widget _buildDebtCard(dynamic debt, bool isDark) {
    final String name = debt['FullNameArabic'] ?? 'بدون اسم';
    final String kindSubscription = debt['Kind_subscrip'] ?? '';
    final String branchName = debt['branchName'] ?? '';
    final double totalAmount = double.tryParse(debt['amount_Sub']?.toString() ?? '0') ?? 0;
    final double totalPaid = double.tryParse(debt['totalPaid']?.toString() ?? '0') ?? 0;
    final double remaining = totalAmount - totalPaid;
    final double progress = totalAmount > 0 ? (totalPaid / totalAmount).clamp(0.0, 1.0) : 0.0;
    final double percentage = progress * 100;

    final int totalInstallments = debt['totalInstallments'] ?? 0;
    final int paidInstallments = debt['paidInstallments'] ?? 0;

    final double nextAmount = double.tryParse(debt['nextInstallmentAmount']?.toString() ?? '0') ?? 0;

    final bool isPaidFull = remaining <= 0;
    final bool isOverdue = debt['nextInstallmentDate'] != null &&
        DateTime.tryParse(debt['nextInstallmentDate'].toString())?.isBefore(DateTime.now()) == true &&
        !isPaidFull;

    Color statusColor = isPaidFull
        ? const Color(0xFF10B981)
        : isOverdue
            ? const Color(0xFFEF4444)
            : const Color(0xFFF59E0B);

    String statusText = isPaidFull
        ? "مسدد بالكامل ✅"
        : isOverdue
            ? "متأخر في السداد ⚠️"
            : "جاري السداد";

    bool isStudy = kindSubscription.contains('الدراسة');

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => DebtDetailsScreen(
            childId: debt['Child_Id'],
            childName: name,
            sessionId: _selectedSessionId!,
          ),
        )).then((_) => _refresh());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252836) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: isOverdue ? Border.all(color: Colors.red.withOpacity(0.4), width: 1.5) : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الصف الأول
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isStudy ? Icons.school_rounded : Icons.directions_bus_rounded,
                      color: statusColor, size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildMiniTag(isStudy ? "📚 دراسة" : "🚌 باص",
                                isStudy ? const Color(0xFF6366F1) : const Color(0xFFF59E0B)),
                            const SizedBox(width: 6),
                            _buildMiniTag(branchName, const Color(0xFF10B981)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
                ],
              ),

              const SizedBox(height: 16),

              // شريط التقدم
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("المدفوع: ${totalPaid.toStringAsFixed(0)} ج",
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  Text("${percentage.toStringAsFixed(0)}%",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  color: statusColor,
                  minHeight: 8,
                ),
              ),

              const SizedBox(height: 12),
              Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
              const SizedBox(height: 12),

              // التفاصيل
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoChip(Icons.attach_money_rounded, "الإجمالي",
                      "${totalAmount.toStringAsFixed(0)} ج", const Color(0xFF6366F1), isDark),
                  _buildInfoChip(Icons.money_off_rounded, "المتبقي",
                      "${remaining.toStringAsFixed(0)} ج",
                      remaining > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981), isDark),
                  _buildInfoChip(Icons.receipt_long_rounded, "الأقساط",
                      "$paidInstallments/$totalInstallments", const Color(0xFFF59E0B), isDark),
                ],
              ),

              // القسط القادم
              if (!isPaidFull && nextAmount > 0) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isOverdue
                        ? Colors.red.withOpacity(0.05)
                        : Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isOverdue
                          ? Colors.red.withOpacity(0.2)
                          : Colors.blue.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isOverdue ? Icons.warning_rounded : Icons.schedule_rounded,
                        size: 16,
                        color: isOverdue ? Colors.red : Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                         child: Text(
                          isOverdue
                              ? "قسط متأخر: ${nextAmount.toStringAsFixed(0)} ج.م - ${_formatMonth(debt['nextInstallmentDate'])}"
                              : "القسط القادم: ${nextAmount.toStringAsFixed(0)} ج.م - ${_formatMonth(debt['nextInstallmentDate'])}",
                          style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: isOverdue ? Colors.red : Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // حالة السداد
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isPaidFull ? Icons.check_circle_rounded
                          : isOverdue ? Icons.warning_rounded : Icons.schedule_rounded,
                      size: 16, color: statusColor,
                    ),
                    const SizedBox(width: 8),
                    Text(statusText,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: statusColor)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== Widgets مساعدة ====================

  Widget _buildMiniTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value, Color color, bool isDark) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark, IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: Colors.grey[400]),
          ),
          const SizedBox(height: 20),
          Text(title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[400] : Colors.grey[600])),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
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
  
}