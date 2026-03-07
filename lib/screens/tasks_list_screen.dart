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
    with TickerProviderStateMixin {
        // ✅ للردود
  final _replyController = TextEditingController();
  
  // ✅ Tab Controller
  late TabController _tabController;
  
  // ✅ بيانات مهامي
  List<dynamic> _myTasks = [];
  bool _isLoadingMyTasks = true;
  
  // ✅ بيانات المهام المُرسلة
  List<dynamic> _sentTasks = [];
  bool _isLoadingSentTasks = true;

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
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _setupAnimation();
    _loadMyTasks();
    _loadSentTasks();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _isSearching = false;
        _searchController.clear();
      });
    }
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

  // ✅ تحميل مهامي
  Future<void> _loadMyTasks() async {
    setState(() => _isLoadingMyTasks = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final empId = auth.empId;

      if (empId == null) {
        if (mounted) {
          setState(() {
            _myTasks = [];
            _isLoadingMyTasks = false;
          });
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
          _myTasks = tasks;
          _isLoadingMyTasks = false;
        });
        _animationController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMyTasks = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تحميل المهام: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ تحميل المهام المُرسلة
  Future<void> _loadSentTasks() async {
    setState(() => _isLoadingSentTasks = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final userId = auth.user?.userId;

      if (userId == null) {
        if (mounted) {
          setState(() {
            _sentTasks = [];
            _isLoadingSentTasks = false;
          });
        }
        return;
      }

      String endpoint = 'tasks/sent-by/$userId';
      List<String> queryParams = [];

      if (_filterStatus != null) {
        queryParams.add('status=$_filterStatus');
      }

      if (queryParams.isNotEmpty) {
        endpoint += '?${queryParams.join('&')}';
      }

      final data = await ApiService.get(endpoint);

      if (mounted) {
        List<dynamic> tasks = data is List ? data : [];

        if (_searchController.text.isNotEmpty) {
          final query = _searchController.text.toLowerCase();
          tasks = tasks.where((task) {
            final title = (task['Title'] ?? '').toString().toLowerCase();
            final desc = (task['Description'] ?? '').toString().toLowerCase();
            final assignedTo = (task['AssignedToName'] ?? '').toString().toLowerCase();
            return title.contains(query) || desc.contains(query) || assignedTo.contains(query);
          }).toList();
        }

        setState(() {
          _sentTasks = tasks;
          _isLoadingSentTasks = false;
        });
        _animationController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSentTasks = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تحميل المهام المُرسلة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // ✅ جلب ردود مهمة
Future<List<dynamic>> _getTaskReplies(int taskId) async {
  try {
    final data = await ApiService.get('tasks/$taskId/replies');
    return data is List ? data : [];
  } catch (e) {
    debugPrint('Error loading replies: $e');
    return [];
  }
}

// ✅ إضافة رد على مهمة
Future<bool> _addTaskReply(int taskId, String message) async {
  try {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.user?.userId;

    if (userId == null) return false;

    await ApiService.post('tasks/$taskId/replies', {
      'userId': userId,
      'message': message,
    });

    return true;
  } catch (e) {
    debugPrint('Error adding reply: $e');
    return false;
  }
}

// ✅ تعليم المهمة كمقروءة
Future<void> _markTaskAsRead(int taskId) async {
  try {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.user?.userId;

    if (userId == null) return;

    await ApiService.put('tasks/$taskId/read', {
      'userId': userId,
    });
  } catch (e) {
    debugPrint('Error marking task as read: $e');
  }
}

  // ✅ تحميل حسب الـ Tab الحالي
  void _loadCurrentTabTasks() {
    if (_tabController.index == 0) {
      _loadMyTasks();
    } else {
      _loadSentTasks();
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
    _loadMyTasks();
    _loadSentTasks();
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

      _loadMyTasks();
      _loadSentTasks();
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
  _tabController.dispose();
  _searchController.dispose();
  _animationController.dispose();
  _replyController.dispose(); // ✅ جديد
  super.dispose();
}

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildSliverAppBar(isDark),
          ];
        },
        body: Column(
          children: [
            // ✅ Tab Bar
            _buildTabBar(isDark),
            
            // ✅ Stats Bar
            _tabController.index == 0
                ? _buildMyTasksStatsBar(isDark)
                : _buildSentTasksStatsBar(isDark),

            // ✅ Active Filters
            if (_activeFiltersCount > 0) _buildActiveFilters(isDark),

            // ✅ Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: مهامي
                  _buildMyTasksList(isDark),
                  // Tab 2: المُرسلة
                  _buildSentTasksList(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  // ✅ Tab Bar Widget
  Widget _buildTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
      child: TabBar(
        controller: _tabController,
        onTap: (index) {
          setState(() {});
        },
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: _tabController.index == 0
                ? [const Color(0xFFF59E0B), const Color(0xFFF97316)]
                : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
          ),
          boxShadow: [
            BoxShadow(
              color: (_tabController.index == 0
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF6366F1))
                  .withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(6),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[500],
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.task_alt_rounded,
                  size: 18,
                  color: _tabController.index == 0 ? Colors.white : Colors.grey[500],
                ),
                const SizedBox(width: 8),
                Text(_tabController.index == 0 ? "مهامي" : "مهامي"),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.send_rounded,
                  size: 18,
                  color: _tabController.index == 1 ? Colors.white : Colors.grey[500],
                ),
                const SizedBox(width: 8),
                Text(_tabController.index == 1 ? "المُرسلة" : "المُرسلة"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Sliver App Bar
  Widget _buildSliverAppBar(bool isDark) {
    final isMyTasks = _tabController.index == 0;
    final gradientColors = isMyTasks
        ? [const Color(0xFFF59E0B), const Color(0xFFF97316)]
        : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)];

    return SliverAppBar(
      expandedHeight: 180,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: gradientColors[0],
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
                _loadCurrentTabTasks();
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
                  color: _activeFiltersCount > 0 ? gradientColors[0] : Colors.white,
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
          onPressed: () {
            _loadMyTasks();
            _loadSentTasks();
          },
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
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
              Positioned(
                bottom: 60,
                left: 20,
                right: 20,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        isMyTasks ? Icons.task_alt_rounded : Icons.send_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMyTasks ? "مهامي" : "المهام المُرسلة",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isMyTasks
                              ? "إدارة ومتابعة المهام اليومية"
                              : "المهام التي قمت بإرسالها للموظفين",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
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
                  onChanged: (_) => _loadCurrentTabTasks(),
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: "ابحث بالعنوان أو الوصف...",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(
                      Icons.search,
                      color: _tabController.index == 0
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF6366F1),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              _loadCurrentTabTasks();
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

  // ✅ Stats Bar لمهامي
  Widget _buildMyTasksStatsBar(bool isDark) {
    final totalTasks = _myTasks.length;
    final pendingTasks = _myTasks.where((t) => t['Status'] == 'Pending').length;
    final completedTasks = _myTasks.where((t) => t['Status'] == 'Completed').length;

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

  // ✅ Stats Bar للمُرسلة
  Widget _buildSentTasksStatsBar(bool isDark) {
    final totalTasks = _sentTasks.length;
    final pendingTasks = _sentTasks.where((t) => t['Status'] == 'Pending').length;
    final completedTasks = _sentTasks.where((t) => t['Status'] == 'Completed').length;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.send_rounded,
              label: "المُرسلة",
              value: totalTasks.toString(),
              color: const Color(0xFF6366F1),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.schedule_rounded,
              label: "معلقة",
              value: pendingTasks.toString(),
              color: const Color(0xFFF59E0B),
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

  // ✅ Active Filters
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

            if (_filterStatus != null)
              _buildFilterChip(
                label: _getStatusLabel(_filterStatus!),
                icon: _getStatusIcon(_filterStatus!),
                color: _getStatusColor(_filterStatus!),
                onRemove: () {
                  setState(() => _filterStatus = null);
                  _updateActiveFiltersCount();
                  _loadMyTasks();
                  _loadSentTasks();
                },
              ),

            if (_filterPriority != null)
              _buildFilterChip(
                label: _getPriorityLabel(_filterPriority!),
                icon: Icons.flag_rounded,
                color: _getPriorityColor(_filterPriority!),
                onRemove: () {
                  setState(() => _filterPriority = null);
                  _updateActiveFiltersCount();
                  _loadMyTasks();
                  _loadSentTasks();
                },
              ),

            const SizedBox(width: 8),

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

  // ✅ قائمة مهامي
  Widget _buildMyTasksList(bool isDark) {
    if (_isLoadingMyTasks) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
      );
    }

    if (_myTasks.isEmpty) {
      return _buildEmptyState(isDark, isMyTasks: true);
    }

    return RefreshIndicator(
      onRefresh: _loadMyTasks,
      color: const Color(0xFFF59E0B),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _myTasks.length,
        itemBuilder: (context, index) {
          final task = _myTasks[index];
          return FadeTransition(
            opacity: _fadeAnimation,
            child: _buildMyTaskCard(task, isDark, index),
          );
        },
      ),
    );
  }

  // ✅ قائمة المهام المُرسلة
  Widget _buildSentTasksList(bool isDark) {
    if (_isLoadingSentTasks) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6366F1)),
      );
    }

    if (_sentTasks.isEmpty) {
      return _buildEmptyState(isDark, isMyTasks: false);
    }

    return RefreshIndicator(
      onRefresh: _loadSentTasks,
      color: const Color(0xFF6366F1),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _sentTasks.length,
        itemBuilder: (context, index) {
          final task = _sentTasks[index];
          return FadeTransition(
            opacity: _fadeAnimation,
            child: _buildSentTaskCard(task, isDark, index),
          );
        },
      ),
    );
  }

  // ✅ كارت مهمة من مهامي
  Widget _buildMyTaskCard(dynamic task, bool isDark, int index) {
    final title = (task['Title'] ?? '---').toString();
    final desc = (task['Description'] ?? '').toString();
    final prio = (task['Priority'] ?? 'Medium').toString();
    final status = (task['Status'] ?? 'Pending').toString();
    final custName = (task['CustomerName'] ?? '').toString();
    final childName = (task['ChildName'] ?? '').toString();
    final leadName = (task['LeadName'] ?? '').toString();
    final assignedByName = (task['AssignedByName'] ?? '').toString();

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
        onTap: () => _showTaskDetailsSheet(task, isDark, isMyTask: true),
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
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
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
                              child: const Center(
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

                            // ✅ عرض اسم المُرسل
                            if (assignedByName.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline_rounded,
                                      size: 12,
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "من: $assignedByName",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            Row(
                              children: [
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
                      Column(
                        children: [
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

  // ✅ كارت مهمة مُرسلة
  Widget _buildSentTaskCard(dynamic task, bool isDark, int index) {
    final title = (task['Title'] ?? '---').toString();
    final desc = (task['Description'] ?? '').toString();
    final prio = (task['Priority'] ?? 'Medium').toString();
    final status = (task['Status'] ?? 'Pending').toString();
    final assignedToName = (task['AssignedToName'] ?? 'غير محدد').toString();

    DateTime? dueDate;
    final dueStr = task['DueDate']?.toString();
    if (dueStr != null && dueStr.isNotEmpty) {
      try {
        dueDate = DateTime.parse(dueStr).toLocal();
      } catch (_) {}
    }

    final prioColor = _getPriorityColor(prio);
    final statusColor = _getStatusColor(status);

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
        onTap: () => _showTaskDetailsSheet(task, isDark, isMyTask: false),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252836) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
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
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              statusColor.withOpacity(0.2),
                              statusColor.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(
                          child: Icon(
                            _getStatusIcon(status),
                            size: 28,
                            color: statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
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

                            // ✅ عرض اسم المُرسل إليه
                            Row(
                              children: [
                                const Icon(
                                  Icons.person_rounded,
                                  size: 12,
                                  color: Color(0xFF6366F1),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "إلى: $assignedToName",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6366F1),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 6),

                            Row(
                              children: [
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
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: prioColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.flag_rounded,
                                        size: 12,
                                        color: prioColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _getPriorityLabel(prio),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: prioColor,
                                          fontWeight: FontWeight.w600,
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

  // ✅ Task Details Sheet
  // ✅ Task Details Sheet مع الردود
// ✅ Task Details Sheet مع الردود
void _showTaskDetailsSheet(dynamic task, bool isDark, {required bool isMyTask}) {
  final taskId = task['TaskID'] as int;
  final title = (task['Title'] ?? '---').toString();
  final desc = (task['Description'] ?? '').toString();
  final prio = (task['Priority'] ?? 'Medium').toString();
  final status = (task['Status'] ?? 'Pending').toString();
  final custName = (task['CustomerName'] ?? '').toString();
  final childName = (task['ChildName'] ?? '').toString();
  final leadName = (task['LeadName'] ?? '').toString();
  final assignedByName = (task['AssignedByName'] ?? '').toString();
  final assignedToName = (task['AssignedToName'] ?? '').toString();

  String formattedDate = 'غير محدد';
  DateTime? dueDate;

  try {
    final dueStr = task['DueDate']?.toString();
    if (dueStr != null && dueStr.isNotEmpty) {
      dueDate = DateTime.tryParse(dueStr)?.toLocal();
      if (dueDate != null) {
        formattedDate = '${dueDate.day}/${dueDate.month}/${dueDate.year}';
      }
    }
  } catch (e) {
    debugPrint('Date parsing error: $e');
  }

  if (isMyTask) {
    _markTaskAsRead(taskId);
  }
  final replyTextController = TextEditingController();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    builder: (ctx) {
      List<dynamic> replies = [];
      bool isLoadingReplies = true;
      bool isSendingReply = false;
      

      return StatefulBuilder(
        builder: (context, setSheetState) {
          if (isLoadingReplies) {
            _getTaskReplies(taskId).then((data) {
              setSheetState(() {
                replies = data;
                isLoadingReplies = false;
              });
            });
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252836) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
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
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (desc.isNotEmpty)
                            _buildDetailItem(
                              icon: Icons.description_rounded,
                              title: "الوصف",
                              value: desc,
                              color: const Color(0xFF8B5CF6),
                              isDark: isDark,
                            ),
                          if (dueDate != null)
                            _buildDetailItem(
                              icon: Icons.calendar_today_rounded,
                              title: "تاريخ الاستحقاق",
                              value: formattedDate,
                              color: const Color(0xFFF59E0B),
                              isDark: isDark,
                            ),
                          if (!isMyTask && assignedToName.isNotEmpty)
                            _buildDetailItem(
                              icon: Icons.person_rounded,
                              title: "مُرسلة إلى",
                              value: assignedToName,
                              color: const Color(0xFF6366F1),
                              isDark: isDark,
                            ),
                          if (isMyTask && assignedByName.isNotEmpty)
                            _buildDetailItem(
                              icon: Icons.send_rounded,
                              title: "تم التكليف بواسطة",
                              value: assignedByName,
                              color: const Color(0xFF6366F1),
                              isDark: isDark,
                            ),
                          if (custName.isNotEmpty)
                            _buildDetailItem(
                              icon: Icons.person_rounded,
                              title: "العميل",
                              value: custName,
                              color: const Color(0xFF3B82F6),
                              isDark: isDark,
                            ),
                          if (childName.isNotEmpty)
                            _buildDetailItem(
                              icon: Icons.child_care_rounded,
                              title: "الطفل",
                              value: childName,
                              color: const Color(0xFF06B6D4),
                              isDark: isDark,
                            ),
                          if (leadName.isNotEmpty)
                            _buildDetailItem(
                              icon: Icons.trending_up_rounded,
                              title: "Lead",
                              value: leadName,
                              color: const Color(0xFF10B981),
                              isDark: isDark,
                            ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.chat_bubble_rounded,
                                  color: Color(0xFF3B82F6),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "الردود والتعليقات",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "${replies.length}",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (isLoadingReplies)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                            )
                          else if (replies.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 40,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      "لا توجد ردود بعد",
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "كن أول من يرد على هذه المهمة",
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...replies.map((reply) {
                              final replyUserName = (reply['UserName'] ?? 'مستخدم').toString();
                              final replyMessage = (reply['Message'] ?? '').toString();
                              final replyDate = reply['CreatedAt'] != null
                                  ? DateTime.tryParse(reply['CreatedAt'].toString())?.toUtc()
                                  : null;

                              String timeAgo = '';
                              if (replyDate != null) {
                                final localDate = replyDate.toLocal();
                                final diff = DateTime.now().difference(localDate);
                                if (diff.inMinutes < 1) {
                                  timeAgo = 'الآن';
                                } else if (diff.inMinutes < 60) {
                                  timeAgo = 'منذ ${diff.inMinutes} دقيقة';
                                } else if (diff.inHours < 24) {
                                  timeAgo = 'منذ ${diff.inHours} ساعة';
                                } else {
                                  timeAgo = 'منذ ${diff.inDays} يوم';
                                }
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                                            ),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            replyUserName.isNotEmpty ? replyUserName[0].toUpperCase() : '?',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                replyUserName,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: isDark ? Colors.white : Colors.black87,
                                                ),
                                              ),
                                              Text(
                                                timeAgo,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      replyMessage,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      MediaQuery.of(context).padding.bottom + 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
                      border: Border(
                        top: BorderSide(
                          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF252836) : Colors.white,
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                                  ),
                                ),
                                child: TextField(
                                  controller: replyTextController,
                                  maxLines: null,
                                  textInputAction: TextInputAction.send,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "اكتب رداً...",
                                    hintStyle: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                  ),
                                  onSubmitted: (value) async {
                                    if (value.trim().isEmpty) return;
                                    setSheetState(() => isSendingReply = true);
                                    final success = await _addTaskReply(taskId, value.trim());
                                    if (success) {
                                     replyTextController.value = TextEditingValue.empty;
                                    final newReplies = await _getTaskReplies(taskId);
                                    FocusScope.of(context).unfocus();
                                    setSheetState(() {
                                    replies = newReplies;
                                    isSendingReply = false;
                                    });
                                    } else {
                                      setSheetState(() => isSendingReply = false);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('فشل إرسال الرد'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: isSendingReply
                                  ? null
                                  : () async {
                                      final message = replyTextController.text.trim();
                                      if (message.isEmpty) return;
                                      setSheetState(() => isSendingReply = true);
                                      final success = await _addTaskReply(taskId, message);
                                      if (success) {
                                      replyTextController.value = TextEditingValue.empty;
                                      final newReplies = await _getTaskReplies(taskId);
                                      FocusScope.of(context).unfocus();
                                      setSheetState(() {
                                      replies = newReplies;
                                      isSendingReply = false;
                                      });
                                      } else {
                                        setSheetState(() => isSendingReply = false);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('فشل إرسال الرد'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF3B82F6).withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: isSendingReply
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.send_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                              ),
                            ),
                          ],
                        ),
                        if (isMyTask && status != 'Completed') ...[
                          const SizedBox(height: 12),
                          Container(
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
                                _updateTaskStatus(taskId, 'Completed');
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
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

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

  Widget _buildEmptyState(bool isDark, {required bool isMyTasks}) {
    final color = isMyTasks ? const Color(0xFFF59E0B) : const Color(0xFF6366F1);
    final icon = isMyTasks ? Icons.task_alt_rounded : Icons.send_rounded;
    final title = isMyTasks ? "لا توجد مهام" : "لا توجد مهام مُرسلة";
    final subtitle = isMyTasks
        ? "جرب تغيير الفلاتر أو اضغط + للإضافة"
        : "لم تقم بإرسال أي مهام للموظفين بعد";

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 60,
              color: color,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          if (isMyTasks) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddTaskScreen()),
                ).then((result) {
                  if (result == true) {
                    _loadMyTasks();
                    _loadSentTasks();
                  }
                });
              },
              icon: const Icon(Icons.add),
              label: const Text("إضافة مهمة"),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

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
            if (result == true) {
              _loadMyTasks();
              _loadSentTasks();
            }
          });
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add_task_rounded, size: 26, color: Colors.white),
      ),
    );
  }

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
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

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

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                _loadMyTasks();
                                _loadSentTasks();
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
                                  