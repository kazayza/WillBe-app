import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/installment_item.dart';
import '../services/api_service.dart';

class CreateInstallmentsScreen extends StatefulWidget {
  final int financeId;
  final double totalAmount;
  final String childName;
  final String currentUser;

  const CreateInstallmentsScreen({
    super.key,
    required this.financeId,
    required this.totalAmount,
    required this.childName,
    required this.currentUser,
  });

  @override
  State<CreateInstallmentsScreen> createState() =>
      _CreateInstallmentsScreenState();
}

class _CreateInstallmentsScreenState extends State<CreateInstallmentsScreen>
    with TickerProviderStateMixin {
  
  // ═══════════════════════════════════════════════════════════════
  // المتغيرات
  // ═══════════════════════════════════════════════════════════════

  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  int _numberOfInstallments = 3;
  DateTime _startDate = DateTime.now();
  List<InstallmentItem> _installments = [];
  bool _isLoading = false;
  bool _showTemplates = true;
  String? _selectedTemplateId;
  DistributionType _distributionType = DistributionType.equal;

  // Animation Controllers
  late AnimationController _headerAnimController;
  late AnimationController _cardsAnimController;
  late Animation<double> _headerAnimation;

  // Formatters
  final _currencyFormat = NumberFormat('#,###', 'ar_EG');
  final _dateFormat = DateFormat('dd/MM/yyyy', 'ar_EG');

  // Colors
  static const _primaryColor = Color(0xFF6366F1);
  static const _successColor = Color(0xFF10B981);
  static const _warningColor = Color(0xFFF59E0B);
  static const _errorColor = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _headerAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _cardsAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _headerAnimation = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOutCubic,
    );

    _headerAnimController.forward();
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    _cardsAnimController.dispose();
    _scrollController.dispose();
    for (var inst in _installments) {
      inst.dispose();
    }
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // Getters
  // ═══════════════════════════════════════════════════════════════

  double get _totalInstallments {
    double total = 0;
    for (var inst in _installments) {
      total += inst.currentAmount;
    }
    return total;
  }

  double get _difference => widget.totalAmount - _totalInstallments;

  double get _progressValue {
    if (widget.totalAmount == 0) return 0;
    return (_totalInstallments / widget.totalAmount).clamp(0.0, 1.5);
  }

  bool get _isValidTotal => _difference.abs() < 0.01;

  Color get _progressColor {
    if (_isValidTotal) return _successColor;
    if (_totalInstallments > widget.totalAmount) return _errorColor;
    return _warningColor;
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  // ═══════════════════════════════════════════════════════════════
  // توليد الأقساط
  // ═══════════════════════════════════════════════════════════════

  void _generateInstallments() {
    // تنظيف القديم
    for (var inst in _installments) {
      inst.dispose();
    }
    _installments.clear();

    List<double> amounts = _calculateDistribution();

    for (int i = 0; i < _numberOfInstallments; i++) {
      DateTime installmentDate = DateTime(
        _startDate.year,
        _startDate.month + i,
        _startDate.day,
      );

      _installments.add(InstallmentItem(
        amount: amounts[i],
        date: installmentDate,
      ));
    }

    setState(() {});
    _cardsAnimController.reset();
    _cardsAnimController.forward();
  }

  List<double> _calculateDistribution() {
    List<double> amounts = [];
    double total = widget.totalAmount;
    int n = _numberOfInstallments;

    switch (_distributionType) {
      case DistributionType.equal:
        double each = (total / n).floorToDouble();
        double remainder = total - (each * n);
        for (int i = 0; i < n; i++) {
          amounts.add(i == n - 1 ? each + remainder : each);
        }
        break;

      case DistributionType.descending:
        double ratio = 0;
        for (int i = n; i >= 1; i--) {
          ratio += i;
        }
        for (int i = 0; i < n; i++) {
          amounts.add(((n - i) / ratio * total).roundToDouble());
        }
        double diff = total - amounts.reduce((a, b) => a + b);
        amounts[n - 1] += diff;
        break;

      case DistributionType.ascending:
        double ratio = 0;
        for (int i = 1; i <= n; i++) {
          ratio += i;
        }
        for (int i = 0; i < n; i++) {
          amounts.add(((i + 1) / ratio * total).roundToDouble());
        }
        double diff = total - amounts.reduce((a, b) => a + b);
        amounts[n - 1] += diff;
        break;

      case DistributionType.frontLoaded:
        double firstAmount = (total * 0.5).roundToDouble();
        double remaining = total - firstAmount;
        double each = (remaining / (n - 1)).floorToDouble();

        amounts.add(firstAmount);
        for (int i = 1; i < n; i++) {
          amounts.add(i == n - 1 ? remaining - (each * (n - 2)) : each);
        }
        break;
    }

    return amounts;
  }

  // ═══════════════════════════════════════════════════════════════
  // اختيار Template
  // ═══════════════════════════════════════════════════════════════

  void _selectTemplate(InstallmentTemplate template) {
    HapticFeedback.lightImpact();

    setState(() {
      _selectedTemplateId = template.id;

      if (template.isCustom) {
        _showTemplates = false;
        _numberOfInstallments = 3;
        _generateInstallments();
      } else {
        _numberOfInstallments = template.numberOfInstallments;
        _showTemplates = false;
        _generateInstallments();
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // اختيار التواريخ
  // ═══════════════════════════════════════════════════════════════

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              surface: _isDark ? const Color(0xFF1E1E2E) : Colors.white,
              onSurface: _isDark ? Colors.white : Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _startDate) {
      setState(() => _startDate = picked);
      _generateInstallments();
    }
  }

  Future<void> _selectInstallmentDate(int index) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _installments[index].date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              surface: _isDark ? const Color(0xFF1E1E2E) : Colors.white,
              onSurface: _isDark ? Colors.white : Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _installments[index].date = picked);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // إضافة / حذف قسط
  // ═══════════════════════════════════════════════════════════════

  void _addInstallment() {
    HapticFeedback.lightImpact();

    DateTime lastDate =
        _installments.isNotEmpty ? _installments.last.date : _startDate;

    DateTime newDate = DateTime(
      lastDate.year,
      lastDate.month + 1,
      lastDate.day,
    );

    setState(() {
      _installments.add(InstallmentItem(
        amount: 0,
        date: newDate,
      ));
      _numberOfInstallments = _installments.length;
    });
  }

  void _removeInstallment(int index) {
    if (_installments.length <= 1) {
      _showSnackBar('لا يمكن حذف كل الأقساط', isError: true);
      return;
    }

    _showDeleteConfirmation(index);
  }

  void _showDeleteConfirmation(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _isDark ? const Color(0xFF1E1E2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline, color: _errorColor),
            ),
            const SizedBox(width: 12),
            Text(
              'حذف القسط ${index + 1}',
              style: TextStyle(
                color: _isDark ? Colors.white : Colors.black87,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف هذا القسط؟',
          style: TextStyle(
            color: _isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'إلغاء',
              style: TextStyle(
                color: _isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _confirmRemoveInstallment(index);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _errorColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveInstallment(int index) {
    HapticFeedback.mediumImpact();

    setState(() {
      _installments[index].dispose();
      _installments.removeAt(index);
      _numberOfInstallments = _installments.length;
    });

    _showSnackBar('تم حذف القسط');
  }

  // ═══════════════════════════════════════════════════════════════
  // حفظ الأقساط
  // ═══════════════════════════════════════════════════════════════

  Future<void> _saveInstallments() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('يرجى تصحيح الأخطاء أولاً', isError: true);
      return;
    }

    if (!_isValidTotal) {
      _showSnackBar(
        'إجمالي الأقساط لا يساوي المبلغ المطلوب\nالفرق: ${_currencyFormat.format(_difference.abs())} ج.م',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      List<Map<String, dynamic>> installmentsData = _installments.map((inst) {
        return {
          'amount': inst.currentAmount,
          'date': inst.date.toIso8601String(),
        };
      }).toList();

      final result = await ApiService.createInstallments(
        financeId: widget.financeId,
        installments: installmentsData,
        userAdd: widget.currentUser,
        addTime: DateTime.now(),
      );

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        _showSnackBar(result['message'] ?? 'تم حفظ الأقساط بنجاح');
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        _showSnackBar(result['message'] ?? 'حدث خطأ', isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('خطأ: $e', isError: true);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SnackBar
  // ═══════════════════════════════════════════════════════════════

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? _errorColor : _successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          _isDark ? const Color(0xFF0F0F1E) : const Color(0xFFF8FAFC),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildHeader(),
                  if (_showTemplates)
                    _buildTemplatesSection()
                  else
                    _buildInstallmentsSection(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _showTemplates ? null : _buildBottomBar(),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SLIVER APP BAR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: _isDark ? const Color(0xFF1A1A2E) : Colors.white,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: _isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
      title: Text(
        'تقسيط الاشتراك',
        style: TextStyle(
          color: _isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        if (!_showTemplates)
          IconButton(
            onPressed: () => setState(() => _showTemplates = true),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.dashboard_customize_rounded,
                size: 18,
                color: _primaryColor,
              ),
            ),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _headerAnimation,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1),
              Color(0xFF8B5CF6),
              Color(0xFFA855F7),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // أيقونة
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.payments_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),

            // اسم الطفل
            Text(
              widget.childName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // المبلغ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: Colors.purple.shade700,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${_currencyFormat.format(widget.totalAmount)} ج.م',
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.purple.shade700,
                      fontWeight: FontWeight.bold,
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

  // ═══════════════════════════════════════════════════════════════
  // TEMPLATES SECTION
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTemplatesSection() {
    final templates = InstallmentTemplate.getTemplates(widget.totalAmount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.style_rounded,
                  color: _primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'اختر خطة التقسيط',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              return _buildTemplateCard(templates[index], index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(InstallmentTemplate template, int index) {
    final isSelected = _selectedTemplateId == template.id;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: GestureDetector(
        onTap: () => _selectTemplate(template),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? template.color.withOpacity(0.15)
                : (_isDark ? const Color(0xFF1E1E2E) : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? template.color : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? template.color.withOpacity(0.2)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: template.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(template.icon, color: template.color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                template.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                template.description,
                style: TextStyle(
                  fontSize: 11,
                  color: _isDark ? Colors.grey[500] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // INSTALLMENTS SECTION
  // ═══════════════════════════════════════════════════════════════

  Widget _buildInstallmentsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      child: Column(
        children: [
          _buildProgressCard(),
          const SizedBox(height: 20),
          _buildSettingsCard(),
          const SizedBox(height: 20),
          _buildDistributionSelector(),
          const SizedBox(height: 20),
          _buildInstallmentsList(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PROGRESS CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              Text(
                'نسبة التغطية',
                style: TextStyle(
                  fontSize: 14,
                  color: _isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _progressColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(_progressValue * 100).clamp(0, 150).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: _progressColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: _progressValue.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 14,
                  backgroundColor:
                      _isDark ? Colors.grey[800] : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(_progressColor),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProgressDetail('المطلوب',
                  '${_currencyFormat.format(widget.totalAmount)} ج.م'),
              _buildProgressDetail(
                  'الأقساط', '${_currencyFormat.format(_totalInstallments)} ج.م'),
              _buildProgressDetail(
                'الفرق',
                '${_currencyFormat.format(_difference.abs())} ج.م',
                color: _progressColor,
              ),
            ],
          ),

          if (_isValidTotal) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: _successColor, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'المبلغ مغطى بالكامل ✓',
                    style: TextStyle(
                      color: _successColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressDetail(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: _isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color ?? (_isDark ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SETTINGS CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'عدد الأقساط',
                      style: TextStyle(
                        fontSize: 13,
                        color: _isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: _isDark ? Colors.grey[800] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              _isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      child: DropdownButton<int>(
                        value: _numberOfInstallments,
                        isExpanded: true,
                        underline: const SizedBox(),
                        dropdownColor:
                            _isDark ? const Color(0xFF1E1E2E) : Colors.white,
                        style: TextStyle(
                          color: _isDark ? Colors.white : Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        items: List.generate(12, (i) => i + 1)
                            .map((n) => DropdownMenuItem(
                                  value: n,
                                  child: Text('$n'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _numberOfInstallments = value);
                            _generateInstallments();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تاريخ أول قسط',
                      style: TextStyle(
                        fontSize: 13,
                        color: _isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectStartDate,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: _isDark ? Colors.grey[800] : Colors.grey[50],
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color:
                                _isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _dateFormat.format(_startDate),
                              style: TextStyle(
                                color: _isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color:
                                  _isDark ? Colors.grey[400] : Colors.grey[600],
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _generateInstallments,
                  icon: const Icon(Icons.autorenew_rounded, size: 18),
                  label: const Text('توزيع تلقائي'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryColor,
                    side: const BorderSide(color: _primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addInstallment,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('إضافة قسط'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _successColor,
                    side: const BorderSide(color: _successColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DISTRIBUTION SELECTOR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildDistributionSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'نوع التوزيع',
            style: TextStyle(
              fontSize: 13,
              color: _isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: DistributionType.values.map((type) {
              final isSelected = _distributionType == type;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _distributionType = type);
                    _generateInstallments();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _primaryColor
                          : (_isDark ? Colors.grey[800] : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          type.icon,
                          size: 20,
                          color: isSelected
                              ? Colors.white
                              : (_isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          type.arabicName,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (_isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // INSTALLMENTS LIST
  // ═══════════════════════════════════════════════════════════════

  Widget _buildInstallmentsList() {
    return Column(
      children: _installments.asMap().entries.map((entry) {
        final index = entry.key;
        final inst = entry.value;
        return _buildInstallmentCard(inst, index);
      }).toList(),
    );
  }

  Widget _buildInstallmentCard(InstallmentItem inst, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: inst.amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  labelText: 'المبلغ',
                  labelStyle: TextStyle(
                    color: _isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                  suffixText: 'ج.م',
                  suffixStyle: TextStyle(
                    color: _isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                  filled: true,
                  fillColor: _isDark ? Colors.grey[800] : Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _primaryColor, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _errorColor, width: 1),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'مطلوب';
                  final amount = double.tryParse(value);
                  if (amount == null) return 'رقم غير صحيح';
                  if (amount <= 0) return 'يجب أن يكون أكبر من صفر';
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: InkWell(
                onTap: () => _selectInstallmentDate(index),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _isDark ? Colors.grey[800] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: _isDark
                            ? const Color(0xFF818CF8)
                            : _primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _dateFormat.format(inst.date),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: _errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () => _removeInstallment(index),
                icon: const Icon(Icons.delete_outline_rounded),
                color: _errorColor,
                iconSize: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // BOTTOM BAR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF1A1A2E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: (_isLoading || !_isValidTotal) ? null : _saveInstallments,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isValidTotal
                  ? [_primaryColor, const Color(0xFF8B5CF6)]
                  : [Colors.grey.shade400, Colors.grey.shade500],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isValidTotal
                ? [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isValidTotal
                            ? Icons.check_circle_rounded
                            : Icons.warning_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isValidTotal ? 'حفظ الأقساط' : 'الأقساط غير متطابقة',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}