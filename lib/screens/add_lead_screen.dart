import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';

class AddLeadScreen extends StatefulWidget {
  const AddLeadScreen({super.key});

  @override
  State<AddLeadScreen> createState() => _AddLeadScreenState();
}

class _AddLeadScreenState extends State<AddLeadScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _childAgeController = TextEditingController();
  final _notesController = TextEditingController();
  final _nextFollowUpController = TextEditingController();

  String? _selectedSource;
  int? _selectedSourceId;
  String? _selectedProgram;
  int? _selectedBranchId;
  int? _selectedAssignedTo;
  DateTime? _selectedNextFollowUp;

  bool _isSaving = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<Map<String, dynamic>> _sources = [];
  bool _isLoadingSources = false;

  List<Map<String, dynamic>> _employees = [];
  bool _isLoadingEmployees = false;

  final List<String> _programs = [
    'Baby Class',
    'KG1',
    'KG2',
    'Nursery Morning',
    'After School',
    'Summer Camp',
    'Winter Camp',
    'Courses',
    'رحلات',
  ];

  List<Map<String, dynamic>> _branches = [];
  bool _isLoadingBranches = false;
  bool _branchesLoadError = false;

  double get _completionPercentage {
    int filled = 0;
    int total = 7;
    if (_nameController.text.isNotEmpty) filled++;
    if (_phoneController.text.isNotEmpty) filled++;
    if (_selectedSource != null) filled++;
    if (_selectedProgram != null) filled++;
    if (_selectedBranchId != null) filled++;
    if (_selectedAssignedTo != null) filled++;
    if (_selectedNextFollowUp != null) filled++;
    return filled / total;
  }

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _loadBranches();
    _loadSources();
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

  Future<void> _loadSources() async {
    setState(() => _isLoadingSources = true);
    try {
      final data = await ApiService.get('lead-sources');
      if (mounted && data is List) {
        setState(() {
          _sources = data.map<Map<String, dynamic>>((s) => {
            'id': s['SourceID'],
            'name': s['SourceName'],
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading sources: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSources = false);
    }
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoadingEmployees = true);
    try {
      final data = await ApiService.get('employees');
      if (mounted && data is List) {
        setState(() {
          _employees = data.map<Map<String, dynamic>>((e) => {
            'id': e['ID'],
            'name': e['empName'] ?? '${e['FirstName'] ?? ''} ${e['LastName'] ?? ''}',
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading employees: $e');
    } finally {
      if (mounted) setState(() => _isLoadingEmployees = false);
    }
  }

  Future<void> _loadBranches() async {
    setState(() {
      _isLoadingBranches = true;
      _branchesLoadError = false;
    });
    try {
      final data = await ApiService.get('general/branches');
      if (mounted && data is List) {
        _branches = data.map<Map<String, dynamic>>((b) => {
          'id': b['IDbranch'],
          'name': b['branchName'],
        }).toList();
      }
    } catch (e) {
      if (mounted) _branchesLoadError = true;
    } finally {
      if (mounted) {
        _isLoadingBranches = false;
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _childAgeController.dispose();
    _notesController.dispose();
    _nextFollowUpController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickNextFollowUpDate() async {
    final now = DateTime.now();
    final initial = _selectedNextFollowUp ?? now.add(const Duration(days: 1));
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      builder: (ctx, child) {
        final isDark = Provider.of<ThemeProvider>(ctx, listen: false).isDark;
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(primary: Color(0xFF6366F1), surface: Color(0xFF252836))
                : const ColorScheme.light(primary: Color(0xFF6366F1)),
            dialogBackgroundColor: isDark ? const Color(0xFF252836) : Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      _selectedNextFollowUp = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, 10);
      _nextFollowUpController.text = DateFormat('yyyy/MM/dd').format(_selectedNextFollowUp!);
      setState(() {});
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final int? childAge = int.tryParse(_childAgeController.text.trim());
    final String email = _emailController.text.trim();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userAdd = authProvider.user?.fullName ?? 'Unknown User';
    //final clientTime = DateTime.now().toIso8601String();
    final clientTime = DateTime.now().toString();

    final data = {
      'fullName': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': email.isEmpty ? null : email,
      'childAge': childAge,
      'source': _selectedSource ?? 'Direct',
      'sourceId': _selectedSourceId,
      'interestedProgram': _selectedProgram,
      'branchId': _selectedBranchId,
      'assignedTo': _selectedAssignedTo,
      'nextFollowUp': _selectedNextFollowUp?.toIso8601String(),
      'notes': _notesController.text.trim(),
      'userAdd': userAdd,
      'clientTime': clientTime,
    };

    try {
      await ApiService.post('leads', data);
      if (mounted) _showSuccessDialog();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text('فشل الحفظ: $e')),
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final isDark = Provider.of<ThemeProvider>(ctx, listen: false).isDark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF252836) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 60),
              ),
              const SizedBox(height: 20),
              Text('تم بنجاح! 🎯', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 10),
              Text('تم تسجيل العميل المحتمل بنجاح', style: TextStyle(fontSize: 14, color: Colors.grey[500]), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('تم', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required Color color,
    required bool isDark,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    bool isLoading = false,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        );
      }).toList(),
      onChanged: onChanged,
      icon: isLoading 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[500]),
      dropdownColor: isDark ? const Color(0xFF252836) : Colors.white,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[500]),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildSourceDropdown(bool isDark) {
  if (_isLoadingSources) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Row(
        children: [
          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 12),
          Text("جاري تحميل المصادر...", style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  return DropdownButtonFormField<int>(
    value: _selectedSourceId,
    items: _sources.map((source) => DropdownMenuItem<int>(
      value: source['id'],
      child: Text(source['name'], style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
    )).toList(),
    onChanged: (sourceId) {
      setState(() {
        _selectedSourceId = sourceId;
        _selectedSource = _sources.firstWhere((s) => s['id'] == sourceId, orElse: () => {'name': 'Direct'})['name'];
      });
    },
    decoration: InputDecoration(
      labelText: "مصدر المعرفة",
      labelStyle: TextStyle(color: Colors.grey[500]),
      prefixIcon: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.campaign_rounded, color: Color(0xFF3B82F6), size: 20),
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    dropdownColor: isDark ? const Color(0xFF252836) : Colors.white,
    icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[500]),
  );
}

  Widget _buildEmployeeDropdown(bool isDark) {
  if (_isLoadingEmployees) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Row(
        children: [
          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 12),
          Expanded( // ✅ أضف Expanded هنا
            child: Text(
              "جاري تحميل الموظفين...",
              style: TextStyle(color: Colors.grey[500]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  return DropdownButtonFormField<int>(
    value: _selectedAssignedTo,
    items: _employees.map((emp) => DropdownMenuItem<int>(
      value: emp['id'],
      child: Container( // ✅ لف الـ Text في Container
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.5), // ✅ حدد عرض أقصى
        child: Text(
          emp['name'],
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          overflow: TextOverflow.ellipsis, // ✅ أضف overflow
          maxLines: 1, // ✅ سطر واحد بس
        ),
      ),
    )).toList(),
    onChanged: (val) => setState(() => _selectedAssignedTo = val),
    isExpanded: true, // ✅ أضف دي مهمة جداً
    decoration: InputDecoration(
      labelText: "الموظف المسؤول",
      labelStyle: TextStyle(color: Colors.grey[500]),
      prefixIcon: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF8B5CF6).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.person_rounded, color: Color(0xFF8B5CF6), size: 20),
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    dropdownColor: isDark ? const Color(0xFF252836) : Colors.white,
    icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[500]),
  );
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
          SliverToBoxAdapter(child: _buildProgressIndicator(isDark)),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildAnimatedCard(
                        index: 0,
                        child: _buildCard(
                          isDark: isDark,
                          title: "البيانات الأساسية",
                          icon: Icons.person_add_rounded,
                          color: const Color(0xFF6366F1),
                          children: [
                            _buildTextField(
                              controller: _nameController,
                              label: "اسم ولي الأمر",
                              icon: Icons.person_rounded,
                              color: const Color(0xFF6366F1),
                              isDark: isDark,
                              validator: (v) => v == null || v.isEmpty ? "مطلوب" : null,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 14),
                            _buildTextField(
                              controller: _phoneController,
                              label: "رقم الموبايل",
                              icon: Icons.phone_rounded,
                              color: const Color(0xFF10B981),
                              isDark: isDark,
                              keyboardType: TextInputType.phone,
                              validator: (v) => v == null || v.isEmpty ? "مطلوب" : null,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 14),
                            _buildTextField(
                              controller: _emailController,
                              label: "البريد الإلكتروني (اختياري)",
                              icon: Icons.email_rounded,
                              color: const Color(0xFF3B82F6),
                              isDark: isDark,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 14),
                            _buildTextField(
                              controller: _childAgeController,
                              label: "سن الطفل (بالسنوات)",
                              icon: Icons.cake_rounded,
                              color: const Color(0xFFF59E0B),
                              isDark: isDark,
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildAnimatedCard(
                        index: 1,
                        child: _buildCard(
                          isDark: isDark,
                          title: "الاهتمام والمتابعة",
                          icon: Icons.trending_up_rounded,
                          color: const Color(0xFFF59E0B),
                          children: [
                            _buildSourceDropdown(isDark),
                            const SizedBox(height: 14),
                            _buildDropdown(
                              label: "البرنامج المهتم به",
                              icon: Icons.school_rounded,
                              color: const Color(0xFF10B981),
                              isDark: isDark,
                              value: _selectedProgram,
                              items: _programs,
                              onChanged: (val) => setState(() => _selectedProgram = val),
                            ),
                            const SizedBox(height: 14),
                            _buildBranchDropdown(isDark),
                            const SizedBox(height: 14),
                            _buildEmployeeDropdown(isDark),
                            const SizedBox(height: 14),
                            _buildDatePicker(isDark),
                            const SizedBox(height: 14),
                            _buildTextField(
                              controller: _notesController,
                              label: "ملاحظات إضافية",
                              icon: Icons.note_alt_rounded,
                              color: const Color(0xFF8B5CF6),
                              isDark: isDark,
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSaveButton(isDark),
                      const SizedBox(height: 30),
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
                          child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 15),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("عميل محتمل جديد", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                            Text("أضف بيانات العميل المحتمل", style: TextStyle(color: Colors.white70, fontSize: 14)),
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
    );
  }

  Widget _buildProgressIndicator(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.1),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.pie_chart_rounded, color: Color(0xFF6366F1), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text("نسبة الاكتمال", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getProgressColor(_completionPercentage).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text("${(_completionPercentage * 100).toInt()}%", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _getProgressColor(_completionPercentage))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _completionPercentage,
              minHeight: 8,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(_completionPercentage)),
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
      duration: Duration(milliseconds: 500 + (index * 200)),
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

  Widget _buildCard({
    required bool isDark,
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
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
                    colors: [color, color.withOpacity(0.5)],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 18),
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
      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[500]),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildBranchDropdown(bool isDark) {
    if (_isLoadingBranches) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        ),
        child: Row(
          children: [
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 12),
            Text("جاري تحميل الفروع...", style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    if (_branchesLoadError) {
      return GestureDetector(
        onTap: _loadBranches,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text("فشل تحميل الفروع", style: TextStyle(color: Colors.red[400]))),
              const Icon(Icons.refresh_rounded, color: Color(0xFFEF4444), size: 20),
            ],
          ),
        ),
      );
    }

    return DropdownButtonFormField<int>(
      value: _selectedBranchId,
      items: _branches.map((b) => DropdownMenuItem<int>(
        value: b['id'] as int,
        child: Text(b['name'] as String, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
      )).toList(),
      onChanged: (val) => setState(() => _selectedBranchId = val),
      decoration: InputDecoration(
        labelText: "الفرع المفضّل",
        labelStyle: TextStyle(color: Colors.grey[500]),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF97316).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.location_on_rounded, color: Color(0xFFF97316), size: 20),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFF97316), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      dropdownColor: isDark ? const Color(0xFF252836) : Colors.white,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[500]),
    );
  }

  Widget _buildDatePicker(bool isDark) {
    return GestureDetector(
      onTap: _pickNextFollowUpDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _selectedNextFollowUp != null
                ? const Color(0xFF6366F1)
                : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
            width: _selectedNextFollowUp != null ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.event_note_rounded, color: Color(0xFF6366F1), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("ميعاد المتابعة الجاية", style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  const SizedBox(height: 4),
                  Text(
                    _selectedNextFollowUp != null
                        ? DateFormat('EEEE, d MMMM yyyy', 'ar').format(_selectedNextFollowUp!)
                        : "اختر التاريخ (اختياري)",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: _selectedNextFollowUp != null ? FontWeight.w600 : FontWeight.normal,
                      color: _selectedNextFollowUp != null ? (isDark ? Colors.white : Colors.black87) : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedNextFollowUp != null)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedNextFollowUp = null;
                    _nextFollowUpController.clear();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(Icons.close_rounded, size: 16, color: Colors.grey[500]),
                ),
              )
            else
              Icon(Icons.calendar_today_rounded, size: 18, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: _isSaving ? [Colors.grey, Colors.grey] : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
          ),
          boxShadow: _isSaving ? [] : [
            BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _isSaving
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white.withOpacity(0.8), strokeWidth: 2.5)),
                    const SizedBox(width: 12),
                    const Text("جاري الحفظ...", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text("حفظ العميل المحتمل", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
        ),
      ),
    );
  }
}