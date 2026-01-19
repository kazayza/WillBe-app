import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/employees_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';

class EmployeeFormScreen extends StatefulWidget {
  final int? empId;

  const EmployeeFormScreen({super.key, this.empId});

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers - Personal
  final _nameController = TextEditingController();
  final _nidController = TextEditingController();
  final _mobile1Controller = TextEditingController();
  final _mobile2Controller = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  // Controllers - Job
  final _jobController = TextEditingController();
  final _jobDateController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _salaryController = TextEditingController();

  // Tracking Info
  String _addedBy = "---";
  String _addedTime = "---";
  String _editedBy = "---";
  String _editedTime = "---";

  // Selections
  int? _selectedBranch;
  int? _selectedMgmt;
  int? _selectedWorkerType;
  bool _isActive = true;

  List<dynamic> _managements = [];
  bool _isLoading = false;
  bool _isSaving = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  int _expandedSection = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _jobDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _initData();
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

  void _initData() async {
    final provider = Provider.of<EmployeesProvider>(context, listen: false);
    setState(() => _isLoading = true);

    await provider.fetchLookups();
    try {
      final mgmts = await ApiService.get('general/managements');
      if (mounted) setState(() => _managements = mgmts);
    } catch (e) {}

    if (widget.empId != null) {
      final data = await provider.fetchEmployeeById(widget.empId!);

      if (data != null && mounted) {
        setState(() {
          _nameController.text = data['empName'] ?? '';
          _nidController.text = data['nationalID']?.toString() ?? '';
          _mobile1Controller.text = data['mobile1'] ?? '';
          _mobile2Controller.text = data['mobile2'] ?? '';
          _emailController.text = data['email'] ?? '';
          _addressController.text = data['adress'] ?? '';
          _notesController.text = data['notes'] ?? '';

          _jobController.text = data['job'] ?? '';
          _jobDateController.text = data['jobdate'] != null
              ? data['jobdate'].toString().split('T')[0]
              : '';
          _qualificationController.text = data['Qualification'] ?? '';
          _experienceController.text = data['Experience'] ?? '';

          _isActive = data['empstatus'] == true || data['empstatus'] == 1;

          _selectedBranch = data['BranchID'];
          _selectedMgmt = data['empIDmangment'];
          _selectedWorkerType = data['EmpType'];

          _addedBy = data['userAdd'] ?? '---';
          _addedTime = data['Addtime'] != null
              ? data['Addtime'].toString().split('T')[0]
              : '---';
          _editedBy = data['useredit'] ?? '---';
          _editedTime = data['editTime'] != null
              ? data['editTime'].toString().split('T')[0]
              : '---';

          _fetchSalary();
        });
      }
    }
    setState(() => _isLoading = false);
  }

  void _fetchSalary() async {
    try {
      final history = await ApiService.get('employees/${widget.empId}/salary');
      if (history is List && history.isNotEmpty) {
        _salaryController.text = history[0]['BaseSalary'].toString();
      }
    } catch (e) {}
  }

