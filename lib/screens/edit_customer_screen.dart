import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';

class EditCustomerScreen extends StatefulWidget {
  final Map<String, dynamic> customer;

  const EditCustomerScreen({super.key, required this.customer});

  @override
  State<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends State<EditCustomerScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _secondaryPhoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;

  bool _isSaving = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupAnimation();
  }

  void _initializeControllers() {
    final c = widget.customer;
    _nameController = TextEditingController(text: c['FullName']?.toString() ?? '');
    _phoneController = TextEditingController(text: c['Phone']?.toString() ?? '');
    _secondaryPhoneController = TextEditingController(text: c['SecondaryPhone']?.toString() ?? '');
    _emailController = TextEditingController(text: c['Email']?.toString() ?? '');
    _addressController = TextEditingController(text: c['Address']?.toString() ?? '');
    _notesController = TextEditingController(text: c['Notes']?.toString() ?? '');
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

    final customerId = widget.customer['CustomerID'];
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final useredit = authProvider.user?.fullName ?? 'Unknown';
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
      'useredit': useredit,
      'clientTime': clientTime,
    };

    try {
      await ApiService.put('customers/$customerId', data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تعديل البيانات بنجاح ✅'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context, true); // Return true to refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل التعديل: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        title: const Text('تعديل بيانات العميل'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildCard(
                  isDark: isDark,
                  title: "البيانات الأساسية",
                  icon: Icons.person_rounded,
                  color: const Color(0xFF10B981),
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: "اسم ولي الأمر",
                      icon: Icons.person_rounded,
                      isDark: isDark,
                      validator: (v) => v == null || v.isEmpty ? "مطلوب" : null,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _phoneController,
                      label: "رقم الموبايل",
                      icon: Icons.phone_rounded,
                      isDark: isDark,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.isEmpty ? "مطلوب" : null,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _secondaryPhoneController,
                      label: "رقم احتياطي",
                      icon: Icons.phone_android_rounded,
                      isDark: isDark,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _emailController,
                      label: "البريد الإلكتروني",
                      icon: Icons.email_rounded,
                      isDark: isDark,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _addressController,
                      label: "العنوان",
                      icon: Icons.location_on_rounded,
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                      isDark: isDark,
                      maxLines: 3,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSaveButton(isDark),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
      ),
    );
  }

  Widget _buildSaveButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'حفظ التعديلات',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}