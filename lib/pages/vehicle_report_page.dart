import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class VehicleReportPage extends StatefulWidget {
  final String vehicleName;

  const VehicleReportPage({super.key, required this.vehicleName});

  @override
  State<VehicleReportPage> createState() => _VehicleReportPageState();
}

class _VehicleReportPageState extends State<VehicleReportPage> {
  final supabase = Supabase.instance.client;

  DateTime startDate = DateTime.now().subtract(const Duration(days: 30));

  DateTime endDate = DateTime.now();

  String tripFilter = "Both";

  bool loading = false;

  // ✅ ADD HELPER FUNCTION HERE

  // ✅ ADD THIS FUNCTION RIGHT HERE
  Future<pw.MemoryImage> _loadLogo() async {
    final bytes = await rootBundle.load('assets/images/amity_logo.png');

    return pw.MemoryImage(bytes.buffer.asUint8List());
  }

  // your other functions continue below...

  Future<void> emailPdf(pw.Document pdf) async {
    final bytes = await pdf.save();

    final dir = await getTemporaryDirectory();

    final vehicle = widget.vehicleName.replaceAll(" ", "");

    final trip = tripFilter == "Both" ? "AllTrips" : tripFilter;

    final start = DateFormat("yyyy-MM-dd").format(startDate);

    final end = DateFormat("yyyy-MM-dd").format(endDate);

    final filename = "Amity_${vehicle}_${trip}_${start}_to_${end}.pdf";

    final file = File("${dir.path}/$filename");

    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],

      subject: "Amity Labradoodles Vehicle Log Report",

      text:
          "Vehicle: ${widget.vehicleName}\n"
          "Trip type: $tripFilter\n"
          "Period: $start to $end",
    );
  }

  pw.Widget _cell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> loadLogs() async {
    final builder = supabase
        .from('vehicle_logs')
        .select()
        .eq('vehicle_name', widget.vehicleName)
        .gte('created_at', startDate.toIso8601String())
        .lte('created_at', endDate.toIso8601String());

    // Apply business/private filter safely
    if (tripFilter == "Business") {
      builder.eq('is_business', true);
    } else if (tripFilter == "Private") {
      builder.eq('is_business', false);
    }

    final data = await builder.order('created_at');

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> generatePdf() async {
    setState(() => loading = true);

    final logs = await loadLogs();

    final logo = await _loadLogo();

    int totalKm = 0;
    int businessKm = 0;
    int privateKm = 0;

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,

        margin: const pw.EdgeInsets.all(24),

        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,

            margin: const pw.EdgeInsets.only(top: 10),

            child: pw.Text(
              "Page ${context.pageNumber} of ${context.pagesCount}",

              style: const pw.TextStyle(fontSize: 10),
            ),
          );
        },

        build: (context) {
          return [
            // LOGO + HEADER
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,

              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,

                  children: [
                    pw.Text(
                      "Amity Labradoodles",
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),

                    pw.Text("${widget.vehicleName} Vehicle Log Report"),

                    pw.Text("$tripFilter trips"),

                    pw.Text(
                      "${DateFormat('dd/MM/yyyy').format(startDate)}"
                      " to "
                      "${DateFormat('dd/MM/yyyy').format(endDate)}",
                    ),
                  ],
                ),

                pw.Image(logo, width: 100, height: 100),
              ],
            ),

            pw.SizedBox(height: 20),

            pw.Table(
              border: pw.TableBorder.all(),

              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(1),
                5: const pw.FlexColumnWidth(1),
                6: const pw.FlexColumnWidth(3),
              },

              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),

                  children: [
                    _cell("Date", bold: true),

                    _cell("Driver", bold: true),

                    _cell("Business", bold: true),

                    _cell("Start", bold: true),

                    _cell("End", bold: true),

                    _cell("Distance", bold: true),

                    _cell("Notes", bold: true),
                  ],
                ),

                ...logs.map((log) {
                  final start = (log['start_km'] ?? 0) as num;

                  final end = (log['end_km'] ?? 0) as num;

                  final distance = end.toInt() - start.toInt();

                  totalKm += distance;

                  if (log['is_business'] == true) {
                    businessKm += distance;
                  } else {
                    privateKm += distance;
                  }

                  return pw.TableRow(
                    children: [
                      _cell(
                        DateFormat(
                          'dd/MM/yyyy',
                        ).format(DateTime.parse(log['created_at'])),
                      ),

                      _cell(log['driver_name'] ?? ""),

                      _cell(log['is_business'] ? "Yes" : "No"),

                      _cell(start.toInt().toString()),

                      _cell(end.toInt().toString()),

                      _cell(distance.toString()),

                      _cell(log['notes'] ?? ""),
                    ],
                  );
                }).toList(),
              ],
            ),

            pw.SizedBox(height: 20),

            pw.Container(
              padding: const pw.EdgeInsets.all(12),

              decoration: pw.BoxDecoration(border: pw.Border.all()),

              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,

                children: [
                  pw.Text(
                    "ATO Summary",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),

                  pw.Text("Total KM: $totalKm"),

                  pw.Text("Business KM: $businessKm"),

                  pw.Text("Private KM: $privateKm"),

                  pw.Text(
                    "Business Use %: "
                    "${totalKm == 0 ? 0 : ((businessKm / totalKm) * 100).toStringAsFixed(1)}%",
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    setState(() => loading = false);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Report Preview"),

              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),

              actions: [
                IconButton(
                  icon: const Icon(Icons.email),
                  tooltip: "Email Report",
                  onPressed: () {
                    emailPdf(pdf);
                  },
                ),
              ],
            ),

            body: PdfPreview(
              build: (format) async {
                return pdf.save();
              },

              allowPrinting: false,

              allowSharing: true,

              canChangeOrientation: false,

              canChangePageFormat: false,
            ),
          );
        },
      ),
    );
  }

  Future<void> pickStartDate() async {
    final picked = await showDatePicker(
      context: context,

      initialDate: startDate,

      firstDate: DateTime(2020),

      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => startDate = picked);
    }
  }

  Future<void> pickEndDate() async {
    final picked = await showDatePicker(
      context: context,

      initialDate: endDate,

      firstDate: DateTime(2020),

      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => endDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.vehicleName} Report")),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            DropdownButtonFormField(
              value: tripFilter,

              items: const [
                DropdownMenuItem(value: "Both", child: Text("Both")),

                DropdownMenuItem(value: "Business", child: Text("Business")),

                DropdownMenuItem(value: "Private", child: Text("Private")),
              ],

              onChanged: (value) {
                setState(() {
                  tripFilter = value.toString();
                });
              },

              decoration: const InputDecoration(labelText: "Trip Type"),
            ),

            const SizedBox(height: 10),

            ListTile(
              title: Text(
                "Start: ${DateFormat('dd/MM/yyyy').format(startDate)}",
              ),

              trailing: const Icon(Icons.calendar_today),

              onTap: pickStartDate,
            ),

            ListTile(
              title: Text("End: ${DateFormat('dd/MM/yyyy').format(endDate)}"),

              trailing: const Icon(Icons.calendar_today),

              onTap: pickEndDate,
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),

              label: const Text("Generate PDF"),

              onPressed: loading ? null : generatePdf,
            ),
          ],
        ),
      ),
    );
  }
}
