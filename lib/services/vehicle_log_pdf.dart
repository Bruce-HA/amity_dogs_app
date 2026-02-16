import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class VehicleLogPdfService {
  static Future<pw.Document> generate({
    required List<Map<String, dynamic>> logs,
    required bool landscape,
  }) async {
    final pdf = pw.Document();

    final pageFormat = landscape
        ? PdfPageFormat.a4.landscape
        : PdfPageFormat.a4.portrait;

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.all(24),
        ),

        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Vehicle Log Report',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ),

          pw.SizedBox(height: 10),

          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),

            cellStyle: const pw.TextStyle(fontSize: 9),

            headers: const [
              'Date',
              'Driver',
              'Vehicle',
              'Start KM',
              'End KM',
              'Total KM',
            ],

            data: logs.map((log) {
              final start = (log['start_km'] ?? 0) as num;

              final end = (log['end_km'] ?? 0) as num;

              final total = end - start;

              return [
                log['date']?.toString() ?? '',

                log['driver_name']?.toString() ?? '',

                log['vehicle_name']?.toString() ?? '',

                start.toString(),

                end.toString(),

                total.toString(),
              ];
            }).toList(),
          ),
        ],
      ),
    );

    return pdf;
  }
}
