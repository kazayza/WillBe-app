import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/attendance_provider.dart';
import '../providers/children_provider.dart';
import '../providers/classes_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import 'children_attendance_report_screen.dart'; 

class AttendanceChildrenScreen extends StatefulWidget {
  const AttendanceChildrenScreen({super.key});

  @override
  State<AttendanceChildrenScreen> createState() =>
      _AttendanceChildrenScreenState();
}

class _AttendanceChildrenScreenState extends State<AttendanceChildrenScreen> {
  int? _selectedBranchId;
  int? _selectedClassId;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // تحميل الفروع عند الفتح
    Future.delayed(Duration.zero, () {
      Provider.of<ChildrenProvider>(context, listen: false).fetchBranches();
    });
  }

  // عند تغيير الفرع، نجيب الفصول
  void _onBranchChanged(int? branchId) {
    if (branchId == null) return;
    setState(() {
      _selectedBranchId = branchId;
      _selectedClassId = null; // تصفير الفصل القديم
    });
    // نجيب فصول الفرع
    Provider.of<ClassesProvider>(context, listen: false).fetchClasses(branchId);
  }

  // عند تغيير الفصل، نجيب الطلاب
  void _onClassChanged(int? classId) {
    if (classId == null) return;
    setState(() {
      _selectedClassId = classId;
    });
    // نجيب طلاب الفصل لليوم المحدد
    Provider.of<AttendanceProvider>(context, listen: false)
        .fetchStudents(classId, _selectedDate);
  }

  // اختيار التاريخ
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(), // ممنوع تسجيل غياب للمستقبل
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      // لو كنا مختارين فصل، نحدث القائمة للتاريخ الجديد
      if (_selectedClassId != null) {
        Provider.of<AttendanceProvider>(context, listen: false)
            .fetchStudents(_selectedClassId!, picked);
      }
    }
  }

   // حفظ الغياب (المعدلة)
  Future<void> _saveAttendance() async {
    // 1. التأكد من اختيار الفصل
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى اختيار الفصل أولاً"), backgroundColor: Colors.orange),
      );
      return;
    }

    final provider = Provider.of<AttendanceProvider>(context, listen: false);
    final user = Provider.of<AuthProvider>(context, listen: false).user?.fullName ?? "System";

    try {
      // 2. استدعاء دالة الحفظ مع تمرير رقم الفصل
      final success = await provider.saveAttendance(
        _selectedDate, 
        user, 
        _selectedClassId! // 👈 ده التعديل المهم
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("تم حفظ الغياب بنجاح ✅"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("فشل الحفظ: ${e.toString().replaceAll('Exception: ', '')}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    final branches = Provider.of<ChildrenProvider>(context).branches;
    final classes = Provider.of<ClassesProvider>(context).classes;
    final attendanceProvider = Provider.of<AttendanceProvider>(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("تسجيل غياب الأطفال"),
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        // 👇👇 الإضافة الجديدة 👇👇
        actions: [
          IconButton(
            onPressed: () {
              // الانتقال لشاشة التقرير مباشرة
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChildrenAttendanceReportScreen(),
                ),
              );
            },
            icon: const Icon(Icons.history_edu_rounded), // أيقونة معبرة عن السجل/التقرير
            tooltip: "عرض تقرير الغياب",
          ),
          const SizedBox(width: 8), // مسافة صغيرة
        ],
      ),
      body: Column(
        children: [
          // 1. الفلاتر العلوية (Header)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252836) : Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
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
                // سطر التاريخ
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "التاريخ: ${DateFormat('yyyy-MM-dd', 'en').format(_selectedDate)}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const Icon(Icons.calendar_today_rounded, color: Color(0xFF6366F1)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // سطر الفروع والفصول (المصحح لمنع Overflow)
                Row(
                  children: [
                    // 1. Dropdown الفروع
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        isExpanded: true, // 👈 الحل السحري
                        value: _selectedBranchId,
                        hint: const Text(
                          "اختر الفرع", 
                          style: TextStyle(fontSize: 13), 
                          overflow: TextOverflow.ellipsis // 👈 قص النص الطويل
                        ),
                        items: branches.map<DropdownMenuItem<int>>((branch) {
                          return DropdownMenuItem(
                            value: branch['IDbranch'],
                            child: Text(
                              branch['branchName'], 
                              overflow: TextOverflow.ellipsis, // 👈 قص النص في القائمة
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: _onBranchChanged,
                        decoration: _inputDecoration(isDark),
                      ),
                    ),
                    
                    const SizedBox(width: 10),
                    
                    // 2. Dropdown الفصول
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        isExpanded: true, // 👈 الحل السحري
                        value: _selectedClassId,
                        hint: const Text(
                          "اختر الفصل", 
                          style: TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis
                        ),
                        items: classes.map<DropdownMenuItem<int>>((cls) {
                          return DropdownMenuItem(
                            value: cls['Class_ID'],
                            child: Text(
                              cls['ClassName'], 
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: _onClassChanged,
                        decoration: _inputDecoration(isDark),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. قائمة الطلاب
          Expanded(
            child: attendanceProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                : _selectedClassId == null
                    ? Center(
                        child: Text(
                          "يرجى اختيار الفرع والفصل لعرض الطلاب",
                          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                      )
                    : attendanceProvider.students.isEmpty
                        ? const Center(child: Text("لا يوجد طلاب في هذا الفصل"))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: attendanceProvider.students.length,
                            itemBuilder: (context, index) {
                              final student = attendanceProvider.students[index];
                              return _buildStudentCard(student, isDark, attendanceProvider);
                            },
                          ),
          ),

          // 3. شريط الحفظ السفلي
          if (_selectedClassId != null && !attendanceProvider.isLoading)
            Container(
              padding: const EdgeInsets.all(16),
              color: isDark ? const Color(0xFF252836) : Colors.white,
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "الإجمالي: ${attendanceProvider.students.length}",
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                          Text(
                            "غياب: ${attendanceProvider.absentCount}",
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _saveAttendance,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.save_rounded),
                        label: const Text("حفظ الغياب"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 🎨 تصميم كارت الطالب
  Widget _buildStudentCard(dynamic student, bool isDark, AttendanceProvider provider) {
    final int childId = student['ID_Child'];
    final bool isAbsent = provider.isAbsent(childId);
    final String note = provider.getNote(childId);

    return InkWell(
      onTap: () => provider.toggleAbsence(childId),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isAbsent
              ? (isDark ? Colors.red.withOpacity(0.2) : Colors.red.shade50)
              : (isDark ? const Color(0xFF252836) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAbsent ? Colors.red.withOpacity(0.5) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: isAbsent
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: isAbsent ? Colors.red.withOpacity(0.2) : const Color(0xFF6366F1).withOpacity(0.1),
              child: Icon(
                isAbsent ? Icons.close_rounded : Icons.person,
                color: isAbsent ? Colors.red : const Color(0xFF6366F1),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student['FullNameArabic'] ?? "بدون اسم",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      decoration: isAbsent ? TextDecoration.lineThrough : null,
                      decorationColor: Colors.red.withOpacity(0.5),
                    ),
                  ),
                  if (note.isNotEmpty)
                    Text(
                      note,
                      style: const TextStyle(fontSize: 12, color: Colors.orange),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (isAbsent)
              IconButton(
                icon: Icon(
                  note.isNotEmpty ? Icons.edit_note : Icons.add_comment_outlined,
                  color: note.isNotEmpty ? Colors.orange : Colors.grey,
                ),
                onPressed: () => _showNoteDialog(context, provider, childId, note),
              ),
            Switch(
              value: !isAbsent, // True = حضور
              activeColor: const Color(0xFF10B981),
              activeTrackColor: const Color(0xFF10B981).withOpacity(0.2),
              inactiveThumbColor: Colors.red,
              inactiveTrackColor: Colors.red.withOpacity(0.2),
              onChanged: (val) => provider.toggleAbsence(childId),
            ),
          ],
        ),
      ),
    );
  }

  // 📝 نافذة الملاحظة
  void _showNoteDialog(BuildContext context, AttendanceProvider provider, int childId, String currentNote) {
    final controller = TextEditingController(text: currentNote);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("سبب الغياب"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "اكتب السبب هنا..."),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () {
              provider.updateNote(childId, controller.text);
              Navigator.pop(ctx);
            },
            child: const Text("حفظ"),
          ),
        ],
      ),
    );
  }

  // ستايل الحقول
  InputDecoration _inputDecoration(bool isDark) {
    return InputDecoration(
      filled: true,
      fillColor: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}