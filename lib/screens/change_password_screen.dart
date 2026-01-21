import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'dart:math' as math;

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  final _currentPassFocus = FocusNode();
  final _newPassFocus = FocusNode();
  final _confirmPassFocus = FocusNode();

  bool _isCurrentObscure = true;
  bool _isNewObscure = true;
  bool _isConfirmObscure = true;
  bool _isLoading = false;

  double _passwordStrength = 0;
  String _passwordStrengthText = '';
  Color _passwordStrengthColor = Colors.grey;

  late AnimationController _waveController;
  late AnimationController _fadeController;
  late AnimationController _slideController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _newPassController.addListener(_checkPasswordStrength);
  }

  void _setupAnimations() {
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
  }

  void _checkPasswordStrength() {
    String password = _newPassController.text;
    double strength = 0;

    if (password.isEmpty) {
      setState(() {
        _passwordStrength = 0;
        _passwordStrengthText = '';
        _passwordStrengthColor = Colors.grey;
      });
      return;
    }

    // Length check
    if (password.length >= 6) strength += 0.2;
    if (password.length >= 8) strength += 0.1;
    if (password.length >= 12) strength += 0.1;

    // Contains lowercase
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.1;

    // Contains uppercase
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.15;

    // Contains numbers
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.15;

    // Contains special characters
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.2;

    setState(() {
      _passwordStrength = strength.clamp(0.0, 1.0);

      if (_passwordStrength < 0.3) {
        _passwordStrengthText = 'ضعيفة جداً';
        _passwordStrengthColor = const Color(0xFFEF4444);
      } else if (_passwordStrength < 0.5) {
        _passwordStrengthText = 'ضعيفة';
        _passwordStrengthColor = const Color(0xFFF97316);
      } else if (_passwordStrength < 0.7) {
        _passwordStrengthText = 'متوسطة';
        _passwordStrengthColor = const Color(0xFFEAB308);
      } else if (_passwordStrength < 0.9) {
        _passwordStrengthText = 'قوية';
        _passwordStrengthColor = const Color(0xFF22C55E);
      } else {
        _passwordStrengthText = 'قوية جداً';
        _passwordStrengthColor = const Color(0xFF10B981);
      }
    });
  }

