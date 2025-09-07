import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kurdpoint/screens/main_screen.dart';
import 'package:provider/provider.dart';
import 'register_screen.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final success = await Provider.of<AuthProvider>(context, listen: false)
          .login(_emailController.text, _passwordController.text);

      if (success && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (Route<dynamic> route) => false,
        );
      } else if (mounted) {
        setState(() {
          _errorMessage = 'ئیمەیڵ یان وشەی نهێنی هەڵەیە.';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'هەڵەیەک ڕوویدا، تکایە دووبارە هەوڵبدەرەوە.';
        });
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min, // Prevent overflow
                children: [
                  // 🔹 Logo Glassmorphism
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.white.withOpacity(0.6),
                          child: Icon(
                            Icons.lock_rounded,
                            size: 50,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // 🔹 Welcome Text
                  Text(
                    'بەخێربێیتەوە!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'بچۆ ژوورەوە بۆ بەردەوامبوون',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 🔹 Email
                  _buildTextField(
                    controller: _emailController,
                    labelText: 'ئیمەیڵ',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                        (value == null || !value.contains('@'))
                            ? 'تکایە ئیمەیڵێکی دروست بنووسە'
                            : null,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),

                  // 🔹 Password
                  _buildTextField(
                    controller: _passwordController,
                    labelText: 'وشەی نهێنی',
                    icon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (value) =>
                        (value == null || value.isEmpty)
                            ? 'وشەی نهێنی بنووسە'
                            : null,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        'وشەی نهێنیت لەبیرکردووە؟',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 🔹 Error Message
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

                  // 🔹 Login Button
                  _isLoading
                      ? _buildLoadingButton()
                      : _buildLoginButton(context),

                  const SizedBox(height: 30),

                  _buildDividerWithText(isDark: isDark),
                  const SizedBox(height: 24),

                  // 🔹 Social Buttons
                  _buildSocialRow(isDark: isDark),
                  const SizedBox(height: 36),

                  // 🔹 Register Link
                  _buildRegisterLink(isDark: isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    required bool isDark,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon,
            color: isDark ? Colors.grey[400] : Colors.grey[600]),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
    );
  }

  Widget _buildLoginButton(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: EdgeInsets.zero,
          ).copyWith(
            backgroundColor: WidgetStateProperty.resolveWith((_) =>
                null), // clear so gradient works
            elevation: WidgetStateProperty.all(0),
          ),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF4CAF50)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'چوونەژوورەوە',
                style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
        ),
      );

  Widget _buildLoadingButton() => Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF4CAF50)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
      );

  Widget _buildDividerWithText({required bool isDark}) => Row(
        children: [
          const Expanded(child: Divider(thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'یان',
              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey),
            ),
          ),
          const Expanded(child: Divider(thickness: 1)),
        ],
      );

  Widget _buildSocialRow({required bool isDark}) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSocialButton(Icons.apple, isDark),
          const SizedBox(width: 16),
          _buildSocialButton(Icons.g_mobiledata, isDark),
          const SizedBox(width: 16),
          _buildSocialButton(Icons.facebook, isDark),
        ],
      );

  Widget _buildSocialButton(IconData icon, bool isDark) => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          boxShadow: isDark
              ? null
              : [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Icon(icon, size: 28, color: isDark ? Colors.white : Colors.black),
      );

  Widget _buildRegisterLink({required bool isDark}) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('هەژمارت نییە؟',
              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey)),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const RegisterScreen()),
              );
            },
            child: Text('یەکێک دروست بکە',
                style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
        ],
      );
}
 