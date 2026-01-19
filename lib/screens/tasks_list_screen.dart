import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'add_task_screen.dart';

class TasksListScreen extends StatefulWidget {
  const TasksListScreen({super.key});

  @override
  State<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends State<TasksListScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _tasks = [];
  bool _isLoading = true;
  
  // Filter Values
  String? _filterStatus;
  String? _filterPriority;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isSearching = false;
  final _searchController = TextEditingController();
  int _activeFiltersCount = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _loadTasks();
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

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final empId = auth.empId;

      if (empId == null) {
        if (mounted) {
          setState(() {
            _tasks = [];
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('حسابك غير مربوط بكود موظف، لا توجد مهام شخصية لعرضها.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      String endpoint = 'tasks/$empId';
      List<String> queryParams = [];

      if (_filterStatus != null) {
        queryParams.add('status=$_filterStatus');
      }
      if (_filterPriority != null) {
        queryParams.add('priority=$_filterPriority');
      }

      if (queryParams.isNotEmpty) {
        endpoint += '?${queryParams.join('&')}';
      }

      final data = await ApiService.get(endpoint);

      if (mounted) {
        List<dynamic> tasks = data is List ? data : [];
        
        // تصفية البحث محلياً
        if (_searchController.text.isNotEmpty) {
          final query = _searchController.text.toLowerCase();
          tasks = tasks.where((task) {
            final title = (task['Title'] ?? '').toString().toLowerCase();
            final desc = (task['Description'] ?? '').toString().toLowerCase();
            final custName = (task['CustomerName'] ?? '').toString().toLowerCase();
            return title.contains(query) || desc.contains(query) || custName.contains(query);
          }).toList();
        }

        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
        _animationController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تحميل المهام: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateActiveFiltersCount() {
    int count = 0;
    if (_filterStatus != null) count++;
    if (_filterPriority != null) count++;
    setState(() => _activeFiltersCount = count);
  }

  void _clearAllFilters() {
    setState(() {
      _filterStatus = null;
      _filterPriority = null;
      _activeFiltersCount = 0;
    });
    _loadTasks();
  }

  Future<void> _updateTaskStatus(int taskId, String newStatus) async {
    try {
      await ApiService.put('tasks/$taskId/status', {
        'status': newStatus,
        'notes': 'تم التحديث من التطبيق',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحديث حالة المهمة إلى: $newStatus'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }

      _loadTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تحديث المهمة: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Color _getPriorityColor(String prio) {
    switch (prio) {
      case 'High':
        return const Color(0xFFEF4444);
      case 'Medium':
        return const Color(0xFFF59E0B);
      case 'Low':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return const Color(0xFFF59E0B);
      case 'In Progress':
        return const Color(0xFF3B82F6);
      case 'Completed':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.schedule_rounded;
      case 'In Progress':
        return Icons.play_circle_rounded;
      case 'Completed':
        return Icons.check_circle_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'Pending':
        return 'معلقة';
      case 'In Progress':
        return 'قيد التنفيذ';
      case 'Completed':
        return 'مكتملة';
      default:
        return status;
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'High':
        return 'عالية';
      case 'Medium':
        return 'متوسطة';
      case 'Low':
        return 'منخفضة';
      default:
        return priority;
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
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 🎨 App Bar
          _buildSliverAppBar(isDark),

          // 📊 Stats Bar
          SliverToBoxAdapter(
            child: _buildStatsBar(isDark),
          ),

          // 🏷️ Active Filters
          if (_activeFiltersCount > 0)
            SliverToBoxAdapter(
              child: _buildActiveFilters(isDark),
            ),

          // 📋 Tasks List
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                )
              : _tasks.isEmpty
                  ? SliverFillRemaining(
                      child: _buildEmptyState(isDark),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final task = _tasks[index];
                            return FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildTaskCard(task, isDark, index),
                            );
                          },
                          childCount: _tasks.length,
                        ),
                      ),
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
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFFF59E0B),
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
        // 🔍 Search Toggle
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.white,
              size: 20,
            ),
          ),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
                _loadTasks();
              }
            });
          },
        ),

        // 🔽 Filter
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _activeFiltersCount > 0
                  ? Colors.white
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Icon(
                  Icons.tune_rounded,
                  color: _activeFiltersCount > 0
                      ? const Color(0xFFF59E0B)
                      : Colors.white,
                  size: 20,
                ),
                if (_activeFiltersCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          "$_activeFiltersCount",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          onPressed: () => _showFilterBottomSheet(isDark),
        ),

