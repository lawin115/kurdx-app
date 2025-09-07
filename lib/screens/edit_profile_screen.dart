import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kurdpoint/models/user_model.dart';
import 'package:kurdpoint/providers/auth_provider.dart';
import 'package:kurdpoint/providers/theme_provider.dart';
import 'package:kurdpoint/screens/become_vendor_screen.dart';
import 'package:kurdpoint/screens/login_screen.dart';
import 'package:kurdpoint/screens/manage_drivers_screen.dart';
import 'package:kurdpoint/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Modern Professional Color Palette (matching profile_screen.dart)
const Color kModernPrimary = Color(0xFF6366F1); // Modern Purple
const Color kModernSecondary = Color(0xFFEC4899); // Hot Pink
const Color kModernAccent = Color(0xFF06B6D4); // Cyan
const Color kModernWarning = Color(0xFFFF9A56); // Orange
const Color kModernError = Color(0xFFEF4444); // Red
const Color kModernGradientStart = Color(0xFF667EEA); // Purple Blue
const Color kModernGradientEnd = Color(0xFF764BA2); // Deep Purple
const Color kModernPink = Color(0xFFF093FB); // Light Pink
const Color kModernBlue = Color(0xFF4FACFE); // Light Blue
const Color kModernOrange = Color(0xFFFF9A56); // Orange
const Color kModernGreen = Color(0xFF00F5A0); // Neon Green
const Color kModernDark = Color(0xFF1A1A2E); // Dark Background
const Color kModernSurface = Color(0xFFF8FAFC); // Light Surface
const Color kModernCard = Color(0xFFFFFFFF); // White Cards
const Color kModernTextPrimary = Color(0xFF0F172A); // Dark Text
const Color kModernTextSecondary = Color(0xFF64748B); // Gray Text
const Color kModernTextLight = Color(0xFF94A3B8); // Light Gray
const Color kModernBorder = Color(0xFFE2E8F0); // Subtle Border

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  late TextEditingController _termsController;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  late TextEditingController _aboutController;

  File? _imageFile;
  bool _isLoading = false;
  User? _currentUser;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentUser = Provider.of<AuthProvider>(context, listen: false).user;
    _termsController =
        TextEditingController(text: _currentUser?.vendorTerms ?? '');
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: _currentUser?.name ?? '');
    _emailController = TextEditingController(text: _currentUser?.email ?? '');
    _phoneController =
        TextEditingController(text: _currentUser?.phoneNumber ?? '');
    _locationController =
        TextEditingController(text: _currentUser?.location ?? '');
    _aboutController = TextEditingController(text: _currentUser?.about ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
      );
      if (pickedFile != null) {
        setState(() => _imageFile = File(pickedFile.path));
      }
    } on PlatformException catch (e) {
      _showErrorSnackbar('Failed to pick image: ${e.message}');
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final updatedUser = await _apiService.updateUserProfile(
        token: auth.token!,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        location: _locationController.text.trim(),
        about: _aboutController.text.trim(),
        vendorTerms: _termsController.text.trim(),
        photoFile: _imageFile,
      );

      if (updatedUser != null) {
        auth.updateUser(updatedUser);
        if (mounted) {
          Navigator.of(context).pop();
          _showSuccessSnackbar('Profile updated successfully');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Failed to update profile: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ================== UI Widgets ==================

  Widget _buildProfileImage() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min, // Prevent overflow
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    kModernPink,
                    kModernOrange,
                    kModernAccent,
                    kModernGreen,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: kModernPrimary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(4),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(4),
                child: ClipOval(
                  child: _imageFile != null
                      ? Image.file(
                          _imageFile!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      : ((_currentUser?.profilePhotoUrl != null && _currentUser!.profilePhotoUrl!.isNotEmpty && !_currentUser!.profilePhotoUrl!.contains('null'))
                          ? CachedNetworkImage(
                              imageUrl: _currentUser!.profilePhotoUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: (context, url) => Container(
                                color: kModernSurface,
                                child: Icon(
                                  Icons.person,
                                  size: 40,
                                  color: kModernTextSecondary,
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: kModernSurface,
                                child: Icon(
                                  Icons.person,
                                  size: 40,
                                  color: kModernTextSecondary,
                                ),
                              ),
                            )
                          : Container(
                              color: kModernSurface,
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: kModernTextSecondary,
                              ),
                            )),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kModernAccent, kModernBlue],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: kModernAccent.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Change Photo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLines = 1,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kModernTextPrimary,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: kModernBorder.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Enter $label',
                hintStyle: TextStyle(
                  color: kModernTextLight,
                  fontSize: 14,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kModernPrimary.withOpacity(0.1), kModernAccent.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: kModernPrimary,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: kModernBorder,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: kModernPrimary,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: kModernError,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              keyboardType: keyboardType,
              maxLines: maxLines,
              style: TextStyle(
                fontSize: 14,
                color: kModernTextPrimary,
                fontWeight: FontWeight.w500,
              ),
              validator: (value) {
                if (required && (value == null || value.trim().isEmpty)) {
                  return 'This field is required';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kModernPrimary.withOpacity(0.1),
            kModernAccent.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: kModernBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kModernPrimary, kModernAccent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kModernTextPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 56,
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [kModernPrimary, kModernSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: kModernPrimary.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'SAVING...',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.save_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SAVE PROFILE',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildThemeSwitcher() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: kModernBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: kModernBorder.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kModernOrange.withOpacity(0.1), kModernPink.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.palette_outlined,
                  color: kModernOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Theme Preference',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kModernTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildThemeOption(
                  'Light',
                  Icons.light_mode_outlined,
                  themeProvider.themeMode == ThemeMode.light,
                  () => themeProvider.setThemeMode(ThemeMode.light),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildThemeOption(
                  'Dark',
                  Icons.dark_mode_outlined,
                  themeProvider.themeMode == ThemeMode.dark,
                  () => themeProvider.setThemeMode(ThemeMode.dark),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildThemeOption(
                  'System',
                  Icons.settings_outlined,
                  themeProvider.themeMode == ThemeMode.system,
                  () => themeProvider.setThemeMode(ThemeMode.system),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [kModernPrimary, kModernAccent],
                )
              : null,
          color: isSelected ? null : kModernSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : kModernBorder,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : kModernTextSecondary,
              size: 20,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : kModernTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBecomeVendorTile() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kModernGreen.withOpacity(0.1), kModernAccent.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: kModernGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (ctx) => const BecomeVendorScreen()),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kModernGreen, kModernAccent],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: kModernGreen.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.storefront_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Become a Vendor',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: kModernTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Start selling your products',
                        style: TextStyle(
                          fontSize: 12,
                          color: kModernTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: kModernTextSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

Widget _buildLogoutButton() {
  return Container(
    width: double.infinity,
    height: 56,
    margin: const EdgeInsets.only(top: 16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: LinearGradient(
        colors: [kModernError, const Color(0xFFDC2626)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: kModernError.withOpacity(0.4),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: ElevatedButton.icon(
      onPressed: _handleLogout,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      icon: const Icon(
        Icons.logout_rounded,
        color: Colors.white,
        size: 20,
      ),
      label: const Text(
        "LOG OUT",
        style: TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: Colors.white,
          fontSize: 16,
        ),
      ),
    ),
  );
}


  // ================== Snackbar ==================
  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.green,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.redAccent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ================== Logout Logic ==================
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Log Out"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () {
                Provider.of<AuthProvider>(context, listen: false).logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (ctx) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: const Text("Log Out",
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kModernSurface,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                kModernGradientStart,
                kModernGradientEnd,
              ],
            ),
          ),
          child: SafeArea(
            child: AppBar(
              title: Text(
                "Edit Profile",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
              centerTitle: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.save_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    onPressed: _isLoading ? null : _submitForm,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileImage(),
              const SizedBox(height: 24),
              _buildSectionHeader("Basic Information"),
              _buildFormField(
                  controller: _nameController,
                  label: "Full Name",
                  icon: Icons.person_outline),
              _buildFormField(
                  controller: _emailController,
                  label: "Email",
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress),
              _buildSectionHeader("Contact Information"),
              _buildFormField(
                  controller: _phoneController,
                  label: "Phone Number",
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  required: false),
              _buildFormField(
                  controller: _locationController,
                  label: "Location",
                  icon: Icons.location_on_outlined,
                  required: false),
              _buildSectionHeader("About You"),
              _buildFormField(
                  controller: _aboutController,
                  label: "Bio",
                  icon: Icons.info_outline,
                  maxLines: 3,
                  required: false),
              _buildThemeSwitcher(),
              if (_currentUser?.role == "vendor") ...[
                _buildSectionHeader("Vendor Settings"),
                _buildFormField(
                    controller: _termsController,
                    label: "Vendor Terms",
                    icon: Icons.description_outlined,
                    maxLines: 3,
                    required: false),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: kModernBorder,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kModernBorder.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kModernBlue.withOpacity(0.1), kModernAccent.withOpacity(0.1)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.drive_eta_outlined,
                        color: kModernBlue,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      "Manage Drivers",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: kModernTextPrimary,
                      ),
                    ),
                    subtitle: Text(
                      "Manage your delivery drivers",
                      style: TextStyle(
                        fontSize: 12,
                        color: kModernTextSecondary,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: kModernTextSecondary,
                    ),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (ctx) => const ManageDriversScreen()));
                    },
                  ),
                )
              ],
              if (_currentUser?.role == "user") _buildBecomeVendorTile(),
              _buildSaveButton(),
              const SizedBox(height: 20),
              _buildLogoutButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
