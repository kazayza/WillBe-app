import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/profit_loss_model.dart';
import '../services/profit_loss_service.dart';
import '../theme/app_colors.dart';
import '../widgets/profit_loss/summary_cards.dart';
import '../widgets/profit_loss/filter_section.dart';
import '../widgets/profit_loss/report_tab.dart';
import '../widgets/profit_loss/monthly_tab.dart';
import '../widgets/profit_loss/branches_tab.dart';
import '../services/ProfitLoss_pdf_service.dart';

class ProfitLossScreen extends StatefulWidget {
  const ProfitLossScreen({super.key});

  @override
  State<ProfitLossScreen> createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends State<ProfitLossScreen>
    with SingleTickerProviderStateMixin, TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;

  // ============================================
  // 📊 البيانات
  // ============================================
  ProfitLossReport? _report;
  MonthlyTrendResponse? _monthlyTrend;
  BranchReportResponse? _branchReport;

  // ============================================
  // 🔄 حالات التحميل
  // ============================================
  bool _isLoadingReport = false;
  bool _isLoadingMonthly = false;
  bool _isLoadingBranches = false;
  String? _error;

  // ============================================
  // 🎛️ الفلاتر
  // ============================================
  late DateTime _startDate;
  late DateTime _endDate;
  String _selectedBranchId = 'all';
  int _selectedYear = DateTime.now().year;
  bool _isFilterExpanded = true; // الفلتر مفتوح افتراضياً

  @override
  void initState() {
    super.initState();
    
    // 🎯 تاريخ أول يوم وآخر يوم في الشهر الحالي
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
    
    _tabController = TabController(length: 3, vsync: this);
    _filterAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );

    if (_isFilterExpanded) {
      _filterAnimationController.forward();
    }

    _tabController.addListener(_onTabChanged);
    _loadReport();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _filterAnimationController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    
    setState(() {
      // طي الفلتر تلقائياً عند تغيير التاب
      if (_isFilterExpanded) {
        _toggleFilter();
      }
    });

