import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/classes_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/employees_provider.dart';
import '../providers/children_provider.dart';
import 'class_details_screen.dart';

class ClassesDashboardScreen extends StatefulWidget {
  const ClassesDashboardScreen({super.key});

  @override
  State<ClassesDashboardScreen> createState() => _ClassesDashboardScreenState();
}

class _ClassesDashboardScreenState extends State<ClassesDashboardScreen> {
  int? _selectedBranchId;
  bool _showStatistics = true;

  // ==================== Lifecycle ====================

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);
    final employeesProvider = Provider.of<EmployeesProvider>(context, listen: false);

    await Future.wait([
      childrenProvider.fetchBranches(),
      employeesProvider.fetchEmployees(),
    ]);

    if (mounted && childrenProvider.branches.isNotEmpty) {
      setState(() {
        _selectedBranchId = childrenProvider.branches[0]['IDbranch'];
      });
      _loadBranchData(_selectedBranchId!);
    }
  }

  Future<void> _loadBranchData(int branchId) async {
    final classesProvider = Provider.of<ClassesProvider>(context, listen: false);
    await classesProvider.refreshAll(branchId);
  }

  Future<void> _refresh() async {
    if (_selectedBranchId != null) {
      await _loadBranchData(_selectedBranchId!);
    }
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
    String cancelText = "إلغاء",
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
            child: Text(cancelText),
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

  // ==================== Build ====================

  @override
  Widget build(BuildContext context) {
    final classesProvider = Provider.of<ClassesProvider>(context);
    final branches = Provider.of<ChildrenProvider>(context).branches;
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    final classes = classesProvider.classes;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
      floatingActionButton: _selectedBranchId != null
          ? FloatingActionButton.extended(
              heroTag: "add_class_fab",
              onPressed: () => _showAddEditClassDialog(),
              backgroundColor: const Color(0xFF6366F1),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                "فصل جديد",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFF6366F1),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            _buildSliverAppBar(isDark, branches),

            if (classesProvider.errorMessage != null)
              SliverToBoxAdapter(
                child: _buildErrorBanner(classesProvider.errorMessage!, isDark),
              ),
            
            if (_selectedBranchId != null && classes.isNotEmpty)
  SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: _buildStatisticsToggle(classes, isDark),
    ),
  ),

            if (_selectedBranchId == null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF6366F1)),
                      const SizedBox(height: 16),
                      Text(
                        "جاري تحميل الفروع...",
                        style: TextStyle(color: isDark ? Colors.white : Colors.black54),
                      ),
                    ],
                  ),
                ),
              )
            else if (classesProvider.isLoading && classes.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
              )
            else if (classes.isEmpty)
              _buildEmptyState(isDark)
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildClassCard(classes[index], isDark),
                    childCount: classes.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==================== Widgets ====================

  Widget _buildErrorBanner(String message, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message.replaceAll('Exception: ', ''),
              style: const TextStyle(color: Colors.red),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red, size: 20),
            onPressed: () {
              Provider.of<ClassesProvider>(context, listen: false).clearError();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(bool isDark, List<dynamic> branches) {
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
          onPressed: _refresh,
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
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                bottom: 60,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                right: 20,
                left: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.class_rounded, color: Colors.white, size: 28),
                        SizedBox(width: 10),
                        Text(
                          "إدارة الفصول",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedBranchId,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                          dropdownColor: const Color(0xFF6366F1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          isExpanded: true,
                          hint: const Text("اختر الفرع", style: TextStyle(color: Colors.white70)),
                          items: branches.map<DropdownMenuItem<int>>((branch) {
                            return DropdownMenuItem(
                              value: branch['IDbranch'],
                              child: Text(branch['branchName'] ?? ''),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedBranchId = val);
                              _loadBranchData(val);
                            }
                          },
                        ),
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

  Widget _buildClassCard(dynamic cls, bool isDark) {
    final bool isFull = cls['IsFull'] == true;
    final int capacity = cls['Capacity'] ?? 0;
    final int current = cls['CurrentStudentCount'] ?? 0;
    final double progress = capacity > 0 ? (current / capacity).clamp(0.0, 1.0) : 0.0;
    final String teachers = cls['TeachersNames'] ?? "لا يوجد مدرسين";
    final String? notes = cls['Notes'];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClassDetailsScreen(
              classData: Map<String, dynamic>.from(cls),
              branchId: _selectedBranchId!,
            ),
          ),
        ).then((_) => _refresh());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252836) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: isFull ? Border.all(color: Colors.red.withOpacity(0.5), width: 1.5) : null,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isFull
                          ? Colors.red.withOpacity(0.1)
                          : const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.meeting_room_rounded,
                      color: isFull ? Colors.red : const Color(0xFF6366F1),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                cls['ClassName'] ?? '',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isFull 
                                    ? Colors.red.withOpacity(0.1) 
                                    : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "$current / $capacity",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isFull ? Colors.red : Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isFull ? "الفصل ممتلئ ⚠️" : "${capacity - current} مقعد متاح",
                          style: TextStyle(
                            fontSize: 13,
                            color: isFull ? Colors.red : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit_rounded, color: Colors.grey[400]),
                    onPressed: () => _showAddEditClassDialog(classData: cls),
                    tooltip: "تعديل الفصل",
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  color: isFull ? Colors.red : const Color(0xFF10B981),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (notes != null && notes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black.withOpacity(0.2) : Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.note_alt_outlined, size: 16, color: Colors.amber[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          notes,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.amber[200] : Colors.amber[800],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (notes != null && notes.isNotEmpty) const SizedBox(height: 12),

            Divider(height: 1, color: Colors.grey.withOpacity(0.2)),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.person_pin_circle_rounded, size: 18, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      teachers,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withOpacity(0.2) : const Color(0xFFF5F5F5),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      label: "تسكين طالب",
                      icon: Icons.person_add_alt_1_rounded,
                      color: const Color(0xFF6366F1),
                      onTap: isFull ? null : () => _showAssignStudentDialog(cls),
                      disabled: isFull,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionButton(
                      label: "تعيين مدرس",
                      icon: Icons.assignment_ind_rounded,
                      color: const Color(0xFFF59E0B),
                      onTap: () => _showAssignTeacherDialog(cls),
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

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    bool disabled = false,
  }) {
    final effectiveColor = disabled ? Colors.grey : color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: effectiveColor.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
            color: effectiveColor.withOpacity(0.1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: effectiveColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: effectiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.meeting_room_outlined, size: 64, color: Colors.grey[400]),
            ),
            const SizedBox(height: 20),
            Text(
              "لا توجد فصول في هذا الفرع",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "اضغط على زر (+) لإنشاء أول فصل",
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Dialogs ====================

  void _showAddEditClassDialog({Map<String, dynamic>? classData}) {
  final isEdit = classData != null;
  final currentStudents = classData?['CurrentStudentCount'] ?? 0;

  // حفظ الـ Providers
  final classesProvider = Provider.of<ClassesProvider>(context, listen: false);
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final branchId = _selectedBranchId!;

  final nameController = TextEditingController(text: isEdit ? classData['ClassName'] : '');
  final capacityController = TextEditingController(text: isEdit ? classData['Capacity'].toString() : '');
  final notesController = TextEditingController(text: isEdit ? classData['Notes'] ?? '' : '');

  final formKey = GlobalKey<FormState>();
  bool isSaving = false;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (_, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isEdit ? Icons.edit_rounded : Icons.add_circle_rounded,
                color: const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(width: 12),
            Text(isEdit ? "تعديل الفصل" : "إضافة فصل جديد"),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "اسم الفصل",
                    hintText: "مثال: فصل الورد",
                    prefixIcon: const Icon(Icons.class_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v!.trim().isEmpty ? "اسم الفصل مطلوب" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: capacityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "سعة الفصل",
                    hintText: "مثال: 25",
                    prefixIcon: const Icon(Icons.people_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    helperText: isEdit ? "الطلاب الحاليين: $currentStudents" : null,
                  ),
                  validator: (v) {
                    if (v!.isEmpty) return "السعة مطلوبة";
                    final capacity = int.tryParse(v);
                    if (capacity == null || capacity <= 0) {
                      return "يجب إدخال رقم صحيح أكبر من صفر";
                    }
                    if (isEdit && capacity < currentStudents) {
                      return "السعة لا يمكن أن تكون أقل من عدد الطلاب ($currentStudents)";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: "ملاحظات (اختياري)",
                    prefixIcon: const Icon(Icons.note_alt_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: isSaving ? null : () {
              Navigator.pop(dialogContext);
            },
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: isSaving ? null : () async {
              if (!formKey.currentState!.validate()) return;

              setState(() => isSaving = true);

              try {
                final user = authProvider.user?.fullName ?? "System";

                if (isEdit) {
                  await classesProvider.updateClass(
                    classId: classData['Class_ID'],
                    className: nameController.text.trim(),
                    capacity: int.parse(capacityController.text),
                    notes: notesController.text.trim(),
                    branchId: branchId,
                    userEdit: user,
                  );
                } else {
                  await classesProvider.addClass(
                    className: nameController.text.trim(),
                    capacity: int.parse(capacityController.text),
                    notes: notesController.text.trim(),
                    branchId: branchId,
                    userAdd: user,
                  );
                }

                Navigator.pop(dialogContext);
                
                // التحديث بعد إغلاق الـ Dialog
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) {
                    _showSnackBar(isEdit ? "تم التعديل بنجاح ✅" : "تمت الإضافة بنجاح ✅");
                  }
                });
              } catch (e) {
                setState(() => isSaving = false);
                _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
              }
            },
            child: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(isEdit ? "حفظ التعديلات" : "إضافة"),
          ),
        ],
      ),
    ),
  );
}

