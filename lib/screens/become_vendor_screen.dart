// lib/screens/become_vendor_screen.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class BecomeVendorScreen extends StatefulWidget {
  const BecomeVendorScreen({super.key});

  @override
  State<BecomeVendorScreen> createState() => _BecomeVendorScreenState();
}

class _BecomeVendorScreenState extends State<BecomeVendorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  final _galleryNameController = TextEditingController();
  final _detailsController = TextEditingController();
  
  // گۆڕاوێک بۆ مەرج و ڕێنماییەکان
  bool _agreedToTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _galleryNameController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    // 1. پشکنینی فۆڕم و مەرجەکان
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('تکایە ڕازیبە لەسەر مەرج و ڕێنماییەکان'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => _isLoading = true);
    
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      setState(() => _isLoading = false); return;
    }
    
    final success = await _apiService.applyToBeVendor({
      'gallery_name': _galleryNameController.text,
      'details': _detailsController.text,
    }, token);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        // پیشاندانی پەیامی سەرکەوتن و گەڕانەوە
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('سەرکەوتوو بوو'),
            content: const Text('داواکارییەکەت بە سەرکەوتوویی نێردرا. تکایە چاوەڕێی وەڵامی تیمی ئێمە بە.'),
            actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('باشە'))],
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هەڵەیەک ڕوویدا یان تۆ پێشتر داواکاریت ناردووە'), backgroundColor: Colors.red));
      }
    }
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مەرج و ڕێنماییەکانی بوون بە پێشانگا'),
        content: const SingleChildScrollView(
          child: Text(
            '1. پێویستە هەموو کاڵاکانت ڕەسەن بن و هیچ کاڵایەکی کۆپیکراو یان ساختە دانەنێیت.\n\n'
            '2. تۆ بەرپرسی لە گەیاندنی کاڵاکە بۆ کڕیار بە شێوەیەکی سەلامەت.\n\n'
            '3. هەر زانیارییەکی هەڵە یان چەواشەکارانە لەسەر کاڵا دەبێتە هۆی سڕینەوەی مەزادەکە و لەوانەیە هەژمارەکەت دابخرێت.\n\n'
            '4. تکایە پابەندی یاسا و ڕێساکانی ناوخۆیی و نێودەوڵەتی بازرگانی بە.\n\n'
            '5. بە ناردنی ئەم داواکارییە، تۆ ڕەزامەندی دەردەبڕیت لەسەر هەموو ئەم خاڵانەی سەرەوە.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('داخستن')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('داواکاری بۆ بوون بە پێشانگا')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min, // Prevent overflow
                  children: [
                    const Icon(Icons.storefront_outlined, size: 80, color: Colors.indigo),
                    const SizedBox(height: 16),
                    Text(
                      'هەنگاوێک نزیکتر بەرەو فرۆشتن',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      'تکایە زانیاری پێشانگاکەت پڕ بکەرەوە',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),

                    TextFormField(
                      controller: _galleryNameController,
                      decoration: const InputDecoration(labelText: 'ناوی پێشانگا', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'نابێت بەتاڵ بێت' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _detailsController,
                      decoration: const InputDecoration(labelText: 'زانیاری زیاتر (بۆ نموونە، جۆری کاڵاکانت)', border: OutlineInputBorder(), alignLabelWithHint: true),
                      maxLines: 5,
                      validator: (v) => v!.isEmpty ? 'نابێت بەتاڵ بێت' : null,
                    ),
                    const SizedBox(height: 16),

                    // ===== بەشی مەرج و ڕێنماییەکان =====
                    FormField<bool>(
                      builder: (state) {
                        return Column(
                          mainAxisSize: MainAxisSize.min, // Prevent overflow
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _agreedToTerms,
                                  onChanged: (value) {
                                    setState(() => _agreedToTerms = value!);
                                  },
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                                    child: RichText(
                                      text: TextSpan(
                                        style: Theme.of(context).textTheme.bodyMedium,
                                        children: [
                                          const TextSpan(text: 'ڕازیم لەسەر '),
                                          TextSpan(
                                            text: 'مەرج و ڕێنماییەکان',
                                            style: TextStyle(color: Theme.of(context).primaryColor, decoration: TextDecoration.underline),
                                            recognizer: TapGestureRecognizer()..onTap = _showTermsDialog,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: _submitApplication,
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('ناردنی داواکاری'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}