    switch (_tabController.index) {
      case 0:
        if (_report == null) _loadReport();
        break;
      case 1:
        if (_monthlyTrend == null) _loadMonthlyTrend();
        break;
      case 2:
        if (_branchReport == null) _loadBranchReport();
        break;
    }
  }

  void _toggleFilter() {
    setState(() {
      _isFilterExpanded = !_isFilterExpanded;
      if (_isFilterExpanded) {
        _filterAnimationController.forward();
      } else {
        _filterAnimationController.reverse();
      }
    });
  }

  // ============================================
  // 📡 تحميل البيانات
  // ============================================
  Future<void> _loadReport() async {
    setState(() {
      _isLoadingReport = true;
      _error = null;
    });

    try {
      final report = await ProfitLossService.getReport(
        startDate: DateFormat('yyyy-MM-dd').format(_startDate),
        endDate: DateFormat('yyyy-MM-dd').format(_endDate),
        branchId: _selectedBranchId,
      );
      
      if (mounted) {
        setState(() {
          _report = report;
          _isLoadingReport = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoadingReport = false;
        });
        _showErrorSnackBar(_error!);
      }
    }
  }

  Future<void> _loadMonthlyTrend() async {
    setState(() {
      _isLoadingMonthly = true;
    });

    try {
      final trend = await ProfitLossService.getMonthlyTrend(
        year: _selectedYear,
        branchId: _selectedBranchId,
      );
      
      if (mounted) {
        setState(() {
          _monthlyTrend = trend;
          _isLoadingMonthly = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMonthly = false;
        });
        _showErrorSnackBar(e.toString());
      }
    }
  }

  Future<void> _loadBranchReport() async {
    setState(() {
      _isLoadingBranches = true;
    });

    try {
      final branches = await ProfitLossService.getBranchReport(
        startDate: DateFormat('yyyy-MM-dd').format(_startDate),
        endDate: DateFormat('yyyy-MM-dd').format(_endDate),
      );
      
      if (mounted) {
        setState(() {
          _branchReport = branches;
          _isLoadingBranches = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBranches = false;
        });
        _showErrorSnackBar(e.toString());
      }
    }
  }

  void _onFilterChanged({
    DateTime? startDate,
    DateTime? endDate,
    String? branchId,
    int? year,
  }) {
    bool hasChanges = false;

    if (startDate != null && !startDate.isAtSameMomentAs(_startDate)) {
      _startDate = startDate;
      hasChanges = true;
    }
    if (endDate != null && !endDate.isAtSameMomentAs(_endDate)) {
      _endDate = endDate;
      hasChanges = true;
    }
    if (branchId != null && branchId != _selectedBranchId) {
      _selectedBranchId = branchId;
      hasChanges = true;
    }
    if (year != null && year != _selectedYear) {
      _selectedYear = year;
      hasChanges = true;
    }

    if (hasChanges) {
      setState(() {
        _report = null;
        _monthlyTrend = null;
        _branchReport = null;
      });

      // إعادة تحميل التاب الحالي
      switch (_tabController.index) {
        case 0:
          _loadReport();
          break;
        case 1:
          _loadMonthlyTrend();
          break;
        case 2:
          _loadBranchReport();
          break;
      }
    }
  }

  Future<void> _refreshCurrentTab() async {
    switch (_tabController.index) {
      case 0:
        await _loadReport();
        break;
      case 1:
        await _loadMonthlyTrend();
        break;
      case 2:
        await _loadBranchReport();
        break;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'حسناً',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBg(context),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // ════════════════════════════════════════
          // 🎛️ الفلاتر القابلة للطي
          // ════════════════════════════════════════
          _buildCollapsibleFilter(),

          // ════════════════════════════════════════
          // 📊 الكروت العلوية
          // ════════════════════════════════════════
          if (_report != null)
            AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              offset: Offset.zero,
              child: SummaryCards(summary: _report!.summary),
            ),

          // ════════════════════════════════════════
          // 📑 التابات
          // ════════════════════════════════════════
          _buildTabBar(),

          const SizedBox(height: 8),

          // ════════════════════════════════════════
          // 📄 محتوى التابات
          // ════════════════════════════════════════
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: التقرير التفصيلي
                RefreshIndicator(
                  onRefresh: _refreshCurrentTab,
                  color: AppColors.primary,
                  child: ReportTab(
                    report: _report,
                    isLoading: _isLoadingReport,
                    error: _error,
                    onRetry: _loadReport,
                  ),
                ),

                // Tab 2: التقرير الشهري
                RefreshIndicator(
                  onRefresh: _refreshCurrentTab,
                  color: AppColors.primary,
                  child: MonthlyTab(
                    data: _monthlyTrend,
                    isLoading: _isLoadingMonthly,
                    onRetry: _loadMonthlyTrend,
                  ),
                ),

                // Tab 3: تقرير الفروع
                RefreshIndicator(
                  onRefresh: _refreshCurrentTab,
                  color: AppColors.primary,
                  child: BranchesTab(
                    data: _branchReport,
                    isLoading: _isLoadingBranches,
                    onRetry: _loadBranchReport,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════
  // 🔧 Widgets
  // ════════════════════════════════════════

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'قائمة الأرباح والخسائر',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      centerTitle: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        // زر تصدير
        if (_report != null)
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => _showExportOptions(context),
            tooltip: 'تصدير',
          ),
        // زر تحديث
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => _refreshCurrentTab(),
          tooltip: 'تحديث',
        ),
      ],
    );
  }

  Widget _buildCollapsibleFilter() {
    return Column(
      children: [
        // Header للفلتر (دائماً ظاهر)
        InkWell(
          onTap: _toggleFilter,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.getCard(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.getBorder(context)),
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_list, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الفترة المحددة',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.getTextSecondary(context),
                        ),
                      ),
                      Text(
                        '${DateFormat('yyyy/MM/dd').format(_startDate)} - ${DateFormat('yyyy/MM/dd').format(_endDate)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getText(context),
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _isFilterExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // محتوى الفلتر (قابل للطي)
        SizeTransition(
          sizeFactor: _filterAnimation,
          child: FilterSection(
            startDate: _startDate,
            endDate: _endDate,
            selectedBranchId: _selectedBranchId,
            selectedYear: _selectedYear,
            currentTabIndex: _tabController.index,
            onFilterChanged: _onFilterChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.getCard(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.getBorder(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.getTextSecondary(context),
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColors.primary,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.receipt_long, size: 18),
            text: 'التقرير',
            height: 50,
          ),
          Tab(
            icon: Icon(Icons.trending_up, size: 18),
            text: 'الشهري',
            height: 50,
          ),
          Tab(
            icon: Icon(Icons.business, size: 18),
            text: 'الفروع',
            height: 50,
          ),
        ],
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.getCard(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: AppColors.getBorder(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'خيارات التصدير',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getText(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'الفترة: ${DateFormat('yyyy/MM/dd').format(_startDate)} - ${DateFormat('yyyy/MM/dd').format(_endDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _exportOption(
  context: context,
  icon: Icons.picture_as_pdf,
  color: Colors.red,
  title: 'تصدير PDF',
  subtitle: 'قائمة أرباح وخسائر كاملة',
  onTap: () {
    Navigator.pop(context);
    _shareReport();
  },
),
                  _exportOption(
                    context: context,
                    icon: Icons.table_chart,
                    color: AppColors.success,
                    title: 'تصدير Excel',
                    subtitle: 'تصدير البيانات لملف Excel',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('قريباً - تصدير Excel'),
                          backgroundColor: AppColors.info,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                  ),
                  _exportOption(
                    context: context,
                    icon: Icons.share,
                    color: AppColors.primary,
                    title: 'مشاركة التقرير',
                    subtitle: 'مشاركة ملخص التقرير',
                    onTap: () {
                      Navigator.pop(context);
                      _shareReport();
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _exportOption({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppColors.getCardDecoration(context),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.getText(context),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.getTextSecondary(context),
          ),
        ),
        trailing: Icon(
          Icons.chevron_left,
          color: AppColors.getTextSecondary(context),
        ),
        onTap: onTap,
      ),
    );
  }

  void _shareReport() async {
  if (_report == null) return;

  try {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    await PdfService.sharePDF(_report!);

    if (mounted) Navigator.pop(context);
  } catch (e) {
    if (mounted) {
      Navigator.pop(context);
      _showErrorSnackBar('فشل في إنشاء PDF: $e');
    }
  }
}
}