void _showAssignStudentDialog(dynamic cls) {
  // حفظ الـ Providers
  final classesProvider = Provider.of<ClassesProvider>(context, listen: false);
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final branchId = _selectedBranchId!;
  final classId = cls['Class_ID'];
  
  // جلب الطلاب المسكنين
  classesProvider.fetchClassChildren(classId);

  final unassigned = List<dynamic>.from(classesProvider.unassignedChildren);

  if (unassigned.isEmpty) {
    _showSnackBar("لا يوجد أطفال غير مسكنين في هذا الفرع", isError: true);
    return;
  }

  // المتغيرات المحلية
  int? selectedChildId;
  String searchQuery = '';
  List<dynamic> localUnassigned = List.from(unassigned);
  List<dynamic> filteredChildren = List.from(unassigned);
  List<dynamic> currentChildrenLocal = List.from(classesProvider.classChildren);
  bool isLoading = false;
  
  final notesController = TextEditingController();
  final searchController = TextEditingController();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (_, setState) {
        final currentCount = currentChildrenLocal.length;
        final capacity = cls['Capacity'] ?? 0;
        final isFull = currentCount >= capacity;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_add_alt_1, color: Color(0xFF6366F1), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cls['ClassName'] ?? 'الفصل',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: capacity > 0 ? (currentCount / capacity).clamp(0.0, 1.0) : 0,
                              backgroundColor: Colors.grey[300],
                              color: isFull ? Colors.red : const Color(0xFF10B981),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "$currentCount / $capacity",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isFull ? Colors.red : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الطلاب الحاليين
                  if (currentChildrenLocal.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.people, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          "الطلاب في الفصل (${currentChildrenLocal.length})",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
                      ),
                      child: Wrap(
  spacing: 8,
  runSpacing: 8,
  children: currentChildrenLocal.map<Widget>((child) {
    final name = child['FullNameArabic'] ?? '?';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.15),  // ✅ بنفسجي فاتح
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: const Color(0xFF6366F1),
            child: Text(name[0], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4338CA),  // ✅ بنفسجي غامق
            ),
          ),
        ],
      ),
    );
  }).toList(),
),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                  ],

                  // رسالة الفصل ممتلئ
                  if (isFull)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_rounded, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Expanded(child: Text("الفصل ممتلئ!", style: TextStyle(color: Colors.red, fontSize: 13))),
                        ],
                      ),
                    ),

                  // اختيار طالب
                  if (!isFull) ...[
                    Text("اختر طالب للتسكين:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                    const SizedBox(height: 10),

                    // البحث
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: "ابحث عن اسم الطالب...",
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                      ),
                      onChanged: (val) {
                        setState(() {
                          searchQuery = val;
                          filteredChildren = localUnassigned.where((c) {
                            return (c['FullNameArabic'] ?? '').toString().toLowerCase().contains(val.toLowerCase());
                          }).toList();
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // قائمة الطلاب
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: filteredChildren.isEmpty
                          ? Center(child: Text("لا توجد نتائج", style: TextStyle(color: Colors.grey[500])))
                          : ListView.builder(
                              itemCount: filteredChildren.length,
                              itemBuilder: (_, index) {
                                final child = filteredChildren[index];
                                final isSelected = selectedChildId == child['ID_Child'];
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    child['FullNameArabic'] ?? "",
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? const Color(0xFF6366F1) : null,
                                    ),
                                  ),
                                  subtitle: Text("${child['Age'] ?? 0} سنة", style: const TextStyle(fontSize: 12)),
                                  leading: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: isSelected ? const Color(0xFF6366F1) : Colors.grey[200],
                                    child: Icon(Icons.person, size: 14, color: isSelected ? Colors.white : Colors.grey),
                                  ),
                                  trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF6366F1), size: 18) : null,
                                  onTap: () => setState(() => selectedChildId = child['ID_Child']),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 12),

                    // الملاحظات
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: "ملاحظات (اختياري)",
                        prefixIcon: const Icon(Icons.note_alt_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            // زر إنهاء
            TextButton(
              onPressed: isLoading ? null : () {
                Navigator.pop(dialogContext);
                // التحديث بعد إغلاق الـ Dialog
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) _refresh();
                });
              },
              child: const Text("إنهاء"),
            ),
            
            // زر تسكين
            if (!isFull)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: (selectedChildId == null || isLoading) ? null : () async {
                  setState(() => isLoading = true);

                  try {
                    final user = authProvider.user?.fullName ?? "System";

                    await classesProvider.assignStudent(
                      childId: selectedChildId!,
                      classId: classId,
                      branchId: branchId,
                      notes: notesController.text,
                      userAdd: user,
                    );

                    // تحديث القوائم المحلية
                    final addedChild = localUnassigned.firstWhere(
                      (c) => c['ID_Child'] == selectedChildId,
                      orElse: () => <String, dynamic>{},
                    );

                    setState(() {
                      if (addedChild.isNotEmpty) {
                        currentChildrenLocal.add({'FullNameArabic': addedChild['FullNameArabic'], 'Age': addedChild['Age']});
                      }
                      localUnassigned.removeWhere((c) => c['ID_Child'] == selectedChildId);
                      filteredChildren = localUnassigned.where((c) {
                        return (c['FullNameArabic'] ?? '').toString().toLowerCase().contains(searchQuery.toLowerCase());
                      }).toList();
                      selectedChildId = null;
                      notesController.clear();
                      isLoading = false;
                    });

                    _showSnackBar("تم تسكين الطالب بنجاح ✅");
                  } catch (e) {
                    setState(() => isLoading = false);
                    _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
                  }
                },
                child: isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add, size: 18), SizedBox(width: 6), Text("تسكين")]),
              ),
          ],
        );
      },
    ),
  );
}

  void _showAssignTeacherDialog(dynamic cls) {
    final employees = Provider.of<EmployeesProvider>(context, listen: false).employees;

    final branchTeachers = employees
        .where((e) => e.branchId == _selectedBranchId || e.branchId == null)
        .toList();

    if (branchTeachers.isEmpty) {
      _showSnackBar("لا يوجد مدرسين مسجلين لهذا الفرع", isError: true);
      return;
    }

    int? selectedEmpId;
    final notesController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assignment_ind, color: Color(0xFFF59E0B)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "تعيين مدرس لـ ${cls['ClassName']}",
                  style: const TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  labelText: "اختر المدرس",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person_search),
                ),
                isExpanded: true,
                items: branchTeachers.map<DropdownMenuItem<int>>((emp) {
                  return DropdownMenuItem(
                    value: emp.id,
                    child: Text(emp.empName),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedEmpId = val),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: "ملاحظات (اختياري)",
                  prefixIcon: const Icon(Icons.note_alt_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading
                  ? null
                  : () {
                      notesController.dispose();
                      Navigator.pop(ctx);
                    },
              child: const Text("إلغاء"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: (selectedEmpId == null || isLoading)
                  ? null
                  : () async {
                      setState(() => isLoading = true);

                      try {
                        final user = Provider.of<AuthProvider>(context, listen: false)
                                .user?.fullName ?? "System";

                        await Provider.of<ClassesProvider>(context, listen: false).assignTeacher(
                          classId: cls['Class_ID'],
                          empId: selectedEmpId!,
                          branchId: _selectedBranchId!,
                          notes: notesController.text,
                          userAdd: user,
                        );

                        notesController.dispose();

                        if (mounted) {
                          Navigator.pop(ctx);
                          _showSnackBar("تم تعيين المدرس بنجاح ✅");
                        }
                      } catch (e) {
                        setState(() => isLoading = false);
                        _showSnackBar(
                          e.toString().replaceAll('Exception: ', ''),
                          isError: true,
                        );
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text("حفظ"),
            ),
          ],
        ),
      ),
    );
  }
  // ==================== Statistics Section ====================

