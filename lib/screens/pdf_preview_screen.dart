// lib/screens/pdf_preview_screen.dart

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/order_model.dart';
import '../utils/invoice_generator.dart';

class PdfPreviewScreen extends StatelessWidget {
  final Order order;
  const PdfPreviewScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    
 final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text('پێشبینی پسووڵە #${order.id}',style: TextStyle(color: colorScheme.surfaceDim)),
      backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      
      body: PdfPreview(
        // build-ەکەمان بانگی функцIAی دروستکردنی PDF دەکات
        build: (format) => InvoiceGenerator.generateInvoice(order),
      ),
    );
  }
}