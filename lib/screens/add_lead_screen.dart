import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  String? _selectedSource;
  int? _selectedSourceId;
  String? _selectedProgram;
  int? _selectedBranchId;
  int? _selectedAssignedTo;
  DateTime? _selectedNextFollowUp;

  bool _isSaving = false;

  // التحقق من رقم الموبايل
  bool _isCheckingPhone = false;
  bool? _phoneExists;
  String _phoneMessage = '';
  String _phoneSourceType = '';
  bool _phoneValid = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<Map<String, dynamic>> _sources = [];
  bool _isLoadingSources = false;

  List<Map<String, dynamic>> _assignees = [];
  bool _isLoadingAssignees = false;

  final List<String> _programs = [
    'Baby Class', 'KG1', 'KG2', 'Nursery Morning',
    'After School', 'Summer Camp', 'Winter Camp', 'Courses', 'رحلات',
  ];

  List<Map<String, dynamic>> _branches = [];
  bool _isLoadingBranches = false;
  bool _branchesLoadError = false;

  double get _completionPercentage {
    int filled = 0;
    const int total = 7;
    if (_nameController.text.isNotEmpty) filled++;
    if (_phoneController.text.isNotEmpty && _phoneValid) filled++;
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
    _loadAssignees();
    _setDefaultAssignee();
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

  // ✅ لو المستخدم PRUser يتحدد تلقائي
  void _setDefaultAssignee() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final role = auth.user?.role ?? '';
      final empId = auth.empId;

      if (role == 'PRUser' && empId != null) {
        setState(() => _selectedAssignedTo = empId);
      }
    });
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

  // ✅ جلب PRUser فقط
  Future<void> _loadAssignees() async {
    setState(() => _isLoadingAssignees = true);
    try {
      final data = await ApiService.getLeadsAssignees();
      if (mounted) {
        setState(() {
          _assignees = List<Map<String, dynamic>>.from(
            data.where((a) => a['Role'] == 'PRUser').map((a) => {
              'id': a['EmpID'],
              'name': a['empName'] ?? '',
            }),
          );
          _isLoadingAssignees = false;
        });

        // لو PRUser حدد نفسه تلقائي
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final role = auth.user?.role ?? '';
        final empId = auth.empId;

        if (role == 'PRUser' && empId != null) {
          final exists = _assignees.any((a) => a['id'] == empId);
          if (exists) {
            setState(() => _selectedAssignedTo = empId);
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingAssignees = false);
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
        setState(() {
          _branches = data.map<Map<String, dynamic>>((b) => {
            'id': b['IDbranch'],
            'name': b['branchName'],
          }).toList();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _branchesLoadError = true);
    } finally {
      if (mounted) setState(() => _isLoadingBranches = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _childAgeController.dispose();
    _notesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // =============================================
  // ✅ تنظيف والتحقق من رقم الموبايل
  // =============================================
  String _cleanPhone(String phone) {
    return phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
  }

  bool _isValidEgyptianPhone(String phone) {
    final cleaned = _cleanPhone(phone);
    return RegExp(r'^(010|011|012|015)\d{8}$').hasMatch(cleaned);
  }

  Future<void> _onPhoneChanged(String value) async {
    final cleaned = _cleanPhone(value);

    // لو الرقم ناقص ما نعملش request
    if (cleaned.length < 11) {
      setState(() {
        _phoneExists = null;
        _phoneMessage = '';
        _phoneValid = false;
        _isCheckingPhone = false;
      });
      return;
    }

    // لو الرقم غلط
    if (!_isValidEgyptianPhone(cleaned)) {
      setState(() {
        _phoneExists = null;
        _phoneMessage = 'رقم غير صحيح (يجب أن يبدأ بـ 010, 011, 012, 015)';
        _phoneValid = false;
        _isCheckingPhone = false;
      });
      return;
    }

    // الرقم صحيح → نتحقق من التكرار
    setState(() => _isCheckingPhone = true);

    try {
      final result = await ApiService.checkLeadPhone(cleaned);
      if (mounted) {
        setState(() {
          _phoneExists = result['exists'] ?? false;
          _phoneMessage = result['message'] ?? '';
          _phoneSourceType = result['sourceType'] ?? '';
          _phoneValid = !(_phoneExists ?? false);
          _isCheckingPhone = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _phoneExists = null;
          _phoneValid = true;
          _isCheckingPhone = false;
        });
      }
    }
  }

  Future<void> _pickNextFollowUpDate() async {
    final now = DateTime.now();
    final initial = _selectedNextFollowUp ?? now.add(const Duration(days: 1));
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedNextFollowUp = DateTime(
            pickedDate.year, pickedDate.month, pickedDate.day, 10);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // التحقق من رقم الموبايل
    if (_isCheckingPhone) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.hourglass_empty_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text('جاري التحقق من الرقم...'),
          ]),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    if (_phoneExists == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.warning_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(_phoneMessage)),
          ]),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final cleanPhone = _cleanPhone(_phoneController.text.trim());
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userAdd = auth.user?.fullName ?? 'Unknown User';

    final data = {
      'fullName': _nameController.text.trim(),
      'phone': cleanPhone,
      'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      'childAge': int.tryParse(_childAgeController.text.trim()),
      'source': _selectedSource ?? 'Direct',
      'sourceId': _selectedSourceId,
      'interestedProgram': _selectedProgram,
      'branchId': _selectedBranchId,
      'assignedTo': _selectedAssignedTo,
      'nextFollowUp': _selectedNextFollowUp?.toIso8601String(),
      'notes': _notesController.text.trim(),
      'userAdd': userAdd,
      'clientTime': DateTime.now().toString(),
    };

    try {
      await ApiService.post('leads', data);
      if (mounted) _showSuccessDialog();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text('فشل الحفظ: $e')),
            ]),
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
                child: const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF10B981), size: 60),
              ),
              const SizedBox(height: 20),
              Text('تم بنجاح! 🎯',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 10),
              Text('تم تسجيل العميل المحتمل بنجاح',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('تم',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
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

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
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
                              validator: (v) =>
                                  v == null || v.isEmpty ? "مطلوب" : null,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 14),

                            // ✅ حقل رقم الموبايل المحسن
                            _buildPhoneField(isDark),

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
                              onChanged: (val) =>
                                  setState(() => _selectedProgram = val),
                            ),
                            const SizedBox(height: 14),
                            _buildBranchDropdown(isDark),
                            const SizedBox(height: 14),
                            _buildAssigneeDropdown(isDark),
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

  // =============================================
  // ✅ حقل رقم الموبايل المحسن
  // =============================================
  Widget _buildPhoneField(bool isDark) {
    Color borderColor;
    Color iconColor;
    Widget? suffixIcon;

    if (_isCheckingPhone) {
      borderColor = const Color(0xFFF59E0B);
      iconColor = const Color(0xFFF59E0B);
      suffixIcon = const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
          width: 20, height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF59E0B)),
        ),
      );
    } else if (_phoneExists == true) {
      borderColor = const Color(0xFFEF4444);
      iconColor = const Color(0xFFEF4444);
      suffixIcon = const Icon(Icons.error_rounded, color: Color(0xFFEF4444));
    } else if (_phoneValid) {
      borderColor = const Color(0xFF10B981);
      iconColor = const Color(0xFF10B981);
      suffixIcon = const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981));
    } else {
      borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade200;
      iconColor = const Color(0xFF10B981);
      suffixIcon = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 15,
            letterSpacing: 1.5,
          ),
          onChanged: (value) {
            setState(() {});
            _onPhoneChanged(value);
          },
          validator: (v) {
            if (v == null || v.isEmpty) return 'رقم الموبايل مطلوب';
            if (!_isValidEgyptianPhone(v)) return 'رقم غير صحيح';
            if (_phoneExists == true) return _phoneMessage;
            return null;
          },
          decoration: InputDecoration(
            labelText: "رقم الموبايل",
            labelStyle: TextStyle(color: Colors.grey[500]),
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.phone_rounded, color: iconColor, size: 20),
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            counterText: '${_cleanPhone(_phoneController.text).length}/11',
            counterStyle: TextStyle(
              color: _phoneValid
                  ? const Color(0xFF10B981)
                  : Colors.grey.shade500,
              fontSize: 11,
            ),
          ),
        ),

        // ✅ رسالة التحقق
        if (_phoneMessage.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: (_phoneExists == true
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981))
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (_phoneExists == true
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981))
                    .withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _phoneExists == true
                      ? Icons.warning_rounded
                      : Icons.check_circle_rounded,
                  size: 16,
                  color: _phoneExists == true
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _phoneMessage,
                    style: TextStyle(
                      fontSize: 12,
                      color: _phoneExists == true
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF10B981),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // =============================================
  // ✅ Dropdown الموظف المسؤول (PRUser فقط)
  // =============================================
  Widget _buildAssigneeDropdown(bool isDark) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isPRUser = auth.user?.role == 'PRUser';

    if (_isLoadingAssignees) {
      return _buildLoadingContainer(isDark, "جاري تحميل الموظفين...");
    }

    return DropdownButtonFormField<int>(
      value: _selectedAssignedTo,
      isExpanded: true,
      items: _assignees.map((emp) => DropdownMenuItem<int>(
        value: emp['id'],
        child: Text(
          emp['name'],
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          overflow: TextOverflow.ellipsis,
        ),
      )).toList(),
      onChanged: isPRUser
          ? null // PRUser ما يقدرش يغيره
          : (val) => setState(() => _selectedAssignedTo = val),
      decoration: InputDecoration(
        labelText: isPRUser ? "الموظف المسؤول (أنت)" : "الموظف المسؤول",
        labelStyle: TextStyle(color: Colors.grey[500]),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.support_agent_rounded,
              color: Color(0xFF8B5CF6), size: 20),
        ),
        suffixIcon: isPRUser
            ? Container(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.lock_rounded,
                    size: 16, color: Colors.grey.shade400),
              )
            : null,
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFF8B5CF6), width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: const Color(0xFF8B5CF6).withOpacity(0.3)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      dropdownColor: isDark ? const Color(0xFF252836) : Colors.white,
      icon: isPRUser
          ? const SizedBox.shrink()
          : Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[500]),
    );
  }

  Widget _buildLoadingContainer(bool isDark, String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Row(
        children: [
          const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: Colors.grey[500])),
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
          child: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
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
                right: -50, top: -50,
                child: Container(
                  width: 200, height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: 40, left: 20, right: 20,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.person_add_alt_1_rounded,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 15),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("عميل محتمل جديد",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold)),
                        Text("أضف بيانات العميل المحتمل",
                            style: TextStyle(
                                color: Colors.white70, fontSize: 14)),
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
                    child: const Icon(Icons.pie_chart_rounded,
                        color: Color(0xFF6366F1), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text("نسبة الاكتمال",
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getProgressColor(_completionPercentage)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${(_completionPercentage * 100).toInt()}%",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getProgressColor(_completionPercentage)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _completionPercentage,
              minHeight: 8,
              backgroundColor:
                  isDark ? Colors.grey[800] : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressColor(_completionPercentage)),
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
              offset: const Offset(0, 5)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              right: 0, top: 0, bottom: 0,
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
                      Text(title,
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87)),
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
      style: TextStyle(
          color: isDark ? Colors.white : Colors.black87, fontSize: 15),
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
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
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
          child: Text(item,
              style:
                  TextStyle(color: isDark ? Colors.white : Colors.black87)),
        );
      }).toList(),
      onChanged: onChanged,
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.grey[500]),
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
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
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

  Widget _buildSourceDropdown(bool isDark) {
    if (_isLoadingSources) {
      return _buildLoadingContainer(isDark, "جاري تحميل المصادر...");
    }

    return DropdownButtonFormField<int>(
      value: _selectedSourceId,
      items: _sources.map((source) => DropdownMenuItem<int>(
        value: source['id'],
        child: Text(source['name'],
            style:
                TextStyle(color: isDark ? Colors.white : Colors.black87)),
      )).toList(),
      onChanged: (sourceId) {
        setState(() {
          _selectedSourceId = sourceId;
          _selectedSource = _sources.firstWhere(
              (s) => s['id'] == sourceId,
              orElse: () => {'name': 'Direct'})['name'];
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
          child: const Icon(Icons.campaign_rounded,
              color: Color(0xFF3B82F6), size: 20),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      dropdownColor: isDark ? const Color(0xFF252836) : Colors.white,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[500]),
    );
  }

  Widget _buildBranchDropdown(bool isDark) {
    if (_isLoadingBranches) {
      return _buildLoadingContainer(isDark, "جاري تحميل الفروع...");
    }

    if (_branchesLoadError) {
      return GestureDetector(
        onTap: _loadBranches,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFFEF4444).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFEF4444), size: 20),
              const SizedBox(width: 12),
              Expanded(
                  child: Text("فشل تحميل الفروع",
                      style: TextStyle(color: Colors.red[400]))),
              const Icon(Icons.refresh_rounded,
                  color: Color(0xFFEF4444), size: 20),
            ],
          ),
        ),
      );
    }

    return DropdownButtonFormField<int>(
      value: _selectedBranchId,
      items: _branches.map((b) => DropdownMenuItem<int>(
        value: b['id'] as int,
        child: Text(b['name'] as String,
            style:
                TextStyle(color: isDark ? Colors.white : Colors.black87)),
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
          child: const Icon(Icons.location_on_rounded,
              color: Color(0xFFF97316), size: 20),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFF97316), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      dropdownColor: isDark ? const Color(0xFF252836) : Colors.white,
      icon:
          Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[500]),
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
              child: const Icon(Icons.event_note_rounded,
                  color: Color(0xFF6366F1), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("ميعاد المتابعة الجاية",
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[500])),
                  const SizedBox(height: 4),
                  Text(
                    _selectedNextFollowUp != null
                        ? DateFormat('EEEE, d MMMM yyyy', 'ar')
                            .format(_selectedNextFollowUp!)
                        : "اختر التاريخ (اختياري)",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: _selectedNextFollowUp != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: _selectedNextFollowUp != null
                          ? (isDark ? Colors.white : Colors.black87)
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedNextFollowUp != null)
              GestureDetector(
                onTap: () => setState(() => _selectedNextFollowUp = null),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: Icon(Icons.close_rounded,
                      size: 16, color: Colors.grey[500]),
                ),
              )
            else
              Icon(Icons.calendar_today_rounded,
                  size: 18, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(bool isDark) {
    final canSave = !_isSaving &&
        !_isCheckingPhone &&
        (_phoneExists != true) &&
        _phoneValid;

    return SizedBox(
      width: double.infinity,
      height: 58,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: canSave
                ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                : [Colors.grey, Colors.grey.shade400],
          ),
          boxShadow: canSave
              ? [
                  BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8))
                ]
              : [],
        ),
        child: ElevatedButton(
          onPressed: canSave ? _save : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          child: _isSaving
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white.withOpacity(0.8),
                          strokeWidth: 2.5),
                    ),
                    const SizedBox(width: 12),
                    const Text("جاري الحفظ...",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.person_add_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text("حفظ العميل المحتمل",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ],
                ),
        ),
      ),
    );
  }
}