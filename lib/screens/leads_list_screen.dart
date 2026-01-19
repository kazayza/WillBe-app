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
    with SingleTickerProviderStateMixin {
  List<dynamic> _leads = [];
  List<dynamic> _filteredLeads = [];
  bool _isLoading = true;
  String _selectedStatus = 'الكل'; // الكل - جديد - تم التواصل - تم التحويل

  final TextEditingController _searchController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _loadLeads();

    _searchController.addListener(() {
      _filterLeads();
    });
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
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
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تحميل البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterLeads() {
    setState(() {
      _filteredLeads = _leads.where((lead) {
        final name = (lead['FullName'] ?? '').toString().toLowerCase();
        final phone = (lead['Phone'] ?? '').toString().toLowerCase();
        final query = _searchController.text.toLowerCase();

        final matchesSearch = name.contains(query) || phone.contains(query);

        if (_selectedStatus == 'الكل') return matchesSearch;

        final status = (lead['Status'] ?? 'New').toString();
        final statusMatch =
            _selectedStatus == 'جديد' && status == 'New' ||
            _selectedStatus == 'تم التواصل' && status == 'Contacted' ||
            _selectedStatus == 'تم التحويل' && status == 'Converted';

        return matchesSearch && statusMatch;
      }).toList();
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'New':
        return const Color(0xFFF59E0B);
      case 'Contacted':
        return const Color(0xFF3B82F6);
      case 'Converted':
        return const Color(0xFF10B981);
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
      case 'Converted':
        return 'تم التحويل';
      default:
        return 'غير معروف';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
      body: RefreshIndicator(
        onRefresh: _loadLeads,
        color: const Color(0xFF6366F1),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(isDark),

            SliverToBoxAdapter(
              child: _buildSearchAndFilter(isDark),
            ),

            SliverToBoxAdapter(
              child: _buildStatsRow(isDark),
            ),

            _isLoading
                ? const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF6366F1)),
                    ),
                  )
                : _filteredLeads.isEmpty
                    ? SliverFillRemaining(
                        child: _buildEmptyState(isDark),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final lead = _filteredLeads[index];
                              return FadeTransition(
                                opacity: _fadeAnimation,
                                child:
                                    _buildLeadCard(lead, isDark, index),
                              );
                            },
                            childCount: _filteredLeads.length,
                          ),
                        ),
                      ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 160,
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
            child: const Icon(Icons.refresh_rounded,
                color: Colors.white, size: 20),
          ),
          onPressed: _loadLeads,
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
                bottom: 40,
                left: 20,
                right: 20,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.people_alt_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "العملاء المحتملين",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "إدارة ومتابعة الاستفسارات",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
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

  Widget _buildSearchAndFilter(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252836) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "ابحث بالاسم أو التليفون...",
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: const Icon(Icons.search,
                    color: Color(0xFF6366F1)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFilterChip('الكل', _selectedStatus == 'الكل', isDark),
              _buildFilterChip('جديد', _selectedStatus == 'جديد', isDark),
              _buildFilterChip('تم التواصل',
                  _selectedStatus == 'تم التواصل', isDark),
              _buildFilterChip('تم التحويل',
                  _selectedStatus == 'تم التحويل', isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, bool isDark) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = label;
          _filterLeads();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1)
              : (isDark ? Colors.grey[800] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6366F1)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    final newCount =
        _leads.where((l) => l['Status'] == 'New').length;
    final contactedCount =
        _leads.where((l) => l['Status'] == 'Contacted').length;
    final convertedCount =
        _leads.where((l) => l['Status'] == 'Converted').length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              "جدد",
              newCount,
              const Color(0xFFF59E0B),
              isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatCard(
              "تم التواصل",
              contactedCount,
              const Color(0xFF3B82F6),
              isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatCard(
              "تم التحويل",
              convertedCount,
              const Color(0xFF10B981),
              isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, int count, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.1), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadCard(dynamic lead, bool isDark, int index) {
    final status = (lead['Status'] ?? 'New').toString();
    final color = _getStatusColor(status);

    // معالجة التاريخ (CreatedAt) بحيث يبقى Local
    DateTime createdAt;
    final createdAtStr = lead['CreatedAt']?.toString();
    try {
      if (createdAtStr != null && createdAtStr.isNotEmpty) {
        createdAt =
            DateTime.parse(createdAtStr).toLocal();
      } else {
        createdAt = DateTime.now();
      }
    } catch (_) {
      createdAt = DateTime.now();
    }

    // تاريخ المتابعة الجاية (NextFollowUp) إن وجد
    DateTime? nextFollowUp;
    final nextStr = lead['NextFollowUp']?.toString();
    if (nextStr != null && nextStr.isNotEmpty) {
      try {
        nextFollowUp = DateTime.parse(nextStr).toLocal();
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
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LeadDetailsScreen(lead: lead),
            ),
          ).then((_) => _loadLeads());
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252836) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    (lead['FullName'] ?? '?')
                        .toString()
                        .characters
                        .first
                        .toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
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
                      (lead['FullName'] ?? '---').toString(),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          (lead['Phone'] ?? '---').toString(),
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                    if (lead['InterestedProgram'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          "مهتم بـ: ${lead['InterestedProgram']}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ),
                    if (nextFollowUp != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.event_note_rounded,
                              size: 14,
                              color: Color(0xFFEF4444),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "متابعة: ${DateFormat('d MMM').format(nextFollowUp)}",
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusText(status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('d MMM').format(createdAt),
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search_rounded,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            "لا يوجد عملاء محتملين",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "اضغط + لبدء إضافة استفسار جديد",
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddLeadScreen()),
          ).then((_) => _loadLeads());
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child:
            const Icon(Icons.add_rounded, size: 28, color: Colors.white),
      ),
    );
  }
}