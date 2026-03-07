// ============================================
// FILE: lib/services/word_export_helper.dart
// Helper class for exporting meeting data to Word (.docx)
// ============================================

import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/models/event_model.dart';

class WordExportHelper {
  /// Export a meeting event to a Word (.docx) document
  static Future<void> exportMeetingToWord({required EventModel event}) async {
    final archive = Archive();

    // 1. [Content_Types].xml
    archive.addFile(
      ArchiveFile('[Content_Types].xml', 0, utf8.encode(_contentTypesXml)),
    );

    // 2. _rels/.rels
    archive.addFile(ArchiveFile('_rels/.rels', 0, utf8.encode(_relsXml)));

    // 3. word/_rels/document.xml.rels
    archive.addFile(
      ArchiveFile(
        'word/_rels/document.xml.rels',
        0,
        utf8.encode(_documentRelsXml),
      ),
    );

    // 4. word/styles.xml
    archive.addFile(ArchiveFile('word/styles.xml', 0, utf8.encode(_stylesXml)));

    // 5. word/document.xml - Main content
    final documentXml = _buildDocumentXml(event);
    archive.addFile(
      ArchiveFile('word/document.xml', 0, utf8.encode(documentXml)),
    );

    // Encode as ZIP
    final zipData = ZipEncoder().encode(archive);
    if (zipData == null) throw Exception('Failed to create docx archive');

    // Save to file
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sanitizedTitle = event.title.replaceAll(
      RegExp(r'[^\w\u0600-\u06FF\s]'),
      '_',
    );
    final filePath = '${directory.path}/محضر_${sanitizedTitle}_$timestamp.docx';
    final file = File(filePath);
    await file.writeAsBytes(zipData);

    // Share the file
    await Share.shareXFiles([
      XFile(filePath),
    ], text: 'محضر اجتماع - ${event.title}');
  }

  static String _buildDocumentXml(EventModel event) {
    final buffer = StringBuffer();

    buffer.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    buffer.writeln(
      '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"'
      ' xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">',
    );
    buffer.writeln('<w:body>');

    // === Meeting Header ===
    _addTitle(buffer, 'محضر الاجتماع', 36);
    _addSpacing(buffer);
    _addLabelValue(buffer, 'التاريخ', event.date);
    final category = event.meetingCategory ?? _getMeetingCategory(event);
    _addLabelValue(buffer, 'تصنيف الاجتماع', category);
    if (event.committeeName != null && event.committeeName!.isNotEmpty) {
      _addLabelValue(buffer, 'اللجنة', event.committeeName!);
    }
    _addSpacing(buffer);

    // === Previous Meeting Points ===
    if (event.previousMeetingPoints.isNotEmpty) {
      _addSectionTitle(buffer, 'نقاط الاجتماع السابق');
      for (final point in event.previousMeetingPoints) {
        _addBulletPoint(buffer, point);
      }
      _addSpacing(buffer);
    }

    // === New Meeting Points ===
    if (event.newMeetingPoints.isNotEmpty) {
      _addSectionTitle(buffer, 'نقاط جديدة للاجتماع');
      for (final point in event.newMeetingPoints) {
        _addBulletPoint(buffer, point);
      }
      _addSpacing(buffer);
    }

    // === Voting Section ===
    if (event.votingItems.isNotEmpty) {
      _addSectionTitle(buffer, 'التصويت');
      for (final item in event.votingItems) {
        final topic = item['topic'] ?? '';
        final result = item['result'] ?? '';
        _addBulletPoint(buffer, 'الموضوع: $topic – النتيجة: $result');
      }
      _addSpacing(buffer);
    }

    // === Meeting Decisions ===
    if (event.meetingDecisions.isNotEmpty) {
      _addSectionTitle(buffer, 'قرارات الاجتماع');
      for (final decision in event.meetingDecisions) {
        _addBulletPoint(buffer, decision);
      }
      _addSpacing(buffer);
    }

    // === Deferred Points ===
    if (event.deferredPoints.isNotEmpty) {
      _addSectionTitle(buffer, 'نقاط مؤجلة للاجتماع القادم');
      for (final point in event.deferredPoints) {
        _addBulletPoint(buffer, point);
      }
      _addSpacing(buffer);
    }

    // === Additional Details ===
    if (event.additionalDetails != null &&
        event.additionalDetails!.isNotEmpty) {
      _addSectionTitle(buffer, 'تفاصيل أخرى');
      _addParagraph(buffer, event.additionalDetails!);
      _addSpacing(buffer);
    }

    buffer.writeln('</w:body>');
    buffer.writeln('</w:document>');

    return buffer.toString();
  }

