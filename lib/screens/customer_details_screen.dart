import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'add_task_screen.dart';
import 'customer_interactions_screen.dart';
import 'edit_customer_screen.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> customer;

  const CustomerDetailsScreen({
    super.key,
    required this.customer,
  });

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  Map<String, dynamic> get customer => widget.customer;
  List<dynamic> _children = [];
  bool _isLoadingChildren = true;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    final customerId = customer['CustomerID'];
    if (customerId == null) return;

    try {
      final data = await ApiService.get('customer-children/customer/$customerId');
      if (mounted) {
        setState(() {
          _children = data is List ? data : [];
          _isLoadingChildren = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingChildren = false);
      debugPrint('Error loading children: $e');
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatDate(dynamic date) {
    if (date == null) return '---';
    try {
      final d = DateTime.parse(date.toString()).toLocal();
      return '${d.day}/${d.month}/${d.year} - ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return date.toString();
    }
  }

  String _getRelativeTime(dynamic date) {
    if (date == null) return '';
    try {
      final d = DateTime.parse(date.toString()).toLocal();
      final now = DateTime.now();
      final diff = now.difference(d);

      if (diff.inDays > 365) {
        return 'منذ ${(diff.inDays / 365).floor()} سنة';
      } else if (diff.inDays > 30) {
        return 'منذ ${(diff.inDays / 30).floor()} شهر';
      } else if (diff.inDays > 0) {
        return 'منذ ${diff.inDays} يوم';
      } else {
        return 'اليوم';
      }
    } catch (_) {
      return '';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return const Color(0xFF10B981);
      case 'Inactive':
        return const Color(0xFFF97316);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Active':
        return Icons.check_circle_rounded;
      case 'Inactive':
        return Icons.pause_circle_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'Active':
        return 'نشط';
      case 'Inactive':
        return 'غير نشط';
      default:
        return status;
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('لا يمكن إجراء المكالمة: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '2$cleanPhone'; // مصر
    }
    
    final Uri uri = Uri.parse('https://wa.me/$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('لا يمكن فتح واتساب: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

      void _openEditCustomer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditCustomerScreen(customer: widget.customer),
      ),
    ).then((result) {
      if (result == true) {
        // ✅ لو تم التعديل، نرجع للشاشة اللي قبلها عشان تعمل Refresh
        // أو ممكن نعمل Refresh هنا لو الشاشة دي Stateful وبتجيب داتا من API
        Navigator.pop(context); // ده الحل الأسهل حالياً (يرجع للقائمة)
      }
    });
  }

   void _showChangeStatusSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentStatus = widget.customer['Status']?.toString() ?? 'Active';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252836) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "تغيير حالة العميل",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              _buildStatusOption(
                label: "نشط",
                value: "Active",
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF10B981),
                isSelected: currentStatus == "Active",
                isDark: isDark,
                ctx: ctx,
              ),
              const SizedBox(height: 12),
              _buildStatusOption(
                label: "غير نشط",
                value: "Inactive",
                icon: Icons.pause_circle_rounded,
                color: const Color(0xFFF97316),
                isSelected: currentStatus == "Inactive",
                isDark: isDark,
                ctx: ctx,
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusOption({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required bool isDark,
    required BuildContext ctx,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(ctx);
        _updateStatus(value);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.1)
              : (isDark ? const Color(0xFF1E1E2E) : Colors.grey[100]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(String newStatus) async {
    final customerId = widget.customer['CustomerID'];
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final useredit = authProvider.user?.fullName ?? 'Unknown';
    final clientTime = DateTime.now().toIso8601String();

    try {
      // ✅ لاحظ: بنستخدم PUT لأن مفيش PATCH للعملاء حالياً
      // بنبعت كل البيانات القديمة مع الحالة الجديدة
      final updatedData = Map<String, dynamic>.from(widget.customer);
      updatedData['status'] = newStatus; // الاسم في الـ API small 'status'
      
      // لازم نغير أسماء الحقول لتطابق الـ API (CamelCase)
      final apiData = {
        'fullName': updatedData['FullName'],
        'phone': updatedData['Phone'],
        'secondaryPhone': updatedData['SecondaryPhone'],
        'email': updatedData['Email'],
        'address': updatedData['Address'],
        'notes': updatedData['Notes'],
        'status': newStatus,
        'useredit': useredit,
        'clientTime': clientTime,
      };

      await ApiService.put('customers/$customerId', apiData);

      if (mounted) {
        setState(() {
          widget.customer['Status'] = newStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الحالة بنجاح ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل التحديث: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;

    final name = (customer['FullName'] ?? '---').toString();
    final phone = (customer['Phone'] ?? '---').toString();
    final email = (customer['Email'] ?? '').toString().trim();
    final status = (customer['Status'] ?? 'Active').toString();
    final statusColor = _getStatusColor(status);
    final createdAt = _formatDate(customer['CreatedAt']);
    final relativeTime = _getRelativeTime(customer['CreatedAt']);
    final customerId = customer['CustomerID'] as int?;
    final childrenCount = _children.length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(isDark, name, status, statusColor),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildAnimatedCard(
                      index: 0,
                      child: _buildQuickStats(isDark, status, statusColor, relativeTime, childrenCount),
                    ),
                    const SizedBox(height: 16),
                    _buildAnimatedCard(
                      index: 1,
                      child: _buildContactCard(isDark, phone, email),
                    ),
                    const SizedBox(height: 16),
                    _buildAnimatedCard(
                      index: 2,
                      child: _buildChildrenCard(isDark),
                    ),
                    const SizedBox(height: 16),
                    _buildAnimatedCard(
                      index: 3,
                      child: _buildDetailsCard(isDark, createdAt, statusColor),
                    ),
                    const SizedBox(height: 16),
                    _buildAnimatedCard(
                      index: 4,
                      child: _buildQuickActionsCard(isDark, phone),
                    ),
                    const SizedBox(height: 16),
                    _buildAnimatedCard(
                      index: 5,
                      child: _buildMainActionsCard(isDark, customerId, name),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(bool isDark, String name, String status, Color statusColor) {
    return SliverAppBar(
      expandedHeight: 220,
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
            actions: [
        // ✅ 1. زر التعديل
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
          ),
          onPressed: _openEditCustomer, // بيفتح شاشة التعديل
          tooltip: 'تعديل البيانات',
        ),
        
        const SizedBox(width: 8),

        // ✅ 2. زر الحالة (بقى Clickable)
        GestureDetector(
          onTap: _showChangeStatusSheet, // بيفتح Bottom Sheet لتغيير الحالة
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getStatusIcon(status), color: statusColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  _getStatusText(status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
                right: -80,
                top: -80,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                left: -60,
                bottom: -20,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              Positioned(
                right: 30,
                bottom: 80,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: Row(
                  children: [
                    Hero(
                      tag: 'customer_avatar_${customer['CustomerID']}',
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : "?",
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "👨‍👩‍👧 ولي أمر",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

  Widget _buildAnimatedCard({required int index, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + (index * 100)),
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

  Widget _buildQuickStats(bool isDark, String status, Color statusColor, String relativeTime, int childrenCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: _getStatusIcon(status),
              label: "الحالة",
              value: _getStatusText(status),
              color: statusColor,
              isDark: isDark,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.timer_outlined,
              label: "مدة العضوية",
              value: relativeTime.isNotEmpty ? relativeTime : '---',
              color: const Color(0xFF6366F1),
              isDark: isDark,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.child_care_rounded,
              label: "الأطفال",
              value: childrenCount > 0 ? "$childrenCount طفل" : "---",
              color: const Color(0xFFEC4899),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard(bool isDark, String phone, String email) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                    colors: [
                      const Color(0xFF10B981),
                      const Color(0xFF10B981).withOpacity(0.5),
                    ],
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
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.contact_phone_rounded,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "معلومات الاتصال",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildContactRow(
                    icon: Icons.phone_rounded,
                    value: phone,
                    color: const Color(0xFF10B981),
                    isDark: isDark,
                    onTap: () => _makePhoneCall(phone),
                    actionIcon: Icons.call_rounded,
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildContactRow(
                      icon: Icons.email_rounded,
                      value: email,
                      color: const Color(0xFF3B82F6),
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String value,
    required Color color,
    required bool isDark,
    VoidCallback? onTap,
    IconData? actionIcon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          if (onTap != null && actionIcon != null)
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(actionIcon, color: Colors.white, size: 18),
              ),
            ),
        ],
      ),
    );
  }

  // ✅ كارت الأطفال الجديد
  Widget _buildChildrenCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              right: 0, top: 0, bottom: 0,
              child: Container(
                width: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFFEC4899), const Color(0xFFEC4899).withOpacity(0.5)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEC4899).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.child_care_rounded, color: Color(0xFFEC4899), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "الأطفال المرتبطين",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Color(0xFFEC4899)),
                        onPressed: _showAddChildDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (_isLoadingChildren)
                    const Center(child: CircularProgressIndicator())
                  else if (_children.isEmpty)
                    const Center(child: Text("لا يوجد أطفال مرتبطين", style: TextStyle(color: Colors.grey)))
                  else
                    ..._children.map((child) => _buildChildItem(child, isDark)).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildItem(dynamic child, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFEC4899).withOpacity(0.1),
            child: const Icon(Icons.face, color: Color(0xFFEC4899)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child['ChildName'] ?? 'بدون اسم',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  child['Relationship'] ?? 'ولي أمر',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          if (child['IsPrimary'] == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'أساسي',
                style: TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(bool isDark, String createdAt, Color statusColor) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                    colors: [
                      const Color(0xFF6366F1),
                      const Color(0xFF6366F1).withOpacity(0.5),
                    ],
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
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.info_rounded,
                          color: Color(0xFF6366F1),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "معلومات إضافية",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: "تاريخ التسجيل",
                    value: createdAt,
                    color: const Color(0xFF6366F1),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(bool isDark, String phone) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                    colors: [
                      const Color(0xFF25D366),
                      const Color(0xFF25D366).withOpacity(0.5),
                    ],
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
                          color: const Color(0xFF25D366).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.flash_on_rounded,
                          color: Color(0xFF25D366),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "إجراءات سريعة",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionButton(
                          icon: Icons.call_rounded,
                          label: "اتصال",
                          color: const Color(0xFF10B981),
                          isDark: isDark,
                          onTap: () => _makePhoneCall(phone),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionButton(
                          icon: Icons.chat_rounded,
                          label: "واتساب",
                          color: const Color(0xFF25D366),
                          isDark: isDark,
                          onTap: () => _openWhatsApp(phone),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionButton(
                          icon: Icons.sms_rounded,
                          label: "رسالة",
                          color: const Color(0xFF3B82F6),
                          isDark: isDark,
                          onTap: () {},
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
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.15), color.withOpacity(0.08)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainActionsCard(bool isDark, int? customerId, String name) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                    colors: [
                      const Color(0xFFF59E0B),
                      const Color(0xFFF59E0B).withOpacity(0.5),
                    ],
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
                          color: const Color(0xFFF59E0B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.settings_rounded,
                          color: Color(0xFFF59E0B),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "إدارة العميل",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildMainActionButton(
                    icon: Icons.add_task_rounded,
                    label: "إضافة مهمة متابعة",
                    subtitle: "جدولة مهمة جديدة لهذا العميل",
                    gradient: [const Color(0xFFF59E0B), const Color(0xFFF97316)],
                    onTap: customerId == null
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddTaskScreen(
                                  customerId: customerId,
                                  customerName: name,
                                ),
                              ),
                            );
                          },
                  ),
                  const SizedBox(height: 12),
                  _buildMainActionButton(
                    icon: Icons.history_rounded,
                    label: "سجل التواصل",
                    subtitle: "عرض جميع التفاعلات السابقة",
                    gradient: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                    onTap: customerId == null
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CustomerInteractionsScreen(
                                  customerId: customerId,
                                  customerName: name,
                                ),
                              ),
                            );
                          },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isEnabled
              ? LinearGradient(colors: gradient)
              : LinearGradient(colors: [Colors.grey[400]!, Colors.grey[500]!]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: gradient[0].withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.8),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildDetailRow({
  required IconData icon,
  required String label,
  required String value,
  required Color color,
  required bool isDark,
}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
// ✅ دالة البحث وربط الطفل
void _showAddChildDialog() {
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
                // Handle & Title
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                ),
                Text(
                  "ربط طفل بالعميل",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                
                // Search Field
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "ابحث باسم الطفل...",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search_rounded),
                        onPressed: () async {
                          if (searchController.text.isEmpty) return;
                          setModalState(() => isSearching = true);
                          try {
                            final data = await ApiService.get('customer-children/search-children?query=${searchController.text}');
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

                // Results
                Expanded(
                  child: isSearching
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final child = searchResults[index];
                            return ListTile(
                              title: Text(child['FullNameArabic'] ?? '', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                              subtitle: Text('السن: ${child['Age']} سنوات'),
                              trailing: ElevatedButton(
                                onPressed: () async {
                                  // ✅ استدعاء API الربط
                                  try {
                                    await ApiService.post('customer-children', {
                                      'customerId': widget.customer['CustomerID'],
                                      'childId': child['ChildID'],
                                      'relationship': 'ولي أمر',
                                      'isPrimary': false,
                                    });
                                    Navigator.pop(ctx);
                                    _loadChildren(); // Refresh List
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('تم ربط الطفل بنجاح ✅')),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('فشل الربط: $e')),
                                    );
                                  }
                                },
                                child: const Text("ربط"),
                              ),
                            );
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
}