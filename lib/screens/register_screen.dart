import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import './main_screen.dart';
import 'login_screen.dart'; // دڵنیابە ئەمە بە دروستی ئیمپۆرت کراوە

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  // --- کۆنترۆڵەرەکان ---
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  // --- دۆخی ڕووکار ---
  bool _isLoading = false;
  bool _isVerificationStep = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = ''; // پاککردنەوەی هەر پەیامێکی هەڵەی پێشوو
    });

    try {
      // TODO: ئەمە بگۆڕە بە بانگکردنی API ڕاستەقینەی خۆت بۆ ناردنی OTP
      // final response = await _apiService.sendVerificationCode(_phoneController.text);
      // if (response != null && response['success']) {
      //   setState(() {
      //     _isVerificationStep = true;
      //     _isLoading = false;
      //   });
      // } else {
      //   setState(() {
      //     _errorMessage = response?['message'] ?? 'ناردنی کۆدی OTP سەرکەوتوو نەبوو. تکایە دووبارە هەوڵبدەرەوە.';
      //     _isLoading = false;
      //   });
      // }

      // بۆ مەبەستی تاقیکردنەوە، دواخستن و سەرکەوتنێک دروست دەکەین
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _isVerificationStep = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'هەڵەیەک ڕوویدا: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitRegistration() async {
    // TODO: لۆجیکی پشتڕاستکردنەوەی OTP لێرە زیاد بکە
    // بۆ نموونە: if (_otpController.text != "123456") {
    //   setState(() {
    //     _errorMessage = 'کۆدی OTP نادروستە. تکایە دووبارە هەوڵبدەرەوە.';
    //   });
    //   return;
    // }
    if (!_formKey.currentState!.validate()) return;


    setState(() {
      _isLoading = true;
      _errorMessage = ''; // پاککردنەوەی هەر پەیامێکی هەڵەی پێشوو
    });

    final data = {
      'name': _nameController.text,
      'email': _emailController.text,
      'password': _passwordController.text,
      'password_confirmation': _confirmPasswordController.text,
      'phone_number': _phoneController.text,
      'location': _locationController.text,
      // لەوانەیە پێویست بکات 'otp': _otpController.text لێرە زیاد بکەیت ئەگەر APIـەکەت داوای بکات
    };

    try {
      final response = await _apiService.register(data);

      if (mounted) {
        if (response != null && response.containsKey('token')) {
          await Provider.of<AuthProvider>(context, listen: false).loginWithData(response);
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (c) => const MainScreen()),
            (route) => false,
          );
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = response?['message'] ?? 'هەڵەیەکی نەزانراو لە کاتی تۆمارکردندا ڕوویدا.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'هەڵەیەک لە کاتی تۆمارکردندا ڕوویدا: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // پاشبنەمایەکی سپی پاک
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0, // بێ سێبەر بۆ شێوازێکی مۆدێرن
        leading: _isVerificationStep
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
                onPressed: () {
                  setState(() {
                    _isVerificationStep = false; // گەڕانەوە بۆ فۆڕمی تۆمارکردن
                  });
                },
              )
            : null,
        title: Text(
          _isVerificationStep ? 'هەژمارەکەت پشتڕاست بکەرەوە' : 'دروستکردنی هەژماری نوێ',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0), // زیادکردنی بۆشایی ئاسۆیی
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1.0, 0.0), // جووڵە لە ڕاستەوە بۆ چەپ
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    );
                  },
                  child: _isVerificationStep
                      ? _buildVerificationForm()
                      : _buildRegistrationForm(),
                ),
              ),
            ),
    );
  }

  // ===== ویجێتی فۆڕمی تۆمارکردن =====
  Widget _buildRegistrationForm() {
    return Column(
      key: const ValueKey('registrationForm'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // دەقی بەخێرهاتن
        Text(
          'تۆماربە بۆ دەستپێکردن!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),

        _buildTextFormField(
          controller: _nameController,
          labelText: 'ناوی تەواو',
          icon: Icons.person_outline,
          validator: (v) => v!.isEmpty ? 'ناو نابێت بەتاڵ بێت' : null,
        ),
        const SizedBox(height: 20),
        _buildTextFormField(
          controller: _emailController,
          labelText: 'ئیمەیڵ',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (v) => v!.isEmpty || !v.contains('@') ? 'ئیمەیڵێکی دروست بنووسە' : null,
        ),
        const SizedBox(height: 20),
        _buildTextFormField(
          controller: _phoneController,
          labelText: 'ژمارەی تەلەفۆن',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (v) => v!.isEmpty ? 'ژمارەی تەلەفۆن نابێت بەتاڵ بێت' : null,
        ),
        const SizedBox(height: 20),
        _buildTextFormField(
          controller: _locationController,
          labelText: 'ناونیشان (شار)',
          icon: Icons.location_city_outlined,
          validator: (v) => v!.isEmpty ? 'ناونیشان نابێت بەتاڵ بێت' : null,
        ),
        const SizedBox(height: 20),
        _buildTextFormField(
          controller: _passwordController,
          labelText: 'وشەی نهێنی',
          icon: Icons.lock_outline,
          obscureText: true,
          validator: (v) => v!.length < 8 ? 'وشەی نهێنی دەبێت لە ٨ پیت کەمتر نەبێت' : null,
        ),
        const SizedBox(height: 20),
        _buildTextFormField(
          controller: _confirmPasswordController,
          labelText: 'دووبارە نووسینەوەی وشەی نهێنی',
          icon: Icons.lock_outline,
          obscureText: true,
          validator: (v) => v != _passwordController.text ? 'وشەی نهێنیەکان وەک یەک نین' : null,
        ),
        const SizedBox(height: 40),
        _buildElevatedButton(
          onPressed: _sendOtp,
          text: 'ناردنی کۆدی پشتڕاستکردنەوە',
        ),
        const SizedBox(height: 20),
        _buildLoginLink(),
        if (_errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  // ===== ویجێتی فۆڕمی پشتڕاستکردنەوە =====
  Widget _buildVerificationForm() {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: TextStyle(
        fontSize: 22,
        color: Theme.of(context).primaryColor,
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2)),
      ),
    );

    return Column(
      key: const ValueKey('verificationForm'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'کۆدی پشتڕاستکردنەوە بنووسە',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Text(
          'کۆدێکی ٦ ژمارەیی بۆ ژمارە تەلەفۆنەکەت نێردرا:',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.black54,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          _phoneController.text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 32),
        Center(
          child: Pinput(
            length: 6,
            controller: _otpController,
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: defaultPinTheme.copyWith(
              decoration: defaultPinTheme.decoration!.copyWith(
                border: Border.all(color: Theme.of(context).primaryColor, width: 2),
              ),
            ),
            submittedPinTheme: defaultPinTheme.copyWith(
              decoration: defaultPinTheme.decoration!.copyWith(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                border: Border.all(color: Theme.of(context).primaryColor),
              ),
            ),
            errorPinTheme: defaultPinTheme.copyWith(
              decoration: defaultPinTheme.decoration!.copyWith(
                border: Border.all(color: Colors.redAccent),
              ),
            ),
            validator: (value) => value!.length != 6 ? 'کۆد دەبێت ٦ ژمارە بێت' : null,
            pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
            showCursor: true,
          ),
        ),
        const SizedBox(height: 32),
        _buildElevatedButton(
          onPressed: _submitRegistration,
          text: 'پشتڕاستکردنەوە و تۆمارکردن',
        ),
        if (_errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () {
            // TODO: لۆجیکی دووبارە ناردنەوەی OTP جێبەجێ بکە
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('...دووبارە ناردنەوەی کۆد')),
            );
          },
          child: Text(
            'دووبارە ناردنەوەی کۆد',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ===== ویجێتە دووبارە بەکارهێنراوەکان بۆ ستایلی پرۆفیشناڵ =====

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(color: Colors.black87), // ڕەنگی نووسینی ناو خانەکە
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.black54), // ڕەنگی ناونیشانی خانەکە
        prefixIcon: Icon(icon, color: Theme.of(context).primaryColor.withOpacity(0.7)), // ڕەنگی ئایکۆن
        filled: true,
        fillColor: Colors.grey[50], // پاشبنەمایەکی کاڵ بۆ خانەی نووسینەکان
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), // گۆشەی خڕ
          borderSide: BorderSide.none, // بێ چوارچێوە
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!), // چوارچێوەیەکی کاڵ
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2), // دیاریکردن لە کاتی فۆکەس
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
    );
  }

  Widget _buildElevatedButton({
    required VoidCallback onPressed,
    required String text,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).primaryColor, // بەکارهێنانی ڕەنگی سەرەکی بۆ دوگمەکان
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // هاوشێوەی گۆشەی خانەی نووسینەکان
        ),
        elevation: 5, // سێبەرێکی کاڵ بۆ قووڵی
        shadowColor: Theme.of(context).primaryColor.withOpacity(0.4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'پێشتر هەژمارت هەبووە؟',
          style: TextStyle(color: Colors.black54),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (c) => const LoginScreen()),
            );
          },
          child: Text(
            'لێرە بچۆ ژوورەوە',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}