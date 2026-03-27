import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/cash_receipt_model.dart';

/// Formal cash receipt PDF: letterhead, readable charity registration, crisp logo, clear sections.
class ReceiptPdfService {
  static const String _orgName = 'NAGINA SOCIAL WELFARE UK LIMITED';
  static const String _charityNo = '083429371';
  static const String _address =
      '103 Burmer Road, PE1 3HT, Peterborough';
  static const String _phones = '07831 684738 · 07716 954738';

  static const PdfColor _forestGreen = PdfColor.fromInt(0xFF1B3022);
  static const PdfColor _forestGreenLight = PdfColor.fromInt(0xFF2d4a3e);
  static const PdfColor _gold = PdfColor.fromInt(0xFFc9a227);
  static const PdfColor _cream = PdfColor.fromInt(0xFFf7f9f7);
  static const PdfColor _white = PdfColors.white;
  static const PdfColor _ink = PdfColor.fromInt(0xFF1a1a1a);
  static const PdfColor _muted = PdfColor.fromInt(0xFF5c5c5c);

  static const String _assetLogo = 'assets/images/nagina.jpeg';

  static Future<File> buildReceiptPdf(CashReceiptModel receipt) async {
    final logoBytes = await rootBundle.load(_assetLogo);
    final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());

    final primaryPurpose = receipt.purpose.trim();
    final isDonation = _matchesPurpose(primaryPurpose, 'Donation');
    final isZakat = _matchesPurpose(primaryPurpose, 'Zakat');
    final isFitrana = _matchesPurpose(primaryPurpose, 'Fitrana');
    final isSadqa = _matchesPurpose(primaryPurpose, 'Sadqa') ||
        _matchesPurpose(primaryPurpose, 'Sadaqah');