  static String _getMeetingCategory(EventModel event) {
    if (event.administrativeType == 'اجتماع ليدرات') {
      return 'اجتماع ليدرات';
    } else if (event.committeeName != null && event.committeeName!.isNotEmpty) {
      return 'اجتماع لجنة';
    } else {
      return 'اجتماع الفريق';
    }
  }

  static String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static void _addTitle(StringBuffer buffer, String text, int fontSize) {
    buffer.writeln('<w:p>');
    buffer.writeln('<w:pPr><w:bidi/><w:jc w:val="center"/></w:pPr>');
    buffer.writeln(
      '<w:r><w:rPr><w:b/><w:bCs/><w:sz w:val="${fontSize * 2}"/><w:szCs w:val="${fontSize * 2}"/><w:rtl/></w:rPr>',
    );
    buffer.writeln('<w:t>${_escapeXml(text)}</w:t></w:r>');
    buffer.writeln('</w:p>');
  }

  static void _addSectionTitle(StringBuffer buffer, String text) {
    buffer.writeln('<w:p>');
    buffer.writeln(
      '<w:pPr><w:bidi/><w:jc w:val="right"/><w:spacing w:before="240" w:after="120"/></w:pPr>',
    );
    buffer.writeln(
      '<w:r><w:rPr><w:b/><w:bCs/><w:sz w:val="28"/><w:szCs w:val="28"/><w:rtl/><w:color w:val="8A3A4A"/></w:rPr>',
    );
    buffer.writeln('<w:t>${_escapeXml(text)}</w:t></w:r>');
    buffer.writeln('</w:p>');
  }

  static void _addLabelValue(StringBuffer buffer, String label, String value) {
    buffer.writeln('<w:p>');
    buffer.writeln('<w:pPr><w:bidi/><w:jc w:val="right"/></w:pPr>');
    // Label (bold)
    buffer.writeln(
      '<w:r><w:rPr><w:b/><w:bCs/><w:sz w:val="24"/><w:szCs w:val="24"/><w:rtl/></w:rPr>',
    );
    buffer.writeln(
      '<w:t xml:space="preserve">${_escapeXml(label)}: </w:t></w:r>',
    );
    // Value (normal)
    buffer.writeln(
      '<w:r><w:rPr><w:sz w:val="24"/><w:szCs w:val="24"/><w:rtl/></w:rPr>',
    );
    buffer.writeln('<w:t>${_escapeXml(value)}</w:t></w:r>');
    buffer.writeln('</w:p>');
  }

  static void _addBulletPoint(StringBuffer buffer, String text) {
    buffer.writeln('<w:p>');
    buffer.writeln(
      '<w:pPr><w:bidi/><w:jc w:val="right"/><w:ind w:right="720"/></w:pPr>',
    );
    buffer.writeln(
      '<w:r><w:rPr><w:sz w:val="24"/><w:szCs w:val="24"/><w:rtl/></w:rPr>',
    );
    buffer.writeln(
      '<w:t xml:space="preserve">• ${_escapeXml(text)}</w:t></w:r>',
    );
    buffer.writeln('</w:p>');
  }

  static void _addParagraph(StringBuffer buffer, String text) {
    buffer.writeln('<w:p>');
    buffer.writeln(
      '<w:pPr><w:bidi/><w:jc w:val="right"/><w:ind w:right="360"/></w:pPr>',
    );
    buffer.writeln(
      '<w:r><w:rPr><w:sz w:val="24"/><w:szCs w:val="24"/><w:rtl/></w:rPr>',
    );
    buffer.writeln('<w:t>${_escapeXml(text)}</w:t></w:r>');
    buffer.writeln('</w:p>');
  }

  static void _addSpacing(StringBuffer buffer) {
    buffer.writeln('<w:p><w:pPr><w:spacing w:after="200"/></w:pPr></w:p>');
  }

  // ========== Static XML templates ==========

  static const String _contentTypesXml =
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>''';

  static const String _relsXml =
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';

  static const String _documentRelsXml =
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''';

  static const String _stylesXml =
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults>
    <w:rPrDefault>
      <w:rPr>
        <w:sz w:val="24"/>
        <w:szCs w:val="24"/>
      </w:rPr>
    </w:rPrDefault>
    <w:pPrDefault>
      <w:pPr>
        <w:spacing w:after="100" w:line="276" w:lineRule="auto"/>
      </w:pPr>
    </w:pPrDefault>
  </w:docDefaults>
</w:styles>''';
}