Widget _buildStatisticsSection(List<dynamic> classes, bool isDark) {
  // حساب الإحصائيات
  int totalClasses = classes.length;
  int totalStudents = 0;
  int totalCapacity = 0;
  int fullClasses = 0;

  for (var cls in classes) {
    int current = cls['CurrentStudentCount'] ?? 0;
    int capacity = cls['Capacity'] ?? 0;
    totalStudents += current;
    totalCapacity += capacity;
    if (cls['IsFull'] == true) fullClasses++;
  }

  int availableSeats = totalCapacity - totalStudents;
  double occupancyRate = totalCapacity > 0 ? (totalStudents / totalCapacity) * 100 : 0;

  return Column(
    children: [
      // البطاقات الإحصائية
      _buildStatsCards(
        totalClasses: totalClasses,
        totalStudents: totalStudents,
        availableSeats: availableSeats,
        occupancyRate: occupancyRate,
        fullClasses: fullClasses,
        isDark: isDark,
      ),
      const SizedBox(height: 16),
      const SizedBox(height: 12),

      // ملخص سريع
      _buildQuickSummary(classes, isDark),
      const SizedBox(height: 14),
      // أعمدة الإشغال
      _buildOccupancyBars(classes, isDark),
    ],
  );
}

// البطاقات الأربعة
Widget _buildStatsCards({
  required int totalClasses,
  required int totalStudents,
  required int availableSeats,
  required double occupancyRate,
  required int fullClasses,
  required bool isDark,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.meeting_room_rounded,
                  value: "$totalClasses",
                  label: "فصول",
                  color: const Color(0xFF6366F1),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.people_rounded,
                  value: "$totalStudents",
                  label: "طالب",
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.event_seat_rounded,
                  value: "$availableSeats",
                  label: "مقعد متاح",
                  color: const Color(0xFFF59E0B),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.pie_chart_rounded,
                  value: "${occupancyRate.toStringAsFixed(0)}%",
                  label: "نسبة الإشغال",
                  color: _getOccupancyColor(occupancyRate),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

// بطاقة إحصائية واحدة
Widget _buildStatCard({
  required IconData icon,
  required String value,
  required String label,
  required Color color,
  required bool isDark,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF252836) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      border: Border.all(
        color: color.withOpacity(0.2),
        width: 1,
      ),
    ),
    child: Row(
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// أعمدة الإشغال لكل فصل
Widget _buildOccupancyBars(List<dynamic> classes, bool isDark) {
  if (classes.isEmpty) return const SizedBox.shrink();

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
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
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // العنوان
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                color: Color(0xFF6366F1),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "إشغال الفصول",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const Spacer(),
            // مفتاح الألوان
            _buildColorLegend(),
          ],
        ),
        const SizedBox(height: 16),

        // الأعمدة
        ...classes.map((cls) {
          return _buildSingleBar(cls, isDark);
        }).toList(),
      ],
    ),
  );
}

