import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import './main_screen.dart';
import 'login_screen.dart'; // دڵنیابە ئەمە بە دروستی ئیمپۆرت کراوە
import '../generated/l10n/app_localizations.dart';
import '../services/localization_service.dart';

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _isVerificationStep
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
                onPressed: () {
                  setState(() {
                    _isVerificationStep = false;
                  });
                },
              )
            : null,
        title: Text(
          _isVerificationStep 
              ? LocalizationService.getString(context, (l10n) => l10n.verifyAccount, 'Verify your account')
              : LocalizationService.getString(context, (l10n) => l10n.createNewAccount, 'Create new account'),
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
                padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
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

  Widget _buildRegistrationForm() {
    return Column(
      key: const ValueKey('registrationForm'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min, // Prevent overflow
      children: [
        Text(
          LocalizationService.getString(context, (l10n) => l10n.registerToStart, 'Sign up to get started!'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // --- Name Field ---
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: LocalizationService.getString(context, (l10n) => l10n.fullName, 'Full Name'),
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.person_outline),
          ),
          validator: (value) =>
              (value == null || value.isEmpty)
                  ? LocalizationService.getString(context, (l10n) => l10n.nameCannotBeEmpty, 'Name cannot be empty')
                  : null,
        ),
        const SizedBox(height: 16),

        // --- Email Field ---
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: LocalizationService.getString(context, (l10n) => l10n.email, 'Email'),
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.email_outlined),
          ),
          validator: (value) =>
              (value == null || !value.contains('@'))
                  ? LocalizationService.getString(context, (l10n) => l10n.enterValidEmail, 'Please enter a valid email')
                  : null,
        ),
        const SizedBox(height: 16),

        // --- Phone Field ---
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: LocalizationService.getString(context, (l10n) => l10n.phoneNumber, 'Phone Number'),
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.phone_outlined),
          ),
          validator: (value) =>
              (value == null || value.isEmpty)
                  ? LocalizationService.getString(context, (l10n) => l10n.phoneCannotBeEmpty, 'Phone number cannot be empty')
                  : null,
        ),
        const SizedBox(height: 16),

        // --- Location Field ---
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            labelText: LocalizationService.getString(context, (l10n) => l10n.address, 'Address (City)'),
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.location_on_outlined),
          ),
          validator: (value) =>
              (value == null || value.isEmpty)
                  ? LocalizationService.getString(context, (l10n) => l10n.addressCannotBeEmpty, 'Address cannot be empty')
                  : null,
        ),
        const SizedBox(height: 16),

        // --- Password Field ---
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: LocalizationService.getString(context, (l10n) => l10n.password, 'Password'),
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock_outline),
          ),
          validator: (value) =>
              (value == null || value.length < 8)
                  ? LocalizationService.getString(context, (l10n) => l10n.passwordMinLength, 'Password must be at least 8 characters')
                  : null,
        ),
        const SizedBox(height: 16),

        // --- Confirm Password Field ---
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: LocalizationService.getString(context, (l10n) => l10n.confirmPassword, 'Confirm Password'),
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock_outline),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return LocalizationService.getString(context, (l10n) => l10n.passwordMinLength, 'Password must be at least 8 characters');
            }
            if (value != _passwordController.text) {
              return LocalizationService.getString(context, (l10n) => l10n.passwordsDoNotMatch, 'Passwords do not match');
            }
            return null;
          },
        ),
        const SizedBox(height: 24),

        // --- Error Message ---
        if (_errorMessage.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        if (_errorMessage.isNotEmpty) const SizedBox(height: 16),

        // --- Register Button ---
        FilledButton(
          onPressed: _sendOtp,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            LocalizationService.getString(context, (l10n) => l10n.sendVerificationCode, 'Send Verification Code'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // --- Login Link ---
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              LocalizationService.getString(context, (l10n) => l10n.alreadyHaveAccount, 'Already have an account?'),
              style: const TextStyle(color: Colors.black54),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: Text(
                LocalizationService.getString(context, (l10n) => l10n.loginHere, 'Login here'),
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVerificationForm() {
    return Column(
      key: const ValueKey('verificationForm'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min, // Prevent overflow
      children: [
        Text(
          LocalizationService.getString(context, (l10n) => l10n.enterVerificationCode, 'Enter the verification code'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '${LocalizationService.getString(context, (l10n) => l10n.sixDigitCodeSent, 'A 6-digit code has been sent to your phone number:')} ${_phoneController.text}',
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Pinput(
          controller: _otpController,
          length: 6,
          defaultPinTheme: PinTheme(
            width: 56,
            height: 56,
            textStyle: const TextStyle(
              fontSize: 20,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[100]!,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
          ),
          focusedPinTheme: PinTheme(
            width: 56,
            height: 56,
            textStyle: const TextStyle(
              fontSize: 20,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[100]!,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return LocalizationService.getString(context, (l10n) => l10n.codeMustBeSixDigits, 'Code must be 6 digits');
            }
            if (value.length != 6) {
              return LocalizationService.getString(context, (l10n) => l10n.codeMustBeSixDigits, 'Code must be 6 digits');
            }
            return null;
          },
        ),
        const SizedBox(height: 32),
        if (_errorMessage.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        if (_errorMessage.isNotEmpty) const SizedBox(height: 16),
        FilledButton(
          onPressed: _submitRegistration,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            LocalizationService.getString(context, (l10n) => l10n.verifyAndRegister, 'Verify and Register'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _sendOtp,
          child: Text(
            LocalizationService.getString(context, (l10n) => l10n.resendCode, 'Resend code'),
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 16,
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