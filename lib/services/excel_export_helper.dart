// ============================================
// FILE: lib/core/utils/excel_export_helper.dart
// Helper class for exporting data to Excel
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

      // Add committee info header
      sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('F1'));
      var committeeHeaderCell = sheet.cell(CellIndex.indexByString('A1'));
      committeeHeaderCell.value = TextCellValue('معلومات اللجنة');
      committeeHeaderCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 16,
        horizontalAlign: HorizontalAlign.Center,
      );

      // Committee details
      sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue(
        'اسم اللجنة:',
      );
      sheet.cell(CellIndex.indexByString('B2')).value = TextCellValue(
        committee.name,
      );

      sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue('الوصف:');
      sheet.cell(CellIndex.indexByString('B3')).value = TextCellValue(
        committee.description ?? 'لا يوجد',
      );

      sheet.cell(CellIndex.indexByString('A4')).value = TextCellValue(
        'الحالة:',
      );
      sheet.cell(CellIndex.indexByString('B4')).value = TextCellValue(
        committee.isActive ? 'نشط' : 'غير نشط',
      );

      // Volunteers table header
      sheet.merge(CellIndex.indexByString('A6'), CellIndex.indexByString('F6'));
      var volunteersHeaderCell = sheet.cell(CellIndex.indexByString('A6'));
      volunteersHeaderCell.value = TextCellValue('المتطوعون');
      volunteersHeaderCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 14,
        horizontalAlign: HorizontalAlign.Center,
      );

      // Column headers
      var headers = ['#', 'الاسم', 'الهاتف', 'البريد', 'العنوان', 'العمر'];
      for (var i = 0; i < headers.length; i++) {
        var cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 7),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.blue,
          fontColorHex: ExcelColor.white,
        );
      }

      // Add volunteers data
      for (var i = 0; i < volunteers.length; i++) {
        var volunteer = volunteers[i];
        var rowIndex = i + 8;

        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          (i + 1).toString(),
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          volunteer.name,
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          volunteer.phone,
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          volunteer.email,
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          volunteer.address,
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          volunteer.age?.toString() ?? 'غير محدد',
        );
      }

      // Auto-fit columns
      for (var i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 20);
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

  // Export event with volunteers
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

      // Event info header
      sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('G1'));
      var eventHeaderCell = sheet.cell(CellIndex.indexByString('A1'));
      eventHeaderCell.value = TextCellValue('معلومات الحدث');
      eventHeaderCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 16,
        horizontalAlign: HorizontalAlign.Center,
      );

      // Event details
      sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue(
        'عنوان الحدث:',
      );
      sheet.cell(CellIndex.indexByString('B2')).value = TextCellValue(
        eventTitle,
      );

      sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue(
        'نوع الحدث:',
      );
      sheet.cell(CellIndex.indexByString('B3')).value = TextCellValue(
        eventType,
      );

      sheet.cell(CellIndex.indexByString('A4')).value = TextCellValue(
        'التاريخ:',
      );
      sheet.cell(CellIndex.indexByString('B4')).value = TextCellValue(
        eventDate,
      );

      sheet.cell(CellIndex.indexByString('A5')).value = TextCellValue(
        'المكان:',
      );
      sheet.cell(CellIndex.indexByString('B5')).value = TextCellValue(
        eventLocation ?? 'غير محدد',
      );

      // Volunteers table header
      sheet.merge(CellIndex.indexByString('A7'), CellIndex.indexByString('G7'));
      var volunteersHeaderCell = sheet.cell(CellIndex.indexByString('A7'));
      volunteersHeaderCell.value = TextCellValue('المتطوعون');
      volunteersHeaderCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 14,
        horizontalAlign: HorizontalAlign.Center,
      );

      // Column headers
      var headers = [
        '#',
        'الاسم',
        'الهاتف',
        'البريد',
        'العنوان',
        'العمر',
        'تيشيرت',
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
        );
      }

      // Add volunteers data
      for (var i = 0; i < volunteers.length; i++) {
        var volunteer = volunteers[i];
        var rowIndex = i + 9;

        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          (i + 1).toString(),
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          volunteer.name,
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          volunteer.phone,
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          volunteer.email,
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          volunteer.address,
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          volunteer.age?.toString() ?? 'غير محدد',
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          volunteer.hasTshirt ? 'نعم' : 'لا',
        );
      }

      // Auto-fit columns
      for (var i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 18);
      }

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
}
