import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import 'lead_details_screen.dart';
import 'add_lead_screen.dart';

class LeadsListScreen extends StatefulWidget {
  const LeadsListScreen({super.key});

  @override
  State<LeadsListScreen> createState() => _LeadsListScreenState();
}

class _LeadsListScreenState extends State<LeadsListScreen>
    with TickerProviderStateMixin {
  List<dynamic> _leads = [];
  List<dynamic> _filteredLeads = [];
  bool _isLoading = true;
  String _selectedStatus = 'الكل';
  bool _isSearchFocused = false;
  bool _showScrollToTop = false;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  late AnimationController _statsAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _fabScaleAnimation;

  // ✅ قائمة الحالات المتاحة
  final List<Map<String, dynamic>> _statusFilters = [
    {'label': 'الكل', 'value': 'all', 'color': Color(0xFF6366F1), 'icon': Icons.all_inclusive_rounded},
    {'label': 'جديد', 'value': 'New', 'color': Color(0xFFF59E0B), 'icon': Icons.fiber_new_rounded},
    {'label': 'تم التواصل', 'value': 'Contacted', 'color': Color(0xFF3B82F6), 'icon': Icons.phone_callback_rounded},
    {'label': 'مهتم', 'value': 'Interested', 'color': Color(0xFF8B5CF6), 'icon': Icons.thumb_up_rounded},
    {'label': 'غير مهتم', 'value': 'Not Interested', 'color': Color(0xFFEF4444), 'icon': Icons.thumb_down_rounded},
    {'label': 'متابعة', 'value': 'Follow Up', 'color': Color(0xFFEC4899), 'icon': Icons.schedule_rounded},
    {'label': 'تم التحويل', 'value': 'Converted', 'color': Color(0xFF10B981), 'icon': Icons.check_circle_rounded},
    {'label': 'خسرناه', 'value': 'Lost', 'color': Color(0xFF6B7280), 'icon': Icons.cancel_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupListeners();
    _loadLeads();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabScaleAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );

    _statsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  void _setupListeners() {
    _searchController.addListener(_filterLeads);
    _searchFocusNode.addListener(() {
      setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
    });

    _scrollController.addListener(() {
      // إظهار/إخفاء زر Scroll to Top
      if (_scrollController.offset > 300 && !_showScrollToTop) {
        setState(() => _showScrollToTop = true);
      } else if (_scrollController.offset <= 300 && _showScrollToTop) {
        setState(() => _showScrollToTop = false);
      }

      // إخفاء FAB عند الـ Scroll لأسفل
      if (_scrollController.position.userScrollDirection.name == 'reverse') {
        if (_fabAnimationController.status != AnimationStatus.forward) {
          _fabAnimationController.forward();
        }
      } else {
        if (_fabAnimationController.status != AnimationStatus.reverse) {
          _fabAnimationController.reverse();
        }
      }
    });
  }

  Future<void> _loadLeads() async {
    setState(() => _isLoading = true);

    try {
      final data = await ApiService.get('leads');

      if (mounted) {
        setState(() {
          _leads = data is List ? data : [];
          _filteredLeads = List.from(_leads);
          _isLoading = false;
        });
        _animationController.forward();
        _statsAnimationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('فشل تحميل البيانات: $e');
      }
    }
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

  void _filterLeads() {
    setState(() {
      _filteredLeads = _leads.where((lead) {
        final name = (lead['FullName'] ?? '').toString().toLowerCase();
        final phone = (lead['Phone'] ?? '').toString().toLowerCase();
        final source = (lead['SourceName'] ?? '').toString().toLowerCase();
        final query = _searchController.text.toLowerCase();

        final matchesSearch = name.contains(query) ||
            phone.contains(query) ||
            source.contains(query);

        if (_selectedStatus == 'الكل') return matchesSearch;
        if (_selectedStatus == 'متأخر') {
          final nextFollowUp = lead['NextFollowUp'];
          if (nextFollowUp == null) return false;
          try {
            final followUpDate = DateTime.parse(nextFollowUp.toString());
            return matchesSearch && followUpDate.isBefore(DateTime.now());
          } catch (_) {
            return false;
          }
        }

        final statusFilter = _statusFilters.firstWhere(
          (s) => s['label'] == _selectedStatus,
          orElse: () => {'value': 'all'},
        );

        final status = (lead['Status'] ?? 'New').toString();
        return matchesSearch && status == statusFilter['value'];
      }).toList();
    });
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'New':
        return const Color(0xFFF59E0B);
      case 'Contacted':
        return const Color(0xFF3B82F6);
      case 'Interested':
        return const Color(0xFF8B5CF6);
      case 'Not Interested':
        return const Color(0xFFEF4444);
      case 'Follow Up':
        return const Color(0xFFEC4899);
      case 'Converted':
        return const Color(0xFF10B981);
      case 'Lost':
        return const Color(0xFF6B7280);
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'New':
        return 'جديد';
      case 'Contacted':
        return 'تم التواصل';
      case 'Interested':
        return 'مهتم';
      case 'Not Interested':
        return 'غير مهتم';
      case 'Follow Up':
        return 'متابعة';
      case 'Converted':
        return 'تم التحويل';
      case 'Lost':
        return 'خسرناه';
      default:
        return 'غير معروف';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'New':
        return Icons.fiber_new_rounded;
      case 'Contacted':
        return Icons.phone_callback_rounded;
      case 'Interested':
        return Icons.thumb_up_rounded;
      case 'Not Interested':
        return Icons.thumb_down_rounded;
      case 'Follow Up':
        return Icons.schedule_rounded;
      case 'Converted':
        return Icons.check_circle_rounded;
      case 'Lost':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  bool _isOverdue(dynamic lead) {
    final nextFollowUp = lead['NextFollowUp'];
    if (nextFollowUp == null) return false;
    try {
      final followUpDate = DateTime.parse(nextFollowUp.toString());
      return followUpDate.isBefore(DateTime.now()) &&
          lead['Status'] != 'Converted' &&
          lead['Status'] != 'Lost';
    } catch (_) {
      return false;
    }
  }

  int _getOverdueCount() {
    return _leads.where((lead) => _isOverdue(lead)).length;
  }

  int _getStatusCount(String statusValue) {
    if (statusValue == 'all') return _leads.length;
    return _leads.where((l) => l['Status'] == statusValue).length;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    _fabAnimationController.dispose();
    _statsAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
      body: RefreshIndicator(
        onRefresh: _loadLeads,
        color: const Color(0xFF6366F1),
        backgroundColor: isDark ? const Color(0xFF252836) : Colors.white,
        strokeWidth: 3,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(isDark),
            SliverToBoxAdapter(child: _buildSearchAndFilter(isDark)),
            SliverToBoxAdapter(child: _buildStatsRow(isDark)),
            _isLoading
                ? SliverFillRemaining(child: _buildLoadingState(isDark))
                : _filteredLeads.isEmpty
                    ? SliverFillRemaining(child: _buildEmptyState(isDark))
                    : SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final lead = _filteredLeads[index];
                              return FadeTransition(
                                opacity: _fadeAnimation,
                                child: _buildLeadCard(lead, isDark, index),
                              );
                            },
                            childCount: _filteredLeads.length,
                          ),
                        ),
                      ),
            // مساحة إضافية في الأسفل
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingButtons(isDark),
    );
  }

  // ============================================
  // ✅ Sliver AppBar محسن
  // ============================================

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
        // ✅ زر المتأخرين
        if (_getOverdueCount() > 0)
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedStatus = 'متأخر';
                _filterLeads();
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${_getOverdueCount()} متأخر',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
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
          onPressed: () {
            _animationController.reset();
            _statsAnimationController.reset();
            _loadLeads();
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
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
          ),
          child: Stack(
            children: [
              // الدوائر الديكورية
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
                top: 50,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              Positioned(
                right: 50,
                bottom: 80,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              // المحتوى
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "العملاء المحتملين",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 5,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person_rounded, color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  "إجمالي: ${_leads.length} عميل",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
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
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // ✅ Search and Filter محسن
  // ============================================

  Widget _buildSearchAndFilter(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ✅ حقل البحث المحسن
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252836) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isSearchFocused
                    ? const Color(0xFF6366F1)
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isSearchFocused
                      ? const Color(0xFF6366F1).withOpacity(0.2)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: _isSearchFocused ? 15 : 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: "ابحث بالاسم أو التليفون أو المصدر...",
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isSearchFocused
                          ? const Color(0xFF6366F1)
                          : const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.search,
                      color: _isSearchFocused ? Colors.white : const Color(0xFF6366F1),
                      size: 20,
                    ),
                  ),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.clear, color: Colors.grey[500], size: 18),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _filterLeads();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // ✅ فلاتر الحالة المحسنة
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildFilterChip(
                  label: 'الكل',
                  icon: Icons.all_inclusive_rounded,
                  isSelected: _selectedStatus == 'الكل',
                  isDark: isDark,
                  color: const Color(0xFF6366F1),
                  count: _leads.length,
                ),
                if (_getOverdueCount() > 0)
                  _buildFilterChip(
                    label: 'متأخر',
                    icon: Icons.warning_rounded,
                    isSelected: _selectedStatus == 'متأخر',
                    isDark: isDark,
                    color: const Color(0xFFEF4444),
                    count: _getOverdueCount(),
                  ),
                ..._statusFilters.skip(1).map((status) => _buildFilterChip(
                      label: status['label'],
                      icon: status['icon'],
                      isSelected: _selectedStatus == status['label'],
                      isDark: isDark,
                      color: status['color'],
                      count: _getStatusCount(status['value']),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required Color color,
    required int count,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = label;
          _filterLeads();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [color, color.withOpacity(0.8)])
              : null,
          color: isSelected ? null : (isDark ? const Color(0xFF252836) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.transparent : color.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.25) : color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // ✅ Stats Row محسن
  // ============================================

  // ============================================
// ✅ Stats Row - المُصحح
// ============================================

Widget _buildStatsRow(bool isDark) {
  final stats = [
    {'label': 'جدد', 'value': 'New', 'color': const Color(0xFFF59E0B), 'icon': Icons.fiber_new_rounded},
    {'label': 'تم التواصل', 'value': 'Contacted', 'color': const Color(0xFF3B82F6), 'icon': Icons.phone_callback_rounded},
    {'label': 'مهتم', 'value': 'Interested', 'color': const Color(0xFF8B5CF6), 'icon': Icons.thumb_up_rounded},
    {'label': 'تم التحويل', 'value': 'Converted', 'color': const Color(0xFF10B981), 'icon': Icons.check_circle_rounded},
  ];

  if (_getOverdueCount() > 0) {
    stats.add({'label': 'متأخر', 'value': 'overdue', 'color': const Color(0xFFEF4444), 'icon': Icons.warning_rounded});
  }

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    // ✅ الحل: إزالة height الثابت واستخدام constraints
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(stats.length, (index) {
          final stat = stats[index];
          final count = stat['value'] == 'overdue'
              ? _getOverdueCount()
              : _leads.where((l) => l['Status'] == stat['value']).length;

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 500 + (index * 100)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: _buildStatCard(
              label: stat['label'] as String,
              count: count,
              color: stat['color'] as Color,
              icon: stat['icon'] as IconData,
              isDark: isDark,
              index: index,
            ),
          );
        }),
      ),
    ),
  );
}