    final isCash = receipt.paymentMethod == 'cash';
    final isChequeOnline = receipt.paymentMethod == 'cheque_online';

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 36),
        theme: pw.ThemeData(
          defaultTextStyle: pw.TextStyle(fontSize: 10, color: _ink),
        ),
        build: (context) {
          return pw.Center(
            child: pw.Container(
              width: 410,
              decoration: pw.BoxDecoration(
                color: _white,
                border: pw.Border.all(color: _forestGreen, width: 1.4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Container(
                    color: _forestGreen,
                    padding: const pw.EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        _letterheadLogo(logo),
                        pw.SizedBox(width: 14),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                _orgName,
                                style: pw.TextStyle(
                                  color: _white,
                                  fontSize: 11.5,
                                  fontWeight: pw.FontWeight.bold,
                                  letterSpacing: 0.6,
                                  height: 1.15,
                                ),
                              ),
                              pw.SizedBox(height: 8),
                              pw.Container(
                                height: 3,
                                width: 72,
                                decoration: pw.BoxDecoration(
                                  color: _gold,
                                  borderRadius:
                                      const pw.BorderRadius.all(pw.Radius.circular(1)),
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                'Official cash receipt',
                                style: pw.TextStyle(
                                  color: _white,
                                  fontSize: 8.2,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        _charityBadge(),
                      ],
                    ),
                  ),
                  pw.Container(
                    color: _cream,
                    padding: const pw.EdgeInsets.fromLTRB(18, 18, 18, 14),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Expanded(child: _fieldLine('Receipt No.', receipt.receiptId)),
                            pw.SizedBox(width: 16),
                            pw.Expanded(
                              child: _fieldLine(
                                'Date',
                                DateFormat('dd MMM yyyy').format(receipt.date),
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 12),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          decoration: pw.BoxDecoration(
                            color: _white,
                            borderRadius:
                                const pw.BorderRadius.all(pw.Radius.circular(6)),
                            border: pw.Border.all(
                              color: PdfColor.fromInt(0xFFe0e8e4),
                              width: 1,
                            ),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Received with thanks from',
                                style: pw.TextStyle(
                                  fontSize: 8.5,
                                  color: _muted,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                receipt.payeeLine,
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                  color: _forestGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 12),
                        _fieldLine(
                          'Amount',
                          '£${receipt.amount.toStringAsFixed(2)}',
                          valueEmphasis: true,
                        ),
                        pw.SizedBox(height: 14),
                        _sectionLabel('Purpose of donation'),
                        pw.SizedBox(height: 8),
                        pw.Wrap(
                          spacing: 14,
                          runSpacing: 10,
                          children: [
                            _checkRow('Donation', isDonation),
                            _checkRow('Zakat', isZakat),
                            _checkRow('Fitrana', isFitrana),
                            _checkRow('Sadqa', isSadqa),
                          ],
                        ),
                        if (!isDonation &&
                            !isZakat &&
                            !isFitrana &&
                            !isSadqa &&
                            receipt.purpose.isNotEmpty) ...[
                          pw.SizedBox(height: 8),
                          pw.Text(
                            'Other: ${receipt.purpose}',
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: _muted,
                              fontStyle: pw.FontStyle.italic,
                            ),
                          ),
                        ],
                        pw.SizedBox(height: 14),
                        _sectionLabel('Payment method'),
                        pw.SizedBox(height: 8),
                        pw.Row(
                          children: [
                            _checkRow('Cash', isCash),
                            pw.SizedBox(width: 20),
                            _checkRow('Chq. / Online', isChequeOnline),
                          ],
                        ),
                        pw.SizedBox(height: 16),
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              'Received by',
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: _forestGreen,
                              ),
                            ),
                            pw.SizedBox(width: 8),
                            pw.Expanded(
                              child: pw.Container(
                                decoration: const pw.BoxDecoration(
                                  border: pw.Border(
                                    bottom: pw.BorderSide(
                                      color: _ink,
                                      width: 0.75,
                                    ),
                                  ),
                                ),
                                padding:
                                    const pw.EdgeInsets.only(left: 6, bottom: 3),
                                child: pw.Text(
                                  receipt.receivedBy.isEmpty
                                      ? ' '
                                      : receipt.receivedBy,
                                  style: const pw.TextStyle(fontSize: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      gradient: pw.LinearGradient(
                        colors: [_forestGreen, _forestGreenLight],
                        begin: pw.Alignment.centerLeft,
                        end: pw.Alignment.centerRight,
                      ),
                    ),
                    padding:
                        const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          _address,
                          style: const pw.TextStyle(
                            color: _white,
                            fontSize: 8.8,
                            height: 1.25,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          _phones,
                          style: pw.TextStyle(
                            color: _gold,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final filename = '${receipt.receiptId}.pdf';
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _letterheadLogo(pw.ImageProvider logo) {
    const double size = 56;
    return pw.Container(
      width: size,
      height: size,
      decoration: pw.BoxDecoration(
        shape: pw.BoxShape.circle,
        border: pw.Border.all(color: _gold, width: 2),
        color: _white,
      ),
      child: pw.Center(
        child: pw.SizedBox(
          width: size - 6,
          height: size - 6,
          child: pw.ClipOval(
            child: pw.Image(
              logo,
              fit: pw.BoxFit.cover,
              alignment: pw.Alignment.center,
            ),
          ),
        ),
      ),
    );
  }

  static pw.Widget _charityBadge() {
    return pw.Container(
      constraints: const pw.BoxConstraints(minWidth: 108),
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: pw.BoxDecoration(
        color: _white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: _gold, width: 1.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            'CHARITY',
            style: pw.TextStyle(
              fontSize: 7,
              letterSpacing: 1.2,
              color: _muted,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'REG. NO.',
            style: pw.TextStyle(
              fontSize: 7,
              letterSpacing: 0.8,
              color: _muted,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            _charityNo,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: _forestGreen,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _sectionLabel(String text) {
    return pw.Row(
      children: [
        pw.Container(
          width: 3,
          height: 12,
          decoration: pw.BoxDecoration(
            color: _gold,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(1)),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          text.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 8.5,
            fontWeight: pw.FontWeight.bold,
            color: _forestGreen,
            letterSpacing: 0.9,
          ),
        ),
      ],
    );
  }

  static bool _matchesPurpose(String value, String label) {
    return value.trim().toLowerCase() == label.toLowerCase();
  }

  static pw.Widget _fieldLine(
    String label,
    String value, {
    bool valueEmphasis = false,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 7.5,
            fontWeight: pw.FontWeight.bold,
            color: _muted,
            letterSpacing: 0.6,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.only(bottom: 4),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(
                color: PdfColor.fromInt(0xFFcfd8d4),
                width: 1,
              ),
            ),
          ),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: valueEmphasis ? 12 : 10,
              fontWeight:
                  valueEmphasis ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: valueEmphasis ? _forestGreen : _ink,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _checkRow(String label, bool selected) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 13,
          height: 13,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _forestGreen, width: 1.1),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
            color: selected ? PdfColor.fromInt(0xFFe8f0ec) : _white,
          ),
          alignment: pw.Alignment.center,
          child: selected
              ? pw.Text(
                  '✓',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _forestGreen,
                  ),
                )
              : pw.SizedBox(),
        ),
        pw.SizedBox(width: 7),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 9.2, color: _ink),
        ),
      ],
    );
  }

  static Future<void> shareReceipt(CashReceiptModel receipt) async {
    final file = await buildReceiptPdf(receipt);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Cash Receipt ${receipt.receiptId}',
    );
  }
}
