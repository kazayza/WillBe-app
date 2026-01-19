import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/children_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';

class ChildFormScreen extends StatefulWidget {
  final int? childId;

  const ChildFormScreen({super.key, this.childId});

  @override
  State<ChildFormScreen> createState() => _ChildFormScreenState();
}

class _ChildFormScreenState extends State<ChildFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _nameEnController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _birthDateController = TextEditingController();

  final _fatherNameController = TextEditingController();
  final _fatherPhoneController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _motherPhoneController = TextEditingController();
  final _addressController = TextEditingController();

  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _allergiesController = TextEditingController();

  int? _selectedBranch;
  bool _isFullTime = false;
  bool _isSports = false;
  bool _wearDiapers = false;

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isTranslating = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Track current expanded section
  int _expandedSection = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
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
    final provider = Provider.of<ChildrenProvider>(context, listen: false);
    await provider.fetchBranches();

    if (widget.childId != null) {
      setState(() => _isLoading = true);
      final data = await provider.fetchChildById(widget.childId!);

      if (data != null && mounted) {
        setState(() {
          _nameController.text = data['FullNameArabic'] ?? '';
          _nameEnController.text = data['FullNameEnglish'] ?? '';
          _nationalIdController.text = data['NationalID']?.toString() ?? '';
          _birthDateController.text = data['birthDate'] != null
              ? data['birthDate'].toString().split('T')[0]
              : '';
          _selectedBranch = data['Branch'];

          _fatherNameController.text = data['FatherName'] ?? '';
          _fatherPhoneController.text = data['FatherMobile1'] ?? '';
          _motherNameController.text = data['MotherName'] ?? '';
          _motherPhoneController.text = data['MotherMobile1'] ?? '';
          _addressController.text = data['ResidenceAddress'] ?? '';

          _emergencyNameController.text = data['EmergencyName1'] ?? '';
          _emergencyPhoneController.text = data['EmergencyNumber1'] ?? '';
          _notesController.text = data['Notes'] ?? '';
          _allergiesController.text = data['Allergies'] ?? '';

          _isFullTime = data['DidFullTime'] == true;
          _isSports = data['DoSports'] == true;
          _wearDiapers = data['WearDiapers'] == true;

          _isLoading = false;
        });
      }
    }
  }

  void _extractFatherName(String fullName) {
    if (fullName.isEmpty) return;
    List<String> parts = fullName.trim().split(' ');
    if (parts.length > 1) {
      _fatherNameController.text = parts.sublist(1).join(' ');
    }
  }

  void _extractBirthDateFromID(String nid) {
    if (nid.length != 14) return;
    try {
      String century = nid[0];
      String year = nid.substring(1, 3);
      String month = nid.substring(3, 5);
      String day = nid.substring(5, 7);
      String fullYear = (century == '2') ? '19$year' : '20$year';
      String fullDate = '$fullYear-$month-$day';
      DateTime date = DateTime.parse(fullDate);
      setState(() {
        _birthDateController.text = DateFormat('yyyy-MM-dd').format(date);
      });
    } catch (e) {}
  }

  void _translate() async {
    if (_nameController.text.isEmpty) return;

    setState(() => _isTranslating = true);
    _extractFatherName(_nameController.text);

    String translated = await ApiService.translateName(_nameController.text);
    if (mounted) {
      setState(() {
        _nameEnController.text = translated;
        _isTranslating = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDark;
    
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF6366F1),
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
        _birthDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBranch == null) {
      _showErrorSnackBar('يرجى اختيار الفرع');
      return;
    }
    setState(() => _isSaving = true);

    final Map<String, dynamic> data = {
      'FullNameArabic': _nameController.text,
      'FullNameEnglish': _nameEnController.text,
      'NationalID': _nationalIdController.text,
      'birthDate': _birthDateController.text,
      'Branch': _selectedBranch,
      'Status': true,
      'FatherName': _fatherNameController.text,
      'FatherMobile1': _fatherPhoneController.text,
      'MotherName': _motherNameController.text,
      'MotherMobile1': _motherPhoneController.text,
      'ResidenceAddress': _addressController.text,
      'EmergencyName1': _emergencyNameController.text,
      'EmergencyNumber1': _emergencyPhoneController.text,
      'Notes': _notesController.text,
      'Allergies': _allergiesController.text,
      'DidFullTime': _isFullTime,
      'DoSports': _isSports,
      'WearDiapers': _wearDiapers,
    };

    final user = Provider.of<AuthProvider>(context, listen: false).user?.fullName ?? "System";
    bool success;

    if (widget.childId != null) {
      data['userEdit'] = user;
      success = await Provider.of<ChildrenProvider>(context, listen: false)
          .updateChild(widget.childId!, data);
    } else {
      data['userAdd'] = user;
      success = await Provider.of<ChildrenProvider>(context, listen: false)
          .addChild(data);
    }

    setState(() => _isSaving = false);

    if (success && mounted) {
      _showSuccessSnackBar(widget.childId != null ? 'تم التعديل بنجاح ✅' : 'تمت الإضافة بنجاح ✅');
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
            Text(message),
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
    _nameEnController.dispose();
    _nationalIdController.dispose();
    _birthDateController.dispose();
    _fatherNameController.dispose();
    _fatherPhoneController.dispose();
    _motherNameController.dispose();
    _motherPhoneController.dispose();
    _addressController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _notesController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChildrenProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;
    final isEdit = widget.childId != null;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)),
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
                            _buildProgressIndicator(isDark),
                            const SizedBox(height: 20),

                            // Section 1: البيانات الأساسية
                            _buildAnimatedCard(
                              index: 0,
                              isDark: isDark,
                              title: "البيانات الأساسية",
                              subtitle: "الاسم والرقم القومي والفرع",
                              icon: Icons.person_rounded,
                              color: const Color(0xFF6366F1),
                              children: _buildBasicDataSection(provider, isDark),
                            ),

                            const SizedBox(height: 16),

                            // Section 2: بيانات ولي الأمر
                            _buildAnimatedCard(
                              index: 1,
                              isDark: isDark,
                              title: "بيانات ولي الأمر",
                              subtitle: "معلومات الأب والأم",
                              icon: Icons.family_restroom_rounded,
                              color: const Color(0xFF10B981),
                              children: _buildParentDataSection(isDark),
                            ),

                            const SizedBox(height: 16),

                            // Section 3: تفاصيل إضافية
                            _buildAnimatedCard(
                              index: 2,
                              isDark: isDark,
                              title: "تفاصيل إضافية",
                              subtitle: "الخيارات والطوارئ",
                              icon: Icons.health_and_safety_rounded,
                              color: const Color(0xFFF59E0B),
                              children: _buildAdditionalSection(isDark),
                            ),

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
        if (isEdit)
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
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
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
                        isEdit ? Icons.edit_rounded : Icons.person_add_rounded,
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
                            isEdit ? "تعديل البيانات" : "إضافة طفل جديد",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isEdit ? "قم بتحديث بيانات الطفل" : "أدخل بيانات الطفل الجديد",
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
  Widget _buildProgressIndicator(bool isDark) {
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
              Icon(
                Icons.checklist_rounded,
                color: const Color(0xFF6366F1),
                size: 20,
              ),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${_expandedSection + 1}/3",
                  style: const TextStyle(
                    color: Color(0xFF6366F1),
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
              _buildProgressStep(0, "الأساسية", isDark),
              _buildProgressLine(0, isDark),
              _buildProgressStep(1, "ولي الأمر", isDark),
              _buildProgressLine(1, isDark),
              _buildProgressStep(2, "إضافية", isDark),
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
                    ? const Color(0xFF6366F1)
                    : (isDark ? Colors.grey[700] : Colors.grey[300]),
                shape: BoxShape.circle,
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.4),
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
                    ? const Color(0xFF6366F1)
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
              ? const Color(0xFF6366F1)
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

  // 📝 Section 1: البيانات الأساسية
  List<Widget> _buildBasicDataSection(ChildrenProvider provider, bool isDark) {
    return [
      _buildModernTextField(
        controller: _nameController,
        label: "الاسم رباعي (عربي)",
        icon: Icons.person_rounded,
        isDark: isDark,
        validator: (v) => v!.isEmpty ? "مطلوب" : null,
        onChanged: (val) => _extractFatherName(val),
        onEditingComplete: _translate,
        suffixIcon: IconButton(
          icon: _isTranslating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF6366F1),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.g_translate_rounded,
                    color: Color(0xFFF59E0B),
                    size: 20,
                  ),
                ),
          onPressed: _translate,
        ),
      ),
      const SizedBox(height: 16),
      _buildModernTextField(
        controller: _nameEnController,
        label: "الاسم (إنجليزي)",
        icon: Icons.language_rounded,
        isDark: isDark,
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: _buildModernTextField(
              controller: _nationalIdController,
              label: "الرقم القومي",
              icon: Icons.badge_rounded,
              isDark: isDark,
              keyboardType: TextInputType.number,
              maxLength: 14,
              onChanged: _extractBirthDateFromID,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildModernTextField(
              controller: _birthDateController,
              label: "تاريخ الميلاد",
              icon: Icons.calendar_today_rounded,
              isDark: isDark,
              readOnly: true,
              onTap: _pickDate,
              validator: (v) => v!.isEmpty ? "مطلوب" : null,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _buildModernDropdown(
        value: _selectedBranch,
        label: "الفرع",
        icon: Icons.store_rounded,
        isDark: isDark,
        items: provider.branches.map<DropdownMenuItem<int>>((branch) {
          return DropdownMenuItem<int>(
            value: branch['IDbranch'],
            child: Text(branch['branchName']),
          );
        }).toList(),
        onChanged: (val) => setState(() => _selectedBranch = val),
        validator: (v) => v == null ? "مطلوب" : null,
      ),
    ];
  }

  // 👨‍👩‍👧 Section 2: بيانات ولي الأمر
  List<Widget> _buildParentDataSection(bool isDark) {
    return [
      // Father Section
      _buildSectionLabel("الأب", Icons.male_rounded, const Color(0xFF3B82F6), isDark),
      const SizedBox(height: 12),
      _buildModernTextField(
        controller: _fatherNameController,
        label: "اسم الأب",
        icon: Icons.person_outline_rounded,
        isDark: isDark,
      ),
      const SizedBox(height: 12),
      _buildModernTextField(
        controller: _fatherPhoneController,
        label: "موبايل الأب",
        icon: Icons.phone_rounded,
        isDark: isDark,
        keyboardType: TextInputType.phone,
      ),

      const SizedBox(height: 20),

      // Mother Section
      _buildSectionLabel("الأم", Icons.female_rounded, const Color(0xFFEC4899), isDark),
      const SizedBox(height: 12),
      _buildModernTextField(
        controller: _motherNameController,
        label: "اسم الأم",
        icon: Icons.person_outline_rounded,
        isDark: isDark,
      ),
      const SizedBox(height: 12),
      _buildModernTextField(
        controller: _motherPhoneController,
        label: "موبايل الأم",
        icon: Icons.phone_rounded,
        isDark: isDark,
        keyboardType: TextInputType.phone,
      ),

      const SizedBox(height: 20),

      // Address
      _buildModernTextField(
        controller: _addressController,
        label: "العنوان",
        icon: Icons.home_rounded,
        isDark: isDark,
        maxLines: 2,
      ),
    ];
  }

  // ⚕️ Section 3: تفاصيل إضافية
  List<Widget> _buildAdditionalSection(bool isDark) {
    return [
      // Checkboxes
      _buildModernSwitch(
        label: "يوم كامل (Full Time)",
        icon: Icons.access_time_filled_rounded,
        value: _isFullTime,
        onChanged: (v) => setState(() => _isFullTime = v),
        isDark: isDark,
        color: const Color(0xFF6366F1),
      ),
      const SizedBox(height: 10),
      _buildModernSwitch(
        label: "مشترك رياضة",
        icon: Icons.sports_soccer_rounded,
        value: _isSports,
        onChanged: (v) => setState(() => _isSports = v),
        isDark: isDark,
        color: const Color(0xFF10B981),
      ),
      const SizedBox(height: 10),
      _buildModernSwitch(
        label: "حفاضات (Diapers)",
        icon: Icons.baby_changing_station_rounded,
        value: _wearDiapers,
        onChanged: (v) => setState(() => _wearDiapers = v),
        isDark: isDark,
        color: const Color(0xFFF59E0B),
      ),

      const SizedBox(height: 20),

      // Emergency Section
      _buildSectionLabel("بيانات الطوارئ", Icons.emergency_rounded, const Color(0xFFEF4444), isDark),
      const SizedBox(height: 12),
      _buildModernTextField(
        controller: _emergencyNameController,
        label: "اسم جهة الطوارئ",
        icon: Icons.contact_phone_rounded,
        isDark: isDark,
      ),
      const SizedBox(height: 12),
      _buildModernTextField(
        controller: _emergencyPhoneController,
        label: "رقم الطوارئ",
        icon: Icons.phone_in_talk_rounded,
        isDark: isDark,
        keyboardType: TextInputType.phone,
      ),
      const SizedBox(height: 12),
      _buildModernTextField(
        controller: _notesController,
        label: "ملاحظات عامة",
        icon: Icons.note_alt_rounded,
        isDark: isDark,
        maxLines: 3,
      ),
    ];
  }

  // 🔤 Modern Text Field
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    void Function()? onEditingComplete,
    void Function()? onTap,
    TextInputType? keyboardType,
    bool readOnly = false,
    int maxLines = 1,
    int? maxLength,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
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
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF6366F1), size: 20),
        ),
        suffixIcon: suffixIcon,
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
          borderSide: const BorderSide(
            color: Color(0xFF6366F1),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        counterText: "",
      ),
    );
  }

  // 🔽 Modern Dropdown
  Widget _buildModernDropdown({
    required int? value,
    required String label,
    required IconData icon,
    required bool isDark,
    required List<DropdownMenuItem<int>> items,
    required void Function(int?)? onChanged,
    String? Function(int?)? validator,
  }) {
    return DropdownButtonFormField<int>(
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
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[500],
          fontSize: 14,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF6366F1), size: 20),
        ),
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
          borderSide: const BorderSide(
            color: Color(0xFF6366F1),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  // 🔘 Modern Switch
  Widget _buildModernSwitch({
    required String label,
    required IconData icon,
    required bool value,
    required void Function(bool) onChanged,
    required bool isDark,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: value ? color.withOpacity(0.1) : (isDark ? const Color(0xFF1E1E2E) : Colors.grey[50]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value ? color : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: value ? FontWeight.w600 : FontWeight.normal,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            activeTrackColor: color.withOpacity(0.3),
            inactiveThumbColor: Colors.grey[400],
            inactiveTrackColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }

  // 🏷️ Section Label
  Widget _buildSectionLabel(String label, IconData icon, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
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

  // 💾 Save Button
  Widget _buildSaveButton(bool isEdit) {
    return Container(
      width: double.infinity,
      height: 60,
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
                    isEdit ? Icons.save_rounded : Icons.add_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEdit ? "حفظ التعديلات" : "إضافة الطفل",
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