Widget _buildStatCard({
  required String label,
  required int count,
  required Color color,
  required IconData icon,
  required bool isDark,
  required int index,
}) {
  return Container(
    width: 100, // ✅ عرض أصغر شوية
    margin: const EdgeInsets.only(right: 12, bottom: 8, top: 8), // ✅ margin للـ shadow
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF252836) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.2), width: 1),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.15),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min, // ✅ مهم جداً
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: count),
          duration: Duration(milliseconds: 800 + (index * 100)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Text(
              value.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            );
          },
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}



  // ============================================
  // ✅ Loading State محسن
  // ============================================

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Loading
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6366F1).withOpacity(0.1),
                    const Color(0xFF8B5CF6).withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "جاري تحميل البيانات...",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "يرجى الانتظار",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // ✅ Lead Card محسن
  // ============================================

  Widget _buildLeadCard(dynamic lead, bool isDark, int index) {
    final status = (lead['Status'] ?? 'New').toString();
    final color = _getStatusColor(status);
    final isOverdue = _isOverdue(lead);
    final name = (lead['FullName'] ?? '---').toString();

    // ✅ تاريخ الإنشاء
    DateTime createdAt;
    final createdAtStr = lead['CreatedAt']?.toString();
    try {
      if (createdAtStr != null && createdAtStr.isNotEmpty) {
        createdAt = DateTime.parse(createdAtStr).toLocal();
      } else {
        createdAt = DateTime.now();
      }
    } catch (_) {
      createdAt = DateTime.now();
    }

    // ✅ تاريخ المتابعة
    DateTime? nextFollowUp;
    final nextStr = lead['NextFollowUp']?.toString();
    if (nextStr != null && nextStr.isNotEmpty) {
      try {
        nextFollowUp = DateTime.parse(nextStr);
      } catch (_) {}
    }

    // ✅ بيانات الإضافة
    final userAdd = lead['userAdd']?.toString();
    DateTime? addTime;
    final addTimeStr = lead['AddTime']?.toString() ?? lead['Addtime']?.toString();
    if (addTimeStr != null && addTimeStr.isNotEmpty) {
      try {
        addTime = DateTime.parse(addTimeStr);
      } catch (_) {}
    }

    // ✅ بيانات التعديل
    final userEdit = lead['useredit']?.toString();
    DateTime? editTime;
    final editTimeStr = lead['editTime']?.toString();
    if (editTimeStr != null && editTimeStr.isNotEmpty) {
      try {
        editTime = DateTime.parse(editTimeStr);
      } catch (_) {}
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252836) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOverdue ? const Color(0xFFEF4444) : color.withOpacity(0.2),
            width: isOverdue ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isOverdue ? const Color(0xFFEF4444) : color).withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LeadDetailsScreen(lead: lead),
                ),
              ).then((_) => _loadLeads());
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ✅ الصف الأول: الصورة + الاسم + الحالة
                  Row(
                    children: [
                      // Avatar محسن
                      Hero(
                        tag: 'lead_avatar_${lead['LeadID']}',
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [color, color.withOpacity(0.7)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : "?",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isOverdue)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFEF4444).withOpacity(0.4),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.warning_rounded, color: Colors.white, size: 10),
                                        SizedBox(width: 3),
                                        Text(
                                          'متأخر',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(Icons.phone_rounded, size: 12, color: Colors.grey[500]),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  (lead['Phone'] ?? '---').toString(),
                                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [color.withOpacity(0.15), color.withOpacity(0.1)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: color.withOpacity(0.3), width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getStatusIcon(status), size: 12, color: color),
                                const SizedBox(width: 4),
                                Text(
                                  _getStatusText(status),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 12, color: Colors.grey[400]),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('d MMM').format(createdAt),
                                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  // ✅ الصف الثاني: المصدر + الموظف + البرنامج
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        if (lead['SourceName'] != null)
                          Expanded(
                            child: _buildInfoChip(
                              icon: Icons.campaign_rounded,
                              text: lead['SourceName'].toString(),
                              color: const Color(0xFF3B82F6),
                              isDark: isDark,
                            ),
                          ),
                        if (lead['AssignedToName'] != null)
                          Expanded(
                            child: _buildInfoChip(
                              icon: Icons.person_rounded,
                              text: lead['AssignedToName'].toString(),
                              color: const Color(0xFF10B981),
                              isDark: isDark,
                            ),
                          ),
                        if (lead['InterestedProgram'] != null)
                          Expanded(
                            child: _buildInfoChip(
                              icon: Icons.school_rounded,
                              text: lead['InterestedProgram'].toString(),
                              color: const Color(0xFF8B5CF6),
                              isDark: isDark,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ✅ تاريخ المتابعة
                  if (nextFollowUp != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isOverdue
                              ? [const Color(0xFFEF4444).withOpacity(0.15), const Color(0xFFEF4444).withOpacity(0.1)]
                              : [const Color(0xFF6366F1).withOpacity(0.15), const Color(0xFF6366F1).withOpacity(0.1)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isOverdue
                              ? const Color(0xFFEF4444).withOpacity(0.3)
                              : const Color(0xFF6366F1).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isOverdue
                                  ? const Color(0xFFEF4444).withOpacity(0.2)
                                  : const Color(0xFF6366F1).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isOverdue ? Icons.warning_rounded : Icons.event_note_rounded,
                              size: 14,
                              color: isOverdue ? const Color(0xFFEF4444) : const Color(0xFF6366F1),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isOverdue
                                ? "متأخر: ${DateFormat('d MMM, h:mm a').format(nextFollowUp)}"
                                : "متابعة: ${DateFormat('d MMM, h:mm a').format(nextFollowUp)}",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isOverdue ? const Color(0xFFEF4444) : const Color(0xFF6366F1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ✅ الصف الأخير: مين أضاف ومين عدّل
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // ✅ مين أضاف
                        Expanded(
                          child: _buildUserInfoMini(
                            icon: Icons.person_add_rounded,
                            label: 'أضافه',
                            userName: userAdd,
                            dateTime: addTime,
                            color: const Color(0xFF10B981),
                            isDark: isDark,
                          ),
                        ),

                        // ✅ الفاصل
                        Container(
                          width: 1,
                          height: 45,
                          color: isDark ? Colors.grey[700] : Colors.grey[300],
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                        ),

                        // ✅ مين عدّل
                        Expanded(
                          child: _buildUserInfoMini(
                            icon: Icons.edit_rounded,
                            label: 'عدّله',
                            userName: userEdit,
                            dateTime: editTime,
                            color: const Color(0xFFF59E0B),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 12, color: color),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfoMini({
    required IconData icon,
    required String label,
    required String? userName,
    required DateTime? dateTime,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 9, color: Colors.grey[500]),
              ),
              const SizedBox(height: 2),
              Text(
                userName ?? '---',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (dateTime != null)
                Text(
                  DateFormat('d/M h:mm a').format(dateTime),
                  style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================
  // ✅ Empty State محسن
  // ============================================

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6366F1).withOpacity(0.15),
                    const Color(0xFF8B5CF6).withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_search_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(opacity: value, child: child);
            },
            child: Column(
              children: [
                Text(
                  _selectedStatus == 'الكل' ? "لا يوجد عملاء محتملين" : "لا يوجد عملاء بهذه الحالة",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "اضغط + لبدء إضافة عميل محتمل جديد",
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          if (_selectedStatus != 'الكل')
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = 'الكل';
                      _filterLeads();
                    });
                  },
                  icon: const Icon(Icons.clear_all_rounded, color: Colors.white),
                  label: const Text(
                    "عرض الكل",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================
  // ✅ Floating Buttons محسن
  // ============================================

  Widget _buildFloatingButtons(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ✅ Scroll to Top Button
        if (_showScrollToTop)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252836) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FloatingActionButton.small(
                heroTag: 'scrollToTop',
                onPressed: _scrollToTop,
                backgroundColor: isDark ? const Color(0xFF252836) : Colors.white,
                elevation: 0,
                child: const Icon(Icons.keyboard_arrow_up_rounded, color: Color(0xFF6366F1)),
              ),
            ),
          ),

        // ✅ Add FAB
        AnimatedBuilder(
          animation: _fabScaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: 1 - (_fabScaleAnimation.value * 0.3),
              child: Transform.translate(
                offset: Offset(0, _fabScaleAnimation.value * 100),
                child: child,
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              heroTag: 'addLead',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddLeadScreen()),
                ).then((_) {
                  _animationController.reset();
                  _statsAnimationController.reset();
                  _loadLeads();
                });
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'إضافة عميل',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }
}