  Future<void> _pickDate() async {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDark;

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF3B82F6),
              onPrimary: Colors.white,
              surface: isDark ? const Color(0xFF252836) : Colors.white,
              onSurface: isDark ? Colors.white : Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _jobDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBranch == null ||
        _selectedMgmt == null ||
        _selectedWorkerType == null) {
      _showErrorSnackBar('أكمل بيانات الفرع والإدارة والنوع');
      return;
    }

    setState(() => _isSaving = true);

    final currentUser =
        Provider.of<AuthProvider>(context, listen: false).user?.fullName ??
            "System";

    final Map<String, dynamic> data = {
      'empName': _nameController.text,
      'nationalID': _nidController.text,
      'mobile1': _mobile1Controller.text,
      'mobile2': _mobile2Controller.text,
      'email': _emailController.text,
      'adress': _addressController.text,
      'notes': _notesController.text,
      'empstatus': _isActive,
      'job': _jobController.text,
      'jobdate': _jobDateController.text,
      'Qualification': _qualificationController.text,
      'Experience': _experienceController.text,
      'branchId': _selectedBranch,
      'mgmtId': _selectedMgmt,
      'workTypeId': _selectedWorkerType,
    };

    bool success;
    if (widget.empId != null) {
      data['userEdit'] = currentUser;
      success = await Provider.of<EmployeesProvider>(context, listen: false)
          .updateEmployee(widget.empId!, data);
    } else {
      data['userAdd'] = currentUser;
      data['baseSalary'] = double.tryParse(_salaryController.text) ?? 0;
      success = await Provider.of<EmployeesProvider>(context, listen: false)
          .addEmployee(data);
    }

    setState(() => _isSaving = false);

    if (success && mounted) {
      _showSuccessSnackBar(
          widget.empId != null ? 'تم التعديل بنجاح ✅' : 'تمت الإضافة بنجاح ✅');
      Navigator.pop(context);
    } else if (mounted) {
      _showErrorSnackBar('فشل الحفظ ❌');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Text(message),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
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

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _nidController.dispose();
    _mobile1Controller.dispose();
    _mobile2Controller.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _jobController.dispose();
    _jobDateController.dispose();
    _qualificationController.dispose();
    _experienceController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EmployeesProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;
    final isEdit = widget.empId != null;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 🎨 App Bar
                _buildSliverAppBar(isDark, isEdit),

                // 📝 Form Content
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Progress Indicator
                            _buildProgressIndicator(isDark, isEdit),
                            const SizedBox(height: 20),

                            // Section 1: البيانات الشخصية
                            _buildAnimatedCard(
                              index: 0,
                              isDark: isDark,
                              title: "البيانات الشخصية",
                              subtitle: "الاسم والرقم القومي والتواصل",
                              icon: Icons.person_rounded,
                              color: const Color(0xFF3B82F6),
                              children: _buildPersonalSection(isDark),
                            ),

                            const SizedBox(height: 16),

                            // Section 2: البيانات الوظيفية
                            _buildAnimatedCard(
                              index: 1,
                              isDark: isDark,
                              title: "البيانات الوظيفية",
                              subtitle: "الوظيفة والمؤهل والخبرة",
                              icon: Icons.work_rounded,
                              color: const Color(0xFFF59E0B),
                              children:
                                  _buildJobSection(isDark, isEdit),
                            ),

                            const SizedBox(height: 16),

                            // Section 3: التسكين الإداري
                            _buildAnimatedCard(
                              index: 2,
                              isDark: isDark,
                              title: "التسكين الإداري",
                              subtitle: "الفرع والإدارة ونوع العمالة",
                              icon: Icons.apartment_rounded,
                              color: const Color(0xFF8B5CF6),
                              children:
                                  _buildAdminSection(provider, isDark),
                            ),

                            // Section 4: سجل المتابعة (Edit Only)
                            if (isEdit) ...[
                              const SizedBox(height: 16),
                              _buildAnimatedCard(
                                index: 3,
                                isDark: isDark,
                                title: "سجل المتابعة",
                                subtitle: "بيانات الإضافة والتعديل",
                                icon: Icons.history_rounded,
                                color: const Color(0xFF6B7280),
                                children: _buildTrackingSection(isDark),
                              ),
                            ],

                            const SizedBox(height: 30),

                            // Save Button
                            _buildSaveButton(isEdit),

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

  // 🎨 Sliver App Bar
  Widget _buildSliverAppBar(bool isDark, bool isEdit) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF3B82F6),
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
        if (isEdit)
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
            onPressed: () {
              setState(() => _isLoading = true);
              _initData();
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
              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
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
                bottom: 40,
                left: 20,
                right: 20,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        isEdit
                            ? Icons.edit_rounded
                            : Icons.person_add_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isEdit ? "تعديل بيانات الموظف" : "إضافة موظف جديد",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isEdit
                                ? "قم بتحديث البيانات المطلوبة"
                                : "أدخل بيانات الموظف الجديد",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
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

  // 📊 Progress Indicator
  Widget _buildProgressIndicator(bool isDark, bool isEdit) {
    final totalSteps = isEdit ? 4 : 3;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.checklist_rounded,
                  color: Color(0xFF3B82F6), size: 20),
              const SizedBox(width: 8),
              Text(
                "خطوات الإدخال",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${_expandedSection + 1}/$totalSteps",
                  style: const TextStyle(
                    color: Color(0xFF3B82F6),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildProgressStep(0, "شخصية", isDark),
              _buildProgressLine(0, isDark),
              _buildProgressStep(1, "وظيفية", isDark),
              _buildProgressLine(1, isDark),
              _buildProgressStep(2, "إدارية", isDark),
              if (isEdit) ...[
                _buildProgressLine(2, isDark),
                _buildProgressStep(3, "متابعة", isDark),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int index, String label, bool isDark) {
    final isActive = _expandedSection >= index;
    final isCurrent = _expandedSection == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _expandedSection = index),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isCurrent ? 35 : 28,
              height: isCurrent ? 35 : 28,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF3B82F6)
                    : (isDark ? Colors.grey[700] : Colors.grey[300]),
                shape: BoxShape.circle,
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: isActive
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : Text(
                        "${index + 1}",
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive
                    ? const Color(0xFF3B82F6)
                    : (isDark ? Colors.grey[500] : Colors.grey[600]),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressLine(int index, bool isDark) {
    final isActive = _expandedSection > index;

    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF3B82F6)
              : (isDark ? Colors.grey[700] : Colors.grey[300]),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // 🎴 Animated Card
  Widget _buildAnimatedCard({
    required int index,
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    final isExpanded = _expandedSection == index;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GestureDetector(
        onTap: () => setState(() => _expandedSection = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252836) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isExpanded ? color : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isExpanded
                    ? color.withOpacity(0.2)
                    : Colors.black.withOpacity(0.05),
                blurRadius: isExpanded ? 20 : 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 14),
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
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: color,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  children: [
                    Divider(
                      height: 1,
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: children),
                    ),
                  ],
                ),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 📝 Section 1: البيانات الشخصية
  List<Widget> _buildPersonalSection(bool isDark) {
    return [
      _buildModernTextField(
        controller: _nameController,
        label: "الاسم رباعي",
        icon: Icons.person_rounded,
        isDark: isDark,
        validator: (v) => v!.isEmpty ? "مطلوب" : null,
      ),
      const SizedBox(height: 14),
      _buildModernTextField(
        controller: _nidController,
        label: "الرقم القومي",
        icon: Icons.badge_rounded,
        isDark: isDark,
        keyboardType: TextInputType.number,
        maxLength: 14,
        validator: (v) => v!.isEmpty ? "مطلوب" : null,
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: _buildModernTextField(
              controller: _mobile1Controller,
              label: "موبايل 1",
              icon: Icons.phone_rounded,
              isDark: isDark,
              keyboardType: TextInputType.phone,
              maxLength: 11,
              validator: (v) => v!.isEmpty ? "مطلوب" : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildModernTextField(
              controller: _mobile2Controller,
              label: "موبايل 2",
              icon: Icons.phone_android_rounded,
              isDark: isDark,
              keyboardType: TextInputType.phone,
              maxLength: 11,
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      _buildModernTextField(
        controller: _emailController,
        label: "البريد الإلكتروني",
        icon: Icons.email_rounded,
        isDark: isDark,
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: 14),
      _buildModernTextField(
        controller: _addressController,
        label: "العنوان",
        icon: Icons.home_rounded,
        isDark: isDark,
      ),
      const SizedBox(height: 14),
      _buildModernTextField(
        controller: _notesController,
        label: "ملاحظات",
        icon: Icons.note_alt_rounded,
        isDark: isDark,
        maxLines: 3,
      ),
    ];
  }

  // 💼 Section 2: البيانات الوظيفية
  List<Widget> _buildJobSection(bool isDark, bool isEdit) {
    return [
      _buildModernTextField(
        controller: _jobController,
        label: "المسمى الوظيفي",
        icon: Icons.work_rounded,
        isDark: isDark,
        validator: (v) => v!.isEmpty ? "مطلوب" : null,
        color: const Color(0xFFF59E0B),
      ),
      const SizedBox(height: 14),
      _buildModernTextField(
        controller: _jobDateController,
        label: "تاريخ التعيين",
        icon: Icons.calendar_today_rounded,
        isDark: isDark,
        readOnly: true,
        onTap: _pickDate,
        color: const Color(0xFFF59E0B),
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: _buildModernTextField(
              controller: _qualificationController,
              label: "المؤهل",
              icon: Icons.school_rounded,
              isDark: isDark,
              color: const Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildModernTextField(
              controller: _experienceController,
              label: "سنوات الخبرة",
              icon: Icons.timeline_rounded,
              isDark: isDark,
              color: const Color(0xFFF59E0B),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      _buildModernTextField(
        controller: _salaryController,
        label: "الراتب الأساسي",
        icon: Icons.attach_money_rounded,
        isDark: isDark,
        keyboardType: TextInputType.number,
        readOnly: isEdit,
        color: const Color(0xFF10B981),
        suffixWidget: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            "ج.م",
            style: TextStyle(
              color: Color(0xFF10B981),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    ];
  }

  // 🏢 Section 3: التسكين الإداري
  List<Widget> _buildAdminSection(EmployeesProvider provider, bool isDark) {
    return [
      // Status Switch
      _buildModernSwitch(
        label: "حالة الموظف",
        subtitle: _isActive ? "نشط - يظهر في القوائم" : "غير نشط",
        icon: Icons.toggle_on_rounded,
        value: _isActive,
        onChanged: (v) => setState(() => _isActive = v),
        isDark: isDark,
        activeColor: const Color(0xFF10B981),
        inactiveColor: const Color(0xFFEF4444),
      ),

      const SizedBox(height: 20),

      // Branch Dropdown
      _buildSectionLabel(
          "الفرع", Icons.store_rounded, const Color(0xFF8B5CF6), isDark),
      const SizedBox(height: 10),
      provider.branches.isNotEmpty
          ? _buildModernDropdown(
              value: _selectedBranch,
              hint: "اختر الفرع",
              isDark: isDark,
              items: provider.branches
                  .map((b) => DropdownMenuItem<int>(
                        value: b['IDbranch'],
                        child: Text(b['branchName'] ?? '---'),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedBranch = val),
              validator: (v) => v == null ? "مطلوب" : null,
              color: const Color(0xFF8B5CF6),
            )
          : _buildLoadingDropdown("جاري تحميل الفروع..."),

      const SizedBox(height: 16),

      // Management Dropdown
      _buildSectionLabel(
          "الإدارة", Icons.account_tree_rounded, const Color(0xFF06B6D4), isDark),
      const SizedBox(height: 10),
      _managements.isNotEmpty
          ? _buildModernDropdown(
              value: _selectedMgmt,
              hint: "اختر الإدارة",
              isDark: isDark,
              items: _managements
                  .map((m) => DropdownMenuItem<int>(
                        value: m['managementID'],
                        child: Text(m['ManagmentName'] ?? '---'),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedMgmt = val),
              validator: (v) => v == null ? "مطلوب" : null,
              color: const Color(0xFF06B6D4),
            )
          : _buildLoadingDropdown("جاري تحميل الإدارات..."),

      const SizedBox(height: 16),

      // Worker Type Dropdown
      _buildSectionLabel(
          "نوع العمالة", Icons.category_rounded, const Color(0xFFEC4899), isDark),
      const SizedBox(height: 10),
      provider.workerTypes.isNotEmpty
          ? _buildModernDropdown(
              value: _selectedWorkerType,
              hint: "اختر نوع العمالة",
              isDark: isDark,
              items: provider.workerTypes
                  .map((w) => DropdownMenuItem<int>(
                        value: w['ID'],
                        child: Text(w['workdescription'] ?? '---'),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedWorkerType = val),
              validator: (v) => v == null ? "مطلوب" : null,
              color: const Color(0xFFEC4899),
            )
          : _buildLoadingDropdown("جاري تحميل أنواع العمالة..."),
    ];
  }

  // 📋 Section 4: سجل المتابعة
  List<Widget> _buildTrackingSection(bool isDark) {
    return [
      _buildTrackingRow(
        icon: Icons.person_add_rounded,
        label: "تمت الإضافة بواسطة",
        value: _addedBy,
        color: const Color(0xFF10B981),
        isDark: isDark,
      ),
      const SizedBox(height: 12),
      _buildTrackingRow(
        icon: Icons.calendar_today_rounded,
        label: "تاريخ الإضافة",
        value: _addedTime,
        color: const Color(0xFF10B981),
        isDark: isDark,
      ),
      const SizedBox(height: 16),
      Divider(color: isDark ? Colors.grey[800] : Colors.grey[200]),
      const SizedBox(height: 16),
      _buildTrackingRow(
        icon: Icons.edit_rounded,
        label: "آخر تعديل بواسطة",
        value: _editedBy,
        color: const Color(0xFFF59E0B),
        isDark: isDark,
      ),
      const SizedBox(height: 12),
      _buildTrackingRow(
        icon: Icons.update_rounded,
        label: "تاريخ التعديل",
        value: _editedTime,
        color: const Color(0xFFF59E0B),
        isDark: isDark,
      ),
    ];
  }

  Widget _buildTrackingRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 🔤 Modern Text Field
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    void Function()? onTap,
    TextInputType? keyboardType,
    bool readOnly = false,
    int maxLines = 1,
    int? maxLength,
    Color color = const Color(0xFF3B82F6),
    Widget? suffixWidget,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      onTap: onTap,
      keyboardType: keyboardType,
      readOnly: readOnly,
      maxLines: maxLines,
      maxLength: maxLength,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[500],
          fontSize: 14,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        suffixIcon: suffixWidget != null
            ? Padding(
                padding: const EdgeInsets.only(left: 12),
                child: suffixWidget,
              )
            : null,
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        counterText: "",
      ),
    );
  }

  // 🔽 Modern Dropdown
  Widget _buildModernDropdown<T>({
    required T? value,
    required String hint,
    required bool isDark,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?)? onChanged,
    String? Function(T?)? validator,
    Color color = const Color(0xFF3B82F6),
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      dropdownColor: isDark ? const Color(0xFF252836) : Colors.white,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[500]),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  // 🔘 Modern Switch
  Widget _buildModernSwitch({
    required String label,
    required String subtitle,
    required IconData icon,
    required bool value,
    required void Function(bool) onChanged,
    required bool isDark,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final color = value ? activeColor : inactiveColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              value ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor,
            activeTrackColor: activeColor.withOpacity(0.3),
            inactiveThumbColor: inactiveColor,
            inactiveTrackColor: inactiveColor.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  // 🏷️ Section Label
  Widget _buildSectionLabel(
      String label, IconData icon, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: color.withOpacity(0.2),
          ),
        ),
      ],
    );
  }

  // ⏳ Loading Dropdown
  Widget _buildLoadingDropdown(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            message,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  // 💾 Save Button
  Widget _buildSaveButton(bool isEdit) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.4),
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
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _isSaving
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    "جاري الحفظ...",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isEdit ? Icons.save_rounded : Icons.person_add_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEdit ? "حفظ التعديلات" : "إضافة الموظف",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}