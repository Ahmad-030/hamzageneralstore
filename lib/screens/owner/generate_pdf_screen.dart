import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/firebase_service.dart';
import '../../models/models.dart';
import '../../utils/theme.dart';
import '../../widgets/widgets.dart';

class GeneratePdfScreen extends StatefulWidget {
  final Customer customer;
  const GeneratePdfScreen({super.key, required this.customer});

  @override
  State<GeneratePdfScreen> createState() => _GeneratePdfScreenState();
}

class _GeneratePdfScreenState extends State<GeneratePdfScreen> {
  String _period = 'This Month';
  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _to = DateTime.now();
  bool _loading = false;
  bool _previewing = false;

  Future<pw.Document> _buildPdf() async {
    final txs = await FirebaseService.instance
        .customerTransactionsStream(widget.customer.id)
        .first;

    final filtered = txs.where((t) {
      return t.date.isAfter(_from.subtract(const Duration(days: 1))) &&
          t.date.isBefore(_to.add(const Duration(days: 1)));
    }).toList();

    final totalAdded = filtered
        .where((t) => t.type == TransactionType.order)
        .fold(0.0, (s, t) => s + t.amount);
    final totalPaid = filtered
        .where((t) => t.type == TransactionType.payment)
        .fold(0.0, (s, t) => s + t.amount);

    final fmt = DateFormat('d MMM yyyy');
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#2563EB'),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Hamza General Store',
                    style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white)),
                pw.Text('Customer Statement',
                    style: const pw.TextStyle(
                        fontSize: 13, color: PdfColors.white)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          // Customer info
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Customer: ${widget.customer.name}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Phone: ${widget.customer.phone}'),
                  ]),
              pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                        'Period: ${fmt.format(_from)} - ${fmt.format(_to)}'),
                    pw.Text('Generated: ${fmt.format(DateTime.now())}'),
                  ]),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 12),
          // Summary
          pw.Row(
            children: [
              _pdfSummaryBox('Total Added',
                  'Rs. ${totalAdded.toStringAsFixed(0)}', PdfColors.red),
              pw.SizedBox(width: 12),
              _pdfSummaryBox('Total Paid',
                  'Rs. ${totalPaid.toStringAsFixed(0)}', PdfColors.green),
              pw.SizedBox(width: 12),
              _pdfSummaryBox(
                  'Balance Due',
                  'Rs. ${(totalAdded - totalPaid).toStringAsFixed(0)}',
                  PdfColor.fromHex('#2563EB')),
            ],
          ),
          pw.SizedBox(height: 20),
          // Table header
          pw.Container(
            padding:
            const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: PdfColor.fromHex('#F1F5F9'),
            child: pw.Row(
              children: [
                pw.Expanded(
                    flex: 2,
                    child: pw.Text('Date',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 11))),
                pw.Expanded(
                    flex: 3,
                    child: pw.Text('Description',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 11))),
                pw.Expanded(
                    child: pw.Text('Type',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 11))),
                pw.Expanded(
                    child: pw.Text('Amount',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 11))),
              ],
            ),
          ),
          // Rows
          ...filtered.map((t) {
            final isPayment = t.type == TransactionType.payment;
            return pw.Container(
              padding:
              const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: const pw.BoxDecoration(
                  border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey300))),
              child: pw.Row(
                children: [
                  pw.Expanded(
                      flex: 2,
                      child: pw.Text(fmt.format(t.date),
                          style: const pw.TextStyle(fontSize: 10))),
                  pw.Expanded(
                      flex: 3,
                      child: pw.Text(t.reason,
                          style: const pw.TextStyle(fontSize: 10))),
                  pw.Expanded(
                      child: pw.Text(isPayment ? 'Payment' : 'Order',
                          style: pw.TextStyle(
                              fontSize: 10,
                              color: isPayment
                                  ? PdfColors.green
                                  : PdfColors.red))),
                  pw.Expanded(
                      child: pw.Text(
                          '${isPayment ? '-' : '+'} Rs. ${t.amount.toStringAsFixed(0)}',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                              fontSize: 10,
                              color: isPayment
                                  ? PdfColors.green
                                  : PdfColors.red))),
                ],
              ),
            );
          }),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Current Due: Rs. ${widget.customer.totalDue.toStringAsFixed(0)}',
              style:
              pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return doc;
  }

  pw.Widget _pdfSummaryBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style: pw.TextStyle(color: PdfColors.white, fontSize: 10)),
            pw.Text(value,
                style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  /// Formats Pakistani phone number for WhatsApp
  /// 03001234567 → 923001234567
  String _formatPhoneForWhatsApp(String phone) {
    String digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.startsWith('0')) {
      return '92${digits.substring(1)}';
    } else if (!digits.startsWith('92')) {
      return '92$digits';
    }
    return digits;
  }

  Future<void> _sendWhatsApp() async {
    try {
      final formattedPhone = _formatPhoneForWhatsApp(widget.customer.phone);
      final fmt = DateFormat('d MMM yyyy');

      final message = 'Hello ${widget.customer.name},\n\n'
          'Your account statement from Hamza General Store:\n\n'
          'Current Due: Rs. ${widget.customer.totalDue.toStringAsFixed(0)}\n\n'
          'Period: ${fmt.format(_from)} to ${fmt.format(_to)}\n\n'
          'Please contact us for any queries.\n'
          'Thank you!';

      final uri = Uri(
        scheme: 'https',
        host: 'wa.me',
        path: '/$formattedPhone',
        queryParameters: {'text': message},
      );

      final launched =
      await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Could not open WhatsApp. Please make sure it is installed.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening WhatsApp: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM yyyy');
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Generate Statement')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customer',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textGrey)),
                  Text(widget.customer.name,
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  Text(widget.customer.phone,
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppColors.textGrey)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Select Period',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            AppCard(
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _period,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      filled: false,
                    ),
                    items: ['This Month', 'Last Month', 'Custom Range']
                        .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e, style: GoogleFonts.poppins())))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _period = v!;
                        final now = DateTime.now();
                        if (v == 'This Month') {
                          _from = DateTime(now.year, now.month, 1);
                          _to = now;
                        } else if (v == 'Last Month') {
                          _from = DateTime(now.year, now.month - 1, 1);
                          _to = DateTime(now.year, now.month, 0);
                        }
                      });
                    },
                  ),
                  if (_period == 'Custom Range') ...[
                    const Divider(color: AppColors.border),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('From',
                                  style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: AppColors.textGrey)),
                              TextButton(
                                onPressed: () async {
                                  final d = await showDatePicker(
                                    context: context,
                                    initialDate: _from,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (d != null) setState(() => _from = d);
                                },
                                child: Text(fmt.format(_from),
                                    style: GoogleFonts.poppins(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('To',
                                  style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: AppColors.textGrey)),
                              TextButton(
                                onPressed: () async {
                                  final d = await showDatePicker(
                                    context: context,
                                    initialDate: _to,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (d != null) setState(() => _to = d);
                                },
                                child: Text(fmt.format(_to),
                                    style: GoogleFonts.poppins(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Preview button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _previewing
                    ? null
                    : () async {
                  setState(() => _previewing = true);
                  try {
                    final doc = await _buildPdf();
                    if (!mounted) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(
                              title: const Text('Preview Statement')),
                          body: PdfPreview(
                            build: (fmt) => doc.save(),
                            allowPrinting: true,
                            allowSharing: true,
                          ),
                        ),
                      ),
                    );
                  } finally {
                    if (mounted) setState(() => _previewing = false);
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                ),
                icon: const Icon(Icons.visibility_rounded,
                    color: AppColors.primary, size: 18),
                label: Text('Preview Statement',
                    style: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),

            // Generate PDF button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading
                    ? null
                    : () async {
                  setState(() => _loading = true);
                  try {
                    final doc = await _buildPdf();
                    await Printing.layoutPdf(
                        onLayout: (_) => doc.save());
                  } finally {
                    if (mounted) setState(() => _loading = false);
                  }
                },
                icon: _loading
                    ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.picture_as_pdf_rounded, size: 18),
                label: const Text('Generate PDF'),
              ),
            ),
            const SizedBox(height: 12),

            // WhatsApp share button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sendWhatsApp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                ),
                icon: const Icon(Icons.chat, size: 18),
                label: Text('Send via WhatsApp',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}