import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'tasks_list_screen.dart';
import 'all_incomes_screen.dart';
import 'expenses_list_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  static const _primary = Color(0xFF6366F1);
  static const _green = Color(0xFF10B981);
  static const _red = Color(0xFFEF4444);
  static const _orange = Color(0xFFF59E0B);
  static const _blue = Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.userId;

    if (userId != null) {
      final notifications = await ApiService.getNotifications(userId);
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(int notificationId, int index) async {
    await ApiService.markNotificationAsRead(notificationId);
    setState(() {
      _notifications[index]['IsRead'] = true;
    });
  }

  Future<void> _markAllAsRead() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.userId;

    if (userId != null) {
      await ApiService.markAllNotificationsAsRead(userId);
      setState(() {
        for (var notification in _notifications) {
          notification['IsRead'] = true;
        }
      });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'الآن';
      } else if (difference.inMinutes < 60) {
        return 'منذ ${difference.inMinutes} دقيقة';
      } else if (difference.inHours < 24) {
        return 'منذ ${difference.inHours} ساعة';
      } else if (difference.inDays < 7) {
        return 'منذ ${difference.inDays} يوم';
      } else {
        return DateFormat('yyyy/MM/dd').format(date);
      }
    } catch (e) {
      return '';
    }
  }

  String _formatPaymentDate(dynamic date) {
    if (date == null) return '-';
    try {
      DateTime d = DateTime.parse(date.toString());
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return '-';
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'Task':
      case 'TaskReply':
      case 'TaskRead':
        return Icons.task_alt;
      case 'Debt':
        return Icons.warning_rounded;
      case 'Reminder':
        return Icons.notifications_active_rounded;
      case 'DailySummary':
        return Icons.analytics_rounded;
      case 'Income':
        return Icons.arrow_downward_rounded;
      case 'Expense':
        return Icons.arrow_upward_rounded;
      case 'Absence':
        return Icons.person_off_rounded;
      case 'Update':
        return Icons.system_update;
      case 'Broadcast':
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'Task':
      case 'TaskReply':
      case 'TaskRead':
        return _blue;
      case 'Debt':
        return _red;
      case 'Reminder':
        return _orange;
      case 'DailySummary':
        return _primary;
      case 'Income':
        return _green;
      case 'Expense':
        return Colors.red[300]!;
      case 'Absence':
        return Colors.purple;
      case 'Update':
        return _green;
      case 'Broadcast':
        return _orange;
      default:
        return Colors.grey;
    }
  }

  // ═══════════════════════════════════════════════════
  //          التنقل حسب نوع الإشعار
  // ═══════════════════════════════════════════════════
  void _handleNotificationTap(Map<String, dynamic> notification, int index) {
    // تعليم كمقروء
    final isRead = notification['IsRead'] == true || notification['IsRead'] == 1;
    if (!isRead) {
      _markAsRead(notification['NotificationID'], index);
    }

    final relatedTo = notification['RelatedTo']?.toString() ?? '';
    final relatedId = notification['RelatedID'];

    switch (relatedTo) {
      // المهام
      case 'Task':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TasksListScreen()),
        );
        break;

      // الأقساط
      case 'installment':
        if (relatedId != null) {
          _showInstallmentDetails(relatedId);
        }
        break;

      // الإيرادات
      case 'income':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AllIncomesScreen()),
        );
        break;

      // المصروفات
      case 'expense':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ExpensesListScreen()),
        );
        break;

      // بروفايل الطفل - لو عندك شاشة
      // case 'child_profile':
      //   if (relatedId != null) {
      //     Navigator.push(context, MaterialPageRoute(
      //       builder: (context) => ChildProfileScreen(childId: relatedId),
      //     ));
      //   }
      //   break;

      default:
        // مفيش حاجة يفتحها
        break;
    }
  }

  // ═══════════════════════════════════════════════════
  //          Bottom Sheet - تفاصيل القسط
  // ═══════════════════════════════════════════════════
  void _showInstallmentDetails(int installmentId) async {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDark;

    // عرض Loading
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    );

    // جلب البيانات
    final response = await ApiService.getInstallmentDetails(installmentId);

    // قفل الـ Loading
    if (mounted) Navigator.pop(context);

    if (response['success'] != true || response['data'] == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لم يتم العثور على بيانات القسط')),
        );
      }
      return;
    }

    final data = response['data'];

    if (!mounted) return;

    // عرض البيانات
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _buildInstallmentBottomSheet(data, isDark);
      },
    );
  }

  Widget _buildInstallmentBottomSheet(Map<String, dynamic> data, bool isDark) {
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subText = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    String status = data['status'] ?? 'pending';
    String name = data['FullNameArabic'] ?? '';
    double amount = double.tryParse(data['amountPyment']?.toString() ?? '0') ?? 0;
    String branch = data['branchName'] ?? '';
    String type = (data['Kind_subscrip'] ?? '').toString();
    bool isStudy = type.contains('الدراسة');
    int daysLate = data['daysLate'] ?? 0;
    String fatherName = data['FatherName'] ?? '';
    String fatherPhone = data['FatherMobile1'] ?? '';
    String motherName = data['MotherName'] ?? '';
    String motherPhone = data['MotherMobile1'] ?? '';
    double totalSub = double.tryParse(data['totalSubscription']?.toString() ?? '0') ?? 0;
    double totalPaid = double.tryParse(data['totalPaidForChild']?.toString() ?? '0') ?? 0;
    int remainingInst = data['remainingInstallments'] ?? 0;
    int paidInst = data['paidInstallments'] ?? 0;
    String session = data['sessionName'] ?? '';

    // لون الحالة
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'paid':
        statusColor = _green;
        statusText = 'مدفوع ✅';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'overdue':
        statusColor = _red;
        statusText = 'متأخر $daysLate يوم';
        statusIcon = Icons.error_rounded;
        break;
      default:
        statusColor = _orange;
        statusText = 'قادم';
        statusIcon = Icons.schedule_rounded;
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // المقبض
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),

            // أيقونة الحالة
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 36),
            ),
            const SizedBox(height: 12),

            // الحالة
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(statusText,
                  style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
            const SizedBox(height: 20),

            // بيانات الطفل
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('👶', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(name,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.store_rounded, size: 16, color: subText),
                      const SizedBox(width: 6),
                      Text(branch, style: TextStyle(color: subText, fontSize: 13)),
                      const SizedBox(width: 16),
                      Icon(isStudy ? Icons.menu_book_rounded : Icons.directions_bus_rounded,
                          size: 16, color: subText),
                      const SizedBox(width: 6),
                      Text(isStudy ? 'دراسة' : 'باص',
                          style: TextStyle(color: subText, fontSize: 13)),
                    ],
                  ),
                  if (session.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 14, color: subText),
                        const SizedBox(width: 6),
                        Text(session,
                            style: TextStyle(color: subText, fontSize: 12)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // تفاصيل القسط
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _buildInfoRow('💰', 'مبلغ القسط',
                      '$amount ج.م', statusColor, textColor),
                  const Divider(height: 16),
                  _buildInfoRow('📅', 'تاريخ الاستحقاق',
                      _formatPaymentDate(data['MonthPayment']),
                      subText, textColor),
                  const Divider(height: 16),
                  _buildInfoRow('📊', 'إجمالي الاشتراك',
                      '$totalSub ج.م', subText, textColor),
                  const Divider(height: 16),
                  _buildInfoRow('📥', 'إجمالي المسدد',
                      '$totalPaid ج.م', _green, textColor),
                  const Divider(height: 16),
                  _buildInfoRow('📋', 'الأقساط',
                      '$paidInst مدفوع / $remainingInst متبقي',
                      subText, textColor),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // أرقام التواصل
            if (fatherPhone.isNotEmpty || motherPhone.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📞 التواصل مع ولي الأمر',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            fontSize: 14)),
                    const SizedBox(height: 12),
                    if (fatherPhone.isNotEmpty)
                      _buildContactRow(
                          fatherName.isNotEmpty ? fatherName : 'الأب',
                          fatherPhone, isDark),
                    if (fatherPhone.isNotEmpty && motherPhone.isNotEmpty)
                      const SizedBox(height: 8),
                    if (motherPhone.isNotEmpty)
                      _buildContactRow(
                          motherName.isNotEmpty ? motherName : 'الأم',
                          motherPhone, isDark),
                  ],
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String icon, String label, String value,
      Color valueColor, Color textColor) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        const Spacer(),
        Flexible(
          child: Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                  fontSize: 13),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _buildContactRow(String name, String phone, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white : Colors.black87)),
              Text(phone,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ),
        ),
        GestureDetector(
          onTap: () async {
            final uri = Uri.parse('tel:$phone');
            if (await canLaunchUrl(uri)) await launchUrl(uri);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.phone_rounded, size: 14, color: _green),
                SizedBox(width: 4),
                Text('اتصال',
                    style: TextStyle(
                        fontSize: 11,
                        color: _green,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () async {
            final uri = Uri.parse('https://wa.me/+2$phone');
            if (await canLaunchUrl(uri)) await launchUrl(uri);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_rounded, size: 14, color: _green),
                SizedBox(width: 4),
                Text('واتساب',
                    style: TextStyle(
                        fontSize: 11,
                        color: _green,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  //                    BUILD
  // ═══════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        centerTitle: true,
        actions: [
          if (_notifications
              .any((n) => n['IsRead'] == false || n['IsRead'] == 0))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('قراءة الكل',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState(isDark)
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationCard(
                          notification, index, isDark);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 80,
              color: isDark ? Colors.grey[600] : Colors.grey[400]),
          const SizedBox(height: 16),
          Text('لا توجد إشعارات',
              style: TextStyle(
                  fontSize: 18,
                  color: isDark ? Colors.grey[400] : Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
      Map<String, dynamic> notification, int index, bool isDark) {
    final isRead =
        notification['IsRead'] == true || notification['IsRead'] == 1;
    final type = notification['NotificationType'];
    final color = _getNotificationColor(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead
            ? (isDark ? const Color(0xFF1E1E2E) : Colors.white)
            : (isDark ? const Color(0xFF2A2A3E) : color.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRead
              ? (isDark ? Colors.grey[800]! : Colors.grey[200]!)
              : color.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_getNotificationIcon(type), color: color, size: 24),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(notification['Title'] ?? 'إشعار',
                  style: TextStyle(
                      fontWeight:
                          isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 15)),
            ),
            if (!isRead)
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                    color: color, shape: BoxShape.circle),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(notification['Message'] ?? '',
                style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(_formatDate(notification['CreatedAt']),
                    style:
                        TextStyle(color: Colors.grey[500], fontSize: 11)),
              ],
            ),
          ],
        ),
        onTap: () => _handleNotificationTap(notification, index),
      ),
    );
  }
}