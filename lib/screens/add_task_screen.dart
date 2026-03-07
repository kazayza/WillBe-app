import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class AddTaskScreen extends StatefulWidget {
  final int? customerId;
  final String? customerName;
  final int? leadId;
  final String? leadName;

  const AddTaskScreen({
    super.key,
    this.customerId,
    this.customerName,
    this.leadId,
    this.leadName,
  });

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _notesController = TextEditingController();
  final _dueDateController = TextEditingController();

  String _selectedPriority = 'Medium';
  DateTime? _selectedDueDate;

  bool _isSaving = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  int? _currentEmpId;
  String? _currentRole;

  List<Map<String, dynamic>> _employees = [];
  bool _isLoadingEmployees = false;
  int? _selectedAssignedEmpId;

  double get _completionPercentage {
    int filled = 0;
    int total = 4;

    if (_titleController.text.isNotEmpty) filled++;
    if (_selectedAssignedEmpId != null) filled++;
    if (_selectedPriority.isNotEmpty) filled++;
    if (_selectedDueDate != null) filled++;

    return filled / total;
  }

  @override
  void initState() {
    super.initState();
    _setupAnimation();

    final auth = Provider.of<AuthProvider>(context, listen: false);
    _currentEmpId = auth.empId;
    _currentRole = auth.user?.role;

    _loadEmployees();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoadingEmployees = true);
    try {
      final data = await ApiService.get('employees/with-users');

      if (mounted && data is List) {
        _employees = [];
        for (final e in data) {
          final id = e['ID'];
          final nameRaw = e['empName'];
          final name = nameRaw != null ? nameRaw.toString().trim() : '';

          if (id != null && name.isNotEmpty) {
            _employees.add({'id': id, 'name': name});
          }
        }

        if (_currentEmpId != null &&
            _employees.any((emp) => emp['id'] == _currentEmpId)) {
          _selectedAssignedEmpId = _currentEmpId;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text('فشل تحميل قائمة الموظفين: $e')),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingEmployees = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _notesController.dispose();
    _dueDateController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final initial = _selectedDueDate ?? now.add(const Duration(days: 1));
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDark;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFFF59E0B),
                    surface: Color(0xFF252836),
                  )
                : const ColorScheme.light(
                    primary: Color(0xFFF59E0B),
                  ),
            dialogBackgroundColor:
                isDark ? const Color(0xFF252836) : Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _selectedDueDate = DateTime(picked.year, picked.month, picked.day);
      _dueDateController.text = DateFormat('yyyy/MM/dd').format(_selectedDueDate!);
      setState(() {});
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final assignedTo = _selectedAssignedEmpId;
    if (assignedTo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text('برجاء اختيار الموظف المسؤول عن المهمة'),
            ],
          ),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.user?.userId;

    final data = {
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'assignedTo': assignedTo,
      'assignedBy': userId,
      'priority': _selectedPriority,
      'dueDate': _selectedDueDate?.toIso8601String(),
      'customerId': widget.customerId,
      'leadId': widget.leadId,
      'notes': _notesController.text.trim(),
    };

    try {
      await ApiService.post('tasks', data);

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text('فشل حفظ المهمة: $e')),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }

    if (mounted) setState(() => _isSaving = false);
  }

  void _showSuccessDialog() {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF252836) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF10B981).withOpacity(0.2),
                        const Color(0xFF10B981).withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'تم بنجاح! ✅',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'تم إضافة المهمة وتعيينها للموظف المسؤول',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Container(
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
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'تم',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(isDark, isSmallScreen),
          SliverToBoxAdapter(
            child: _buildProgressIndicator(isDark, isSmallScreen),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (widget.customerName != null || widget.leadName != null)
                        _buildAnimatedCard(
                          index: 0,
                          child: _buildRelatedEntityCard(isDark, isSmallScreen),
                        ),
                      if (widget.customerName != null || widget.leadName != null)
                        SizedBox(height: isSmallScreen ? 12 : 16),
                      _buildAnimatedCard(
                        index: 1,
                        child: _buildTaskDataCard(isDark, isSmallScreen),
                      ),
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      _buildAnimatedCard(
                        index: 2,
                        child: _buildPriorityAndDateCard(isDark, isSmallScreen),
                      ),
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      _buildAnimatedCard(
                        index: 3,
                        child: _buildNotesCard(isDark, isSmallScreen),
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 24),
                      _buildSaveButton(isDark, isSmallScreen),
                      SizedBox(height: isSmallScreen ? 20 : 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(bool isDark, bool isSmallScreen) {
    return SliverAppBar(
      expandedHeight: isSmallScreen ? 120 : 180,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFFF59E0B),
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
          ),
          child: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: isSmallScreen ? 16 : 18,
          ),
        ),
        onPressed: () => _showExitConfirmation(isDark),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
            ),
            child: Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: isSmallScreen ? 18 : 20,
            ),
          ),
          onPressed: _resetForm,
        ),
        SizedBox(width: isSmallScreen ? 4 : 8),
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
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: isSmallScreen ? 150 : 200,
                  height: isSmallScreen ? 150 : 200,
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
                  width: isSmallScreen ? 70 : 100,
                  height: isSmallScreen ? 70 : 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: isSmallScreen ? 20 : 40,
                left: isSmallScreen ? 15 : 20,
                right: isSmallScreen ? 15 : 20,
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 15),
                      ),
                      child: Icon(
                        Icons.add_task_rounded,
                        color: Colors.white,
                        size: isSmallScreen ? 22 : 28,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 10 : 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "مهمة جديدة",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 18 : 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "أضف مهمة متابعة جديدة",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: isSmallScreen ? 11 : 14,
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

  Widget _buildProgressIndicator(bool isDark, bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.all(isSmallScreen ? 12 : 16),
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                    ),
                    child: Icon(
                      Icons.pie_chart_rounded,
                      color: const Color(0xFFF59E0B),
                      size: isSmallScreen ? 14 : 18,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 10),
                  Text(
                    "نسبة الاكتمال",
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 12,
                  vertical: isSmallScreen ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: _getProgressColor(_completionPercentage).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${(_completionPercentage * 100).toInt()}%",
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.bold,
                    color: _getProgressColor(_completionPercentage),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _completionPercentage,
              minHeight: isSmallScreen ? 6 : 8,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(_completionPercentage),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) return const Color(0xFFEF4444);
    if (progress < 0.6) return const Color(0xFFF59E0B);
    if (progress < 1) return const Color(0xFF3B82F6);
    return const Color(0xFF10B981);
  }

  Widget _buildAnimatedCard({required int index, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + (index * 150)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: child,
    );
  }

  Widget _buildRelatedEntityCard(bool isDark, bool isSmallScreen) {
    final isCustomer = widget.customerName != null;
    final name = isCustomer ? widget.customerName! : widget.leadName!;
    final color = isCustomer ? const Color(0xFF3B82F6) : const Color(0xFF8B5CF6);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
              ),
              child: Icon(
                isCustomer ? Icons.person_rounded : Icons.person_add_rounded,
                color: color,
                size: isSmallScreen ? 20 : 24,
              ),
            ),
            SizedBox(width: isSmallScreen ? 10 : 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCustomer ? "مهمة للعميل" : "مهمة للعميل المحتمل",
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 2 : 4),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 8 : 10,
                vertical: isSmallScreen ? 4 : 5,
              ),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isCustomer ? "عميل" : "Lead",
                style: TextStyle(
                  fontSize: isSmallScreen ? 9 : 11,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskDataCard(bool isDark, bool isSmallScreen) {
    return _buildCard(
      isDark: isDark,
      isSmallScreen: isSmallScreen,
      title: "بيانات المهمة",
      icon: Icons.task_alt_rounded,
      color: const Color(0xFFF59E0B),
      children: [
        _buildEmployeeDropdown(isDark, isSmallScreen),
        SizedBox(height: isSmallScreen ? 12 : 16),
        _buildTextField(
          controller: _titleController,
          label: "عنوان المهمة",
          icon: Icons.title_rounded,
          color: const Color(0xFFF59E0B),
          isDark: isDark,
          isSmallScreen: isSmallScreen,
          validator: (v) => v == null || v.isEmpty ? "مطلوب" : null,
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: isSmallScreen ? 10 : 14),
        _buildTextField(
          controller: _descController,
          label: "وصف المهمة (اختياري)",
          icon: Icons.description_rounded,
          color: const Color(0xFF8B5CF6),
          isDark: isDark,
          isSmallScreen: isSmallScreen,
          maxLines: 3,
        ),
      ],
    );
  }

  // ✅ قائمة منسدلة للموظفين
  Widget _buildEmployeeDropdown(bool isDark, bool isSmallScreen) {
    if (_isLoadingEmployees) {
      return Container(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
              ),
              child: SizedBox(
                width: isSmallScreen ? 16 : 20,
                height: isSmallScreen ? 16 : 20,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF6366F1),
                ),
              ),
            ),
            SizedBox(width: isSmallScreen ? 10 : 12),
            Text(
              "جاري تحميل الموظفين...",
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: isSmallScreen ? 12 : 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_employees.isEmpty) {
      return Container(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withOpacity(0.1),
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
          border: Border.all(
            color: const Color(0xFFEF4444).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: const Color(0xFFEF4444),
                size: isSmallScreen ? 16 : 20,
              ),
            ),
            SizedBox(width: isSmallScreen ? 10 : 12),
            Expanded(
              child: Text(
                "لا توجد موظفين متاحين",
                style: TextStyle(
                  color: Colors.red[400],
                  fontWeight: FontWeight.w500,
                  fontSize: isSmallScreen ? 12 : 14,
                ),
              ),
            ),
            GestureDetector(
              onTap: _loadEmployees,
              child: Icon(
                Icons.refresh_rounded,
                color: const Color(0xFFEF4444),
                size: isSmallScreen ? 18 : 20,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
              ),
              child: Icon(
                Icons.person_search_rounded,
                color: const Color(0xFF6366F1),
                size: isSmallScreen ? 14 : 18,
              ),
            ),
            SizedBox(width: isSmallScreen ? 8 : 10),
            Text(
              "تعيين المهمة إلى",
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(width: isSmallScreen ? 4 : 6),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 6 : 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
              ),
              child: Text(
                "مطلوب",
                style: TextStyle(
                  fontSize: isSmallScreen ? 8 : 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 10 : 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
            border: Border.all(
              color: _selectedAssignedEmpId != null
                  ? const Color(0xFF6366F1)
                  : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
              width: _selectedAssignedEmpId != null ? 2 : 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedAssignedEmpId,
              isExpanded: true,
              hint: Padding(
                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      color: Colors.grey[500],
                      size: isSmallScreen ? 18 : 22,
                    ),
                    SizedBox(width: isSmallScreen ? 10 : 12),
                    Text(
                      "اختر الموظف المسؤول",
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: isSmallScreen ? 13 : 15,
                      ),
                    ),
                  ],
                ),
              ),
              icon: Padding(
                padding: EdgeInsets.only(left: isSmallScreen ? 8 : 12),
                child: Container(
                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                  ),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF6366F1),
                    size: isSmallScreen ? 18 : 22,
                  ),
                ),
              ),
              dropdownColor: isDark ? const Color(0xFF252836) : Colors.white,
              borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 4 : 8),
              items: _employees.map((emp) {
                final isSelected = _selectedAssignedEmpId == emp['id'];
                return DropdownMenuItem<int>(
                  value: emp['id'] as int,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 8 : 12,
                      vertical: isSmallScreen ? 6 : 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6366F1).withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                  )
                                : null,
                            color: isSelected
                                ? null
                                : const Color(0xFF6366F1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                          ),
                          child: Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.person_outline_rounded,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF6366F1),
                            size: isSmallScreen ? 16 : 20,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 10 : 12),
                        Expanded(
                          child: Text(
                            emp['name'] as String,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 13 : 15,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFF6366F1)
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_rounded,
                            color: const Color(0xFF6366F1),
                            size: isSmallScreen ? 16 : 20,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedAssignedEmpId = value);
              },
              selectedItemBuilder: (context) {
                return _employees.map((emp) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            ),
                            borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: isSmallScreen ? 14 : 18,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 10 : 12),
                        Expanded(
                          child: Text(
                            emp['name'] as String,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 13 : 15,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityAndDateCard(bool isDark, bool isSmallScreen) {
    return _buildCard(
      isDark: isDark,
      isSmallScreen: isSmallScreen,
      title: "الأولوية والموعد",
      icon: Icons.schedule_rounded,
      color: const Color(0xFFEF4444),
      children: [
        _buildPrioritySelector(isDark, isSmallScreen),
        SizedBox(height: isSmallScreen ? 12 : 16),
        _buildDatePicker(isDark, isSmallScreen),
      ],
    );
  }

  Widget _buildPrioritySelector(bool isDark, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
              ),
              child: Icon(
                Icons.flag_rounded,
                color: const Color(0xFFEF4444),
                size: isSmallScreen ? 14 : 18,
              ),
            ),
            SizedBox(width: isSmallScreen ? 8 : 10),
            Text(
              "أولوية المهمة",
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 10 : 12),
        Row(
          children: [
            _buildPriorityChip(
              label: "عالية",
              value: "High",
              icon: Icons.keyboard_double_arrow_up_rounded,
              color: const Color(0xFFEF4444),
              isDark: isDark,
              isSmallScreen: isSmallScreen,
            ),
            SizedBox(width: isSmallScreen ? 8 : 10),
            _buildPriorityChip(
              label: "متوسطة",
              value: "Medium",
              icon: Icons.remove_rounded,
              color: const Color(0xFFF59E0B),
              isDark: isDark,
              isSmallScreen: isSmallScreen,
            ),
            SizedBox(width: isSmallScreen ? 8 : 10),
            _buildPriorityChip(
              label: "منخفضة",
              value: "Low",
              icon: Icons.keyboard_double_arrow_down_rounded,
              color: const Color(0xFF10B981),
              isDark: isDark,
              isSmallScreen: isSmallScreen,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriorityChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
    required bool isSmallScreen,
  }) {
    final isSelected = _selectedPriority == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedPriority = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(colors: [color, color.withOpacity(0.8)])
                : null,
            color: isSelected ? null : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
            border: Border.all(
              color: isSelected ? color : color.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: isSmallScreen ? 16 : 20,
                color: isSelected ? Colors.white : color,
              ),
              SizedBox(height: isSmallScreen ? 2 : 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(bool isDark, bool isSmallScreen) {
    return GestureDetector(
      onTap: _pickDueDate,
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
          border: Border.all(
            color: _selectedDueDate != null
                ? const Color(0xFFF59E0B)
                : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
            width: _selectedDueDate != null ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
              ),
              child: Icon(
                Icons.event_rounded,
                color: const Color(0xFFF59E0B),
                size: isSmallScreen ? 16 : 20,
              ),
            ),
            SizedBox(width: isSmallScreen ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "تاريخ الاستحقاق",
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 2 : 4),
                  Text(
                    _selectedDueDate != null
                        ? DateFormat('EEEE, d MMMM yyyy', 'ar').format(_selectedDueDate!)
                        : "اختر التاريخ (اختياري)",
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      fontWeight: _selectedDueDate != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: _selectedDueDate != null
                          ? (isDark ? Colors.white : Colors.black87)
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedDueDate != null)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDueDate = null;
                    _dueDateController.clear();
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: isSmallScreen ? 14 : 16,
                    color: Colors.grey[500],
                  ),
                ),
              )
            else
              Icon(
                Icons.calendar_today_rounded,
                size: isSmallScreen ? 16 : 18,
                color: Colors.grey[500],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(bool isDark, bool isSmallScreen) {
    return _buildCard(
      isDark: isDark,
      isSmallScreen: isSmallScreen,
      title: "ملاحظات إضافية",
      icon: Icons.note_alt_rounded,
      color: const Color(0xFF8B5CF6),
      children: [
        _buildTextField(
          controller: _notesController,
          label: "أضف ملاحظات للمهمة (اختياري)",
          icon: Icons.edit_note_rounded,
          color: const Color(0xFF8B5CF6),
          isDark: isDark,
          isSmallScreen: isSmallScreen,
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildCard({
    required bool isDark,
    required bool isSmallScreen,
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: isSmallScreen ? 4 : 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [color, color.withOpacity(0.5)],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                        ),
                        child: Icon(
                          icon,
                          color: color,
                          size: isSmallScreen ? 18 : 22,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 10 : 12),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 14 : 18),
                  ...children,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    required bool isDark,
    required bool isSmallScreen,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: isSmallScreen ? 13 : 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[500],
          fontSize: isSmallScreen ? 12 : 14,
        ),
        prefixIcon: Container(
          margin: EdgeInsets.all(isSmallScreen ? 6 : 8),
          padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
          ),
          child: Icon(
            icon,
            color: color,
            size: isSmallScreen ? 16 : 20,
          ),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
          borderSide: BorderSide(color: color, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16,
          vertical: isSmallScreen ? 12 : 16,
        ),
      ),
    );
  }

  Widget _buildSaveButton(bool isDark, bool isSmallScreen) {
    return SizedBox(
      width: double.infinity,
      height: isSmallScreen ? 48 : 58,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
          gradient: LinearGradient(
            colors: _isSaving
                ? [Colors.grey, Colors.grey]
                : [const Color(0xFFF59E0B), const Color(0xFFF97316)],
          ),
          boxShadow: _isSaving
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
            ),
          ),
          child: _isSaving
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: isSmallScreen ? 20 : 24,
                      height: isSmallScreen ? 20 : 24,
                      child: CircularProgressIndicator(
                        color: Colors.white.withOpacity(0.8),
                        strokeWidth: 2.5,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 10 : 12),
                    Text(
                      "جاري الحفظ...",
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                      ),
                      child: Icon(
                        Icons.add_task_rounded,
                        color: Colors.white,
                        size: isSmallScreen ? 18 : 22,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 10 : 12),
                    Text(
                      "إضافة المهمة",
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _resetForm() {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDark;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF252836) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  color: Color(0xFFF59E0B),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'إعادة تعيين',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          content: Text(
            'هل تريد مسح جميع البيانات المدخلة؟',
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
                  colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
                ),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _titleController.clear();
                    _descController.clear();
                    _notesController.clear();
                    _dueDateController.clear();
                    _selectedPriority = 'Medium';
                    _selectedDueDate = null;
                    if (_currentEmpId != null &&
                        _employees.any((emp) => emp['id'] == _currentEmpId)) {
                      _selectedAssignedEmpId = _currentEmpId;
                    } else {
                      _selectedAssignedEmpId = null;
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'مسح الكل',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showExitConfirmation(bool isDark) {
    if (_titleController.text.isEmpty &&
        _descController.text.isEmpty &&
        _notesController.text.isEmpty) {
      Navigator.pop(context);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF252836) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.exit_to_app_rounded,
                  color: Color(0xFFEF4444),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'تجاهل التغييرات؟',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          content: Text(
            'لديك بيانات غير محفوظة. هل تريد الخروج بدون حفظ؟',
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'البقاء',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                ),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'خروج',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}