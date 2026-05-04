import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io'; // للملفات
import 'package:path_provider/path_provider.dart'; // لمسار الحفظ المؤقت
import 'package:share_plus/share_plus.dart'; // للمشاركة
import '../providers/attendance_provider.dart';
import '../providers/children_provider.dart';
import '../providers/classes_provider.dart';
import '../providers/theme_provider.dart';

class ChildrenAttendanceReportScreen extends StatefulWidget {
  const ChildrenAttendanceReportScreen({super.key});

  @override
  State<ChildrenAttendanceReportScreen> createState() => _ChildrenAttendanceReportScreenState();
}

class _ChildrenAttendanceReportScreenState extends State<ChildrenAttendanceReportScreen> {
  DateTimeRange? _selectedDateRange;
  int? _selectedBranchId;
  int? _selectedClassId;
  int? _selectedChildId; // (مستقبلاً لو حبيت تختار طفل من قايمة)
  
  // للبحث بالاسم (فلترة محلية مؤقتاً أو نربطها بـ API بحث)
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDateRange = DateTimeRange(start: DateTime.now(), end: DateTime.now());
    
    Future.delayed(Duration.zero, () {
      Provider.of<ChildrenProvider>(context, listen: false).fetchBranches();
      _fetchReport();
    });
  }

  void _fetchReport() {
    Provider.of<AttendanceProvider>(context, listen: false).fetchChildrenAbsenceReport(
      fromDate: _selectedDateRange?.start,
      toDate: _selectedDateRange?.end,
      branchId: _selectedBranchId,
      classId: _selectedClassId,
      childId: _selectedChildId,
    );
  }

  // اختيار الفترة الزمنية
  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF6366F1)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      _fetchReport();
    }
  }

  // تغيير الفرع (وتصفير الفصل)
  void _onBranchChanged(int? val) {
    setState(() {
      _selectedBranchId = val;
      _selectedClassId = null;
    });
    if (val != null) {
      Provider.of<ClassesProvider>(context, listen: false).fetchClasses(val);
    }
    _fetchReport();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    final provider = Provider.of<AttendanceProvider>(context);
    final branches = Provider.of<ChildrenProvider>(context).branches;
    final classes = Provider.of<ClassesProvider>(context).classes;

    // تصفية القائمة بناءً على البحث المحلي (بالاسم)
    final filteredList = provider.reportList.where((item) {
      final name = item['FullNameArabic'] ?? '';
      return name.contains(_searchController.text);
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("تقارير غياب الاطفال"),
        backgroundColor: const Color(0xFF6366F1),
        actions: [
          // زر المشاركة
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
               final provider = Provider.of<AttendanceProvider>(context, listen: false);
              _shareReport(provider.reportList);
            },
            tooltip: "مشاركة",
          ),
          // زر الطباعة
          IconButton(
            icon: const Icon(Icons.print_rounded),
            onPressed: () {
               final provider = Provider.of<AttendanceProvider>(context, listen: false);
              _printReport(provider.reportList);
            },
            tooltip: "طباعة",
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. لوحة التحكم (Filters)
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? const Color(0xFF252836) : Colors.white,
            child: Column(
              children: [
                // سطر التاريخ والبحث (المعدل)
                Row(
                  children: [
                    Expanded(
                      flex: 4, // نسبة العرض 40%
                      child: InkWell(
                        onTap: _pickDateRange,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12), // قللنا الحواف
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.date_range, size: 16, color: Color(0xFF6366F1)),
                              const SizedBox(width: 4),
                              // 👇 الحل هنا: Flexible + Ellipsis
                              Flexible(
                                child: Text(
                                  "${DateFormat('MM/dd').format(_selectedDateRange!.start)} - ${DateFormat('MM/dd').format(_selectedDateRange!.end)}",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), // صغرنا الخط
                                  overflow: TextOverflow.ellipsis, // يقص الزيادة
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 6, // نسبة العرض 60%
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() {}),
                        style: const TextStyle(fontSize: 13), // صغرنا خط الكتابة
                        decoration: InputDecoration(
                          hintText: "بحث بالاسم...",
                          hintStyle: const TextStyle(fontSize: 12),
                          prefixIcon: const Icon(Icons.search, size: 18),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          isDense: true, // يقلل الارتفاع
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                
                // سطر الفروع والفصول (المعدل)
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _selectedBranchId,
                        isExpanded: true, // 👈 الحل السحري (يمنع الخروج عن النص)
                        hint: const Text("كل الفروع", style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                        items: [
                          const DropdownMenuItem<int>(value: null, child: Text("كل الفروع", style: TextStyle(fontSize: 12))),
                          ...branches.map((b) => DropdownMenuItem<int>(
                                value: b['IDbranch'],
                                child: Text(b['branchName'], style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                              )),
                        ],
                        onChanged: _onBranchChanged,
                        decoration: _filterDecoration(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _selectedClassId,
                        isExpanded: true, // 👈 الحل السحري
                        hint: const Text("كل الفصول", style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                        items: [
                          const DropdownMenuItem<int>(value: null, child: Text("كل الفصول", style: TextStyle(fontSize: 12))),
                          ...classes.map((c) => DropdownMenuItem<int>(
                                value: c['Class_ID'],
                                child: Text(c['ClassName'], style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                              )),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedClassId = val);
                          _fetchReport();
                        },
                        decoration: _filterDecoration(),
                      ),
                    ),
                  ],
                ),

              ],
            ),
          ),

          // 2. الإحصائيات المودرن (New)
          if (!provider.isLoading && filteredList.isNotEmpty)
            _buildStatsGrid(filteredList, isDark),

          // 3. الجدول / القائمة
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredList.isEmpty
                    ? _buildEmptyState(isDark)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final item = filteredList[index];
                          return _buildReportCard(item, isDark);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildReportCard(dynamic item, bool isDark) {
    // تنسيق التاريخ
    final dateStr = item['Date'] != null 
        ? DateFormat('yyyy-MM-dd').format(DateTime.parse(item['Date'])) 
        : '';

    return Card(
      color: isDark ? const Color(0xFF252836) : Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, // المحاذاة للأعلى
          children: [
            // 1. التاريخ (في بوكس جانبي ثابت العرض)
            Container(
              width: 50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('dd').format(DateTime.parse(item['Date'])),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
                  ),
                  Text(
                    DateFormat('MMM').format(DateTime.parse(item['Date'])),
                    style: const TextStyle(fontSize: 10, color: Colors.red),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // 2. تفاصيل الاسم والفصل (مرنة)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الاسم
                  Text(
                    item['FullNameArabic'] ?? "بدون اسم",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // الفصل والفرع (بخط صغير ولون رمادي)
                  Row(
                    children: [
                      Icon(Icons.place_outlined, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded( // 👈 الحل هنا
                        child: Text(
                          "${item['branchName']} - ${item['ClassName']}",
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  // الملاحظات (لو موجودة)
                  if (item['Notes'] != null && item['Notes'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "📝 ${item['Notes']}",
                          style: const TextStyle(color: Colors.orange, fontSize: 11),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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

  InputDecoration _filterDecoration() {
    return const InputDecoration(
      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(),
      isDense: true,
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 10),
          Text("لا توجد بيانات تطابق البحث", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])),
        ],
      ),
    );
  }
    /// دالة لإنشاء وطباعة ملف PDF
     /// دالة طباعة التقرير (النسخة النهائية المصححة للعربية)
      /// دالة طباعة التقرير الشاملة (تفاصيل + ملخص إحصائي)
    // ==================== PDF FUNCTIONS (الطباعة والمشاركة) ====================

  /// 1. الدالة الأساسية لبناء ملف الـ PDF (المشتركة)
  Future<pw.Document> _buildPdfDocument(List<dynamic> data) async {
    // تحميل الخط العربي
    final fontData = await rootBundle.load("assets/fonts/Cairo-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);
    
    // تحميل اللوجو (اختياري)
    pw.MemoryImage? logo;
    try {
      final logoData = await rootBundle.load("assets/images/logo.png");
      logo = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {} 

    // تجهيز النصوص الذكية
    String branchName = "كل الفروع";
    if (_selectedBranchId != null) {
      final branches = Provider.of<ChildrenProvider>(context, listen: false).branches;
      final b = branches.firstWhere((b) => b['IDbranch'] == _selectedBranchId, orElse: () => null);
      if (b != null) branchName = "فرع ${b['branchName']}";
    }

    String className = "";
    if (_selectedClassId != null) {
      final classes = Provider.of<ClassesProvider>(context, listen: false).classes;
      final c = classes.firstWhere((c) => c['Class_ID'] == _selectedClassId, orElse: () => null);
      if (c != null) className = " - فصل ${c['ClassName']}";
    }

    String reportTitle = "تقرير غياب $branchName$className";
    String periodText = "${DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start)} إلى ${DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end)}";

    // تجميع الإحصائيات
    Map<String, Map<String, int>> stats = {};
    for (var item in data) {
      String b = item['branchName'] ?? "غير معروف";
      String c = item['ClassName'] ?? "غير معروف";
      if (!stats.containsKey(b)) stats[b] = {};
      stats[b]![c] = (stats[b]![c] ?? 0) + 1;
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: ttf, bold: ttf),
        textDirection: pw.TextDirection.rtl,
        
        header: (context) {
          return pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(reportTitle, style: pw.TextStyle(font: ttf, fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                        pw.SizedBox(height: 4),
                        pw.Text("الفترة: $periodText", style: pw.TextStyle(font: ttf, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (logo != null) pw.Container(width: 60, height: 60, child: pw.Image(logo)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1, color: PdfColors.blue800),
              pw.SizedBox(height: 10),
            ],
          );
        },

        footer: (context) => pw.Center(
          child: pw.Text("صفحة ${context.pageNumber} من ${context.pagesCount}", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
        ),

        build: (context) {
          return [
            // أ) الجدول التفصيلي (مرتب من اليمين لليسار)
            pw.Text("تفاصيل الغياب:", style: pw.TextStyle(font: ttf, fontSize: 14, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
            pw.SizedBox(height: 5),
            
            pw.Table.fromTextArray(
              context: context,
              border: pw.TableBorder.all(color: PdfColors.grey400),
              headerStyle: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
              rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
              cellStyle: pw.TextStyle(font: ttf, fontSize: 10),
              cellAlignment: pw.Alignment.center,
              
                // الترتيب الأصلي اللي أنت بعته
                headers: ["المسجل", "السبب", "الفصل", "اسم الطفل", "التاريخ"],
                
                data: data.map((item) {
                  return [
                    item['userAdd'] ?? "",        // المسجل
                    item['Notes'] ?? "-",         // السبب
                    item['ClassName'] ?? "",      // الفصل
                    item['FullNameArabic'] ?? "", // اسم الطفل
                    DateFormat('MM-dd').format(DateTime.parse(item['Date'])), // التاريخ
                  ];
                }).toList(),

                // المحاذاة (حسب الترتيب ده)
                cellAlignments: {
                  0: pw.Alignment.center,      // المسجل (وسط)
                  1: pw.Alignment.centerRight, // السبب (يمين)
                  2: pw.Alignment.center,      // الفصل (وسط)
                  3: pw.Alignment.centerRight, // اسم الطفل (يمين)
                  4: pw.Alignment.center,      // التاريخ (وسط)
                },
              ),

            pw.SizedBox(height: 20),

            // ب) الملخص الإحصائي
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey), borderRadius: pw.BorderRadius.circular(5)),
              child: pw.Column(
                children: [
                  pw.Text("ملخص الإحصائيات", style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                  pw.Divider(),
                  ...stats.entries.map((branchEntry) {
                    int total = branchEntry.value.values.fold(0, (sum, c) => sum + c);
                    return pw.Column(children: [
                      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                        pw.Text("• ${branchEntry.key}", style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold)),
                        pw.Text("$total", style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold)),
                      ]),
                      pw.Padding(padding: const pw.EdgeInsets.only(right: 10), child: pw.Column(
                        children: branchEntry.value.entries.map((e) => pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, 
                          children: [pw.Text("- ${e.key}", style: pw.TextStyle(font: ttf, fontSize: 10)), pw.Text("${e.value}", style: pw.TextStyle(font: ttf, fontSize: 10))]
                        )).toList()
                      ))
                    ]);
                  }).toList(),
                  pw.Divider(),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                    pw.Text("الإجمالي الكلي:", style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
                    pw.Text("${data.length}", style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, color: PdfColors.red, fontSize: 14)),
                  ]),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  /// 2. دالة الطباعة (Print)
  Future<void> _printReport(List<dynamic> data) async {
    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("لا توجد بيانات")));
      return;
    }
    try {
      final pdf = await _buildPdfDocument(data); // 👈 استدعاء الدالة الموحدة
      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'تقرير_ غياب_الاطفال_${DateFormat('yyyyMMdd').format(DateTime.now())}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: $e")));
    }
  }

  /// 3. دالة المشاركة (Share)
  Future<void> _shareReport(List<dynamic> data) async {
    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("لا توجد بيانات")));
      return;
    }
    try {
      final pdf = await _buildPdfDocument(data); // 👈 استدعاء الدالة الموحدة
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/تقرير_غياب_الاطفال_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf");
      await file.writeAsBytes(await pdf.save());
      
      await Share.shareXFiles([XFile(file.path)], text: 'تقرير غياب الأطفال');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("فشل المشاركة")));
    }
  }
  // دالة الإحصائيات المفصلة (Expandable)
  Widget _buildStatsGrid(List<dynamic> list, bool isDark) {
    // 1. تجميع البيانات
    Map<String, Map<String, int>> stats = {};
    for (var item in list) {
      String branch = item['branchName'] ?? "غير معروف";
      String cls = item['ClassName'] ?? "غير معروف";
      if (!stats.containsKey(branch)) stats[branch] = {};
      stats[branch]![cls] = (stats[branch]![cls] ?? 0) + 1;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? Colors.black26 : Colors.blue.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.blue.withOpacity(0.3))),
      child: ExpansionTile(
        title: Row(
          children: [
            const Icon(Icons.analytics_outlined, color: Colors.blue),
            const SizedBox(width: 10),
            Text("إحصائيات الغياب (${list.length})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: stats.entries.map((branchEntry) {
                int branchTotal = branchEntry.value.values.fold(0, (sum, count) => sum + count);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // سطر الفرع
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(branchEntry.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(4)),
                          child: Text("$branchTotal", style: const TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                      ],
                    ),
                    const Divider(height: 8),
                    // تفاصيل الفصول
                    ...branchEntry.value.entries.map((classEntry) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 10, bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("- ${classEntry.key}", style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                            Text("${classEntry.value}", style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 8),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

}