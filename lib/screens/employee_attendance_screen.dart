import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/employees_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../models/employee_model.dart';
import '../services/api_service.dart';
//import 'AttendanceHistoryScreen.dart';
import 'attendance_calendar_screen.dart';

class EmployeeAttendanceScreen extends StatefulWidget {
  final String? initialDate;
   const EmployeeAttendanceScreen({super.key, this.initialDate});

    @override
  State<EmployeeAttendanceScreen> createState() => _EmployeeAttendanceScreenState();
}

class _EmployeeAttendanceScreenState extends State<EmployeeAttendanceScreen>
    with SingleTickerProviderStateMixin {
  final _dateController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLoadingAttendance = false;

  // كل الموظفين النشطين
  List<Employee> _allEmployees = [];

  // الغياب المحفوظ في الداتابيز
  Set<int> _savedAbsentIds = {};
  Map<int, String> _savedNotesMap = {};
  int? _masterId;

  // الموظفين المختارين حالياً (محفوظين + جدد)
  Set<int> _selectedAbsentIds = {};
  Map<int, String> _notesMap = {};

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

 @override
void initState() {
  super.initState();
  _setupAnimation();
  
  // ✅ بناخد التاريخ، ولو فيه T بناخد الجزء اللي قبلها بس
  String dateStr = widget.initialDate ?? DateTime.now().toString();
  _dateController.text = dateStr.split('T')[0]; 
  
  _loadData();
}

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final empProvider = Provider.of<EmployeesProvider>(context, listen: false);
    await empProvider.fetchEmployees(isActive: true);

    if (mounted) {
      setState(() {
        _allEmployees = empProvider.employees;
        _isLoading = false;
      });
      _animationController.forward();
      
      // جلب الغياب المسجل لليوم الحالي
      _fetchSavedAttendance();
    }
  }

  // 🔥 جلب الغياب المحفوظ لتاريخ معين
