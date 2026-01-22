// ============================================
// FILE: lib/core/utils/excel_export_helper.dart
// Helper class for exporting data to Excel with RTL support
// ============================================

import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/volunteer_model.dart';
import '../../data/models/committee_model.dart';

class ExcelExportHelper {
  // Export committee with its volunteers
  static Future<void> exportCommitteeToExcel({
    required CommitteeModel committee,
    required List<VolunteerModel> volunteers,
  }) async {
    try {
      // Create Excel file
      var excel = Excel.createExcel();
      Sheet sheet = excel['اللجنة - ${committee.name}'];

      // Set sheet to RTL mode
      _setSheetToRTL(sheet);

      // Add committee info header
      sheet.merge(
        CellIndex.indexByString('A1'),
        CellIndex.indexByString('G1'),
      ); // Changed to G for 7 columns
      var committeeHeaderCell = sheet.cell(CellIndex.indexByString('A1'));
      committeeHeaderCell.value = TextCellValue('معلومات اللجنة');
      committeeHeaderCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 16,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      // Committee details
      sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue(
        'اسم اللجنة:',
      );
      sheet.cell(CellIndex.indexByString('A2')).cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
      );

      sheet.cell(CellIndex.indexByString('B2')).value = TextCellValue(
        committee.name,
      );
      sheet.cell(CellIndex.indexByString('B2')).cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
      );

      sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue('الوصف:');
      sheet.cell(CellIndex.indexByString('A3')).cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
      );
      sheet.cell(CellIndex.indexByString('B3')).value = TextCellValue(
        committee.description ?? 'لا يوجد',
      );
      sheet.cell(CellIndex.indexByString('B3')).cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
      );

      sheet.cell(CellIndex.indexByString('A4')).value = TextCellValue(
        'الحالة:',
      );
      sheet.cell(CellIndex.indexByString('A4')).cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
      );
      sheet.cell(CellIndex.indexByString('B4')).value = TextCellValue(
        committee.isActive ? 'نشط' : 'غير نشط',
      );
      sheet.cell(CellIndex.indexByString('B4')).cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
      );

      // Volunteers table header
      sheet.merge(
        CellIndex.indexByString('A6'),
        CellIndex.indexByString('G6'),
      ); // Changed to G for 7 columns
      var volunteersHeaderCell = sheet.cell(CellIndex.indexByString('A6'));
      volunteersHeaderCell.value = TextCellValue('المتطوعون');
      volunteersHeaderCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 14,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      // Column headers - updated order and removed email
      var headers = [
        'المستوى التطوعي', // Educational level
        'اللجنة', // Committee name
        'العمر', // Age
        'العنوان', // Address
        'الهاتف', // Phone
        'الاسم', // Name
        '#', // Number
      ];

      for (var i = 0; i < headers.length; i++) {
        var cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 7),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.blue,
          fontColorHex: ExcelColor.white,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );
      }

      // Add volunteers data - updated to match new column order
      for (var i = 0; i < volunteers.length; i++) {
        var volunteer = volunteers[i];
        var rowIndex = i + 8;

        // Column 0: Educational level (from volunteer.educationalLevel)
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          volunteer.educationalLevel ?? 'غير محدد',
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
            )
            .cellStyle = CellStyle(
          horizontalAlign: HorizontalAlign.Right,
          verticalAlign: VerticalAlign.Center,
        );

        // Column 1: Committee name (from volunteer.committeeName)
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          volunteer.committeeName ?? 'غير محدد',
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
            )
            .cellStyle = CellStyle(
          horizontalAlign: HorizontalAlign.Right,
          verticalAlign: VerticalAlign.Center,
        );

        // Column 2: Age - centered
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          volunteer.age?.toString() ?? 'غير محدد',
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
            )
            .cellStyle = CellStyle(
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );

        // Column 3: Address - right aligned for Arabic
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          volunteer.address ?? 'غير محدد',
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
            )
            .cellStyle = CellStyle(
          horizontalAlign: HorizontalAlign.Right,
          verticalAlign: VerticalAlign.Center,
        );

        // Column 4: Phone - right aligned
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          volunteer.phone,
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
            )
            .cellStyle = CellStyle(
          horizontalAlign: HorizontalAlign.Right,
          verticalAlign: VerticalAlign.Center,
        );

        // Column 5: Name - right aligned for Arabic
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          volunteer.name,
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex),
            )
            .cellStyle = CellStyle(
          horizontalAlign: HorizontalAlign.Right,
          verticalAlign: VerticalAlign.Center,
        );

        // Column 6: Row number - centered
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          (i + 1).toString(),
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex),
            )
            .cellStyle = CellStyle(
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );
      }

      // Auto-fit columns
      for (var i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 18); // Slightly smaller width for 7 columns
      }

      // Save and share file
      await _saveAndShareExcel(
        excel,
        'لجنة_${committee.name}_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      print('Error exporting committee to Excel: $e');
      rethrow;
    }
  }

  // Export event with volunteers - SIMPLIFIED VERSION
  static Future<void> exportEventToExcel({
    required String eventTitle,
    required String eventType,
    required String eventDate,
    required String? eventLocation,
    required List<VolunteerModel> volunteers,
  }) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['الحدث - $eventTitle'];

      // Set sheet to RTL mode
      _setSheetToRTL(sheet);

      // Event info header - only 4 columns needed
      sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('D1'));
      var eventHeaderCell = sheet.cell(CellIndex.indexByString('A1'));
      eventHeaderCell.value = TextCellValue('معلومات الحدث');
      eventHeaderCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 16,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      // Event details
      sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue(
        'عنوان الحدث:',
      );
      sheet.cell(CellIndex.indexByString('A2')).cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
      );

      sheet.cell(CellIndex.indexByString('B2')).value = TextCellValue(
        eventTitle,
      );
      sheet.cell(CellIndex.indexByString('B2')).cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
      );

      sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue(
        'نوع الحدث:',
      );
      sheet.cell(CellIndex.indexByString('A3')).cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
      );
      sheet.cell(CellIndex.indexByString('B3')).value = TextCellValue(
        eventType,
      );
      sheet.cell(CellIndex.indexByString('B3')).cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
      );

      sheet.cell(CellIndex.indexByString('A4')).value = TextCellValue(
        'التاريخ:',
      );
      sheet.cell(CellIndex.indexByString('A4')).cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
      );
      sheet.cell(CellIndex.indexByString('B4')).value = TextCellValue(
        eventDate,
      );
      sheet.cell(CellIndex.indexByString('B4')).cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
      );

      sheet.cell(CellIndex.indexByString('A5')).value = TextCellValue(
        'المكان:',
      );
      sheet.cell(CellIndex.indexByString('A5')).cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
      );
      sheet.cell(CellIndex.indexByString('B5')).value = TextCellValue(
        eventLocation ?? 'غير محدد',
      );
      sheet.cell(CellIndex.indexByString('B5')).cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
      );

      // Volunteers table header - only 4 columns
      sheet.merge(CellIndex.indexByString('A7'), CellIndex.indexByString('D7'));
      var volunteersHeaderCell = sheet.cell(CellIndex.indexByString('A7'));
      volunteersHeaderCell.value = TextCellValue('المتطوعون');
      volunteersHeaderCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 14,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      // Column headers - ONLY 4 COLUMNS as requested
      var headers = [
        'تيشيرت', // T-shirt
        'الهاتف', // Phone
        'الاسم', // Name
        '#', // Number
      ];

      for (var i = 0; i < headers.length; i++) {
        var cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 8),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.green,
          fontColorHex: ExcelColor.white,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );
      }

      // Add volunteers data - simplified to only 4 columns
      for (var i = 0; i < volunteers.length; i++) {
        var volunteer = volunteers[i];
        var rowIndex = i + 9;

        // Column 0: T-shirt - centered
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          volunteer.hasTshirt ? 'نعم' : 'لا',
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
            )
            .cellStyle = CellStyle(
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );

        // Column 1: Phone - right aligned
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          volunteer.phone,
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
            )
            .cellStyle = CellStyle(
          horizontalAlign: HorizontalAlign.Right,
          verticalAlign: VerticalAlign.Center,
        );

        // Column 2: Name - right aligned for Arabic
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          volunteer.name,
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
            )
            .cellStyle = CellStyle(
          horizontalAlign: HorizontalAlign.Right,
          verticalAlign: VerticalAlign.Center,
        );

        // Column 3: Row number - centered
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          (i + 1).toString(),
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
            )
            .cellStyle = CellStyle(
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );
      }

      // Auto-fit columns with appropriate widths
      sheet.setColumnWidth(0, 12); // تيشيرت - smaller
      sheet.setColumnWidth(1, 18); // الهاتف - medium
      sheet.setColumnWidth(2, 25); // الاسم - wider for names
      sheet.setColumnWidth(3, 8); // # - smallest

      // Save and share file
      await _saveAndShareExcel(
        excel,
        'حدث_${eventTitle}_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      print('Error exporting event to Excel: $e');
      rethrow;
    }
  }

  // Helper method to set sheet RTL properties
  static void _setSheetToRTL(Sheet sheet) {
    try {
      // Note: The excel package doesn't have direct RTL support at cell level.
      // We work around this by setting text alignment to Right for Arabic text.
      // Some Excel libraries support RTL via sheet properties, but this package may not.
      // We'll apply Right alignment to all Arabic text cells as a workaround.

      // You could also try to set the default direction if the package supports it:
      // sheet.sheetFormatPr?.rtl = true; // If available

      // For now, we rely on proper alignment for RTL appearance
    } catch (e) {
      print('Error setting RTL: $e');
    }
  }

  // Helper method to save and share Excel file
  static Future<void> _saveAndShareExcel(Excel excel, String fileName) async {
    try {
      // Encode Excel to bytes
      var fileBytes = excel.save();
      if (fileBytes == null) {
        throw Exception('فشل في إنشاء الملف');
      }

      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName.xlsx';

      // Write file
      File file = File(filePath);
      await file.writeAsBytes(fileBytes);

      // Share file
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: fileName,
        text: 'تصدير البيانات من تطبيق رسالة',
      );
    } catch (e) {
      print('Error saving/sharing Excel file: $e');
      rethrow;
    }
  }

  // Alternative: Create a more RTL-friendly Excel using cell formatting
  static Future<void> exportWithBetterRTLSupport({
    required String sheetName,
    required List<Map<String, dynamic>> data,
    required List<String> headers,
  }) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel[sheetName];

      // Set Arabic headers with right alignment
      for (var i = 0; i < headers.length; i++) {
        var cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Right,
          verticalAlign: VerticalAlign.Center,
        );
      }

      // Add data with proper alignment
      for (var row = 0; row < data.length; row++) {
        var rowData = data[row];
        for (var col = 0; col < headers.length; col++) {
          var header = headers[col];
          var value = rowData[header]?.toString() ?? '';

          var cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1),
          );
          cell.value = TextCellValue(value);

          // Determine alignment based on content type
          bool isNumeric = double.tryParse(value) != null;
          bool isArabic = _containsArabic(value);

          cell.cellStyle = CellStyle(
            horizontalAlign: isNumeric || value.isEmpty
                ? HorizontalAlign.Center
                : HorizontalAlign.Right,
            verticalAlign: VerticalAlign.Center,
          );
        }
      }

      // Auto-fit columns
      for (var i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 20);
      }

      await _saveAndShareExcel(
        excel,
        'export_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      print('Error in exportWithBetterRTLSupport: $e');
      rethrow;
    }
  }

  // Helper to check if text contains Arabic characters
  static bool _containsArabic(String text) {
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    return arabicRegex.hasMatch(text);
  }
}
