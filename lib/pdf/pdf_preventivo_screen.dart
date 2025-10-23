import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../data/preventivi_store.dart';

Future<Uint8List?> _loadTemplateBg() async {
  try {
    final bytes = (await rootBundle.load(
      'assets/template.jpg',
    )).buffer.asUint8List();
    print('Template JPG caricato correttamente');
    return bytes;
  } catch (e) {
    print('Template JPG non trovato: $e');
  }

  try {
    final bytes = (await rootBundle.load(
      'assets/template.png',
    )).buffer.asUint8List();
    print('Template PNG caricato correttamente');
    return bytes;
  } catch (e) {
    print('Template PNG non trovato: $e');
  }

  try {
    final pdfBytes = (await rootBundle.load(
      'assets/template.pdf',
    )).buffer.asUint8List();
    final pages = Printing.raster(pdfBytes, dpi: 144);
    final first = await pages.first;
    final png = await first.toPng();
    print('Template PDF caricato e rasterizzato correttamente');
    return png;
  } catch (e) {
    print('Template PDF non trovato o errore rasterizzazione: $e');
  }

  print('Nessun template caricato, PDF senza sfondo');
  return null;
}

class PdfPreventivoScreen extends StatelessWidget {
  final Preventivo preventivo;
  final String spettabile;
  final String preventivoPer;
  final String descrizione;
  final String condizioni;
  final bool mostraIva;
  final double aliquotaIva;

  const PdfPreventivoScreen({
    super.key,
    required this.preventivo,
    this.spettabile = '',
    this.preventivoPer = '',
    this.descrizione = '',
    this.condizioni = '',
    this.mostraIva = true,
    this.aliquotaIva = 0.22,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF BLOCCO v1')),
      body: PdfPreview(
        build: (_) => _buildPdf(preventivo),
        initialPageFormat: PdfPageFormat.a4,
        canChangePageFormat: false,
        allowPrinting: true,
        allowSharing: true,
      ),
    );
  }

  Future<Uint8List> _buildPdf(Preventivo p) async {
    final pdf = pw.Document();
    final fmt = NumberFormat.currency(locale: 'it_IT', symbol: '€ ');
    final dateOnly = DateFormat('dd/MM/yyyy');

    pw.MemoryImage? bg;
    final tpl = await _loadTemplateBg();
    if (tpl != null) bg = pw.MemoryImage(tpl);

    final imponibile = p.totale;
    final iva = mostraIva ? imponibile * aliquotaIva : 0.0;
    final totale = imponibile + iva;

    final righe = p.righe;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) {
          double mm(double v) => v * PdfPageFormat.mm;

          final colMqWidth = mm(25);
          final colEuroWidth = mm(45);
          final colTotWidth = mm(45);
          final gapCols = mm(8);

          final labelStyle = const pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
          );
          final text11 = const pw.TextStyle(fontSize: 11);
          final text10 = const pw.TextStyle(fontSize: 10);
          final bold12 = pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          );
          final bold13 = pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
          );

          final blocco = pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'DEBUG123',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.red),
              ),
              pw.SizedBox(height: mm(2)),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Flexible(
                    fit: pw.FlexFit.tight,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Spettabile :', style: labelStyle),
                        pw.SizedBox(height: 2),
                        pw.Text(spettabile, style: text11),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: mm(6)),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Data :', style: labelStyle),
                      pw.SizedBox(height: 2),
                      pw.Text(dateOnly.format(p.createdAt), style: text11),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: mm(6)),
              pw.Text('Preventivo per :', style: labelStyle),
              pw.SizedBox(height: 2),
              pw.Text(preventivoPer, style: text11),
              if (descrizione.isNotEmpty) ...[
                pw.SizedBox(height: mm(6)),
                pw.Text('Descrizione :', style: labelStyle),
                pw.SizedBox(height: 2),
                pw.Text(descrizione, style: text11),
              ],
              if (righe.isNotEmpty) ...[
                pw.SizedBox(height: mm(8)),
                pw.Text('Descrizioni lavori :', style: labelStyle),
                pw.SizedBox(height: 4),
                ...righe.map((r) {
                  final d = (r.lavorazione.dicitura ?? '').trim();
                  final t = d.isEmpty
                      ? r.lavorazione.tipo
                      : '${r.lavorazione.tipo} — $d';
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 3),
                    child: pw.Text(t, style: text11),
                  );
                }),
                pw.SizedBox(height: mm(8)),
                pw.Row(
                  children: [
                    pw.SizedBox(
                      width: colMqWidth,
                      child: pw.Text('Mq', style: labelStyle),
                    ),
                    pw.SizedBox(width: gapCols),
                    pw.SizedBox(
                      width: colEuroWidth,
                      child: pw.Text('€ al Mq', style: labelStyle),
                    ),
                    pw.SizedBox(width: gapCols),
                    pw.SizedBox(
                      width: colTotWidth,
                      child: pw.Text('Totale', style: labelStyle),
                    ),
                  ],
                ),
                pw.SizedBox(height: 3),
                ...righe.map(
                  (r) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      children: [
                        pw.SizedBox(
                          width: colMqWidth,
                          child: pw.Text(
                            r.mq.toStringAsFixed(2),
                            style: text10,
                          ),
                        ),
                        pw.SizedBox(width: gapCols),
                        pw.SizedBox(
                          width: colEuroWidth,
                          child: pw.Text(
                            fmt.format(r.lavorazione.prezzo),
                            style: text10,
                          ),
                        ),
                        pw.SizedBox(width: gapCols),
                        pw.SizedBox(
                          width: colTotWidth,
                          child: pw.Text(
                            fmt.format(r.subtotale),
                            style: text10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (condizioni.isNotEmpty) ...[
                pw.SizedBox(height: mm(10)),
                pw.Text('Condizioni di pagamento :', style: labelStyle),
                pw.SizedBox(height: 2),
                pw.Text(condizioni, style: text11),
              ],
              pw.SizedBox(height: mm(10)),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Totale: ${fmt.format(imponibile)}${mostraIva ? ' + IVA' : ''}',
                        style: bold12,
                      ),
                      if (mostraIva) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'IVA ${(aliquotaIva * 100).toStringAsFixed(0)}%: ${fmt.format(iva)}',
                          style: text11,
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text('TOTALE: ${fmt.format(totale)}', style: bold13),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          );

          return pw.Stack(
            children: [
              if (bg != null)
                pw.Positioned.fill(child: pw.Image(bg, fit: pw.BoxFit.cover)),
              pw.Positioned(left: mm(10), top: mm(20), child: blocco),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