        // 🔄 Refresh
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
          ),
          onPressed: _loadTasks,
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
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
                bottom: 20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),

              // Content
              Positioned(
                bottom: 60,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.task_alt_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 15),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "متابعات اليوم",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "إدارة ومتابعة المهام اليومية",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottom: _isSearching
          ? PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => _loadTasks(),
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: "ابحث بالعنوان أو الوصف أو العميل...",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFFF59E0B)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              _loadTasks();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  // 📊 Stats Bar
  Widget _buildStatsBar(bool isDark) {
    final totalTasks = _tasks.length;
    final pendingTasks = _tasks.where((t) => t['Status'] == 'Pending').length;
    final completedTasks = _tasks.where((t) => t['Status'] == 'Completed').length;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.assignment_rounded,
              label: "الإجمالي",
              value: totalTasks.toString(),
              color: const Color(0xFFF59E0B),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.schedule_rounded,
              label: "معلقة",
              value: pendingTasks.toString(),
              color: const Color(0xFF3B82F6),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.check_circle_rounded,
              label: "مكتملة",
              value: completedTasks.toString(),
              color: const Color(0xFF10B981),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
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
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // 🏷️ Active Filters
  Widget _buildActiveFilters(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(
              "الفلاتر:",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 10),

            // Status Filter
            if (_filterStatus != null)
              _buildFilterChip(
                label: _getStatusLabel(_filterStatus!),
                icon: _getStatusIcon(_filterStatus!),
                color: _getStatusColor(_filterStatus!),
                onRemove: () {
                  setState(() => _filterStatus = null);
                  _updateActiveFiltersCount();
                  _loadTasks();
                },
              ),

            // Priority Filter
            if (_filterPriority != null)
              _buildFilterChip(
                label: _getPriorityLabel(_filterPriority!),
                icon: Icons.flag_rounded,
                color: _getPriorityColor(_filterPriority!),
                onRemove: () {
                  setState(() => _filterPriority = null);
                  _updateActiveFiltersCount();
                  _loadTasks();
                },
              ),

            const SizedBox(width: 8),

            // Clear All
            GestureDetector(
              onTap: _clearAllFilters,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.clear_all_rounded, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      "مسح الكل",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 12),
            ),
          ),
        ],
      ),
    );
  }

  // 📋 Task Card
  Widget _buildTaskCard(dynamic task, bool isDark, int index) {
    final title = (task['Title'] ?? '---').toString();
    final desc = (task['Description'] ?? '').toString();
    final prio = (task['Priority'] ?? 'Medium').toString();
    final status = (task['Status'] ?? 'Pending').toString();
    final custName = (task['CustomerName'] ?? '').toString();
    final childName = (task['ChildName'] ?? '').toString();
    final leadName = (task['LeadName'] ?? '').toString();

    DateTime? dueDate;
    final dueStr = task['DueDate']?.toString();
    if (dueStr != null && dueStr.isNotEmpty) {
      try {
        dueDate = DateTime.parse(dueStr).toLocal();
      } catch (_) {}
    }

    final prioColor = _getPriorityColor(prio);
    final statusColor = _getStatusColor(status);
    final cardColor = status == 'Completed' 
        ? const Color(0xFF10B981) 
        : const Color(0xFFF59E0B);

    // نجهز النص اللي هنعرّضه كصاحب المهمة
    final displayParts = <String>[];
    if (custName.isNotEmpty) {
      displayParts.add(custName);
    } else if (leadName.isNotEmpty) {
      displayParts.add("Lead: $leadName");
    }
    if (childName.isNotEmpty) {
      displayParts.add("($childName)");
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
        onTap: () => _showTaskDetailsSheet(task, isDark),
        onLongPress: () {
          if (status != 'Completed') {
            _showCompleteDialog(task['TaskID'] as int, title);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252836) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: cardColor.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
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
                        colors: [prioColor, prioColor.withOpacity(0.5)],
                      ),
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Icon with Status
                      Stack(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  cardColor.withOpacity(0.2),
                                  cardColor.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Center(
                              child: Icon(
                                _getTaskIcon(status),
                                size: 28,
                                color: cardColor,
                              ),
                            ),
                          ),
                          // Priority Indicator
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: prioColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? const Color(0xFF252836) : Colors.white,
                                  width: 3,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.flag_rounded,
                                  color: Colors.white,
                                  size: 9,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 15),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                                decoration: status == 'Completed'
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),

                            if (desc.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  desc,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                            Row(
                              children: [
                                // Status Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getStatusIcon(status),
                                        size: 12,
                                        color: statusColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _getStatusLabel(status),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: statusColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Customer Badge
                                if (displayParts.isNotEmpty)
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6366F1).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.person_rounded,
                                            size: 12,
                                            color: Color(0xFF6366F1),
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              displayParts.join(' '),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF6366F1),
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Actions Column
                      Column(
                        children: [
                          // Due Date
                          if (dueDate != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _isOverdue(dueDate, status)
                                    ? const Color(0xFFEF4444).withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 14,
                                    color: _isOverdue(dueDate, status)
                                        ? const Color(0xFFEF4444)
                                        : Colors.grey[500],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('d MMM').format(dueDate),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: _isOverdue(dueDate, status)
                                          ? const Color(0xFFEF4444)
                                          : Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 8),

                          // Complete Button
                          if (status != 'Completed')
                            GestureDetector(
                              onTap: () => _showCompleteDialog(
                                task['TaskID'] as int,
                                title,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Color(0xFF10B981),
                                  size: 18,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: cardColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: cardColor,
                                size: 14,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getTaskIcon(String status) {
    switch (status) {
      case 'Completed':
        return Icons.task_alt_rounded;
      case 'In Progress':
        return Icons.play_arrow_rounded;
      default:
        return Icons.assignment_rounded;
    }
  }

  bool _isOverdue(DateTime dueDate, String status) {
    if (status == 'Completed') return false;
    return dueDate.isBefore(DateTime.now());
  }

  // 📋 Task Details Sheet
 // 📋 Task Details Sheet - Fixed Version
void _showTaskDetailsSheet(dynamic task, bool isDark) {
  final title = (task['Title'] ?? '---').toString();
  final desc = (task['Description'] ?? 'لا يوجد وصف').toString();
  final prio = (task['Priority'] ?? 'Medium').toString();
  final status = (task['Status'] ?? 'Pending').toString();
  final custName = (task['CustomerName'] ?? '').toString();
  final childName = (task['ChildName'] ?? '').toString();
  final leadName = (task['LeadName'] ?? '').toString();

  // ✅ Fixed: Safe date parsing
  String formattedDate = 'غير محدد';
  DateTime? dueDate;
  
  try {
    final dueStr = task['DueDate']?.toString();
    if (dueStr != null && dueStr.isNotEmpty) {
      dueDate = DateTime.tryParse(dueStr)?.toLocal();
      if (dueDate != null) {
        // استخدم format بسيط بدون locale لتجنب المشاكل
        formattedDate = '${dueDate.day}/${dueDate.month}/${dueDate.year}';
      }
    }
  } catch (e) {
    debugPrint('Date parsing error: $e');
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252836) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _getTaskIcon(status),
                      color: _getStatusColor(status),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _getStatusLabel(status),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _getStatusColor(status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _getPriorityColor(prio).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.flag_rounded,
                                    size: 10,
                                    color: _getPriorityColor(prio),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getPriorityLabel(prio),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _getPriorityColor(prio),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),

            // Details
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    if (desc.isNotEmpty && desc != 'لا يوجد وصف')
                      _buildDetailItem(
                        icon: Icons.description_rounded,
                        title: "الوصف",
                        value: desc,
                        color: const Color(0xFF8B5CF6),
                        isDark: isDark,
                      ),

                    // Due Date
                    if (dueDate != null)
                      _buildDetailItem(
                        icon: Icons.calendar_today_rounded,
                        title: "تاريخ الاستحقاق",
                        value: formattedDate,
                        color: const Color(0xFFF59E0B),
                        isDark: isDark,
                      ),

                    // Customer
                    if (custName.isNotEmpty)
                      _buildDetailItem(
                        icon: Icons.person_rounded,
                        title: "العميل",
                        value: custName,
                        color: const Color(0xFF3B82F6),
                        isDark: isDark,
                      ),

                    // Child
                    if (childName.isNotEmpty)
                      _buildDetailItem(
                        icon: Icons.child_care_rounded,
                        title: "الطفل",
                        value: childName,
                        color: const Color(0xFF06B6D4),
                        isDark: isDark,
                      ),

                    // Lead
                    if (leadName.isNotEmpty)
                      _buildDetailItem(
                        icon: Icons.trending_up_rounded,
                        title: "Lead",
                        value: leadName,
                        color: const Color(0xFF10B981),
                        isDark: isDark,
                      ),
                      
                    // Empty state if no details
                    if (desc.isEmpty && dueDate == null && custName.isEmpty && childName.isEmpty && leadName.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'لا توجد تفاصيل إضافية',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Actions
            if (status != 'Completed')
              Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  MediaQuery.of(context).padding.bottom + 16,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    ),
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
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
                    onPressed: () {
                      Navigator.pop(ctx);
                      final taskId = task['TaskID'];
                      if (taskId != null) {
                        _updateTaskStatus(taskId as int, 'Completed');
                      }
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: const Text(
                      "تعليم كمكتملة",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

// ✅ Helper function للتفاصيل
Widget _buildDetailItem({
  required IconData icon,
  required String title,
  required String value,
  required Color color,
  required bool isDark,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}



  // ✅ Complete Dialog
  void _showCompleteDialog(int taskId, String title) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDark;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF252836) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'إنهاء المهمة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        content: Text(
          'هل تريد تعليم المهمة "$title" كمكتملة؟',
          style: TextStyle(
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'إلغاء',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _updateTaskStatus(taskId, 'Completed');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'تأكيد',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 📭 Empty State
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              size: 60,
              color: Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "لا توجد مهام",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "جرب تغيير الفلاتر أو اضغط + للإضافة",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddTaskScreen()),
              ).then((result) {
                if (result == true) _loadTasks();
              });
            },
            icon: const Icon(Icons.add),
            label: const Text("إضافة مهمة"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
          colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTaskScreen()),
          ).then((result) {
            if (result == true) _loadTasks();
          });
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add_task_rounded, size: 26, color: Colors.white),
      ),
    );
  }

  // 🔽 Filter Bottom Sheet
  void _showFilterBottomSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.55,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252836) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: Color(0xFFF59E0B),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "تصفية المهام",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                "اختر معايير البحث",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_activeFiltersCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "$_activeFiltersCount فلتر",
                              style: const TextStyle(
                                color: Color(0xFFF59E0B),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),

                  // Filters Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status Filter
                          _buildFilterSection(
                            title: "الحالة",
                            icon: Icons.toggle_on_rounded,
                            color: const Color(0xFF3B82F6),
                            isDark: isDark,
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _buildStatusFilterChip(
                                  label: "الكل",
                                  isSelected: _filterStatus == null,
                                  color: const Color(0xFF6B7280),
                                  onTap: () => setSheetState(() => _filterStatus = null),
                                ),
                                _buildStatusFilterChip(
                                  label: "معلقة",
                                  icon: Icons.schedule_rounded,
                                  isSelected: _filterStatus == 'Pending',
                                  color: const Color(0xFFF59E0B),
                                  onTap: () => setSheetState(() => _filterStatus = 'Pending'),
                                ),
                                _buildStatusFilterChip(
                                  label: "قيد التنفيذ",
                                  icon: Icons.play_circle_rounded,
                                  isSelected: _filterStatus == 'In Progress',
                                  color: const Color(0xFF3B82F6),
                                  onTap: () => setSheetState(() => _filterStatus = 'In Progress'),
                                ),
                                _buildStatusFilterChip(
                                  label: "مكتملة",
                                  icon: Icons.check_circle_rounded,
                                  isSelected: _filterStatus == 'Completed',
                                  color: const Color(0xFF10B981),
                                  onTap: () => setSheetState(() => _filterStatus = 'Completed'),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Priority Filter
                          _buildFilterSection(
                            title: "الأولوية",
                            icon: Icons.flag_rounded,
                            color: const Color(0xFFEF4444),
                            isDark: isDark,
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _buildStatusFilterChip(
                                  label: "الكل",
                                  isSelected: _filterPriority == null,
                                  color: const Color(0xFF6B7280),
                                  onTap: () => setSheetState(() => _filterPriority = null),
                                ),
                                _buildStatusFilterChip(
                                  label: "عالية",
                                  icon: Icons.keyboard_arrow_up_rounded,
                                  isSelected: _filterPriority == 'High',
                                  color: const Color(0xFFEF4444),
                                  onTap: () => setSheetState(() => _filterPriority = 'High'),
                                ),
                                _buildStatusFilterChip(
                                  label: "متوسطة",
                                  icon: Icons.remove_rounded,
                                  isSelected: _filterPriority == 'Medium',
                                  color: const Color(0xFFF59E0B),
                                  onTap: () => setSheetState(() => _filterPriority = 'Medium'),
                                ),
                                _buildStatusFilterChip(
                                  label: "منخفضة",
                                  icon: Icons.keyboard_arrow_down_rounded,
                                  isSelected: _filterPriority == 'Low',
                                  color: const Color(0xFF10B981),
                                  onTap: () => setSheetState(() => _filterPriority = 'Low'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Action Buttons
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      16,
                      20,
                      MediaQuery.of(context).padding.bottom + 16,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
                      border: Border(
                        top: BorderSide(
                          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setSheetState(() {
                                _filterStatus = null;
                                _filterPriority = null;
                              });
                            },
                            icon: const Icon(Icons.clear_all_rounded),
                            label: const Text("مسح الكل"),
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
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B).withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _updateActiveFiltersCount();
                                _loadTasks();
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.check_rounded),
                              label: const Text(
                                "تطبيق الفلاتر",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterSection({
    required String title,
    required IconData icon,
    required Color color,
    required bool isDark,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildStatusFilterChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : color,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}