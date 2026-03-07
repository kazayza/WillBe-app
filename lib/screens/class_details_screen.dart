import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/classes_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'package:printing/printing.dart';
import '../services/class_pdf_report_service.dart';
import 'child_form_screen.dart';

class ClassDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> classData;
  final int branchId;

  const ClassDetailsScreen({
    super.key,
    required this.classData,
    required this.branchId,
  });

  @override
  State<ClassDetailsScreen> createState() => _ClassDetailsScreenState();
}

class _ClassDetailsScreenState extends State<ClassDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _classId;
  late int _branchId;
  late Map<String, dynamic> _classData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _classId = widget.classData['Class_ID'];
    _branchId = widget.branchId;
    _classData = Map<String, dynamic>.from(widget.classData);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = Provider.of<ClassesProvider>(context, listen: false);
    await provider.fetchClassDetails(widget.classData['Class_ID']);
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  // ==================== Helper Methods ====================

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    String confirmText = "تأكيد",
    Color confirmColor = Colors.red,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmText, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      final DateTime dateTime = date is String ? DateTime.parse(date) : date;
      return DateFormat('yyyy/MM/dd', 'ar').format(dateTime);
    } catch (e) {
      return date.toString();
    }
  }

  // ==================== Build ====================

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    final provider = Provider.of<ClassesProvider>(context);
    final className = _classData['ClassName'] ?? 'الفصل';
    final capacity = _classData['Capacity'] ?? 0;
    final currentCount = provider.classChildren.length;
    final isFull = currentCount >= capacity;
    final stats = provider.classStatistics;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
      resizeToAvoidBottomInset: true,
      floatingActionButton: _tabController.index == 0 && !isFull
          ? FloatingActionButton.extended(
              heroTag: "add_student_details_fab",
              onPressed: () => _showAssignStudentDialog(),
              backgroundColor: const Color(0xFF6366F1),
              icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
              label: const Text(
                "إضافة طفل",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 280,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, size: 18),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                // زر الطباعة
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.print_rounded, size: 20),
                  ),
                  onPressed: () => _showPrintOptions(),
                  tooltip: "طباعة",
                ),
                // زر التحديث
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.refresh_rounded, size: 20),
                  ),
                  onPressed: _refresh,
                  tooltip: "تحديث",
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
                  child: SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(25, 20, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // اسم الفصل
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.meeting_room_rounded,
                                    color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      className,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isFull
                                            ? Colors.red.withOpacity(0.3)
                                            : Colors.green.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isFull
                                            ? "ممتلئ"
                                            : "${capacity - currentCount} مقعد متاح",
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // الإحصائيات
                          Row(
                            children: [
                              _buildStatCard(
                                icon: Icons.people_rounded,
                                value: "$currentCount / $capacity",
                                label: "الطلاب",
                                color: Colors.white,
                              ),
                              const SizedBox(width: 12),
                              _buildStatCard(
                                icon: Icons.pie_chart_rounded,
                                value: "${stats?['occupancyRate'] ?? 0}%",
                                label: "الإشغال",
                                color: Colors.white,
                              ),
                              const SizedBox(width: 12),
                              _buildStatCard(
                                icon: Icons.cake_rounded,
                                value: "${stats?['averageAge'] ?? 0}",
                                label: "متوسط العمر",
                                color: Colors.white,
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // آخر تسكين
                          if (stats?['lastJoinDate'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.schedule,
                                      color: Colors.white70, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    "آخر تسكين: ${_formatDate(stats!['lastJoinDate'])}",
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                onTap: (index) {
                  setState(() {});
                },
                tabs: [
                  Tab(
                    icon: const Icon(Icons.people_rounded, size: 20),
                    text: "الطلاب ($currentCount)",
                  ),
                  Tab(
                    icon: const Icon(Icons.history_rounded, size: 20),
                    text: "السجل (${provider.classHistory.length})",
                  ),
                ],
              ),
            ),
          ];
        },
        body: RefreshIndicator(
          onRefresh: _refresh,
          color: const Color(0xFF6366F1),
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCurrentStudentsTab(provider, isDark),
              _buildHistoryTab(provider, isDark),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== Tab 1: الطلاب الحاليين ====================

  Widget _buildCurrentStudentsTab(ClassesProvider provider, bool isDark) {
    if (provider.isLoading && provider.classChildren.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6366F1)),
      );
    }

    if (provider.classChildren.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "لا يوجد طلاب في هذا الفصل",
              style: TextStyle(
                fontSize: 18,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.classChildren.length,
      itemBuilder: (context, index) {
        final child = provider.classChildren[index];
        return _buildStudentCard(child, isDark, isHistory: false);
      },
    );
  }

  // ==================== Tab 2: السجل ====================

  Widget _buildHistoryTab(ClassesProvider provider, bool isDark) {
    if (provider.classHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "لا يوجد سجل سابق",
              style: TextStyle(
                fontSize: 18,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.classHistory.length,
      itemBuilder: (context, index) {
        final child = provider.classHistory[index];
        return _buildStudentCard(child, isDark, isHistory: true);
      },
    );
  }

  // ==================== Student Card ====================

  Widget _buildStudentCard(Map<String, dynamic> child, bool isDark,
      {required bool isHistory}) {
    final String name = child['FullNameArabic'] ?? 'بدون اسم';
    final String joinDate = _formatDate(child['JoinDate']);
    final String? leaveDate = isHistory ? _formatDate(child['LeaveDate']) : null;
    final int? age = child['Age'];
    final String? notes = child['AssignNotes'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isHistory
            ? Border.all(color: Colors.grey.withOpacity(0.3))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: المعلومات الأساسية
            Row(
              children: [
                // أيقونة الطفل
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Color(0xFF6366F1),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),

                // الاسم والعمر
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (age != null) ...[
                            Icon(Icons.cake_outlined,
                                size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              "$age سنة",
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[600]),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // الأزرار (للطلاب الحاليين فقط)
                if (!isHistory) ...[
  _buildIconButton(
    icon: Icons.edit_rounded,
    color: const Color(0xFF10B981),
    tooltip: "تعديل البيانات",
    onPressed: () async {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChildFormScreen(childId: child['Child_ID']),
        ),
      );
      _refresh();
    },
  ),
  const SizedBox(width: 4),
  _buildIconButton(
    icon: Icons.swap_horiz_rounded,
    color: const Color(0xFF6366F1),
    tooltip: "نقل لفصل آخر",
    onPressed: () => _showTransferDialog(child),
  ),
  const SizedBox(width: 4),
  _buildIconButton(
    icon: Icons.person_remove_rounded,
    color: Colors.red,
    tooltip: "إخراج من الفصل",
    onPressed: () => _handleRemoveStudent(child),
  ),
],
              ],
            ),

            const SizedBox(height: 16),
            Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
            const SizedBox(height: 12),

            // Row 2: التواريخ
            Row(
              children: [
                Expanded(
                  child: _buildDateChip(
                    icon: Icons.login_rounded,
                    label: "الالتحاق",
                    date: joinDate,
                    color: Colors.green,
                    isDark: isDark,
                  ),
                ),
                if (isHistory && leaveDate != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateChip(
                      icon: Icons.logout_rounded,
                      label: "المغادرة",
                      date: leaveDate,
                      color: Colors.red,
                      isDark: isDark,
                    ),
                  ),
                ],
              ],
            ),

            // الملاحظات
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.amber.withOpacity(0.1)
                      : Colors.amber.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note_alt_outlined,
                        size: 16, color: Colors.amber[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        notes,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.amber[200] : Colors.amber[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateInfo({
    required IconData icon,
    required String label,
    required String date,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
            Text(
              date,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: color, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildDateChip({
    required IconData icon,
    required String label,
    required String date,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
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

  // ==================== Dialogs ====================

  /// Dialog نقل الطفل
  void _showTransferDialog(Map<String, dynamic> child) {
    final provider = Provider.of<ClassesProvider>(context, listen: false);
    final availableClasses = provider.availableClassesForTransfer;

    if (availableClasses.isEmpty) {
      _showSnackBar("لا توجد فصول متاحة للنقل", isError: true);
      return;
    }

    int? selectedClassId;
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.swap_horiz_rounded, color: Color(0xFF6366F1)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "نقل ${child['FullNameArabic']}",
                  style: const TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // اختيار الفصل
              DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  labelText: "اختر الفصل الجديد",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.meeting_room_rounded),
                ),
                items: availableClasses.map<DropdownMenuItem<int>>((cls) {
                  return DropdownMenuItem(
                    value: cls['Class_ID'],
                    child: Text(
                      "${cls['ClassName']} (${cls['RemainingSeats']} أماكن)",
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedClassId = val),
              ),
              const SizedBox(height: 16),

              // الملاحظات
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: "سبب النقل (اختياري)",
                  prefixIcon: const Icon(Icons.note_alt_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                notesController.dispose();
                Navigator.pop(ctx);
              },
              child: const Text("إلغاء"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: selectedClassId == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);

                      try {
                        final user =
                            Provider.of<AuthProvider>(context, listen: false)
                                    .user
                                    ?.fullName ??
                                "System";

                        await provider.transferStudent(
                          childId: child['Child_ID'],
                          fromClassId: widget.classData['Class_ID'],
                          toClassId: selectedClassId!,
                          branchId: widget.branchId,
                          notes: notesController.text,
                          userAdd: user,
                        );

                        notesController.dispose();
                        _showSnackBar("تم نقل ${child['FullNameArabic']} بنجاح");
                      } catch (e) {
                        _showSnackBar(
                          e.toString().replaceAll('Exception: ', ''),
                          isError: true,
                        );
                      }
                    },
              child: const Text("نقل"),
            ),
          ],
        ),
      ),
    );
  }

  /// إخراج طفل من الفصل
  Future<void> _handleRemoveStudent(Map<String, dynamic> child) async {
    final confirmed = await _showConfirmDialog(
      title: "إخراج من الفصل",
      message: "هل أنت متأكد من إخراج ${child['FullNameArabic']} من الفصل؟",
      confirmText: "إخراج",
    );

    if (!confirmed) return;

    try {
      final user = Provider.of<AuthProvider>(context, listen: false)
              .user
              ?.fullName ??
          "System";

      final provider = Provider.of<ClassesProvider>(context, listen: false);

      await provider.removeStudentFromClass(
        historyId: child['HistoryId'],
        classId: widget.classData['Class_ID'],
        branchId: widget.branchId,
        userEdit: user,
      );

      _showSnackBar("تم إخراج ${child['FullNameArabic']} من الفصل");
    } catch (e) {
      _showSnackBar(
        e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    }
  }

  void _showAssignStudentDialog() {
    final classesProvider =
        Provider.of<ClassesProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDark;

    classesProvider.fetchUnassignedChildren(_branchId);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      final unassigned = List<dynamic>.from(classesProvider.unassignedChildren);

      if (unassigned.isEmpty) {
        _showSnackBar("لا يوجد أطفال غير مسكنين في هذا الفرع", isError: true);
        return;
      }

      int? selectedChildId;
      String searchQuery = '';
      List<dynamic> localUnassigned = List.from(unassigned);
      List<dynamic> filteredChildren = List.from(unassigned);
      bool isLoading = false;

      final notesController = TextEditingController();
      final searchController = TextEditingController();

      Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (pageContext) => StatefulBuilder(
            builder: (_, setState) {
              final currentCount = classesProvider.classChildren.length;
              final capacity = _classData['Capacity'] ?? 0;
              final isFull = currentCount >= capacity;
              final bgColor =
                  isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA);
              final cardColor = isDark ? const Color(0xFF252836) : Colors.white;
              final textColor = isDark ? Colors.white : Colors.black87;

              return Scaffold(
                backgroundColor: bgColor,
                appBar: AppBar(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(pageContext);
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (mounted) _refresh();
                      });
                    },
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "إضافة طفل للفصل",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${_classData['ClassName']} • $currentCount / $capacity",
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.8)),
                      ),
                    ],
                  ),
                  actions: [
                    if (!isFull && selectedChildId != null)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text("تم الاختيار",
                                style: TextStyle(
                                    fontSize: 12, color: Colors.white)),
                          ],
                        ),
                      ),
                    const SizedBox(width: 12),
                  ],
                ),
                body: Column(
                  children: [
                    // Header gradient
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius:
                            BorderRadius.vertical(bottom: Radius.circular(24)),
                      ),
                      child: Column(
                        children: [
                          // شريط السعة
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "سعة الفصل",
                                        style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.8),
                                            fontSize: 12),
                                      ),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: capacity > 0
                                              ? (currentCount / capacity)
                                                  .clamp(0.0, 1.0)
                                              : 0,
                                          backgroundColor:
                                              Colors.white.withOpacity(0.3),
                                          color: isFull
                                              ? Colors.red[300]
                                              : Colors.greenAccent,
                                          minHeight: 8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color:
                                        isFull ? Colors.red : Colors.greenAccent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "$currentCount / $capacity",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isFull ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // رسالة الفصل ممتلئ
                    if (isFull)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_rounded,
                                color: Colors.red, size: 28),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "الفصل ممتلئ! لا يمكن إضافة طلاب جدد.",
                                style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (!isFull) ...[
                      // البحث
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                        child: TextField(
                          controller: searchController,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            hintText: "ابحث عن اسم الطالب...",
                            hintStyle: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[500]),
                            prefixIcon: const Icon(Icons.search,
                                color: Color(0xFF6366F1)),
                            suffixIcon: searchQuery.isNotEmpty
                                ? IconButton(
                                    onPressed: () {
                                      searchController.clear();
                                      setState(() {
                                        searchQuery = '';
                                        filteredChildren =
                                            List.from(localUnassigned);
                                      });
                                    },
                                    icon: Icon(Icons.clear,
                                        size: 20, color: Colors.grey[500]),
                                  )
                                : null,
                            filled: true,
                            fillColor: cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                  color: Color(0xFF6366F1), width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 18),
                          ),
                          onChanged: (val) {
                            setState(() {
                              searchQuery = val;
                              filteredChildren = localUnassigned.where((c) {
                                return (c['FullNameArabic'] ?? '')
                                    .toString()
                                    .toLowerCase()
                                    .contains(val.toLowerCase());
                              }).toList();
                            });
                          },
                        ),
                      ),

                      // عدد النتائج
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF6366F1).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "${filteredChildren.length} طالب",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6366F1),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // قائمة الطلاب
                      Expanded(
                        child: filteredChildren.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off_rounded,
                                        size: 80, color: Colors.grey[400]),
                                    const SizedBox(height: 16),
                                    Text(
                                      localUnassigned.isEmpty
                                          ? "لا يوجد أطفال غير مسكنين"
                                          : "لا توجد نتائج للبحث",
                                      style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[500],
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: filteredChildren.length,
                                itemBuilder: (_, index) {
                                  final child = filteredChildren[index];
                                  final isSelected =
                                      selectedChildId == child['ID_Child'];
                                  final name = child['FullNameArabic'] ?? '';

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: Material(
                                      color: isSelected
                                          ? const Color(0xFF6366F1)
                                          : cardColor,
                                      borderRadius: BorderRadius.circular(16),
                                      elevation: isSelected ? 4 : 1,
                                      shadowColor: isSelected
                                          ? const Color(0xFF6366F1)
                                              .withOpacity(0.4)
                                          : Colors.black12,
                                      child: InkWell(
                                        onTap: () => setState(() =>
                                            selectedChildId = child['ID_Child']),
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 28,
                                                backgroundColor: isSelected
                                                    ? Colors.white
                                                        .withOpacity(0.2)
                                                    : const Color(0xFF6366F1)
                                                        .withOpacity(0.1),
                                                child: Text(
                                                  name.isNotEmpty
                                                      ? name[0]
                                                      : '?',
                                                  style: TextStyle(
                                                    color: isSelected
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF6366F1),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      name,
                                                      style: TextStyle(
                                                        fontSize: 17,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: isSelected
                                                            ? Colors.white
                                                            : textColor,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.cake_outlined,
                                                          size: 14,
                                                          color: isSelected
                                                              ? Colors.white70
                                                              : Colors
                                                                  .grey[500],
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                          "${child['Age'] ?? 0} سنة",
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color: isSelected
                                                                ? Colors.white70
                                                                : Colors
                                                                    .grey[500],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (isSelected)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: const Icon(Icons.check,
                                                      color: Color(0xFF6366F1),
                                                      size: 24),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),

                      // الملاحظات وزر الإضافة
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          child: Column(
                            children: [
                              TextField(
                                controller: notesController,
                                style: TextStyle(color: textColor),
                                decoration: InputDecoration(
                                  labelText: "ملاحظات (اختياري)",
                                  labelStyle:
                                      TextStyle(color: Colors.grey[500]),
                                  prefixIcon: Icon(Icons.note_alt_outlined,
                                      color: Colors.grey[500]),
                                  filled: true,
                                  fillColor: isDark
                                      ? Colors.grey[800]
                                      : Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF6366F1), width: 2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed:
                                      (selectedChildId == null || isLoading)
                                          ? null
                                          : () async {
                                              setState(() => isLoading = true);

                                              try {
                                                final user = authProvider
                                                        .user?.fullName ??
                                                    "System";

                                                await classesProvider
                                                    .assignStudent(
                                                  childId: selectedChildId!,
                                                  classId: _classId,
                                                  branchId: _branchId,
                                                  notes: notesController.text,
                                                  userAdd: user,
                                                );

                                                setState(() {
                                                  localUnassigned.removeWhere(
                                                      (c) =>
                                                          c['ID_Child'] ==
                                                          selectedChildId);
                                                  filteredChildren =
                                                      localUnassigned
                                                          .where((c) {
                                                    return (c['FullNameArabic'] ??
                                                            '')
                                                        .toString()
                                                        .toLowerCase()
                                                        .contains(searchQuery
                                                            .toLowerCase());
                                                  }).toList();
                                                  selectedChildId = null;
                                                  notesController.clear();
                                                  isLoading = false;
                                                });

                                                await classesProvider
                                                    .fetchClassChildren(
                                                        _classId);

                                                _showSnackBar(
                                                    "تم إضافة الطفل بنجاح ✅");
                                              } catch (e) {
                                                setState(
                                                    () => isLoading = false);
                                                _showSnackBar(
                                                    e
                                                        .toString()
                                                        .replaceAll(
                                                            'Exception: ', ''),
                                                    isError: true);
                                              }
                                            },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6366F1),
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: isDark
                                        ? Colors.grey[700]
                                        : Colors.grey[300],
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    elevation: selectedChildId != null ? 4 : 0,
                                    shadowColor: const Color(0xFF6366F1)
                                        .withOpacity(0.4),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_rounded, size: 24),
                                            SizedBox(width: 8),
                                            Text(
                                              "إضافة الطفل للفصل",
                                              style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      );
    });
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Print & Share Methods ====================

  void _showPrintOptions() {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252836) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // العنوان
              Text(
                "التقارير والطباعة",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              // قائمة الطلاب - طباعة
              _buildPrintOption(
                icon: Icons.print_rounded,
                title: "طباعة قائمة الطلاب",
                subtitle: "طباعة مباشرة",
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  _printChildrenList(share: false);
                },
              ),

              const SizedBox(height: 12),

              // قائمة الطلاب - مشاركة
              _buildPrintOption(
                icon: Icons.share_rounded,
                title: "مشاركة قائمة الطلاب",
                subtitle: "PDF للمشاركة أو الحفظ",
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  _printChildrenList(share: true);
                },
              ),

              const SizedBox(height: 12),

              // كشف الحضور - طباعة
              _buildPrintOption(
                icon: Icons.fact_check_rounded,
                title: "طباعة كشف الحضور",
                subtitle: "كشف حضور فارغ بالأيام",
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  _showAttendanceDaysDialog(share: false);
                },
              ),

              const SizedBox(height: 12),

              // كشف الحضور - مشاركة
              _buildPrintOption(
                icon: Icons.upload_file_rounded,
                title: "مشاركة كشف الحضور",
                subtitle: "PDF للمشاركة أو الحفظ",
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  _showAttendanceDaysDialog(share: true);
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrintOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDark = false,
  }) {
    return Material(
      color: isDark ? Colors.grey[800] : Colors.grey[100],
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF6366F1), size: 24),
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
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  void _showAttendanceDaysDialog({bool share = false}) {
    int selectedDays = 7;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.calendar_month, color: Color(0xFF6366F1)),
              ),
              const SizedBox(width: 12),
              const Text("عدد أيام الكشف"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("اختر عدد الأيام المطلوبة في كشف الحضور"),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [7, 10, 15, 20, 25, 30].map((days) {
                  final isSelected = selectedDays == days;
                  return GestureDetector(
                    onTap: () => setState(() => selectedDays = days),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6366F1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF6366F1)
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        "$days يوم",
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("إلغاء"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                _printAttendanceSheet(selectedDays, share: share);
              },
              child: Text(share ? "مشاركة" : "طباعة"),
            ),
          ],
        ),
      ),
    );
  }

  /// طباعة/مشاركة قائمة الطلاب
  Future<void> _printChildrenList({bool share = false}) async {
    final provider = Provider.of<ClassesProvider>(context, listen: false);

    if (provider.classChildren.isEmpty) {
      _showSnackBar("لا يوجد طلاب في الفصل", isError: true);
      return;
    }

    try {
      _showSnackBar("جاري إعداد قائمة الطلاب...", isError: false);

      final pdfBytes = await ClassPdfReportService.generateChildrenList(
        className: _classData['ClassName'] ?? 'الفصل',
        children: provider.classChildren.cast<Map<String, dynamic>>(),
      );

      if (share) {
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'قائمة_طلاب_${_classData['ClassName'] ?? 'الفصل'}.pdf',
        );
      } else {
        await Printing.layoutPdf(
          onLayout: (format) async => pdfBytes,
          name: 'قائمة_طلاب_${_classData['ClassName'] ?? 'الفصل'}',
        );
      }
    } catch (e) {
      _showSnackBar("حدث خطأ في إنشاء القائمة: $e", isError: true);
    }
  }

  /// طباعة/مشاركة كشف الحضور
  Future<void> _printAttendanceSheet(int daysCount, {bool share = false}) async {
    final provider = Provider.of<ClassesProvider>(context, listen: false);

    if (provider.classChildren.isEmpty) {
      _showSnackBar("لا يوجد طلاب في الفصل", isError: true);
      return;
    }

    try {
      _showSnackBar("جاري إعداد كشف الحضور...", isError: false);

      final pdfBytes = await ClassPdfReportService.generateAttendanceSheet(
        className: _classData['ClassName'] ?? 'الفصل',
        children: provider.classChildren,
        daysCount: daysCount,
      );

      if (share) {
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'كشف_حضور_${_classData['ClassName'] ?? 'الفصل'}.pdf',
        );
      } else {
        await Printing.layoutPdf(
          onLayout: (format) async => pdfBytes,
          name: 'كشف_حضور_${_classData['ClassName'] ?? 'الفصل'}',
        );
      }
    } catch (e) {
      _showSnackBar("حدث خطأ في إنشاء الكشف: $e", isError: true);
    }
  }
}