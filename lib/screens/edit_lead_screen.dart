import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';

class EditLeadScreen extends StatefulWidget {
  final Map<String, dynamic> lead;

  const EditLeadScreen({super.key, required this.lead});

  @override
  State<EditLeadScreen> createState() => _EditLeadScreenState();
}

class _EditLeadScreenState extends State<EditLeadScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _childAgeController;
  late TextEditingController _notesController;

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

  List<Map<String, dynamic>> _branches = [];
  bool _isLoadingBranches = false;

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

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupAnimation();
    _loadBranches();
    _loadSources();
    _loadEmployees();
  }

  void _initializeControllers() {
    final lead = widget.lead;

    _nameController = TextEditingController(text: lead['FullName']?.toString() ?? '');
    _phoneController = TextEditingController(text: lead['Phone']?.toString() ?? '');
    _emailController = TextEditingController(text: lead['Email']?.toString() ?? '');
    _childAgeController = TextEditingController(text: lead['ChildAge']?.toString() ?? '');
    _notesController = TextEditingController(text: lead['Notes']?.toString() ?? '');

    _selectedSource = lead['LeadSource']?.toString();
    _selectedSourceId = lead['SourceID'] as int?;
    _selectedProgram = lead['InterestedProgram']?.toString();
    _selectedBranchId = lead['BranchPreference'] as int?;
    _selectedAssignedTo = lead['AssignedTo'] as int?;

    final nextFollowUp = lead['NextFollowUp']?.toString();
    if (nextFollowUp != null && nextFollowUp.isNotEmpty) {
      try {
        _selectedNextFollowUp = DateTime.parse(nextFollowUp);
      } catch (_) {}
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
    setState(() => _isLoadingBranches = true);
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
      debugPrint('Error loading branches: $e');
    } finally {
      if (mounted) setState(() => _isLoadingBranches = false);
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
        _selectedNextFollowUp = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, 10);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final leadId = widget.lead['LeadID'];
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final useredit = authProvider.user?.fullName ?? 'Unknown';
    final clientTime = DateTime.now().toIso8601String();

    final data = {
      'fullName': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      'childAge': int.tryParse(_childAgeController.text.trim()),
      'source': _selectedSource ?? 'Direct',
      'sourceId': _selectedSourceId,
      'interestedProgram': _selectedProgram,
      'branchId': _selectedBranchId,
      'assignedTo': _selectedAssignedTo,
      'nextFollowUp': _selectedNextFollowUp?.toIso8601String(),
      'notes': _notesController.text.trim(),
      'useredit': useredit,
      'clientTime': clientTime,
    };

    try {
      await ApiService.put('leads/$leadId', data);
      if (mounted) {
        _showSuccessSnackBar('تم تعديل البيانات بنجاح ✅');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('فشل التعديل: $e');
      }
    }
    if (mounted) setState(() => _isSaving = false);
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
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF59E0B),
        elevation: 0,
        title: const Text(
          'تعديل بيانات العميل',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
            onPressed: () {
              _initializeControllers();
              setState(() {});
            },
            tooltip: 'إعادة تعيين',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // ✅ البيانات الأساسية
                _buildCard(
                  isDark: isDark,
                  title: "البيانات الأساسية",
                  icon: Icons.person_rounded,
                  color: const Color(0xFFF59E0B),
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: "اسم ولي الأمر",
                      icon: Icons.person_rounded,
                      color: const Color(0xFF6366F1),
                      isDark: isDark,
                      validator: (v) => v == null || v.isEmpty ? "مطلوب" : null,
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
                      color: const Color(0xFFEC4899),
                      isDark: isDark,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ✅ الاهتمام والمتابعة
                _buildCard(
                  isDark: isDark,
                  title: "الاهتمام والمتابعة",
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF8B5CF6),
                  children: [
                    _buildSourceDropdown(isDark),
                    const SizedBox(height: 14),
                    _buildProgramDropdown(isDark),
                    const SizedBox(height: 14),
                    _buildBranchDropdown(isDark),
                    const SizedBox(height: 14),
                    _buildEmployeeDropdown(isDark),
                    const SizedBox(height: 14),
                    _buildDatePicker(isDark),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _notesController,
                      label: "ملاحظات",
                      icon: Icons.note_alt_rounded,
                      color: const Color(0xFF6B7280),
                      isDark: isDark,
                      maxLines: 3,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ✅ زر الحفظ
                _buildSaveButton(isDark),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
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
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
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
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
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
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: 2),
        ),
      ),
    );
  }

  Widget _buildSourceDropdown(bool isDark) {
    if (_isLoadingSources) {
      return _buildLoadingDropdown("جاري تحميل المصادر...", isDark);
    }
    return DropdownButtonFormField<int>(
      value: _selectedSourceId,
      items: _sources.map((s) => DropdownMenuItem<int>(
        value: s['id'],
        child: Text(s['name'], style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
      )).toList(),
      onChanged: (v) => setState(() {
        _selectedSourceId = v;
        _selectedSource = _sources.firstWhere((s) => s['id'] == v, orElse: () => {'name': 'Direct'})['name'];
      }),
      decoration: _dropdownDecoration("مصدر المعرفة", Icons.campaign_rounded, const Color(0xFF3B82F6), isDark),
      dropdownColor: isDark ? const Color(0xFF252836) : Colors.white,
    );
  }

  Widget _buildProgramDropdown(bool isDark) {
    return DropdownButtonFormField<String>(
      value: _selectedProgram,
      items: _programs.map((p) => DropdownMenuItem<String>(
        value: p,
        child: Text(p, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
      )).toList(),
      onChanged: (v) => setState(() => _selectedProgram = v),
      decoration: _dropdownDecoration("البرنامج المهتم به", Icons.school_rounded, const Color(0xFF10B981), isDark),
      dropdownColor: isDark ? const Color(0xFF252836) : Colors.white,
    );
  }

  Widget _buildBranchDropdown(bool isDark) {
    if (_isLoadingBranches) {
      return _buildLoadingDropdown("جاري تحميل الفروع...", isDark);
    }
    return DropdownButtonFormField<int>(
      value: _selectedBranchId,
      items: _branches.map((b) => DropdownMenuItem<int>(
        value: b['id'],
        child: Text(b['name'], style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
      )).toList(),
      onChanged: (v) => setState(() => _selectedBranchId = v),
      decoration: _dropdownDecoration("الفرع المفضّل", Icons.location_on_rounded, const Color(0xFFF97316), isDark),
      dropdownColor: isDark ? const Color(0xFF252836) : Colors.white,
    );
  }

  Widget _buildEmployeeDropdown(bool isDark) {
    if (_isLoadingEmployees) {
      return _buildLoadingDropdown("جاري تحميل الموظفين...", isDark);
    }
    return DropdownButtonFormField<int>(
      value: _selectedAssignedTo,
      items: _employees.map((e) => DropdownMenuItem<int>(
        value: e['id'],
        child: Text(e['name'], style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
      )).toList(),
      onChanged: (v) => setState(() => _selectedAssignedTo = v),
      decoration: _dropdownDecoration("الموظف المسؤول", Icons.person_rounded, const Color(0xFF8B5CF6), isDark),
      dropdownColor: isDark ? const Color(0xFF252836) : Colors.white,
      isExpanded: true,
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
                        : "اختر التاريخ",
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
                onTap: () => setState(() => _selectedNextFollowUp = null),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close_rounded, size: 16, color: Colors.grey[500]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingDropdown(String text, bool isDark) {
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
          Text(text, style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label, IconData icon, Color color, bool isDark) {
    return InputDecoration(
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
            colors: _isSaving
                ? [Colors.grey, Colors.grey]
                : [const Color(0xFFF59E0B), const Color(0xFFF97316)],
          ),
          boxShadow: _isSaving ? [] : [
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _isSaving
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white.withOpacity(0.8), strokeWidth: 2.5),
                    ),
                    const SizedBox(width: 12),
                    const Text("جاري الحفظ...", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.save_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text("حفظ التعديلات", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
        ),
      ),
    );
  }
}