import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../models/payroll_model.dart';

class PayrollExcelService {
  static Future<String> generatePayrollExcel({
    required List<PayrollModel> employees,
    required int month,
    required int year,
    required String monthName,
  }) async {
    final excel = Excel.createExcel();

    // إنشاء الشيت
    final sheetName = 'رواتب $monthName $year';
    excel.rename('Sheet1', sheetName);
    final sheet = excel[sheetName];

    // ======== عنوان الكشف ========
    sheet.merge(
        CellIndex.indexByString('A1'), CellIndex.indexByString('P1'));
    final titleCell = sheet.cell(CellIndex.indexByString('A1'));
    titleCell.value = TextCellValue('كشف رواتب شهر $monthName / $year');
    titleCell.cellStyle = CellStyle(
      bold: true,
      fontSize: 16,
      horizontalAlign: HorizontalAlign.Center,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#1976D2'),
    );

    // ======== العناوين ========
    final headers = [
      'م',
      'كود',
      'الاسم',
      'الوظيفة',
      'الفرع',
      'الأساسي',
      'إضافي',
      'بدل',
      'مكافأة',
      'إجمالي الاستحقاقات',
      'جزاءات',
      'باص',
      'أيام الغياب',
      'مبلغ الغياب',
      'قسط سلفة',
      'إجمالي الاستقطاعات',
      'سلفة مصروفة',
      'صافي الموظف',
      'ملاحظات',
    ];

    final headerStyle = CellStyle(
      bold: true,
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Center,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#1565C0'),
    );

    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // ======== البيانات ========
    final selectedEmps = employees.where((e) => e.isSelected).toList();
    final dataStyle = CellStyle(
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Center,
    );
    final nameStyle = CellStyle(
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Right,
    );

    for (int i = 0; i < selectedEmps.length; i++) {
      final emp = selectedEmps[i];
      final row = i + 3;

      final values = [
        TextCellValue('${i + 1}'),
        IntCellValue(emp.empId),
        TextCellValue(emp.empName),
        TextCellValue(emp.job ?? ''),
        TextCellValue(emp.branchName ?? ''),
        DoubleCellValue(emp.baseSalary),
        DoubleCellValue(emp.extraTime),
        DoubleCellValue(emp.badal),
        DoubleCellValue(emp.reward),
        DoubleCellValue(emp.totalAdditions),
        DoubleCellValue(emp.penalty),
        DoubleCellValue(emp.busSub),
        IntCellValue(emp.absenceDays),
        DoubleCellValue(emp.absenceAmount),
        DoubleCellValue(emp.qstSolfa),
        DoubleCellValue(emp.totalDeductions),
        DoubleCellValue(emp.solfa),
        DoubleCellValue(emp.netForEmployee),
        TextCellValue(emp.notes ?? ''),
      ];

      for (int j = 0; j < values.length; j++) {
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: row));
        cell.value = values[j];
        cell.cellStyle = j == 2 ? nameStyle : dataStyle;

        // تلوين الصافي السالب
        if (j == 17 && emp.netForEmployee < 0) {
          cell.cellStyle = CellStyle(
            fontSize: 10,
            horizontalAlign: HorizontalAlign.Center,
            fontColorHex: ExcelColor.fromHexString('#FF0000'),
            bold: true,
          );
        }
      }
    }

    // ======== صف الإجماليات ========
    final totalRow = selectedEmps.length + 3;
    final totalStyle = CellStyle(
      bold: true,
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#FFF3E0'),
    );

    // دمج خلايا "الإجمالي"
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRow),
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: totalRow),
    );
    final totalLabelCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRow));
    totalLabelCell.value = TextCellValue('الإجمالي');
    totalLabelCell.cellStyle = totalStyle;

    final totalValues = [
      5,
      selectedEmps.fold(0.0, (s, e) => s + e.baseSalary), // أساسي
      6,
      selectedEmps.fold(0.0, (s, e) => s + e.extraTime), // إضافي
      7,
      selectedEmps.fold(0.0, (s, e) => s + e.badal), // بدل
      8,
      selectedEmps.fold(0.0, (s, e) => s + e.reward), // مكافأة
      9,
      selectedEmps.fold(0.0, (s, e) => s + e.totalAdditions), // إجمالي+
      10,
      selectedEmps.fold(0.0, (s, e) => s + e.penalty), // جزاءات
      11,
      selectedEmps.fold(0.0, (s, e) => s + e.busSub), // باص
      13,
      selectedEmps.fold(0.0, (s, e) => s + e.absenceAmount), // غياب
      14,
      selectedEmps.fold(0.0, (s, e) => s + e.qstSolfa), // ق.سلفة
      15,
      selectedEmps.fold(0.0, (s, e) => s + e.totalDeductions), // إجمالي-
      16,
      selectedEmps.fold(0.0, (s, e) => s + e.solfa), // سلفة
      17,
      selectedEmps.fold(0.0, (s, e) => s + e.netForEmployee), // صافي
    ];

    for (int i = 0; i < totalValues.length; i += 2) {
      final col = totalValues[i] as int;
      final val = totalValues[i + 1] as double;
      final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: totalRow));
      cell.value = DoubleCellValue(val);
      cell.cellStyle = totalStyle;
    }

    // ======== ضبط عرض الأعمدة ========
    sheet.setColumnWidth(2, 25); // الاسم
    sheet.setColumnWidth(3, 15); // الوظيفة
    sheet.setColumnWidth(4, 15); // الفرع
    sheet.setColumnWidth(18, 20); // ملاحظات

    // ======== حفظ الملف ========
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/payroll_${month}_$year.xlsx';
    final fileBytes = excel.save();

    if (fileBytes != null) {
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);
    }

    return filePath;
  }
}