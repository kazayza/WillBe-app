import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import 'add_task_screen.dart';
import 'customer_interactions_screen.dart';
import 'edit_lead_screen.dart';

class LeadDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> lead;
  const LeadDetailsScreen({super.key, required this.lead});

  @override
  State<LeadDetailsScreen> createState() => _LeadDetailsScreenState();
}

class _LeadDetailsScreenState extends State<LeadDetailsScreen>
    with SingleTickerProviderStateMixin {
  bool _isConverting = false;
  bool _isSpeedDialOpen = false;
  late Map<String, dynamic> _currentLead;
  List<dynamic> _interactions = [];
  bool _isLoadingInteractions = true;
  List<dynamic> _statuses = [];
  bool _isLoadingStatuses = true;
  int _tasksCount = 0;

  late AnimationController _speedDialController;
  late Animation<double> _speedDialAnimation;

  @override
  void initState() {
    super.initState();
    _currentLead = Map<String, dynamic>.from(widget.lead);
    _setupAnimations();
    _loadInteractions();
    _loadStatuses();
    _loadTasksCount();
  }
  
  void _setupAnimations() {
    _speedDialController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _speedDialAnimation = CurvedAnimation(
      parent: _speedDialController,
      curve: Curves.easeOut,
    );
  }
  
  // ============================================
// ✅ جلب التفاعلات من API
// ============================================

Future<void> _loadInteractions() async {
  final leadId = _currentLead['LeadID'];
  if (leadId == null) return;

  setState(() => _isLoadingInteractions = true);

  try {
    final data = await ApiService.get('interactions/lead/$leadId');
    if (mounted) {
      setState(() {
        _interactions = data is List ? data : [];
        _isLoadingInteractions = false;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() => _isLoadingInteractions = false);
      debugPrint('Error loading interactions: $e');
    }
  }
}

// ============================================
// ✅ جلب الحالات من API
// ============================================

Future<void> _loadStatuses() async {
  try {
    final data = await ApiService.get('lead-statuses');
    if (mounted) {
      setState(() {
        _statuses = data is List ? data : [];
        _isLoadingStatuses = false;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() => _isLoadingStatuses = false);
      debugPrint('Error loading statuses: $e');
    }
  }
}

  @override
  void dispose() {
    _speedDialController.dispose();
    super.dispose();
  }


// ============================================
// ✅ جلب عدد المهام
// ============================================

Future<void> _loadTasksCount() async {
  final leadId = _currentLead['LeadID'];
  if (leadId == null) return;

  try {
    final data = await ApiService.get('tasks/lead/$leadId/count');
    if (mounted) {
      setState(() {
        _tasksCount = data['count'] ?? 0;
      });
    }
  } catch (e) {
    debugPrint('Error loading tasks count: $e');
  }
}

  // ============================================
// ✅ Next Follow Up Card
// ============================================

Widget _buildNextFollowUpCard(bool isDark) {
  final nextFollowUpStr = _currentLead['NextFollowUp']?.toString();
  
  // لو مفيش تاريخ متابعة
  if (nextFollowUpStr == null || nextFollowUpStr.isEmpty) {
    return const SizedBox.shrink(); // مش هيظهر حاجة
  }

  DateTime? nextFollowUp;
  try {
    nextFollowUp = DateTime.parse(nextFollowUpStr);
  } catch (_) {
    return const SizedBox.shrink();
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final followUpDate = DateTime(nextFollowUp.year, nextFollowUp.month, nextFollowUp.day);

  // تحديد الحالة
  bool isOverdue = followUpDate.isBefore(today);
  bool isToday = followUpDate.isAtSameMomentAs(today);
  
  // الألوان حسب الحالة
  Color cardColor;
  Color iconBgColor;
  IconData statusIcon;
  String statusText;
  
  if (isOverdue) {
    cardColor = const Color(0xFFEF4444);
    iconBgColor = const Color(0xFFEF4444);
    statusIcon = Icons.warning_rounded;
    statusText = "متأخر!";
  } else if (isToday) {
    cardColor = const Color(0xFFF59E0B);
    iconBgColor = const Color(0xFFF59E0B);
    statusIcon = Icons.today_rounded;
    statusText = "اليوم";
  } else {
    cardColor = const Color(0xFF10B981);
    iconBgColor = const Color(0xFF10B981);
    statusIcon = Icons.event_rounded;
    statusText = "قادم";
  }

  return Container(
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF252836) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: cardColor.withOpacity(0.3),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: cardColor.withOpacity(0.15),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          // الشريط الجانبي
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
                  colors: [cardColor, cardColor.withOpacity(0.5)],
                ),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // الأيقونة
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [iconBgColor, iconBgColor.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: iconBgColor.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    statusIcon,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // المحتوى
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "موعد المتابعة",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusText,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('EEEE، d MMMM yyyy', 'ar').format(nextFollowUp),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('h:mm a', 'ar').format(nextFollowUp),
                        style: TextStyle(
                          fontSize: 13,
                          color: cardColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // أيقونة السهم
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.notifications_active_rounded,
                    color: cardColor,
                    size: 22,
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
  // ============================================
  // ✅ دوال الاتصال والواتساب
  // ============================================

  Future<void> _makePhoneCall(String phone) async {
    final Uri uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showSnackBar('لا يمكن إجراء المكالمة', isError: true);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '20${cleanPhone.substring(1)}';
    }
    final Uri uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar('لا يمكن فتح واتساب', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
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
              child: Icon(
                isError ? Icons.error_outline : Icons.check_circle,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _toggleSpeedDial() {
    setState(() {
      _isSpeedDialOpen = !_isSpeedDialOpen;
      if (_isSpeedDialOpen) {
        _speedDialController.forward();
      } else {
        _speedDialController.reverse();
      }
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'New':
        return const Color(0xFFF59E0B);
      case 'Contacted':
        return const Color(0xFF3B82F6);
      case 'Interested':
        return const Color(0xFF8B5CF6);
      case 'Not Interested':
        return const Color(0xFFEF4444);
      case 'Follow Up':
        return const Color(0xFFEC4899);
      case 'Converted':
        return const Color(0xFF10B981);
      case 'Lost':
        return const Color(0xFF6B7280);
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'New':
        return 'جديد';
      case 'Contacted':
        return 'تم التواصل';
      case 'Interested':
        return 'مهتم';
      case 'Not Interested':
        return 'غير مهتم';
      case 'Follow Up':
        return 'متابعة';
      case 'Converted':
        return 'تم التحويل';
      case 'Lost':
        return 'خسرناه';
      default:
        return 'غير معروف';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'New':
        return Icons.fiber_new_rounded;
      case 'Contacted':
        return Icons.phone_callback_rounded;
      case 'Interested':
        return Icons.thumb_up_rounded;
      case 'Not Interested':
        return Icons.thumb_down_rounded;
      case 'Follow Up':
        return Icons.schedule_rounded;
      case 'Converted':
        return Icons.check_circle_rounded;
      case 'Lost':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  // ============================================
// ✅ تحويل Lead إلى Customer - مربوط بالـ API
// ============================================

Future<void> _convertToCustomer() async {
  final status = _currentLead['Status']?.toString() ?? 'New';
  final leadId = _currentLead['LeadID'];

  // التحقق من الحالة
  if (status == 'Converted') {
    _showSnackBar('تم التحويل بالفعل', isError: true);
    return;
  }

  if (leadId == null) {
    _showSnackBar('خطأ: لا يمكن تحديد العميل', isError: true);
    return;
  }

  // تأكيد التحويل
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      return AlertDialog(
        backgroundColor: isDark ? const Color(0xFF252836) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF10B981), size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'تأكيد التحويل',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد من تحويل "${_currentLead['FullName']}" إلى عميل فعلي؟',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'إلغاء',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'تأكيد التحويل',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    },
  );

  if (confirm != true) return;

  // بدء التحويل
  setState(() => _isConverting = true);

  try {
    // استدعاء API التحويل
    final response = await ApiService.post('leads/$leadId/convert', {
      'userAdd': 'User', // ✅ ممكن تجيبه من AuthProvider
      'clientTime': DateTime.now().toIso8601String(),
    });

    if (mounted) {
      setState(() {
        _isConverting = false;
        _currentLead['Status'] = 'Converted';
      });

      // عرض رسالة النجاح
      _showSuccessDialog(
        customerId: response['newCustomerId'],
      );
    }
  } catch (e) {
    if (mounted) {
      setState(() => _isConverting = false);
      _showSnackBar('فشل التحويل: $e', isError: true);
    }
  }
}

  // ============================================
// ✅ Success Dialog - معدّل
// ============================================

void _showSuccessDialog({int? customerId}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        backgroundColor: isDark
            ? const Color(0xFF252836).withOpacity(0.95)
            : Colors.white.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF10B981).withOpacity(0.2),
                      const Color(0xFF10B981).withOpacity(0.1),
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
                    Icons.celebration_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'تم التحويل بنجاح! 🎉',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'تم تحويل العميل المحتمل إلى عميل فعلي',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            if (customerId != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'رقم العميل: $customerId',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6366F1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
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
                    Navigator.pop(context, true); // الرجوع مع تحديث
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
                    'رائع!',
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
    ),
  );
}


// ============================================
// ✅ فتح شاشة تعديل Lead
// ============================================

void _openEditLead() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => EditLeadScreen(lead: _currentLead),
    ),
  ).then((result) {
    if (result == true) {
      // ✅ تحديث البيانات بعد التعديل
      _refreshLeadData();
    }
  });
}

Future<void> _refreshLeadData() async {
  final leadId = _currentLead['LeadID'];
  if (leadId == null) return;

  try {
    final data = await ApiService.get('leads/$leadId');
    if (mounted && data != null) {
      setState(() {
        _currentLead = Map<String, dynamic>.from(data);
      });
      _loadInteractions();
      _loadTasksCount();
    }
  } catch (e) {
    debugPrint('Error refreshing lead: $e');
  }
}



// ============================================
// ✅ تغيير حالة الـ Lead - من API
// ============================================


void _showChangeStatusSheet() {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final currentStatus = _currentLead['Status']?.toString() ?? 'New';

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252836) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.swap_vert_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "تغيير الحالة",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        "اختر الحالة الجديدة للعميل",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),

            // Loading State
            if (_isLoadingStatuses)
              const Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              )
            // Status Options
            else
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: _statuses.map((status) {
                    final statusName = status['StatusName']?.toString() ?? '';
                    final statusLabel = status['StatusLabel']?.toString() ?? '';
                    final statusColor = _parseColor(status['StatusColor']?.toString());
                    final isSelected = currentStatus == statusName;
                    final isConverted = currentStatus == 'Converted';

                    return GestureDetector(
                      onTap: isConverted
                          ? null
                          : () => _updateLeadStatus(statusName, ctx),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? statusColor.withOpacity(0.15)
                              : (isDark ? const Color(0xFF1E1E2E) : Colors.grey[50]),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? statusColor : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [statusColor, statusColor.withOpacity(0.7)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getStatusIcon(statusName),
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            // ملاحظة لو محوّل
            if (currentStatus == 'Converted')
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_rounded, color: Color(0xFF10B981), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "تم تحويل هذا العميل بالفعل ولا يمكن تغيير حالته",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
          ],
        ),
      );
    },
  );
}

// ✅ دالة تحويل اللون من Hex
Color _parseColor(String? hexColor) {
  if (hexColor == null || hexColor.isEmpty) {
    return const Color(0xFF6366F1);
  }
  try {
    return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
  } catch (_) {
    return const Color(0xFF6366F1);
  }
}

Future<void> _updateLeadStatus(String newStatus, BuildContext sheetContext) async {
  final leadId = _currentLead['LeadID'];
  if (leadId == null) return;

  Navigator.pop(sheetContext); // إغلاق الـ Bottom Sheet

  try {
    await ApiService.patch('lead-statuses/leads/$leadId', {
      'status': newStatus,
      'useredit': 'User', // ✅ ممكن تجيبه من AuthProvider
      'clientTime': DateTime.now().toIso8601String(),
    });

    if (mounted) {
      setState(() {
        _currentLead['Status'] = newStatus;
      });
      _showSnackBar('تم تحديث الحالة بنجاح ✅');
    }
  } catch (e) {
    if (mounted) {
      _showSnackBar('فشل تحديث الحالة: $e', isError: true);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = _currentLead['Status']?.toString() ?? 'New';
    final statusColor = _getStatusColor(status);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(isDark, status, statusColor),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildQuickStats(isDark),
                      const SizedBox(height: 16),
                      _buildNextFollowUpCard(isDark),
                      const SizedBox(height: 16),
                      _buildDetailsCard(isDark),
                      const SizedBox(height: 16),
                      _buildUserInfoCard(isDark),
                      const SizedBox(height: 16),
                      _buildNotesCard(isDark),
                      const SizedBox(height: 16),
                      _buildInteractionsTimelineCard(isDark),
                      const SizedBox(height: 24),
                      _buildConvertButton(status),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // ✅ Speed Dial Overlay
          if (_isSpeedDialOpen)
            GestureDetector(
              onTap: _toggleSpeedDial,
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          // ✅ Speed Dial Buttons
          _buildSpeedDial(isDark),
        ],
      ),
    );
  }

  // ============================================
  // ✅ Sliver AppBar
  // ============================================

  Widget _buildSliverAppBar(bool isDark, String status, Color statusColor) {
    final name = _currentLead['FullName']?.toString() ?? '---';
    final phone = _currentLead['Phone']?.toString() ?? '';

    return SliverAppBar(
      expandedHeight: 200,
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
        onPressed: () => Navigator.pop(context, true),
      ),
        actions: [
  // ✅ زر التعديل
  IconButton(
    icon: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
    ),
    onPressed: _openEditLead,
    tooltip: 'تعديل البيانات',
  ),
  // زر تغيير الحالة
  IconButton(
    icon: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.swap_vert_rounded, color: Colors.white, size: 20),
    ),
    onPressed: _showChangeStatusSheet,
    tooltip: 'تغيير الحالة',
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
              // الدوائر الديكورية
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
                bottom: 50,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              // المحتوى
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Avatar
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.1)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                          ),
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : "?",
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // الاسم والتليفون
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_getStatusIcon(status), color: Colors.white, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getStatusText(status),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              // الاسم
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              // رقم التليفون
                              if (phone.isNotEmpty)
                                Text(
                                  phone,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 15,
                                  ),
                                ),
                            ],
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
      ),
    );
  }

  // ============================================
  // ✅ Quick Stats
  // ============================================

  Widget _buildQuickStats(bool isDark) {
  final createdAt = _currentLead['CreatedAt'];

  int daysSinceCreation = 0;
  if (createdAt != null) {
    try {
      final created = DateTime.parse(createdAt.toString());
      daysSinceCreation = DateTime.now().difference(created).inDays;
    } catch (_) {}
  }

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF252836) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: _buildStatItem(
            icon: Icons.timer_rounded,
            label: "منذ التسجيل",
            value: "$daysSinceCreation يوم",
            color: const Color(0xFF6366F1),
            isDark: isDark,
          ),
        ),
        Container(width: 1, height: 50, color: isDark ? Colors.grey[700] : Colors.grey[300]),
        Expanded(
          child: _buildStatItem(
            icon: Icons.chat_bubble_rounded,
            label: "عدد التواصلات",
            value: "${_interactions.length}", // ✅ من المتغير الجديد
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),
        ),
        Container(width: 1, height: 50, color: isDark ? Colors.grey[700] : Colors.grey[300]),
        Expanded(
          child: _buildStatItem(
            icon: Icons.task_alt_rounded,
            label: "المهام",
            value: "$_tasksCount", // ✅ هنعدله بعدين لما نجيب المهام
            color: const Color(0xFFF59E0B),
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
            gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ============================================
  // ✅ Details Card
  // ============================================

  Widget _buildDetailsCard(bool isDark) {
    final source = (_currentLead['SourceName'] ?? _currentLead['LeadSource'] ?? 'غير محدد').toString();
    final program = (_currentLead['InterestedProgram'] ?? 'غير محدد').toString();
    final childAge = _currentLead['ChildAge']?.toString();
    final branchName = (_currentLead['BranchName'] ?? '').toString().trim();
    final assignedToName = (_currentLead['AssignedToName'] ?? '').toString().trim();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(
              icon: Icons.info_rounded,
              title: "معلومات تفصيلية",
              colors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
              isDark: isDark,
            ),
            const SizedBox(height: 18),
            _buildDetailRow(icon: Icons.campaign_rounded, label: "مصدر المعرفة", value: source, color: const Color(0xFF3B82F6), isDark: isDark),
            const SizedBox(height: 12),
            _buildDetailRow(icon: Icons.school_rounded, label: "البرنامج المهتم به", value: program, color: const Color(0xFF8B5CF6), isDark: isDark),
            if (childAge != null && childAge.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDetailRow(icon: Icons.cake_rounded, label: "سن الطفل", value: "$childAge سنة", color: const Color(0xFFEC4899), isDark: isDark),
            ],
            if (branchName.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDetailRow(icon: Icons.location_on_rounded, label: "الفرع المفضّل", value: branchName, color: const Color(0xFFF97316), isDark: isDark),
            ],
            if (assignedToName.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDetailRow(icon: Icons.person_rounded, label: "الموظف المسؤول", value: assignedToName, color: const Color(0xFF06B6D4), isDark: isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader({
    required IconData icon,
    required String title,
    required List<Color> colors,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: colors[0].withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3)),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
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
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // ✅ User Info Card
  // ============================================

  Widget _buildUserInfoCard(bool isDark) {
    final userAdd = _currentLead['userAdd']?.toString();
    final useredit = _currentLead['useredit']?.toString();

    DateTime? addTime;
    final addTimeStr = _currentLead['AddTime']?.toString() ?? _currentLead['Addtime']?.toString();
    if (addTimeStr != null && addTimeStr.isNotEmpty) {
      try {
        addTime = DateTime.parse(addTimeStr);
      } catch (_) {}
    }

    DateTime? editTime;
    final editTimeStr = _currentLead['editTime']?.toString();
    if (editTimeStr != null && editTimeStr.isNotEmpty) {
      try {
        editTime = DateTime.parse(editTimeStr);
      } catch (_) {}
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(
              icon: Icons.history_rounded,
              title: "سجل التعديلات",
              colors: [const Color(0xFF10B981), const Color(0xFF059669)],
              isDark: isDark,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _buildUserInfoItem(
                    icon: Icons.person_add_rounded,
                    label: 'أضافه',
                    userName: userAdd,
                    dateTime: addTime,
                    color: const Color(0xFF10B981),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildUserInfoItem(
                    icon: Icons.edit_rounded,
                    label: 'عدّله',
                    userName: useredit,
                    dateTime: editTime,
                    color: const Color(0xFFF59E0B),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoItem({
    required IconData icon,
    required String label,
    required String? userName,
    required DateTime? dateTime,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          const SizedBox(height: 4),
          Text(
            userName ?? '---',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          if (dateTime != null) ...[
            const SizedBox(height: 6),
            Text(
              DateFormat('d/M/yyyy - h:mm a').format(dateTime),
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  // ============================================
  // ✅ Notes Card
  // ============================================

  Widget _buildNotesCard(bool isDark) {
    final notes = _currentLead['Notes']?.toString().trim();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(
              icon: Icons.note_alt_rounded,
              title: "ملاحظات",
              colors: [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
              isDark: isDark,
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.1)),
              ),
              child: notes == null || notes.isEmpty
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notes_rounded, color: Colors.grey[400], size: 18),
                        const SizedBox(width: 10),
                        Text(
                          "لا توجد ملاحظات مضافة",
                          style: TextStyle(fontSize: 13, color: Colors.grey[500], fontStyle: FontStyle.italic),
                        ),
                      ],
                    )
                  : Text(
                      notes,
                      style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[300] : Colors.grey[800], height: 1.6),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
// ✅ Interactions Timeline Card - معدّل
// ============================================

Widget _buildInteractionsTimelineCard(bool isDark) {
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
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.timeline_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "سجل التواصل",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      "${_interactions.length} تفاعل",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CustomerInteractionsScreen(
                        customerId: 0,
                        leadId: _currentLead['LeadID'],
                        customerName: _currentLead['FullName'] ?? '',
                      ),
                    ),
                  ).then((_) => _loadInteractions()); // ✅ Refresh بعد الرجوع
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        "عرض الكل",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6366F1),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF6366F1)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // ✅ Loading State
          if (_isLoadingInteractions)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          // ✅ Empty State
          else if (_interactions.isEmpty)
            _buildEmptyTimeline(isDark)
          // ✅ عرض التفاعلات
          else
            Column(
              children: _interactions
                  .take(4)
                  .map<Widget>((item) => _buildTimelineItem(item, isDark))
                  .toList(),
            ),
        ],
      ),
    ),
  );
}

  Widget _buildTimelineItem(dynamic item, bool isDark) {
  // ✅ قراءة البيانات من الـ API response
  final type = (item['InteractionType'] ?? 'Other').toString();
  final subject = (item['Subject'] ?? '').toString();
  final details = (item['Details'] ?? '').toString();
  final outcome = (item['Outcome'] ?? '').toString();
  
  DateTime? date;
  try {
    final dateStr = item['InteractionDate']?.toString();
    if (dateStr != null) {
      date = DateTime.parse(dateStr);
    }
  } catch (_) {}

  // تحديد اللون والأيقونة حسب النوع
  Color typeColor;
  IconData typeIcon;
  String typeLabel;

  switch (type) {
    case 'Call':
      typeColor = const Color(0xFF10B981);
      typeIcon = Icons.call_rounded;
      typeLabel = 'مكالمة';
      break;
    case 'WhatsApp':
      typeColor = const Color(0xFF25D366);
      typeIcon = Icons.chat_rounded;
      typeLabel = 'واتساب';
      break;
    case 'Email':
      typeColor = const Color(0xFF3B82F6);
      typeIcon = Icons.email_rounded;
      typeLabel = 'إيميل';
      break;
    case 'Visit':
      typeColor = const Color(0xFFF59E0B);
      typeIcon = Icons.location_on_rounded;
      typeLabel = 'زيارة';
      break;
    default:
      typeColor = const Color(0xFF6366F1);
      typeIcon = Icons.chat_bubble_rounded;
      typeLabel = type;
  }

  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [typeColor, typeColor.withOpacity(0.7)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: typeColor.withOpacity(0.4), blurRadius: 6),
                ],
              ),
              child: Icon(typeIcon, color: Colors.white, size: 14),
            ),
            Container(
              width: 2,
              height: 40,
              color: typeColor.withOpacity(0.3),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: typeColor.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: typeColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (date != null)
                      Text(
                        DateFormat('d/M/yyyy').format(date),
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                  ],
                ),
                if (subject.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    subject,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    details,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (outcome.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flag_rounded, size: 12, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Text(
                          outcome,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    if (date != null)
                      Text(
                        DateFormat('h:mm a').format(date),
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildEmptyTimeline(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chat_bubble_outline_rounded, size: 40, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text(
            "لا يوجد تواصل مسجل بعد",
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "ابدأ بإضافة أول تواصل مع العميل",
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ============================================
  // ✅ Speed Dial
  // ============================================

  Widget _buildSpeedDial(bool isDark) {
    final phone = _currentLead['Phone']?.toString() ?? '';

    return Positioned(
      bottom: 20,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // الأزرار المنبثقة
          ScaleTransition(
            scale: _speedDialAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // إضافة مهمة
                _buildSpeedDialItem(
                  icon: Icons.add_task_rounded,
                  label: "إضافة مهمة",
                  color: const Color(0xFF3B82F6),
                  onTap: () {
                    _toggleSpeedDial();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddTaskScreen(
                          leadId: _currentLead['LeadID'],
                          leadName: _currentLead['FullName'],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                // إضافة تواصل
_buildSpeedDialItem(
  icon: Icons.message_rounded,
  label: "إضافة تواصل",
  color: const Color(0xFF8B5CF6),
  onTap: () {
    _toggleSpeedDial();
    // ✅ فتح شاشة التواصلات
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerInteractionsScreen(
          customerId: 0,
          leadId: _currentLead['LeadID'],
          customerName: _currentLead['FullName'] ?? '',
        ),
      ),
    ).then((_) => _loadInteractions()); // Refresh بعد الرجوع
  },
),
                const SizedBox(height: 12),
                // واتساب
                if (phone.isNotEmpty)
                  _buildSpeedDialItem(
                    icon: Icons.chat_rounded, // أيقونة الواتساب
                    label: "واتساب",
                    color: const Color(0xFF25D366),
                    onTap: () {
                      _toggleSpeedDial();
                      _openWhatsApp(phone);
                    },
                  ),
                if (phone.isNotEmpty) const SizedBox(height: 12),
                // اتصال
                if (phone.isNotEmpty)
                  _buildSpeedDialItem(
                    icon: Icons.call_rounded,
                    label: "اتصال",
                    color: const Color(0xFF10B981),
                    onTap: () {
                      _toggleSpeedDial();
                      _makePhoneCall(phone);
                    },
                  ),
                if (phone.isNotEmpty) const SizedBox(height: 16),
              ],
            ),
          ),
          // الزر الرئيسي
          GestureDetector(
            onTap: _toggleSpeedDial,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isSpeedDialOpen
                      ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                      : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: (_isSpeedDialOpen ? const Color(0xFFEF4444) : const Color(0xFF6366F1)).withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: AnimatedRotation(
                turns: _isSpeedDialOpen ? 0.125 : 0,
                duration: const Duration(milliseconds: 300),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedDialItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  // ============================================
  // ✅ Convert Button
  // ============================================

  Widget _buildConvertButton(String status) {
    final enabled = status.toLowerCase() != 'converted';

    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: enabled
            ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
            : LinearGradient(colors: [Colors.grey[400]!, Colors.grey[500]!]),
        boxShadow: enabled
            ? [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))]
            : null,
      ),
      child: ElevatedButton(
        onPressed: enabled && !_isConverting ? _convertToCustomer : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: _isConverting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white.withOpacity(0.8), strokeWidth: 2.5),
                  ),
                  const SizedBox(width: 12),
                  const Text("جاري التحويل...", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
                    child: Icon(
                      enabled ? Icons.person_add_alt_1_rounded : Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    enabled ? "تحويل إلى عميل (ولي أمر)" : "تم التحويل بالفعل ✓",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
      ),
    );
  }
}