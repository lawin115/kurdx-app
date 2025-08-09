// lib/screens/order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final ApiService _apiService = ApiService();
  String? _vendorPaymentDetails;
  bool _isLoadingPaymentDetails = true;
  bool _isConfirmingPayment = false;
  late Order _currentOrder; // گۆڕاوێک بۆ هەڵگرتنی دۆخی نوێ

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    // تەنها ئەگەر پێویست بوو, زانیاری پارەدان بهێنە
    if (_currentOrder.status == 'processing') {
      _fetchPaymentDetails();
    } else {
      setState(() => _isLoadingPaymentDetails = false);
    }
  }
  
  Future<void> _fetchPaymentDetails() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    
    final details = await _apiService.getOrderPaymentDetails(widget.order.id, token);
    if (mounted) {
      setState(() {
        _vendorPaymentDetails = details?['payment_details'];
        _isLoadingPaymentDetails = false;
      });
    }
  }

  Future<void> _confirmPayment() async {
    setState(() => _isConfirmingPayment = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    final success = await _apiService.confirmPayment(widget.order.id, token);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('پشتڕاستکرایەوە! فرۆشیار ئاگادار کرا.'), backgroundColor: Colors.green));
        setState(() {
          // دۆخی ناوخۆیی نوێ دەکەینەوە
          _currentOrder = _currentOrder.copyWith(status: 'paid'); 
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هەڵەیەک ڕوویدا'), backgroundColor: Colors.red));
      }
    }
    setState(() => _isConfirmingPayment = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('وردەکاری داواکاری #${_currentOrder.id}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderStatusStepper(),
            const SizedBox(height: 24),
            // ===== بەشی پارەدان لێرە دادەنرێت =====
            if (_currentOrder.status == 'processing') _buildPaymentSection(),
          ],
        ),
      ),
    );
  }

  // --- ویجێتە یارمەتیدەرەکان ---

  Widget _buildOrderStatusStepper() {
    final statuses = ['processing', 'shipped', 'out_for_delivery', 'delivered'];
    final currentStatusIndex = statuses.indexOf(_currentOrder.status);

    return Stepper(
      physics: const ClampingScrollPhysics(),
      currentStep: currentStatusIndex >= 0 ? currentStatusIndex : 0,
      controlsBuilder: (context, details) => const SizedBox.shrink(),
      steps: statuses.map((status) {
        return Step(
          title: Text(_getStatusText(status)),
          content: const SizedBox.shrink(),
          isActive: statuses.indexOf(status) <= currentStatusIndex,
          state: statuses.indexOf(status) < currentStatusIndex ? StepState.complete : (statuses.indexOf(status) == currentStatusIndex ? StepState.editing : StepState.indexed),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('پارەدان', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('تکایە بڕی پارەکە بنێرە بۆ یەکێک لەم زانیاریانەی خوارەوە و پاشان دوگمەی پشتڕاستکردنەوە دابگرە.'),
            const Divider(height: 24),
            if (_isLoadingPaymentDetails)
              const Center(child: CircularProgressIndicator())
            else
              Text(_vendorPaymentDetails ?? 'هیچ زانیارییەکی پارەدان تۆمارنەکراوە.'),
            const SizedBox(height: 16),
            
            _isConfirmingPayment
              ? const Center(child: CircularProgressIndicator())
              : FilledButton(
                  onPressed: (_vendorPaymentDetails == null || _vendorPaymentDetails!.isEmpty) ? null : _confirmPayment,
                  child: const Text('پشتڕاستکردنەوەی ناردنی پارە'),
                ),
          ],
        ),
      ),
    );
  }


  String _getStatusText(String status) {
    switch(status) {
        case 'pending_payment': return 'چاوەڕێی پارەدان';
        case 'processing': return 'ئامادەکردن';
        case 'shipped': return 'نێردرا';
        case 'out_for_delivery': return 'لەسەر ڕێگای گەیاندن';
        case 'delivered': return 'گەیشت';
        default: return 'نادیار';
    }
  }
}