Future<void> _fetchSavedAttendance() async {
  setState(() => _isLoadingAttendance = true);

  final cleanDate = _dateController.text.split('T')[0].trim();

  try {
    final data = await ApiService.get('emp-attendance?date=$cleanDate');

    if (mounted) {
      setState(() {
        // تنظيف القوائم
        _savedAbsentIds.clear();
        _savedNotesMap.clear();
        _selectedAbsentIds.clear();
        _notesMap.clear();

        if (data is List && data.isNotEmpty) {
          // حفظ Master ID
          if (data[0]['masterId'] != null) {
            _masterId = int.tryParse(data[0]['masterId'].toString());
          }

          for (var record in data) {
            final empId = int.tryParse(record['empId'].toString()) ?? 0;
            final notes = record['Notes']?.toString() ?? '';

            if (empId != 0) {
              _savedAbsentIds.add(empId);
              _savedNotesMap[empId] = notes;
              _selectedAbsentIds.add(empId);
              _notesMap[empId] = notes;

              // 👈 لو الموظف مش موجود في القائمة (متوقف) - نضيفه
              bool exists = _allEmployees.any((e) => e.id == empId);
              if (!exists) {
                _allEmployees.add(Employee(
                  id: empId,
                  empName: record['empName']?.toString() ?? 'موظف سابق',
                  job: record['job']?.toString(),
                  branchName: record['branchName']?.toString(),
                  status: false, // 👈 متوقف
                ));
              }
            }
          }
        } else {
          _masterId = null;
        }

        _isLoadingAttendance = false;
      });
    }
  } catch (e) {
    print("خطأ في جلب الغياب: $e");
    if (mounted) {
      setState(() => _isLoadingAttendance = false);
    }
  }
}

  Future<void> _pickDate() async {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDark;

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dateController.text) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFFEF4444),
              onPrimary: Colors.white,
              surface: isDark ? const Color(0xFF252836) : Colors.white,
              onSurface: isDark ? Colors.white : Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
      // 🔄 جلب الغياب للتاريخ الجديد
      _fetchSavedAttendance();
    }
  }

  void _showSelectEmployeesSheet() {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDark;
    final tempSelected = Set<int>.from(_selectedAbsentIds);
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            // فلترة الموظفين بالبحث
            final filteredEmployees = _allEmployees.where((emp) {
              return emp.empName.toLowerCase().contains(searchQuery.toLowerCase()) ||
                     (emp.job?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252836) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
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
                            color: const Color(0xFFEF4444).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.person_off_rounded,
                            color: Color(0xFFEF4444),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "اختيار الموظفين الغائبين",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                "${tempSelected.length} موظف مختار",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: const Color(0xFFEF4444),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Select All / Deselect All
                        IconButton(
                          onPressed: () {
                            setSheetState(() {
                              if (tempSelected.length == _allEmployees.length) {
                                tempSelected.clear();
                              } else {
                                tempSelected.addAll(_allEmployees.map((e) => e.id));
                              }
                            });
                          },
                          icon: Icon(
                            tempSelected.length == _allEmployees.length
                                ? Icons.deselect
                                : Icons.select_all,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        onChanged: (val) => setSheetState(() => searchQuery = val),
                        decoration: InputDecoration(
                          hintText: "ابحث عن موظف...",
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),

                  // Employees List
                  Expanded(
                    child: filteredEmployees.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_search_rounded,
                                  size: 60,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "لا يوجد موظفين",
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            itemCount: filteredEmployees.length,
                            itemBuilder: (ctx, i) {
                              final emp = filteredEmployees[i];
                              final isSelected = tempSelected.contains(emp.id);
                              final isSaved = _savedAbsentIds.contains(emp.id);

                              return _buildEmployeeSelectItem(
                                emp: emp,
                                isSelected: isSelected,
                                isSaved: isSaved,
                                isDark: isDark,
                                onChanged: (val) {
                                  setSheetState(() {
                                    if (val == true) {
                                      tempSelected.add(emp.id);
                                    } else {
                                      tempSelected.remove(emp.id);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                  ),

                  // Action Buttons
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      16,
                      20,
                      MediaQuery.of(context).padding.bottom + 16,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
                      border: Border(
                        top: BorderSide(
                          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[600],
                              side: BorderSide(color: Colors.grey[400]!),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text("إلغاء"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _selectedAbsentIds
                                    ..clear()
                                    ..addAll(tempSelected);

                                  for (var id in _selectedAbsentIds) {
                                    _notesMap[id] = _notesMap[id] ?? 
                                                    _savedNotesMap[id] ?? 
                                                    "غياب";
                                  }
                                });
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.check_rounded),
                              label: Text("تأكيد (${tempSelected.length})"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildEmployeeSelectItem({
    required Employee emp,
    required bool isSelected,
    required bool isSaved,
    required bool isDark,
    required void Function(bool?) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFEF4444).withOpacity(0.1)
            : (isDark ? const Color(0xFF1E1E2E) : Colors.grey[50]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? const Color(0xFFEF4444).withOpacity(0.3)
              : Colors.transparent,
        ),
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: onChanged,
        activeColor: const Color(0xFFEF4444),
        checkboxShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                emp.empName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            if (isSaved)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_done_rounded, size: 12, color: Color(0xFF10B981)),
                    SizedBox(width: 4),
                    Text(
                      "محفوظ",
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        subtitle: Text(
          "${emp.job ?? '---'} • ${emp.branchName ?? '---'}",
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
        secondary: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFEF4444).withOpacity(0.2)
                : (isDark ? Colors.grey[800] : Colors.grey[200]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              emp.empName.isNotEmpty ? emp.empName[0] : "?",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? const Color(0xFFEF4444)
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_selectedAbsentIds.isEmpty) {
      _showInfoSnackBar('لم يتم اختيار أي موظف كغائب');
      return;
    }

    setState(() => _isSaving = true);

    final userName = Provider.of<AuthProvider>(context, listen: false)
            .user?.fullName ?? "System";

    final List<Map<String, dynamic>> list = _selectedAbsentIds.map((id) {
      return {
        "empId": id,
        "status": true,
        "notes": _notesMap[id] ?? 'غياب',
      };
    }).toList();

    final body = {
      "date": _dateController.text,
      "user": userName,
      "employeeList": list,
    };

    try {
      final response = await ApiService.post('emp-attendance', body);
      
      if (mounted) {
        final isUpdate = response['isUpdate'] == true;
        _showSuccessSnackBar(
          isUpdate ? 'تم تحديث الغياب بنجاح ✅' : 'تم حفظ الغياب بنجاح ✅'
        );
        
        // تحديث الحالة المحلية
        setState(() {
          _savedAbsentIds = Set.from(_selectedAbsentIds);
          _savedNotesMap = Map.from(_notesMap);
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('فشل الحفظ: $e');
      }
    }

    if (mounted) setState(() => _isSaving = false);
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Text(message),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 10),
            Text(message),
          ],
        ),
        backgroundColor: const Color(0xFFF59E0B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;

    final absentEmployees = _allEmployees
        .where((e) => _selectedAbsentIds.contains(e.id))
        .toList();

    // حساب الإحصائيات
    final newCount = _selectedAbsentIds.difference(_savedAbsentIds).length;
    final savedCount = _selectedAbsentIds.intersection(_savedAbsentIds).length;
    final removedCount = _savedAbsentIds.difference(_selectedAbsentIds).length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFEF4444)),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 🎨 App Bar
                _buildSliverAppBar(isDark),

                // 📅 Date & Actions
                SliverToBoxAdapter(
                  child: _buildDateSection(isDark),
                ),

                // 📊 Stats Cards
                SliverToBoxAdapter(
                  child: _buildStatsCards(
                    isDark: isDark,
                    total: absentEmployees.length,
                    saved: savedCount,
                    newCount: newCount,
                    removed: removedCount,
                  ),
                ),

                // 🏷️ Changes Indicator
                if (newCount > 0 || removedCount > 0)
                  SliverToBoxAdapter(
                    child: _buildChangesIndicator(isDark, newCount, removedCount),
                  ),

                // 📋 Section Header
                SliverToBoxAdapter(
                  child: _buildSectionHeader(isDark, absentEmployees.length),
                ),

                // 👥 Absent Employees List
                _isLoadingAttendance
                    ? const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(50),
                          child: Center(
                            child: CircularProgressIndicator(color: Color(0xFFEF4444)),
                          ),
                        ),
                      )
                    : absentEmployees.isEmpty
                        ? SliverToBoxAdapter(child: _buildEmptyState(isDark))
                        : SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final emp = absentEmployees[index];
                                  return FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: _buildAbsentEmployeeCard(emp, isDark, index),
                                  );
                                },
                                childCount: absentEmployees.length,
                              ),
                            ),
                          ),

                // Bottom Padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),

      // 💾 Save FAB
      floatingActionButton: _buildSaveFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // 🎨 Sliver App Bar
  Widget _buildSliverAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFFEF4444),
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
            child: const Icon(Icons.history_rounded, color: Colors.white, size: 20),
          ),
          onPressed: () {
              Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const AttendanceCalendarScreen(),
    ),
  );
          },
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
          ),
          onPressed: () {
            _loadData();
          },
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: 20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),

              // Content
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.event_busy_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "سجل الغياب",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "تسجيل غياب الموظفين",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
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

  // 📅 Date Section
  Widget _buildDateSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Date Picker
          Expanded(
            child: GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.calendar_today_rounded,
                        color: Color(0xFFEF4444),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "تاريخ الغياب",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDisplayDate(_dateController.text),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Select Button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _showSelectEmployeesSheet,
              icon: const Icon(Icons.person_add_rounded, size: 20),
              label: const Text("اختيار"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 📊 Stats Cards
  Widget _buildStatsCards({
    required bool isDark,
    required int total,
    required int saved,
    required int newCount,
    required int removed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.person_off_rounded,
              label: "إجمالي الغائبين",
              value: total.toString(),
              color: const Color(0xFFEF4444),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatCard(
              icon: Icons.cloud_done_rounded,
              label: "محفوظ",
              value: saved.toString(),
              color: const Color(0xFF10B981),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatCard(
              icon: Icons.add_circle_rounded,
              label: "جديد",
              value: newCount.toString(),
              color: const Color(0xFFF59E0B),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // 🏷️ Changes Indicator
  Widget _buildChangesIndicator(bool isDark, int newCount, int removedCount) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF59E0B).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_rounded,
            color: Color(0xFFF59E0B),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "لديك تغييرات غير محفوظة" +
              (newCount > 0 ? " • $newCount جديد" : "") +
              (removedCount > 0 ? " • $removedCount محذوف" : ""),
              style: const TextStyle(
                color: Color(0xFFF59E0B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 📋 Section Header
  Widget _buildSectionHeader(bool isDark, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.list_alt_rounded,
              color: Color(0xFFEF4444),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "قائمة الغائبين",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "$count موظف",
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 👤 Absent Employee Card
  Widget _buildAbsentEmployeeCard(Employee emp, bool isDark, int index) {
    final isSaved = _savedAbsentIds.contains(emp.id);
    final isNew = !_savedAbsentIds.contains(emp.id);
    final isInactive = !emp.status; // 👈 جديد - هل الموظف متوقف؟

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252836) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isNew
                ? const Color(0xFFF59E0B).withOpacity(0.3)
                : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header Row
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        emp.empName.isNotEmpty ? emp.empName[0] : "?",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
  children: [
    Expanded(
      child: Text(
        emp.empName,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    // 👈 Badge الموظف المتوقف
    if (isInactive)
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        margin: const EdgeInsets.only(left: 6),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_rounded, size: 12, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              "متوقف",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    // Status Badge (محفوظ/جديد)
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isSaved
            ? const Color(0xFF10B981).withOpacity(0.1)
            : const Color(0xFFF59E0B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSaved ? Icons.cloud_done_rounded : Icons.add_circle_rounded,
            size: 12,
            color: isSaved
                ? const Color(0xFF10B981)
                : const Color(0xFFF59E0B),
          ),
          const SizedBox(width: 4),
          Text(
            isSaved ? "محفوظ" : "جديد",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isSaved
                  ? const Color(0xFF10B981)
                  : const Color(0xFFF59E0B),
            ),
          ),
        ],
      ),
    ),
  ],
),
                        const SizedBox(height: 4),
                        Text(
                          "${emp.job ?? '---'} • ${emp.branchName ?? '---'}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Delete Button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAbsentIds.remove(emp.id);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFFEF4444),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Notes Field
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                ),
                child: TextField(
                  controller: TextEditingController(text: _notesMap[emp.id]),
                  onChanged: (val) => _notesMap[emp.id] = val,
                  decoration: InputDecoration(
                    hintText: "ملاحظة (اختياري)...",
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                    prefixIcon: Icon(
                      Icons.note_alt_outlined,
                      size: 18,
                      color: Colors.grey[400],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 📭 Empty State
  Widget _buildEmptyState(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252836) : Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 50,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "لا يوجد غياب مسجل",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "جميع الموظفين حاضرين لهذا اليوم 🎉\nأو اضغط لاختيار الغائبين",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showSelectEmployeesSheet,
            icon: const Icon(Icons.person_add_rounded),
            label: const Text("اختيار الغائبين"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 💾 Save FAB
  Widget _buildSaveFAB() {
    final hasChanges = _selectedAbsentIds.difference(_savedAbsentIds).isNotEmpty ||
                       _savedAbsentIds.difference(_selectedAbsentIds).isNotEmpty;

    if (_selectedAbsentIds.isEmpty && _savedAbsentIds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: hasChanges
              ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
              : [Colors.grey, Colors.grey[600]!],
        ),
        boxShadow: [
          BoxShadow(
            color: hasChanges
                ? const Color(0xFFEF4444).withOpacity(0.4)
                : Colors.grey.withOpacity(0.3),
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isSaving
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
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
                  const Icon(Icons.save_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    hasChanges ? "حفظ التغييرات" : "حفظ الغياب",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (hasChanges) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${_selectedAbsentIds.length}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  // 📅 Format Display Date
  String _formatDisplayDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        return "اليوم - ${DateFormat('d MMMM', 'ar').format(date)}";
      } else if (date.year == yesterday.year &&
                 date.month == yesterday.month &&
                 date.day == yesterday.day) {
        return "أمس - ${DateFormat('d MMMM', 'ar').format(date)}";
      }
      return DateFormat('EEEE d MMMM yyyy', 'ar').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}