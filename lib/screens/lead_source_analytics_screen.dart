import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';

class LeadSourceAnalyticsScreen extends StatefulWidget {
  const LeadSourceAnalyticsScreen({super.key});

  @override
  State<LeadSourceAnalyticsScreen> createState() => _LeadSourceAnalyticsScreenState();
}

class _LeadSourceAnalyticsScreenState extends State<LeadSourceAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _analytics = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Date Filter
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedPreset = 'all';

  // Sort
  String _sortBy = 'leads'; // leads, converted, rate

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ألوان المصادر
  final List<Color> _sourceColors = [
    const Color(0xFF6366F1), // Indigo
    const Color(0xFF10B981), // Emerald
    const Color(0xFFF59E0B), // Amber
    const Color(0xFFEF4444), // Red
    const Color(0xFF8B5CF6), // Violet
    const Color(0xFF06B6D4), // Cyan
    const Color(0xFFEC4899), // Pink
    const Color(0xFF84CC16), // Lime
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _loadAnalytics();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String query = '';
      if (_startDate != null && _endDate != null) {
        query = '?startDate=${_startDate!.toIso8601String()}&endDate=${_endDate!.toIso8601String()}';
      }

      final data = await ApiService.get('analytics/sources$query');

      if (mounted) {
        setState(() {
          _analytics = data is List ? data : [];
          _sortAnalytics();
          _isLoading = false;
        });
        _animationController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  void _sortAnalytics() {
    _analytics.sort((a, b) {
      switch (_sortBy) {
        case 'leads':
          return (b['leads'] ?? 0).compareTo(a['leads'] ?? 0);
        case 'converted':
          return (b['converted'] ?? 0).compareTo(a['converted'] ?? 0);
        case 'rate':
          return (b['rate'] ?? 0).compareTo(a['rate'] ?? 0);
        default:
          return 0;
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📅 Date Presets
  // ═══════════════════════════════════════════════════════════════════════════

  void _setDatePreset(String preset) {
    final now = DateTime.now();
    setState(() {
      _selectedPreset = preset;
      switch (preset) {
        case 'today':
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = now;
          break;
        case 'week':
          _startDate = now.subtract(const Duration(days: 7));
          _endDate = now;
          break;
        case 'month':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = now;
          break;
        case '3months':
          _startDate = DateTime(now.year, now.month - 3, now.day);
          _endDate = now;
          break;
        case 'all':
        default:
          _startDate = null;
          _endDate = null;
          break;
      }
    });
    _loadAnalytics();
  }

  Future<void> _pickCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6366F1),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedPreset = 'custom';
      });
      _loadAnalytics();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📊 Calculations
  // ═══════════════════════════════════════════════════════════════════════════

  int get _totalLeads => _analytics.fold(0, (sum, item) => sum + ((item['leads'] ?? 0) as int));
  int get _totalConverted => _analytics.fold(0, (sum, item) => sum + ((item['converted'] ?? 0) as int));
  double get _avgConversionRate => _totalLeads > 0 ? (_totalConverted / _totalLeads * 100) : 0;
  String get _bestSource {
    if (_analytics.isEmpty) return '-';
    final best = _analytics.reduce((a, b) => (a['leads'] ?? 0) > (b['leads'] ?? 0) ? a : b);
    return best['source'] ?? '-';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
      body: RefreshIndicator(
        onRefresh: _loadAnalytics,
        color: const Color(0xFF6366F1),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // App Bar
            _buildSliverAppBar(isDark),

            // Content
            SliverToBoxAdapter(
              child: _buildContent(isDark),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎨 App Bar
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 180,
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
          onPressed: _loadAnalytics,
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA855F7)],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                right: -50,
                top: -50,
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
                left: -30,
                bottom: 0,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),

              // Title
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.analytics_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "تحليل المصادر",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "من أين يأتي عملاؤك؟",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // 📦 Content
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildContent(bool isDark) {
    if (_isLoading) {
      return _buildLoadingState(isDark);
    }

    if (_errorMessage != null) {
      return _buildErrorState(isDark);
    }

    if (_analytics.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Date Presets
            _buildDatePresets(isDark),

            const SizedBox(height: 16),

            // Summary Cards
            _buildSummaryCards(isDark),

            const SizedBox(height: 20),

            // Pie Chart
            _buildPieChartSection(isDark),

            const SizedBox(height: 20),

            // Sort Options
            _buildSortOptions(isDark),

            const SizedBox(height: 16),

            // Sources List
            _buildSourcesList(isDark),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📅 Date Presets
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDatePresets(bool isDark) {
    final presets = [
      {'key': 'all', 'label': 'الكل'},
      {'key': 'today', 'label': 'اليوم'},
      {'key': 'week', 'label': 'أسبوع'},
      {'key': 'month', 'label': 'شهر'},
      {'key': '3months', 'label': '3 أشهر'},
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Presets
          ...presets.map((preset) {
            final isSelected = _selectedPreset == preset['key'];
            return Expanded(
              child: GestureDetector(
                onTap: () => _setDatePreset(preset['key']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    preset['label']!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ),
                ),
              ),
            );
          }),

          // Custom Date Picker
          GestureDetector(
            onTap: _pickCustomDateRange,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _selectedPreset == 'custom'
                    ? const Color(0xFF6366F1)
                    : (isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                size: 20,
                color: _selectedPreset == 'custom'
                    ? Colors.white
                    : const Color(0xFF6366F1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📊 Summary Cards
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSummaryCards(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.people_alt_rounded,
            label: "إجمالي العملاء",
            value: _totalLeads.toString(),
            color: const Color(0xFF6366F1),
            isDark: isDark,
            index: 0,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.check_circle_rounded,
            label: "تم التحويل",
            value: _totalConverted.toString(),
            color: const Color(0xFF10B981),
            isDark: isDark,
            index: 1,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.trending_up_rounded,
            label: "متوسط التحويل",
            value: "${_avgConversionRate.toStringAsFixed(1)}%",
            color: const Color(0xFFF59E0B),
            isDark: isDark,
            index: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    required int index,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + (index * 150)),
      curve: Curves.easeOutBack,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: animValue,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252836) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
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
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🥧 Pie Chart Section
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPieChartSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: Color(0xFF8B5CF6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "توزيع المصادر",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Chart & Legend
          Row(
            children: [
              // Pie Chart
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 160,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 40,
                      sections: _getPieChartSections(),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Legend
              Expanded(
                flex: 3,
                child: Column(
                  children: List.generate(
                    _analytics.length > 5 ? 5 : _analytics.length,
                    (index) {
                      final item = _analytics[index];
                      final color = _sourceColors[index % _sourceColors.length];
                      final percentage = _totalLeads > 0
                          ? ((item['leads'] ?? 0) / _totalLeads * 100)
                          : 0.0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item['source'] ?? 'غير محدد',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            Text(
                              "${percentage.toStringAsFixed(1)}%",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _getPieChartSections() {
    if (_analytics.isEmpty) {
      return [
        PieChartSectionData(
          color: Colors.grey.withOpacity(0.3),
          value: 100,
          radius: 25,
          title: '',
        ),
      ];
    }

    return _analytics.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final color = _sourceColors[index % _sourceColors.length];
      final value = (item['leads'] ?? 0).toDouble();

      return PieChartSectionData(
        color: color,
        value: value > 0 ? value : 0.1,
        radius: 25,
        title: '',
      );
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔀 Sort Options
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSortOptions(bool isDark) {
    final options = [
      {'key': 'leads', 'label': 'الأكثر عملاء', 'icon': Icons.people_alt_rounded},
      {'key': 'converted', 'label': 'الأكثر تحويل', 'icon': Icons.check_circle_rounded},
      {'key': 'rate', 'label': 'أعلى نسبة', 'icon': Icons.trending_up_rounded},
    ];

    return Row(
      children: [
        Text(
          "ترتيب حسب:",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: options.map((option) {
                final isSelected = _sortBy == option['key'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _sortBy = option['key'] as String;
                      _sortAnalytics();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6366F1)
                          : (isDark ? const Color(0xFF252836) : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF6366F1)
                            : (isDark ? const Color(0xFF3A3A4A) : Colors.grey[300]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          option['icon'] as IconData,
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          option['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.grey[400] : Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📋 Sources List
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSourcesList(bool isDark) {
    return Column(
      children: List.generate(_analytics.length, (index) {
        final item = _analytics[index];
        final color = _sourceColors[index % _sourceColors.length];

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 400 + (index * 100)),
          curve: Curves.easeOutCubic,
          builder: (context, animValue, child) {
            return Transform.translate(
              offset: Offset(30 * (1 - animValue), 0),
              child: Opacity(opacity: animValue, child: child),
            );
          },
          child: _buildSourceCard(item, color, index, isDark),
        );
      }),
    );
  }

  Widget _buildSourceCard(dynamic item, Color color, int index, bool isDark) {
    final leads = item['leads'] ?? 0;
    final converted = item['converted'] ?? 0;
    final rate = item['rate'] ?? 0;
    final cpl = item['cpl'] ?? 0;
    final percentage = _totalLeads > 0 ? (leads / _totalLeads) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Row
          Row(
            children: [
              // Rank Badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: index < 3
                      ? Icon(
                          index == 0
                              ? Icons.emoji_events_rounded
                              : index == 1
                                  ? Icons.military_tech_rounded
                                  : Icons.workspace_premium_rounded,
                          color: Colors.white,
                          size: 16,
                        )
                      : Text(
                          "${index + 1}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),

              const SizedBox(width: 12),

              // Source Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['source'] ?? 'غير محدد',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${(percentage * 100).toStringAsFixed(1)}% من الإجمالي",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),

              // Conversion Rate Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getConversionColor(rate.toDouble()).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getConversionColor(rate.toDouble()).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      size: 14,
                      color: _getConversionColor(rate.toDouble()),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "$rate%",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _getConversionColor(rate.toDouble()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: percentage),
              duration: Duration(milliseconds: 1000 + (index * 150)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildSourceStat(
                  icon: Icons.people_alt_rounded,
                  label: "عملاء محتملين",
                  value: leads.toString(),
                  color: const Color(0xFF6366F1),
                  isDark: isDark,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: isDark ? const Color(0xFF3A3A4A) : Colors.grey[200],
              ),
              Expanded(
                child: _buildSourceStat(
                  icon: Icons.check_circle_rounded,
                  label: "تم التحويل",
                  value: converted.toString(),
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: isDark ? const Color(0xFF3A3A4A) : Colors.grey[200],
              ),
              Expanded(
                child: _buildSourceStat(
                  icon: Icons.attach_money_rounded,
                  label: "تكلفة/عميل",
                  value: "$cpl ج",
                  color: const Color(0xFFF59E0B),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSourceStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Color _getConversionColor(double rate) {
    if (rate >= 30) return const Color(0xFF10B981);
    if (rate >= 15) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔄 Loading State
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLoadingState(bool isDark) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "جاري تحميل التحليلات...",
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ❌ Error State
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildErrorState(bool isDark) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 60,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "حدث خطأ!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'فشل تحميل البيانات',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadAnalytics,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text("إعادة المحاولة"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 📭 Empty State
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildEmptyState(bool isDark) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  size: 60,
                  color: Color(0xFF6366F1),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "لا توجد بيانات",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "لم يتم العثور على بيانات للمصادر\nفي الفترة المحددة",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              if (_startDate != null)
                OutlinedButton.icon(
                  onPressed: () => _setDatePreset('all'),
                  icon: const Icon(Icons.clear_all_rounded),
                  label: const Text("عرض كل الفترات"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6366F1),
                    side: const BorderSide(color: Color(0xFF6366F1)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}