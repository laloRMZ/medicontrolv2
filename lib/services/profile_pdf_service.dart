import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/user.dart';

class ProfilePdfService {
  static Future<Uint8List> buildMedicalProfilePdf(
    AppUser user, {
    bool useGoogleFonts = true,
  }) async {
    pw.ThemeData? theme;
    if (useGoogleFonts) {
      try {
        final regularFont = await PdfGoogleFonts.robotoRegular();
        final boldFont = await PdfGoogleFonts.robotoBold();
        theme = pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
        );
      } catch (_) {
        // Fallback a fuente integrada si no hay conexión
        theme = null;
      }
    }

    final pdf = pw.Document(theme: theme);
    final medical = user.medicalData;
    final generatedAt = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    String valueOrFallback(String value) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? 'No especificado' : trimmed;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Text(
            'MediControl - Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey600,
            ),
          ),
        ),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.blue200),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'MediControl',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Ficha de Perfil Médico',
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Fecha de generación',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Text(
                      generatedAt,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          _buildSectionTitle('Datos Personales'),
          pw.SizedBox(height: 8),
          _buildInfoTable([
            ('Nombre completo', valueOrFallback(user.fullName)),
            ('Correo electrónico', valueOrFallback(user.email)),
            ('Teléfono', valueOrFallback(user.phone)),
            ('Tipo de cuenta', user.role.name.toUpperCase()),
          ]),
          pw.SizedBox(height: 20),

          _buildSectionTitle('Datos Médicos'),
          pw.SizedBox(height: 8),
          _buildInfoTable([
            ('Tipo de sangre', valueOrFallback(medical.bloodType)),
            ('Alergias', valueOrFallback(medical.allergies)),
            ('Notas médicas', valueOrFallback(medical.notes)),
          ]),
          pw.SizedBox(height: 20),

          _buildSectionTitle('Contacto de Emergencia'),
          pw.SizedBox(height: 8),
          _buildInfoTable([
            ('Nombre del contacto', valueOrFallback(medical.emergencyContactName)),
            ('Teléfono de emergencia', valueOrFallback(medical.emergencyContactPhone)),
          ]),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: const pw.BoxDecoration(
        color: PdfColors.blue700,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _buildInfoTable(List<(String, String)> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
      },
      children: rows
          .map(
            (row) => pw.TableRow(
              children: [
                pw.Container(
                  color: PdfColors.grey100,
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    row.$1,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey800,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    row.$2,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}