Future<void> _changePassword() async {
  if (!_formKey.currentState!.validate()) return;

  HapticFeedback.lightImpact();
  FocusScope.of(context).unfocus();

  setState(() => _isLoading = true);

  try {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.user?.userId;

    if (userId == null) {
      _showErrorSnackBar('خطأ في بيانات المستخدم');
      return;
    }

    // API Call لتغيير كلمة المرور
    final response = await ApiService.changePassword(
      userId: userId,
      currentPassword: _currentPassController.text.trim(),
      newPassword: _newPassController.text.trim(),
    );

    if (response['success'] == true && mounted) {
      _showSuccessDialog();
    } else if (mounted) {
      _showErrorSnackBar(response['message'] ?? 'حدث خطأ');
    }
  } catch (e) {
    if (mounted) {
      _showErrorSnackBar('كلمة المرور الحالية غير صحيحة');
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  void _showSuccessDialog() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF10B981).withOpacity(0.1),
                      const Color(0xFF059669).withOpacity(0.1),
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
              const SizedBox(height: 24),
              
              const Text(
                "تم بنجاح! 🎉",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              
              Text(
                "تم تغيير كلمة المرور بنجاح\nاستخدم كلمة المرور الجديدة في تسجيل الدخول",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              
              // OK Button
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "حسناً",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    _currentPassFocus.dispose();
    _newPassFocus.dispose();
    _confirmPassFocus.dispose();
    _waveController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1),
              Color(0xFF8B5CF6),
              Color(0xFFA855F7),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated Background
            _buildAnimatedBackground(),

            // Main Content
            SafeArea(
              child: Column(
                children: [
                  // App Bar
                  _buildAppBar(),

                  // Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.only(
                        left: 20,
                        right: 20,
                        bottom: bottomPadding + 24,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),

                          // Header
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: _buildHeader(),
                          ),

                          const SizedBox(height: 28),

                          // Form Card
                          SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildFormCard(),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Tips
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: _buildPasswordTips(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🎨 Animated Background
  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Stack(
          children: [
            // Floating circles
            Positioned(
              right: -60,
              top: 80,
              child: Transform.translate(
                offset: Offset(
                  math.cos(_waveController.value * 2 * math.pi) * 12,
                  math.sin(_waveController.value * 2 * math.pi) * 12,
                ),
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
            ),
            Positioned(
              left: -40,
              bottom: 120,
              child: Transform.translate(
                offset: Offset(
                  math.sin(_waveController.value * 2 * math.pi) * 10,
                  math.cos(_waveController.value * 2 * math.pi) * 10,
                ),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 40,
              bottom: 200,
              child: Transform.translate(
                offset: Offset(
                  math.cos(_waveController.value * 2 * math.pi + 1) * 8,
                  math.sin(_waveController.value * 2 * math.pi + 1) * 8,
                ),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 📱 App Bar
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          
          const Expanded(
            child: Text(
              "تغيير كلمة المرور",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(width: 48), // Balance for back button
        ],
      ),
    );
  }

  // 🎯 Header
  Widget _buildHeader() {
    return Column(
      children: [
        // Icon
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.lock_reset_rounded,
            size: 50,
            color: Color(0xFF6366F1),
          ),
        ),
        const SizedBox(height: 20),
        
        const Text(
          "إنشاء كلمة مرور جديدة",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        
        Text(
          "أدخل كلمة المرور الحالية والجديدة",
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  // 📝 Form Card
  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Password
            _buildPasswordField(
              controller: _currentPassController,
              focusNode: _currentPassFocus,
              nextFocusNode: _newPassFocus,
              label: "كلمة المرور الحالية",
              hint: "أدخل كلمة المرور الحالية",
              icon: Icons.lock_outline_rounded,
              isObscure: _isCurrentObscure,
              onToggleObscure: () =>
                  setState(() => _isCurrentObscure = !_isCurrentObscure),
              validator: (v) {
                if (v == null || v.isEmpty) return "هذا الحقل مطلوب";
                return null;
              },
            ),

            const SizedBox(height: 20),

            // New Password
            _buildPasswordField(
              controller: _newPassController,
              focusNode: _newPassFocus,
              nextFocusNode: _confirmPassFocus,
              label: "كلمة المرور الجديدة",
              hint: "أدخل كلمة المرور الجديدة",
              icon: Icons.lock_rounded,
              isObscure: _isNewObscure,
              onToggleObscure: () =>
                  setState(() => _isNewObscure = !_isNewObscure),
              validator: (v) {
                if (v == null || v.isEmpty) return "هذا الحقل مطلوب";
                if (v.length < 6) return "يجب أن تكون 6 أحرف على الأقل";
                if (v == _currentPassController.text) {
                  return "يجب أن تختلف عن كلمة المرور الحالية";
                }
                return null;
              },
            ),

            // Password Strength Indicator
            if (_newPassController.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildPasswordStrengthIndicator(),
            ],

            const SizedBox(height: 20),

            // Confirm Password
            _buildPasswordField(
              controller: _confirmPassController,
              focusNode: _confirmPassFocus,
              label: "تأكيد كلمة المرور",
              hint: "أعد إدخال كلمة المرور الجديدة",
              icon: Icons.lock_clock_rounded,
              isObscure: _isConfirmObscure,
              isLast: true,
              onToggleObscure: () =>
                  setState(() => _isConfirmObscure = !_isConfirmObscure),
              validator: (v) {
                if (v == null || v.isEmpty) return "هذا الحقل مطلوب";
                if (v != _newPassController.text) {
                  return "كلمة المرور غير متطابقة";
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Submit Button
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  // 🔐 Password Field
  Widget _buildPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocusNode,
    required String label,
    required String hint,
    required IconData icon,
    required bool isObscure,
    required VoidCallback onToggleObscure,
    required String? Function(String?) validator,
    bool isLast = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: isObscure,
          textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          onFieldSubmitted: (_) {
            if (nextFocusNode != null) {
              FocusScope.of(context).requestFocus(nextFocusNode);
            } else if (isLast) {
              _changePassword();
            }
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontWeight: FontWeight.normal,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isObscure
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: Colors.grey[500],
                size: 22,
              ),
              onPressed: onToggleObscure,
            ),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
          validator: validator,
        ),
      ],
    );
  }

  // 💪 Password Strength Indicator
  Widget _buildPasswordStrengthIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: _passwordStrength),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, value, child) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _passwordStrengthColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _passwordStrengthText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _passwordStrengthColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 🚀 Submit Button
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: _isLoading
              ? LinearGradient(colors: [Colors.grey[400]!, Colors.grey[500]!])
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
          boxShadow: _isLoading
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _changePassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white.withOpacity(0.9),
                          strokeWidth: 2.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "جاري التحديث...",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save_rounded, color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Text(
                        "تحديث كلمة المرور",
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
      ),
    );
  }

  // 💡 Password Tips
  Widget _buildPasswordTips() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lightbulb_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "نصائح لكلمة مرور قوية",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTipItem("استخدم 8 أحرف على الأقل", Icons.check_circle_rounded),
          _buildTipItem("أضف أحرف كبيرة وصغيرة", Icons.check_circle_rounded),
          _buildTipItem("أضف أرقام ورموز خاصة", Icons.check_circle_rounded),
          _buildTipItem("تجنب المعلومات الشخصية", Icons.check_circle_rounded),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white.withOpacity(0.8),
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}