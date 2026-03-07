import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _secondaryPhoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  // ربط بطفل
  Map<String, dynamic>? _selectedChild;
  String _relationship = 'ولي أمر';
  bool _isPrimary = true;

  bool _isSaving = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _relationships = [
    'ولي أمر',
    'أب',
    'أم',
    'جد',
    'جدة',
    'عم',
    'عمة',
    'خال',
    'خالة',
    'أخ',
    'أخت',
    'آخر',
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimation();
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

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _secondaryPhoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userAdd = authProvider.user?.fullName ?? 'Unknown';
    final clientTime = DateTime.now().toIso8601String();

    final data = {
      'fullName': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'secondaryPhone': _secondaryPhoneController.text.trim().isEmpty 
          ? null 
          : _secondaryPhoneController.text.trim(),
      'email': _emailController.text.trim().isEmpty 
          ? null 
          : _emailController.text.trim(),
      'address': _addressController.text.trim().isEmpty 
          ? null 
          : _addressController.text.trim(),
      'notes': _notesController.text.trim().isEmpty 
          ? null 
          : _notesController.text.trim(),
      'userAdd': userAdd,
      'clientTime': clientTime,
    };

    try {
      // 1. إضافة العميل
      final response = await ApiService.post('customers', data);
      final customerId = response['customerId'];

      // 2. ربط بالطفل لو موجود
      if (_selectedChild != null && customerId != null) {
        await ApiService.post('customer-children', {
          'customerId': customerId,
          'childId': _selectedChild!['ChildID'],
          'relationship': _relationship,
          'isPrimary': _isPrimary,
        });
      }

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
                Expanded(child: Text('فشل الحفظ: $e')),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      builder: (ctx) => AlertDialog(
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
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 60,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'تم بنجاح! 🎉',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'تم إضافة العميل بنجاح',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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
      ),
    );
  }

  void _showSearchChildDialog() {
    final searchController = TextEditingController();
    List<dynamic> searchResults = [];
    bool isSearching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Provider.of<ThemeProvider>(context).isDark;

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252836) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
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
                            color: const Color(0xFFEC4899).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.child_care_rounded,
                            color: Color(0xFFEC4899),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          "اختيار طفل",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Search Field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: "ابحث باسم الطفل...",
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: isSearching
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.search_rounded),
                          onPressed: () async {
                            if (searchController.text.isEmpty) return;
                            setModalState(() => isSearching = true);
                            try {
                              final data = await ApiService.get(
                                'customer-children/search-children?query=${searchController.text}',
                              );
                              setModalState(() {
                                searchResults = data is List ? data : [];
                                isSearching = false;
                              });
                            } catch (e) {
                              setModalState(() => isSearching = false);
                            }
                          },
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E1E2E) : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) async {
                        if (searchController.text.isEmpty) return;
                        setModalState(() => isSearching = true);
                        try {
                          final data = await ApiService.get(
                            'customer-children/search-children?query=${searchController.text}',
                          );
                          setModalState(() {
                            searchResults = data is List ? data : [];
                            isSearching = false;
                          });
                        } catch (e) {
                          setModalState(() => isSearching = false);
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Results
                  Expanded(
                    child: searchResults.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  size: 60,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "ابحث عن طفل بالاسم",
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: searchResults.length,
                            itemBuilder: (context, index) {
                              final child = searchResults[index];
                              return _buildChildSearchItem(child, isDark, ctx);
                            },
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

  Widget _buildChildSearchItem(dynamic child, bool isDark, BuildContext sheetContext) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEC4899).withOpacity(0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFEC4899).withOpacity(0.2),
                const Color(0xFFEC4899).withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.face_rounded, color: Color(0xFFEC4899)),
        ),
        title: Text(
          child['FullNameArabic'] ?? 'بدون اسم',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (child['Age'] != null)
              Text(
                'السن: ${child['Age']} سنوات',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            if (child['BranchName'] != null)
              Text(
                'الفرع: ${child['BranchName']}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
        trailing: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEC4899), Color(0xFFDB2777)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedChild = child;
              });
              Navigator.pop(sheetContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              "اختيار",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
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
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // البيانات الأساسية
                      _buildCard(
                        isDark: isDark,
                        title: "البيانات الأساسية",
                        icon: Icons.person_rounded,
                        color: const Color(0xFF10B981),
                        children: [
                          _buildTextField(
                            controller: _nameController,
                            label: "اسم ولي الأمر *",
                            icon: Icons.person_rounded,
                            color: const Color(0xFF10B981),
                            isDark: isDark,
                            validator: (v) => v == null || v.isEmpty ? "مطلوب" : null,
                          ),
                          const SizedBox(height: 14),
                          _buildTextField(
                            controller: _phoneController,
                            label: "رقم الموبايل *",
                            icon: Icons.phone_rounded,
                            color: const Color(0xFF3B82F6),
                            isDark: isDark,
                            keyboardType: TextInputType.phone,
                            validator: (v) => v == null || v.isEmpty ? "مطلوب" : null,
                          ),
                          const SizedBox(height: 14),
                          _buildTextField(
                            controller: _secondaryPhoneController,
                            label: "رقم موبايل احتياطي",
                            icon: Icons.phone_android_rounded,
                            color: const Color(0xFF6366F1),
                            isDark: isDark,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 14),
                          _buildTextField(
                            controller: _emailController,
                            label: "البريد الإلكتروني",
                            icon: Icons.email_rounded,
                            color: const Color(0xFF8B5CF6),
                            isDark: isDark,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),
                          _buildTextField(
                            controller: _addressController,
                            label: "العنوان",
                            icon: Icons.location_on_rounded,
                            color: const Color(0xFFF59E0B),
                            isDark: isDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ربط بطفل
                      _buildCard(
                        isDark: isDark,
                        title: "ربط بطفل (اختياري)",
                        icon: Icons.child_care_rounded,
                        color: const Color(0xFFEC4899),
                        children: [
                          _buildChildSelector(isDark),
                          if (_selectedChild != null) ...[
                            const SizedBox(height: 14),
                            _buildRelationshipDropdown(isDark),
                            const SizedBox(height: 14),
                            _buildPrimarySwitch(isDark),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ملاحظات
                      _buildCard(
                        isDark: isDark,
                        title: "ملاحظات",
                        icon: Icons.note_alt_rounded,
                        color: const Color(0xFF6B7280),
                        children: [
                          _buildTextField(
                            controller: _notesController,
                            label: "ملاحظات إضافية",
                            icon: Icons.notes_rounded,
                            color: const Color(0xFF6B7280),
                            isDark: isDark,
                            maxLines: 3,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // زر الحفظ
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
      backgroundColor: const Color(0xFF10B981),
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
              colors: [Color(0xFF10B981), Color(0xFF059669), Color(0xFF047857)],
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "إضافة عميل جديد",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "أضف بيانات ولي الأمر",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
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

  Widget _buildChildSelector(bool isDark) {
    if (_selectedChild == null) {
      return GestureDetector(
        onTap: _showSearchChildDialog,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFEC4899).withOpacity(0.3),
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Color(0xFFEC4899),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "اختر طفل لربطه بهذا العميل",
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEC4899).withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEC4899)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEC4899), Color(0xFFDB2777)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.face_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedChild!['FullNameArabic'] ?? 'بدون اسم',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (_selectedChild!['Age'] != null)
                  Text(
                    'السن: ${_selectedChild!['Age']} سنوات',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Color(0xFFEF4444)),
            onPressed: () {
              setState(() {
                _selectedChild = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRelationshipDropdown(bool isDark) {
    return DropdownButtonFormField<String>(
      value: _relationship,
      items: _relationships.map((r) => DropdownMenuItem<String>(
        value: r,
        child: Text(r, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
      )).toList(),
      onChanged: (v) => setState(() => _relationship = v ?? 'ولي أمر'),
      decoration: InputDecoration(
        labelText: "صلة القرابة",
        labelStyle: TextStyle(color: Colors.grey[500]),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.family_restroom_rounded, color: Color(0xFF8B5CF6), size: 20),
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
      ),
      dropdownColor: isDark ? const Color(0xFF252836) : Colors.white,
    );
  }

  Widget _buildPrimarySwitch(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.star_rounded, color: Color(0xFF10B981), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ولي الأمر الأساسي",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  "سيتم التواصل معه بشكل أساسي",
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Switch(
            value: _isPrimary,
            onChanged: (v) => setState(() => _isPrimary = v),
            activeColor: const Color(0xFF10B981),
          ),
        ],
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
                : [const Color(0xFF10B981), const Color(0xFF059669)],
          ),
          boxShadow: _isSaving
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.4),
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
                      child: CircularProgressIndicator(
                        color: Colors.white.withOpacity(0.8),
                        strokeWidth: 2.5,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "جاري الحفظ...",
                      style: TextStyle(
                        fontSize: 16,
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.save_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "حفظ العميل",
                      style: TextStyle(
                        fontSize: 16,
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
}