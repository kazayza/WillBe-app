import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // للصور والخطوط
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/attendance_provider.dart';
import '../providers/theme_provider.dart';

class ChildAbsenceHistoryScreen extends StatefulWidget {
  final int childId;
  final String childName;

  const ChildAbsenceHistoryScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<ChildAbsenceHistoryScreen> createState() =>
      _ChildAbsenceHistoryScreenState();
}

class _ChildAbsenceHistoryScreenState extends State<ChildAbsenceHistoryScreen> {
  DateTimeRange _selectedRange = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, 1), // أول الشهر
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      Provider.of<AttendanceProvider>(context, listen: false)
          .fetchChildHistory(widget.childId);
    });
  }

  // فلترة القائمة محلياً
  List<dynamic> _getFilteredHistory(List<dynamic> fullHistory) {
    return fullHistory.where((item) {
      DateTime date = DateTime.parse(item['Date']);
      // مقارنة التاريخ (نتجاهل الوقت)
      return date.isAfter(_selectedRange.start.subtract(const Duration(days: 1))) &&
             date.isBefore(_selectedRange.end.add(const Duration(days: 1)));
    }).toList();
  }

Future<void> _pickDateRange() async {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDark;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark 
                ? const ColorScheme.dark(
                    primary: Color(0xFF6366F1), // لون الهيدر والزرار
                    onPrimary: Colors.white,
                    surface: Color(0xFF252836), // لون الخلفية
                    onSurface: Colors.white, // لون الأيام
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF6366F1),
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black,
                  ), dialogTheme: DialogThemeData(backgroundColor: isDark ? const Color(0xFF252836) : Colors.white),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() => _selectedRange = picked);
    }
  }

  // ==================== PDF & SHARE LOGIC ====================

  Future<pw.Document> _buildPdfDocument(List<dynamic> data) async {
    final fontData = await rootBundle.load("assets/fonts/Cairo-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);
    
    pw.MemoryImage? logo;
    try {
      final logoData = await rootBundle.load("assets/images/logo.png");
      logo = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {}

    String periodText = "${DateFormat('yyyy-MM-dd').format(_selectedRange.start)} إلى ${DateFormat('yyyy-MM-dd').format(_selectedRange.end)}";
    int totalDays = _selectedRange.duration.inDays + 1;
    int absentDays = data.length;
    double percentage = (absentDays / totalDays) * 100;

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
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("تقرير حالة طالب", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.Text("الطالب: ${widget.childName}", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.Text("الفترة: $periodText", style: const pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                  if (logo != null) pw.Container(width: 50, height: 50, child: pw.Image(logo)),
                ],
              ),
              pw.SizedBox(height: 10),
              // شريط الإحصائيات في الـ PDF
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), color: PdfColors.grey100),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Text("أيام الغياب: $absentDays", style: pw.TextStyle(color: PdfColors.red, fontWeight: pw.FontWeight.bold)),
                    pw.Text("نسبة الغياب: ${percentage.toStringAsFixed(1)}%", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              pw.SizedBox(height: 15),
            ],
          );
        },
        build: (context) {
          return [
            pw.Table.fromTextArray(
              context: context,
              border: pw.TableBorder.all(color: PdfColors.grey400),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
              cellAlignment: pw.Alignment.center,
              // ترتيب الأعمدة (يمين لليسار)
              headers: ["المسجل", "السبب", "اليوم", "التاريخ"],
              data: data.map((item) {
                DateTime d = DateTime.parse(item['Date']);
                return [
                  item['userAdd'] ?? "",
                  item['Notes'] ?? "-",
                  DateFormat('EEEE', 'ar').format(d), // اسم اليوم بالعربي
                  DateFormat('yyyy-MM-dd').format(d),
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );
    return pdf;
  }

  Future<void> _printOrShare(List<dynamic> data, {bool share = false}) async {
    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("لا توجد بيانات")));
      return;
    }
    try {
      final pdf = await _buildPdfDocument(data);
      if (share) {
        final output = await getTemporaryDirectory();
        final file = File("${output.path}/Report_${widget.childName}.pdf");
        await file.writeAsBytes(await pdf.save());
        await Share.shareXFiles([XFile(file.path)], text: 'تقرير غياب: ${widget.childName}');
      } else {
        await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'Report_${widget.childName}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ: $e")));
    }
  }

  // ==================== UI BUILD ====================

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AttendanceProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    
    // 1. الفلترة
    final filteredHistory = _getFilteredHistory(provider.childHistory);
    
    // 2. حساب الإحصائيات
    final int totalDaysInRange = _selectedRange.duration.inDays + 1;
    final int absentDays = filteredHistory.length;
    final double absencePercentage = totalDaysInRange > 0 ? (absentDays / totalDaysInRange) : 0.0;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("سجل الغياب", style: TextStyle(fontSize: 16)),
            Text(widget.childName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: const Color(0xFF6366F1),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () => _printOrShare(filteredHistory, share: true),
          ),
          IconButton(
            icon: const Icon(Icons.print_rounded),
            onPressed: () => _printOrShare(filteredHistory, share: false),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. كارت الإحصائيات والفلتر
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252836) : Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Column(
              children: [
                // زر اختيار الفترة
                InkWell(
                  onTap: _pickDateRange,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${DateFormat('yyyy-MM-dd').format(_selectedRange.start)}  إلى  ${DateFormat('yyyy-MM-dd').format(_selectedRange.end)}",
                          style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                        ),
                        const Icon(Icons.calendar_month_rounded, color: Color(0xFF6366F1)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // الإحصائيات (KPIs)
                Row(
                  children: [
                    _buildStatItem("أيام الغياب", "$absentDays يوم", Colors.red, isDark),
                    Container(width: 1, height: 40, color: Colors.grey.shade300),
                    _buildStatItem("نسبة الغياب", "${(absencePercentage * 100).toStringAsFixed(1)}%", Colors.orange, isDark),
                  ],
                ),
                const SizedBox(height: 10),
                // شريط التقدم (Visual Indicator)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: absencePercentage,
                    backgroundColor: Colors.grey.shade200,
                    color: absencePercentage > 0.3 ? Colors.red : Colors.green, // أحمر لو الغياب عدى 30%
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),

          // 2. القائمة
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredHistory.isEmpty
                    ? _buildEmptyState(isDark)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredHistory.length,
                        itemBuilder: (context, index) {
                          final item = filteredHistory[index];
                          return _buildHistoryCard(item, isDark);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(dynamic item, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: isDark ? const Color(0xFF252836) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            DateFormat('dd\nMMM').format(DateTime.parse(item['Date'])),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 12),
          ),
        ),
        title: Text(
          DateFormat('yyyy-MM-dd (EEEE)', 'ar').format(DateTime.parse(item['Date'])), // اليوم بالعربي
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: item['Notes'] != null && item['Notes'].toString().isNotEmpty
            ? Text("📝 ${item['Notes']}", style: const TextStyle(color: Colors.orange))
            : const Text("بدون عذر", style: TextStyle(color: Colors.grey)),
        trailing: Text(
          item['userAdd'] ?? "",
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 80, color: Colors.green.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            "لا يوجد غياب في هذه الفترة ✅",
            style: TextStyle(fontSize: 16, color: isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}