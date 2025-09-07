// lib/utils/invoice_generator.dart

import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/order_model.dart';
import '../models/auction_model.dart';
import 'package:intl/intl.dart';


class InvoiceGenerator {
  static Future<Uint8List> generateInvoice(Order order) async {
    final pdf = pw.Document();
    
    // فۆنتی کوردی زیاد دەکەین
    // تکایە فایلێکی فۆنتی کوردی (بۆ نموونە Rudaw) لە assets/fonts دابنێ
    // و لە pubspec.yaml بناسێنە
    final fontData = await rootBundle.load("assets/fonts/Rabar_043.ttf");
    final ttfFont = pw.Font.ttf(fontData);

    // لۆگۆی کۆمپانیا (ئەگەر هەبوو)
    // final logo = pw.MemoryImage((await rootBundle.load('assets/images/logo.png')).buffer.asUint8List());

    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(base: ttfFont, bold: ttfFont), // دەتوانیت وەشانی boldـیشی دابنێیت
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) {
       
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              pw.SizedBox(height: 20),
              _buildOrderInfo(order),
              pw.SizedBox(height: 30),
               _buildPartyInfo(order),
              pw.SizedBox(height: 30),
              _buildItemsTable(order),
              pw.Spacer(),
              _buildFooter(),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('BUY X', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        // pw.Image(logo, height: 50),
      ],
    );
  }
  
  static pw.Widget _buildOrderInfo(Order order) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('پسووڵەی داواکاری', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
            pw.Text('Order #${order.id}'),
            pw.Text('Date: ${DateFormat('yyyy-MM-dd').format(order.auction.createdAt)}'),
          ],
        ),
        pw.Container(
          height: 100,
          width: 100,
          child: pw.BarcodeWidget(
            barcode: pw.Barcode.qrCode(),
            data: 'ORDER-ID:${order.id}',
          ),
        ),
      ],
    );
  }
  
  static pw.Widget _buildPartyInfo(Order order) {
    // یەکەمجار, user و vendor لە order وەردەگرین
    final winner = order.user;
    final vendor = order.vendor;

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('فرۆشیار (پێشانگا)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(vendor?.name ?? 'زانیاری نییە'),
              pw.Text(vendor?.phoneNumber ?? 'ژمارە نییە'),
            ],
          ),
        ),
        pw.SizedBox(width: 20),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('کڕیار (براوە)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(winner!.name),
              pw.Text(winner.phoneNumber ?? 'ژمارە تۆمارنەکراوە'),
              pw.Text(winner.location ?? 'ناونیشان تۆمارنەکراوە'),
            ],
          ),
        ),
      ],
    );
  }
  static pw.Widget _buildItemsTable(Order order) {
    return pw.TableHelper.fromTextArray(
      headers: ['کاڵا', 'نرخی کۆتایی'],
      data: [
        [
          order.auction.title, 
          NumberFormat.simpleCurrency().format(order.finalPrice)
        ]
      ],
      border: pw.TableBorder.all(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignment: pw.Alignment.center,
    );
  }
  
  static pw.Widget _buildFooter() {
    return pw.Center(
      child: pw.Text('سوپاس بۆ بازرگانیکردن لەگەڵ ئێمە!', style: const pw.TextStyle(fontSize: 12))
    );
  }
}