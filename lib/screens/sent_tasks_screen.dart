import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class SentTasksScreen extends StatefulWidget {
  const SentTasksScreen({super.key});

  @override
  State<SentTasksScreen> createState() => _SentTasksScreenState();
}

class _SentTasksScreenState extends State<SentTasksScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _tasks = [];
  bool _isLoading = true;

  String? _filterStatus;
  String? _filterPriority;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
      final userId = auth.user?.userId;

      if (userId == null) {
        if (mounted) {
          setState(() {
            _tasks = [];
            _isLoading = false;
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
        setState(() {
          _tasks = data is List ? data : [];
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
          _buildSliverAppBar(isDark),
          SliverToBoxAdapter(
            child: _buildStatsBar(isDark),
          ),
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF6366F1),
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
    );
  }

  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: true,
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
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "المهام المُرسلة",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "المهام التي قمت بإرسالها للموظفين",
                          style: TextStyle(
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
    );
  }

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

  Widget _buildTaskCard(dynamic task, bool isDark, int index) {
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
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('d MMM').format(dueDate),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[500],
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

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.send_rounded,
              size: 60,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "لا توجد مهام مُرسلة",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "لم تقم بإرسال أي مهام للموظفين بعد",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}