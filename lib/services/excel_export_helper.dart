// ============================================
// FILE: lib/core/utils/excel_export_helper.dart
// Helper class for exporting data to Excel with RTL support
// ============================================

import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:resala/data/models/report_data_model.dart';
import 'package:share_plus/share_plus.dart';
import '../data/models/volunteer_model.dart';
import '../data/models/committee_model.dart';
import '../data/models/event_model.dart';
import '../data/models/inventory_model.dart';

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

      sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue(
        'الحالة:',
      );
      sheet.cell(CellIndex.indexByString('A3')).cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
      );
      sheet.cell(CellIndex.indexByString('B3')).value = TextCellValue(
        committee.isActive ? 'نشط' : 'غير نشط',
      );
      sheet.cell(CellIndex.indexByString('B3')).cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
      );

      // Volunteers table header
      sheet.merge(
        CellIndex.indexByString('A5'),
        CellIndex.indexByString('G5'),
      ); // Changed to G for 7 columns
      var volunteersHeaderCell = sheet.cell(CellIndex.indexByString('A5'));
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
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 6),
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
        var rowIndex = i + 7;

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
          volunteer.address,
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
    required String eventDescription,
    required List<VolunteerModel> volunteers,
    bool isOnline = false,
    bool isQafla = false,
    Map<String, bool>? qaflaPreparation,
    Map<String, bool>? qaflaFilling,
    Map<String, bool>? qaflaDistribution,
  }) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['الحدث - $eventTitle'];

      // Set sheet to RTL mode
      _setSheetToRTL(sheet);

      // Build dynamic column list based on event type
      var headers = <String>[];
      if (isQafla) {
        headers.addAll(['توزيع', 'تعبئة', 'تجهيز']);
      }
      if (!isOnline) {
        headers.add('تيشيرت');
      }
      headers.addAll(['الهاتف', 'الاسم', '#']);

      final totalCols = headers.length;
      final lastColLetter = String.fromCharCode(64 + totalCols);

      // Event info header
      sheet.merge(
        CellIndex.indexByString('A1'),
        CellIndex.indexByString('${lastColLetter}1'),
      );
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

      sheet.cell(CellIndex.indexByString('A6')).value = TextCellValue(
        'وصف الحدث:',
      );
      sheet.cell(CellIndex.indexByString('A6')).cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
      );
      sheet.cell(CellIndex.indexByString('B6')).value = TextCellValue(
        eventDescription.isNotEmpty ? eventDescription : 'غير محدد',
      );
      sheet.cell(CellIndex.indexByString('B6')).cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
      );

      // Volunteers table header
      sheet.merge(
        CellIndex.indexByString('A8'),
        CellIndex.indexByString('${lastColLetter}8'),
      );
      var volunteersHeaderCell = sheet.cell(CellIndex.indexByString('A8'));
      volunteersHeaderCell.value = TextCellValue('المتطوعون');
      volunteersHeaderCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 14,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      for (var i = 0; i < headers.length; i++) {
        var cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 9),
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

      // Add volunteers data
      for (var i = 0; i < volunteers.length; i++) {
        var volunteer = volunteers[i];
        var rowIndex = i + 10;
        var colIndex = 0;

        // Qafla columns (if applicable)
        if (isQafla) {
          // توزيع
          sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: colIndex,
                  rowIndex: rowIndex,
                ),
              )
              .value = TextCellValue(
            (qaflaDistribution?[volunteer.id] ?? false) ? 'نعم' : 'لا',
          );
          sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: colIndex,
                  rowIndex: rowIndex,
                ),
              )
              .cellStyle = CellStyle(
            horizontalAlign: HorizontalAlign.Center,
            verticalAlign: VerticalAlign.Center,
          );
          colIndex++;

          // تعبئة
          sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: colIndex,
                  rowIndex: rowIndex,
                ),
              )
              .value = TextCellValue(
            (qaflaFilling?[volunteer.id] ?? false) ? 'نعم' : 'لا',
          );
          sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: colIndex,
                  rowIndex: rowIndex,
                ),
              )
              .cellStyle = CellStyle(
            horizontalAlign: HorizontalAlign.Center,
            verticalAlign: VerticalAlign.Center,
          );
          colIndex++;

          // تجهيز
          sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: colIndex,
                  rowIndex: rowIndex,
                ),
              )
              .value = TextCellValue(
            (qaflaPreparation?[volunteer.id] ?? false) ? 'نعم' : 'لا',
          );
          sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: colIndex,
                  rowIndex: rowIndex,
                ),
              )
              .cellStyle = CellStyle(
            horizontalAlign: HorizontalAlign.Center,
            verticalAlign: VerticalAlign.Center,
          );
          colIndex++;
        }

        // T-shirt column (if not online)
        if (!isOnline) {
          sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: colIndex,
                  rowIndex: rowIndex,
                ),
              )
              .value = TextCellValue(
            volunteer.hasTshirt ? 'نعم' : 'لا',
          );
          sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: colIndex,
                  rowIndex: rowIndex,
                ),
              )
              .cellStyle = CellStyle(
            horizontalAlign: HorizontalAlign.Center,
            verticalAlign: VerticalAlign.Center,
          );
          colIndex++;
        }

        // Phone
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: colIndex,
                rowIndex: rowIndex,
              ),
            )
            .value = TextCellValue(
          volunteer.phone,
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: colIndex,
                rowIndex: rowIndex,
              ),
            )
            .cellStyle = CellStyle(
          horizontalAlign: HorizontalAlign.Right,
          verticalAlign: VerticalAlign.Center,
        );
        colIndex++;

        // Name
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: colIndex,
                rowIndex: rowIndex,
              ),
            )
            .value = TextCellValue(
          volunteer.name,
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: colIndex,
                rowIndex: rowIndex,
              ),
            )
            .cellStyle = CellStyle(
          horizontalAlign: HorizontalAlign.Right,
          verticalAlign: VerticalAlign.Center,
        );
        colIndex++;

        // Row number
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: colIndex,
                rowIndex: rowIndex,
              ),
            )
            .value = TextCellValue(
          (i + 1).toString(),
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: colIndex,
                rowIndex: rowIndex,
              ),
            )
            .cellStyle = CellStyle(
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );
      }

      // Auto-fit columns
      var colIdx = 0;
      if (isQafla) {
        sheet.setColumnWidth(colIdx++, 10); // توزيع
        sheet.setColumnWidth(colIdx++, 10); // تعبئة
        sheet.setColumnWidth(colIdx++, 10); // تجهيز
      }
      if (!isOnline) {
        sheet.setColumnWidth(colIdx++, 12); // تيشيرت
      }
      sheet.setColumnWidth(colIdx++, 18); // الهاتف
      sheet.setColumnWidth(colIdx++, 25); // الاسم
      sheet.setColumnWidth(colIdx++, 8); // #

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

  // Export multiple events to a single Excel file (one sheet per event)
  static Future<void> exportMultipleEventsToExcel({
    required List<EventModel> events,
    required Future<List<VolunteerModel>> Function(List<String> volunteerIds)
    getVolunteersByIds,
  }) async {
    try {
      var excel = Excel.createExcel();

      for (var eventIndex = 0; eventIndex < events.length; eventIndex++) {
        final event = events[eventIndex];

        // For the first event, use the default Sheet1; for others, create new sheets
        String sheetName;
        if (eventIndex == 0) {
          sheetName = 'Sheet1';
        } else {
          sheetName = '${eventIndex + 1}_${event.title}';
          if (sheetName.length > 31) {
            sheetName = sheetName.substring(0, 31);
          }
        }

        Sheet sheet = excel[sheetName];
        _setSheetToRTL(sheet);

        // Determine event flags
        final bool eventIsOnline = event.meetingPlace == 'أونلاين';
        final bool eventIsQafla = event.type == 'قافلة';

        // Dynamic column headers
        var headers = <String>[];
        if (eventIsQafla) {
          headers.addAll(['توزيع', 'تعبئة', 'تجهيز']);
        }
        if (!eventIsOnline) {
          headers.add('تيشيرت');
        }
        headers.addAll(['الهاتف', 'الاسم', '#']);

        final totalCols = headers.length;
        final lastColLetter = String.fromCharCode(64 + totalCols);

        // Event info header
        sheet.merge(
          CellIndex.indexByString('A1'),
          CellIndex.indexByString('${lastColLetter}1'),
        );
        var eventHeaderCell = sheet.cell(CellIndex.indexByString('A1'));
        eventHeaderCell.value = TextCellValue('معلومات الحدث');
        eventHeaderCell.cellStyle = CellStyle(
          bold: true,
          fontSize: 16,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );

        // Event details
        _setCellWithStyle(sheet, 'A2', 'عنوان الحدث:');
        _setCellWithStyle(sheet, 'B2', event.title);
        _setCellWithStyle(sheet, 'A3', 'نوع الحدث:');
        _setCellWithStyle(sheet, 'B3', event.type);
        _setCellWithStyle(sheet, 'A4', 'التاريخ:');
        _setCellWithStyle(sheet, 'B4', event.date);
        _setCellWithStyle(sheet, 'A5', 'المكان:');
        _setCellWithStyle(sheet, 'B5', event.location ?? 'غير محدد');
        _setCellWithStyle(sheet, 'A6', 'وصف الحدث:');
        _setCellWithStyle(
          sheet,
          'B6',
          event.description.isNotEmpty ? event.description : 'غير محدد',
        );

        // Get volunteers for this event
        List<VolunteerModel> volunteers = [];
        if (event.volunteerIds.isNotEmpty) {
          volunteers = await getVolunteersByIds(event.volunteerIds);
        }

        // Volunteers table header
        sheet.merge(
          CellIndex.indexByString('A8'),
          CellIndex.indexByString('${lastColLetter}8'),
        );
        var volunteersHeaderCell = sheet.cell(CellIndex.indexByString('A8'));
        volunteersHeaderCell.value = TextCellValue(
          'المتطوعون (${volunteers.length})',
        );
        volunteersHeaderCell.cellStyle = CellStyle(
          bold: true,
          fontSize: 14,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );

        // Column headers
        for (var i = 0; i < headers.length; i++) {
          var cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 9),
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

        // Add volunteers data
        for (var i = 0; i < volunteers.length; i++) {
          var volunteer = volunteers[i];
          var rowIndex = i + 10;
          var colIndex = 0;

          if (eventIsQafla) {
            sheet
                .cell(
                  CellIndex.indexByColumnRow(
                    columnIndex: colIndex,
                    rowIndex: rowIndex,
                  ),
                )
                .value = TextCellValue(
              (event.qaflaDistribution[volunteer.id] ?? false) ? 'نعم' : 'لا',
            );
            sheet
                .cell(
                  CellIndex.indexByColumnRow(
                    columnIndex: colIndex,
                    rowIndex: rowIndex,
                  ),
                )
                .cellStyle = CellStyle(
              horizontalAlign: HorizontalAlign.Center,
            );
            colIndex++;

            sheet
                .cell(
                  CellIndex.indexByColumnRow(
                    columnIndex: colIndex,
                    rowIndex: rowIndex,
                  ),
                )
                .value = TextCellValue(
              (event.qaflaFilling[volunteer.id] ?? false) ? 'نعم' : 'لا',
            );
            sheet
                .cell(
                  CellIndex.indexByColumnRow(
                    columnIndex: colIndex,
                    rowIndex: rowIndex,
                  ),
                )
                .cellStyle = CellStyle(
              horizontalAlign: HorizontalAlign.Center,
            );
            colIndex++;

            sheet
                .cell(
                  CellIndex.indexByColumnRow(
                    columnIndex: colIndex,
                    rowIndex: rowIndex,
                  ),
                )
                .value = TextCellValue(
              (event.qaflaPreparation[volunteer.id] ?? false) ? 'نعم' : 'لا',
            );
            sheet
                .cell(
                  CellIndex.indexByColumnRow(
                    columnIndex: colIndex,
                    rowIndex: rowIndex,
                  ),
                )
                .cellStyle = CellStyle(
              horizontalAlign: HorizontalAlign.Center,
            );
            colIndex++;
          }

          if (!eventIsOnline) {
            sheet
                .cell(
                  CellIndex.indexByColumnRow(
                    columnIndex: colIndex,
                    rowIndex: rowIndex,
                  ),
                )
                .value = TextCellValue(
              volunteer.hasTshirt ? 'نعم' : 'لا',
            );
            sheet
                .cell(
                  CellIndex.indexByColumnRow(
                    columnIndex: colIndex,
                    rowIndex: rowIndex,
                  ),
                )
                .cellStyle = CellStyle(
              horizontalAlign: HorizontalAlign.Center,
            );
            colIndex++;
          }

          sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: colIndex,
                  rowIndex: rowIndex,
                ),
              )
              .value = TextCellValue(
            volunteer.phone,
          );
          sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: colIndex,
                  rowIndex: rowIndex,
                ),
              )
              .cellStyle = CellStyle(
            horizontalAlign: HorizontalAlign.Right,
          );
          colIndex++;

          sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: colIndex,
                  rowIndex: rowIndex,
                ),
              )
              .value = TextCellValue(
            volunteer.name,
          );
          sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: colIndex,
                  rowIndex: rowIndex,
                ),
              )
              .cellStyle = CellStyle(
            horizontalAlign: HorizontalAlign.Right,
          );
          colIndex++;

          sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: colIndex,
                  rowIndex: rowIndex,
                ),
              )
              .value = TextCellValue(
            (i + 1).toString(),
          );
          sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: colIndex,
                  rowIndex: rowIndex,
                ),
              )
              .cellStyle = CellStyle(
            horizontalAlign: HorizontalAlign.Center,
          );
        }

        // Set column widths
        var colIdx = 0;
        if (eventIsQafla) {
          sheet.setColumnWidth(colIdx++, 10);
          sheet.setColumnWidth(colIdx++, 10);
          sheet.setColumnWidth(colIdx++, 10);
        }
        if (!eventIsOnline) {
          sheet.setColumnWidth(colIdx++, 12);
        }
        sheet.setColumnWidth(colIdx++, 18);
        sheet.setColumnWidth(colIdx++, 25);
        sheet.setColumnWidth(colIdx++, 8);
      }

      // Save and share file
      await _saveAndShareExcel(
        excel,
        'أحداث_متعددة_${events.length}_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      print('Error exporting multiple events to Excel: $e');
      rethrow;
    }
  }

  // Helper method to set cell value with right alignment
  static void _setCellWithStyle(Sheet sheet, String cellIndex, String value) {
    var cell = sheet.cell(CellIndex.indexByString(cellIndex));
    cell.value = TextCellValue(value);
    cell.cellStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );
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
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

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

  // Export all committees to a single Excel file
  static Future<void> exportAllCommitteesToExcel({
    required List<CommitteeModel> committees,
    required Future<List<VolunteerModel>> Function(String committeeId) getVolunteersByCommittee,
  }) async {
    try {
      var excel = Excel.createExcel();

      for (var committeeIndex = 0; committeeIndex < committees.length; committeeIndex++) {
        final committee = committees[committeeIndex];
        final volunteers = await getVolunteersByCommittee(committee.id);

        String sheetName = committee.name;
        if (sheetName.length > 31) {
          sheetName = sheetName.substring(0, 31);
        }

        Sheet sheet = excel[sheetName];
        _setSheetToRTL(sheet);

        // Committee info header
        sheet.merge(
          CellIndex.indexByString('A1'),
          CellIndex.indexByString('H1'),
        );
        var headerCell = sheet.cell(CellIndex.indexByString('A1'));
        headerCell.value = TextCellValue('${committee.name} - ${committee.isActive ? 'نشط' : 'غير نشط'}');
        headerCell.cellStyle = CellStyle(
          bold: true,
          fontSize: 16,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );

        // Leader and Co-leader info
        if (committee.leaderName != null) {
          sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue('الليدر:');
          sheet.cell(CellIndex.indexByString('B2')).value = TextCellValue(committee.leaderName!);
        }
        if (committee.coLeaderName != null) {
          sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue('نائب الليدر:');
          sheet.cell(CellIndex.indexByString('B3')).value = TextCellValue(committee.coLeaderName!);
        }

        // Column headers
        var headers = [
          'اللجنة الثانوية',
          'المستوى التطوعي',
          'اللجنة',
          'العمر',
          'العنوان',
          'الهاتف',
          'الاسم',
          '#',
        ];

        for (var i = 0; i < headers.length; i++) {
          var cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 5),
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

        // Add volunteers data
        for (var i = 0; i < volunteers.length; i++) {
          var volunteer = volunteers[i];
          var rowIndex = i + 6;

          // Column 0: Secondary committee
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
            .value = TextCellValue(volunteer.secondaryCommitteeName ?? '');
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
            .cellStyle = CellStyle(horizontalAlign: HorizontalAlign.Right, verticalAlign: VerticalAlign.Center);

          // Column 1: Educational level
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
            .value = TextCellValue(volunteer.educationalLevel ?? 'غير محدد');
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
            .cellStyle = CellStyle(horizontalAlign: HorizontalAlign.Right, verticalAlign: VerticalAlign.Center);

          // Column 2: Committee name
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
            .value = TextCellValue(volunteer.committeeName ?? 'غير محدد');
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
            .cellStyle = CellStyle(horizontalAlign: HorizontalAlign.Right, verticalAlign: VerticalAlign.Center);

          // Column 3: Age
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
            .value = TextCellValue(volunteer.age?.toString() ?? 'غير محدد');
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
            .cellStyle = CellStyle(horizontalAlign: HorizontalAlign.Center, verticalAlign: VerticalAlign.Center);

          // Column 4: Address
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
            .value = TextCellValue(volunteer.address);
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
            .cellStyle = CellStyle(horizontalAlign: HorizontalAlign.Right, verticalAlign: VerticalAlign.Center);

          // Column 5: Phone
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
            .value = TextCellValue(volunteer.phone);
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
            .cellStyle = CellStyle(horizontalAlign: HorizontalAlign.Right, verticalAlign: VerticalAlign.Center);

          // Column 6: Name
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
            .value = TextCellValue(volunteer.name);
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
            .cellStyle = CellStyle(horizontalAlign: HorizontalAlign.Right, verticalAlign: VerticalAlign.Center);

          // Column 7: Row number
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
            .value = TextCellValue((i + 1).toString());
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
            .cellStyle = CellStyle(horizontalAlign: HorizontalAlign.Center, verticalAlign: VerticalAlign.Center);
        }

        // Set column widths
        for (var i = 0; i < headers.length; i++) {
          sheet.setColumnWidth(i, 16);
        }
      }

      await _saveAndShareExcel(
        excel,
        'كل_اللجان_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      print('Error exporting all committees to Excel: $e');
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

  // ============================================
  // REPORT EXPORT FUNCTIONS
  // ============================================

  static Future<void> exportQaflaReport({
    required List<List<String>> rows,
  }) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['تقرير القوافل'];
      _setSheetToRTL(sheet);

      sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('J1'));
      var titleCell = sheet.cell(CellIndex.indexByString('A1'));
      titleCell.value = TextCellValue('تقرير القوافل');
      titleCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 16,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      final headers = [
        'العنوان',
        'التاريخ',
        'المكان',
        'عدد المتطوعين',
        'الموزعين',
        'التيشرتات',
        'عدد العربيات',
        'تفاصيل الوجبات',
        'تفاصيل العربيات',
      ];

      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#8A3A4A'),
          fontColorHex: ExcelColor.white,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );
      }

      for (var i = 0; i < rows.length; i++) {
        final rowIndex = i + 3;
        final rowData = rows[i];
        for (var j = 0; j < headers.length; j++) {
          final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex),
          );
          cell.value = TextCellValue(rowData[j]);
          cell.cellStyle = CellStyle(
            horizontalAlign: j == 0 || j == 1 || j == 2
                ? HorizontalAlign.Right
                : HorizontalAlign.Center,
            verticalAlign: VerticalAlign.Center,
          );
        }
      }

      for (var i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, i < 3 ? 20 : 15);
      }

      await _saveAndShareExcel(
        excel,
        'تقرير_القوافل_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      print('Error exporting qafla report: $e');
      rethrow;
    }
  }

  // Export Comprehensive Report (الكلي)
  static Future<void> exportComprehensiveReport({
    required List<VolunteerReportData> reportData,
    String? filterMonth,
  }) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['تقرير الكلي'];
      _setSheetToRTL(sheet);

      // Title
      sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('K1'));
      var titleCell = sheet.cell(CellIndex.indexByString('A1'));
      titleCell.value = TextCellValue(
        filterMonth != null ? 'تقرير الكلي - $filterMonth' : 'تقرير الكلي',
      );
      titleCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 16,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      // Headers - Comprehensive
      var headers = [
        '#',
        'الاسم',
        'الهاتف',
        'اللجنة',
        'الدرجة التطوعية',
        'الشهور',
        'اجتماع لجنة',
        'يوم عائلي',
        'اجتماع فريق',
        'احداث',
        'اكشنز',
        'مشاركات',
      ];

      for (var i = 0; i < headers.length; i++) {
        var cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#8A3A4A'),
          fontColorHex: ExcelColor.white,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );
      }

      // Data rows
      for (var i = 0; i < reportData.length; i++) {
        var data = reportData[i];
        var rowIndex = i + 3;

        var rowData = [
          (i + 1).toString(),
          data.volunteerName,
          data.phone ?? '-',
          data.committeeName ?? '-',
          data.educationalLevel ?? '-',
          data.monthsString,
          data.committeeMeetingCount.toString(),
          data.familyDayCount.toString(),
          (data.leadersMeetingCount + data.teamMeetingCount).toString(),
          data.eventsCount.toString(),
          data.totalEvents.toString(),
          data.participationDays.toString(),
        ];

        for (var j = 0; j < rowData.length; j++) {
          var cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex),
          );
          cell.value = TextCellValue(rowData[j]);
          cell.cellStyle = CellStyle(
            horizontalAlign: (j == 1 || j == 2)
                ? HorizontalAlign.Right
                : HorizontalAlign.Center,
            verticalAlign: VerticalAlign.Center,
          );
        }
      }

      // Set column widths
      sheet.setColumnWidth(0, 8);
      sheet.setColumnWidth(1, 25);
      sheet.setColumnWidth(2, 18); // الهاتف
      for (var i = 3; i < headers.length; i++) {
        sheet.setColumnWidth(i, 15);
      }

      await _saveAndShareExcel(
        excel,
        'تقرير_الكلي_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      print('Error exporting comprehensive report: $e');
      rethrow;
    }
  }

  // Export Family Day Report (اليوم العائلي)
  static Future<void> exportFamilyDayReport({
    required List<VolunteerReportData> reportData,
    required bool isCubs,
    String? filterMonth,
  }) async {
    try {
      var excel = Excel.createExcel();
      String sheetName = isCubs
          ? 'تقرير اليوم العائلي - الأشبال'
          : 'تقرير اليوم العائلي - الفريق';
      Sheet sheet = excel[sheetName];
      _setSheetToRTL(sheet);

      // Title
      sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('D1'));
      var titleCell = sheet.cell(CellIndex.indexByString('A1'));
      titleCell.value = TextCellValue(
        filterMonth != null ? '$sheetName - $filterMonth' : sheetName,
      );
      titleCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 16,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      // Headers - Family Day
      var headers = [
        '#',
        'الاسم',
        'الهاتف',
        'اللجنة',
        'الدرجة التطوعية',
        'يوم عائلي',
        'الشهور',
      ];

      for (var i = 0; i < headers.length; i++) {
        var cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#8A3A4A'),
          fontColorHex: ExcelColor.white,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );
      }

      // Data rows
      for (var i = 0; i < reportData.length; i++) {
        var data = reportData[i];
        var rowIndex = i + 3;

        var rowData = [
          (i + 1).toString(),
          data.volunteerName,
          data.phone ?? '-',
          data.committeeName ?? '-',
          data.educationalLevel ?? '-',
          data.familyDayCount.toString(),
          data.monthsString,
        ];

        for (var j = 0; j < rowData.length; j++) {
          var cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex),
          );
          cell.value = TextCellValue(rowData[j]);
          cell.cellStyle = CellStyle(
            horizontalAlign: (j == 1 || j == 2)
                ? HorizontalAlign.Right
                : HorizontalAlign.Center,
            verticalAlign: VerticalAlign.Center,
          );
        }
      }

      // Set column widths
      sheet.setColumnWidth(0, 8);
      sheet.setColumnWidth(1, 25);
      sheet.setColumnWidth(2, 18);
      sheet.setColumnWidth(3, 18);
      sheet.setColumnWidth(4, 12);
      sheet.setColumnWidth(5, 10);

      await _saveAndShareExcel(
        excel,
        'تقرير_اليوم_العائلي_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      print('Error exporting family day report: $e');
      rethrow;
    }
  }

  // Export Cubs Report (الأشبال)
  static Future<void> exportCubsReport({
    required List<VolunteerReportData> reportData,
    required String category,
    String? filterMonth,
  }) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['تقرير الأشبال - $category'];
      _setSheetToRTL(sheet);

      // Title
      sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('F1'));
      var titleCell = sheet.cell(CellIndex.indexByString('A1'));
      titleCell.value = TextCellValue(
        filterMonth != null
            ? 'تقرير الأشبال - $category - $filterMonth'
            : 'تقرير الأشبال - $category',
      );
      titleCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 16,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      // Headers - Cubs
      var headers = [
        '#',
        'الاسم',
        'الهاتف',
        'اللجنة',
        'الدرجة التطوعية',
        'يوم عائلي',
        'ايفنت الأشبال',
        'الأحداث',
        'الشهور',
      ];

      for (var i = 0; i < headers.length; i++) {
        var cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#8A3A4A'),
          fontColorHex: ExcelColor.white,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );
      }

      // Data rows
      for (var i = 0; i < reportData.length; i++) {
        var data = reportData[i];
        var rowIndex = i + 3;

        var rowData = [
          (i + 1).toString(),
          data.volunteerName,
          data.phone ?? '-',
          data.committeeName ?? '-',
          data.educationalLevel ?? '-',
          data.familyDayCount.toString(),
          data.cubsEventCount.toString(),
          data.eventsCount.toString(),
          data.monthsString,
        ];

        for (var j = 0; j < rowData.length; j++) {
          var cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex),
          );
          cell.value = TextCellValue(rowData[j]);
          cell.cellStyle = CellStyle(
            horizontalAlign: (j == 1 || j == 2)
                ? HorizontalAlign.Right
                : HorizontalAlign.Center,
            verticalAlign: VerticalAlign.Center,
          );
        }
      }

      // Set column widths
      sheet.setColumnWidth(0, 8);
      sheet.setColumnWidth(1, 25);
      sheet.setColumnWidth(0, 8);
      sheet.setColumnWidth(1, 25);
      sheet.setColumnWidth(2, 18);
      for (var i = 3; i < headers.length; i++) {
        sheet.setColumnWidth(i, 15);
      }

      await _saveAndShareExcel(
        excel,
        'تقرير_الأشبال_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      print('Error exporting cubs report: $e');
      rethrow;
    }
  }

  // Export Meetings Report (الأجتماعات)
  static Future<void> exportMeetingsReport({
    required List<VolunteerReportData> reportData,
    String? filterMonth,
  }) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['تقرير الأجتماعات'];
      _setSheetToRTL(sheet);

      // Title
      sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('F1'));
      var titleCell = sheet.cell(CellIndex.indexByString('A1'));
      titleCell.value = TextCellValue(
        filterMonth != null
            ? 'تقرير الأجتماعات - $filterMonth'
            : 'تقرير الأجتماعات',
      );
      titleCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 16,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      // Headers
      var headers = [
        '#',
        'الاسم',
        'الهاتف',
        'اللجنة',
        'اجتماع اللجنة',
        'اجتماع الفريق',
        'اجتماع الليدرات',
        'الشهور',
      ];

      for (var i = 0; i < headers.length; i++) {
        var cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#8A3A4A'),
          fontColorHex: ExcelColor.white,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );
      }

      // Data rows
      for (var i = 0; i < reportData.length; i++) {
        var data = reportData[i];
        var rowIndex = i + 3;

        var rowData = [
          (i + 1).toString(),
          data.volunteerName,
          data.phone ?? '-',
          data.committeeName ?? '-',
          data.committeeMeetingCount.toString(),
          data.teamMeetingCount.toString(),
          data.leadersMeetingCount.toString(),
          data.monthsString,
        ];

        for (var j = 0; j < rowData.length; j++) {
          var cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex),
          );
          cell.value = TextCellValue(rowData[j]);
          cell.cellStyle = CellStyle(
            horizontalAlign: (j == 1 || j == 2 || j == 3)
                ? HorizontalAlign.Right
                : HorizontalAlign.Center,
            verticalAlign: VerticalAlign.Center,
          );
        }
      }

      // Set column widths
      sheet.setColumnWidth(0, 8);
      sheet.setColumnWidth(1, 25);
      sheet.setColumnWidth(2, 18);
      sheet.setColumnWidth(3, 18);
      for (var i = 4; i < headers.length; i++) {
        sheet.setColumnWidth(i, 15);
      }

      await _saveAndShareExcel(
        excel,
        'تقرير_الأجتماعات_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      print('Error exporting meetings report: $e');
      rethrow;
    }
  }

  // Export Fund Report (الصندوق)
  static Future<void> exportFundReport({
    required List<VolunteerReportData> reportData,
    required double totalFund,
    String? filterMonth,
  }) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['تقرير الصندوق'];
      _setSheetToRTL(sheet);

      // Title
      sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('E1'));
      var titleCell = sheet.cell(CellIndex.indexByString('A1'));
      titleCell.value = TextCellValue(
        filterMonth != null ? 'تقرير الصندوق - $filterMonth' : 'تقرير الصندوق',
      );
      titleCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 16,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      // Total fund row
      sheet.merge(CellIndex.indexByString('A2'), CellIndex.indexByString('C2'));
      var totalLabelCell = sheet.cell(CellIndex.indexByString('A2'));
      totalLabelCell.value = TextCellValue('إجمالي ما في الصندوق:');
      totalLabelCell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
      );

      sheet.merge(CellIndex.indexByString('D2'), CellIndex.indexByString('E2'));
      var totalValueCell = sheet.cell(CellIndex.indexByString('D2'));
      totalValueCell.value = TextCellValue(
        '${totalFund.toStringAsFixed(0)} جنيه',
      );
      totalValueCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 14,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      // Headers - Fund
      var headers = [
        '#',
        'الاسم',
        'الهاتف',
        'اللجنة',
        'الدرجة التطوعية',
        'الصندوق',
        'الإجمالي',
        'الشهور',
      ];

      for (var i = 0; i < headers.length; i++) {
        var cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 3),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#8A3A4A'),
          fontColorHex: ExcelColor.white,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );
      }

      // Data rows
      for (var i = 0; i < reportData.length; i++) {
        var data = reportData[i];
        var rowIndex = i + 4;

        var rowData = [
          (i + 1).toString(),
          data.volunteerName,
          data.phone ?? '-',
          data.committeeName ?? '-',
          data.educationalLevel ?? '-',
          data.fundCount.toString(),
          data.totalFundAmount.toStringAsFixed(0),
          data.monthsString,
        ];

        for (var j = 0; j < rowData.length; j++) {
          var cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex),
          );
          cell.value = TextCellValue(rowData[j]);
          cell.cellStyle = CellStyle(
            horizontalAlign: (j == 1 || j == 2)
                ? HorizontalAlign.Right
                : HorizontalAlign.Center,
            verticalAlign: VerticalAlign.Center,
          );
        }
      }

      // Set column widths
      sheet.setColumnWidth(0, 8);
      sheet.setColumnWidth(1, 25);
      sheet.setColumnWidth(2, 18);
      sheet.setColumnWidth(3, 18);
      sheet.setColumnWidth(4, 12);
      sheet.setColumnWidth(5, 12);
      sheet.setColumnWidth(6, 10);

      await _saveAndShareExcel(
        excel,
        'تقرير_الصندوق_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      print('Error exporting fund report: $e');
      rethrow;
    }
  }

  static Future<void> exportInventoryToExcel({
    required List<InventoryDisplayEntry> displayEntries,
    required List<InventorySectionModel> sections,
  }) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['جرد المخازن'];
      _setSheetToRTL(sheet);

      // Title
      sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('H1'));
      var titleCell = sheet.cell(CellIndex.indexByString('A1'));
      titleCell.value = TextCellValue('جرد المخازن');
      titleCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 16,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      // Summary section
      int totalSubcategories = 0;
      int totalItems = 0;
      for (final section in sections.where((s) => s.id != 'كلي')) {
        totalSubcategories += section.subcategories.length;
        for (final sub in section.subcategories) {
          totalItems += sub.items.length;
        }
      }

      sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue(
        'إجمالي الأقسام الفرعية: $totalSubcategories',
      );
      sheet.cell(CellIndex.indexByString('A2')).cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
      );
      sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue(
        'إجمالي الأصناف: $totalItems',
      );
      sheet.cell(CellIndex.indexByString('A3')).cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Center,
      );

      // Column headers
      var headers = [
        'القسم',
        'القسم الفرعي',
        'الصنف',
        'الوحدة',
        'الكمية',
        'آخر حركة',
        'عدد السجلات',
        '#',
      ];

      for (var i = 0; i < headers.length; i++) {
        var cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 5),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#8A3A4A'),
          fontColorHex: ExcelColor.white,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );
      }

      // Data rows
      for (var i = 0; i < displayEntries.length; i++) {
        final entry = displayEntries[i];
        final item = entry.item;
        final latestHistory = item.history.isNotEmpty
            ? item.history.last
            : null;
        final rowIndex = i + 6;

        var rowData = [
          entry.sectionName,
          entry.subcategoryName,
          item.name,
          item.unit,
          item.quantity.toString(),
          latestHistory != null
              ? '${latestHistory.action}: ${latestHistory.quantity} ${latestHistory.unit}'
              : '-',
          item.history.length.toString(),
          (i + 1).toString(),
        ];

        for (var j = 0; j < rowData.length; j++) {
          var cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex),
          );
          cell.value = TextCellValue(rowData[j]);
          cell.cellStyle = CellStyle(
            horizontalAlign: (j == 0 || j == 1 || j == 2)
                ? HorizontalAlign.Center
                : HorizontalAlign.Center,
            verticalAlign: VerticalAlign.Center,
          );
        }
      }

      // Set column widths
      sheet.setColumnWidth(0, 12);
      sheet.setColumnWidth(1, 18);
      sheet.setColumnWidth(2, 20);
      sheet.setColumnWidth(3, 10);
      sheet.setColumnWidth(4, 10);
      sheet.setColumnWidth(5, 25);
      sheet.setColumnWidth(6, 12);
      sheet.setColumnWidth(7, 8);

      await _saveAndShareExcel(
        excel,
        'جرد_المخازن_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      print('Error exporting inventory to Excel: $e');
      rethrow;
    }
  }

  // Export Marketing Report (الدعايا)
  static Future<void> exportMarketingReport({
    required List<VolunteerReportData> reportData,
    String? filterMonth,
  }) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['تقرير الدعايا'];
      _setSheetToRTL(sheet);

      // Title
      sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('D1'));
      var titleCell = sheet.cell(CellIndex.indexByString('A1'));
      titleCell.value = TextCellValue(
        filterMonth != null ? 'تقرير الدعايا - $filterMonth' : 'تقرير الدعايا',
      );
      titleCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 16,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      // Headers - Marketing
      var headers = [
        '#',
        'الاسم',
        'الهاتف',
        'اللجنة',
        'الدرجة التطوعية',
        'الستوري',
        'الشهور',
      ];

      for (var i = 0; i < headers.length; i++) {
        var cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#8A3A4A'),
          fontColorHex: ExcelColor.white,
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );
      }

      // Data rows
      for (var i = 0; i < reportData.length; i++) {
        var data = reportData[i];
        var rowIndex = i + 3;

        var rowData = [
          (i + 1).toString(),
          data.volunteerName,
          data.phone ?? '-',
          data.committeeName ?? '-',
          data.educationalLevel ?? '-',
          data.storyCount.toString(),
          data.monthsString,
        ];

        for (var j = 0; j < rowData.length; j++) {
          var cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: rowIndex),
          );
          cell.value = TextCellValue(rowData[j]);
          cell.cellStyle = CellStyle(
            horizontalAlign: (j == 1 || j == 2)
                ? HorizontalAlign.Right
                : HorizontalAlign.Center,
            verticalAlign: VerticalAlign.Center,
          );
        }
      }

      // Set column widths
      sheet.setColumnWidth(0, 8);
      sheet.setColumnWidth(1, 25);
      sheet.setColumnWidth(2, 18);
      sheet.setColumnWidth(3, 18);
      sheet.setColumnWidth(4, 12);
      sheet.setColumnWidth(5, 10);

      await _saveAndShareExcel(
        excel,
        'تقرير_الدعايا_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      print('Error exporting marketing report: $e');
      rethrow;
    }
  }
}