// مفتاح الألوان
Widget _buildColorLegend() {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _buildLegendDot(Colors.red, "ممتلئ"),
      const SizedBox(width: 8),
      _buildLegendDot(Colors.orange, "قارب"),
      const SizedBox(width: 8),
      _buildLegendDot(const Color(0xFF10B981), "متاح"),
    ],
  );
}

Widget _buildLegendDot(Color color, String label) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 3),
      Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: Colors.grey[500],
        ),
      ),
    ],
  );
}

// عمود إشغال واحد لفصل
Widget _buildSingleBar(dynamic cls, bool isDark) {
  final String name = cls['ClassName'] ?? '';
  final int current = cls['CurrentStudentCount'] ?? 0;
  final int capacity = cls['Capacity'] ?? 0;
  final double progress = capacity > 0 ? (current / capacity).clamp(0.0, 1.0) : 0.0;
  final double percentage = progress * 100;
  final Color barColor = _getOccupancyColor(percentage);

  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      children: [
        // اسم الفصل والأرقام
        Row(
          children: [
            // أيقونة الحالة
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: barColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  percentage >= 100
                      ? "🔴"
                      : percentage >= 75
                          ? "🟡"
                          : percentage >= 50
                              ? "🟢"
                              : "🔵",
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // اسم الفصل
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // الأرقام
            Text(
              "$current / $capacity",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // شريط التقدم
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // الخلفية
                Container(
                  width: double.infinity,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                // التقدم
                AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  width: constraints.maxWidth * progress,
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        barColor.withOpacity(0.7),
                        barColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: barColor.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    ),
  );
}

// تحديد اللون حسب نسبة الإشغال
Color _getOccupancyColor(double percentage) {
  if (percentage >= 90) return Colors.red;
  if (percentage >= 75) return Colors.orange;
  if (percentage >= 50) return const Color(0xFFF59E0B);
  return const Color(0xFF10B981);
}

// زر إخفاء/إظهار + الإحصائيات
Widget _buildStatisticsToggle(List<dynamic> classes, bool isDark) {
  return Column(
    children: [
      // زر الإخفاء/الإظهار
      GestureDetector(
        onTap: () => setState(() => _showStatistics = !_showStatistics),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252836) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Color(0xFF6366F1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "إحصائيات الفرع",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              AnimatedRotation(
                turns: _showStatistics ? 0.5 : 0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF6366F1),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // الإحصائيات
      AnimatedCrossFade(
        firstChild: const SizedBox.shrink(),
        secondChild: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: _buildStatisticsSection(classes, isDark),
        ),
        crossFadeState: _showStatistics
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 300),
      ),
    ],
  );
}

// ملخص سريع
Widget _buildQuickSummary(List<dynamic> classes, bool isDark) {
  int fullCount = 0;
  int almostFull = 0;
  int available = 0;

  for (var cls in classes) {
    int current = cls['CurrentStudentCount'] ?? 0;
    int capacity = cls['Capacity'] ?? 0;
    double percentage = capacity > 0 ? (current / capacity) * 100 : 0;

    if (percentage >= 100) {
      fullCount++;
    } else if (percentage >= 75) {
      almostFull++;
    } else {
      available++;
    }
  }

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: isDark
          ? Colors.black.withOpacity(0.2)
          : const Color(0xFF6366F1).withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: const Color(0xFF6366F1).withOpacity(0.15),
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildSummaryItem(
          count: fullCount,
          label: "ممتلئ",
          color: Colors.red,
          icon: "🔴",
        ),
        _buildSummaryDivider(isDark),
        _buildSummaryItem(
          count: almostFull,
          label: "قارب",
          color: Colors.orange,
          icon: "🟡",
        ),
        _buildSummaryDivider(isDark),
        _buildSummaryItem(
          count: available,
          label: "متاح",
          color: const Color(0xFF10B981),
          icon: "🟢",
        ),
      ],
    ),
  );
}

Widget _buildSummaryItem({
  required int count,
  required String label,
  required Color color,
  required String icon,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            "$count",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
      const SizedBox(height: 2),
      Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[500],
        ),
      ),
    ],
  );
}

Widget _buildSummaryDivider(bool isDark) {
  return Container(
    width: 1,
    height: 35,
    color: isDark ? Colors.grey[700] : Colors.grey[300],
  );
}

}