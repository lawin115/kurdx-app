import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/category_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'main_screen.dart';

// Instagram-style post creation steps
enum PostStep { selectPhotos, editPhotos, addDetails, sharePost }

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

class AddAuctionScreen extends StatefulWidget {
  const AddAuctionScreen({super.key});

  @override
  State<AddAuctionScreen> createState() => _AddAuctionScreenState();
}

class _AddAuctionScreenState extends State<AddAuctionScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final PageController _pageController = PageController();
  
  late AnimationController _animationController;
  late AnimationController _stepAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  final FocusNode _titleFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();
  final FocusNode _priceFocus = FocusNode();

  // Instagram-style step management
  PostStep _currentStep = PostStep.selectPhotos;
  int _currentImageIndex = 0;
  
  // Photo editing variables
  double _brightness = 0.0;
  double _contrast = 1.0;
  double _saturation = 1.0;
  double _blur = 0.0;
  
  List<Category> _categories = [];
  int? _selectedCategoryId;
  List<File> _imageFiles = [];
  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchCategories();
    
    // Add listeners to validate form
    _titleController.addListener(_validateForm);
    _descriptionController.addListener(_validateForm);
    _priceController.addListener(_validateForm);
  }
  
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _stepAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _stepAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
    _stepAnimationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _stepAnimationController.dispose();
    _pageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _endTimeController.dispose();
    _titleFocus.dispose();
    _descriptionFocus.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  void _validateForm() {
    final isValid = _titleController.text.isNotEmpty &&
        _descriptionController.text.isNotEmpty &&
        _priceController.text.isNotEmpty &&
        _selectedCategoryId != null &&
        _selectedDate != null &&
        _imageFiles.isNotEmpty;
    
    if (isValid != _isFormValid) {
      setState(() => _isFormValid = isValid);
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kModernPrimary, kModernAccent],
              ),
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: kModernPrimary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            "Creating your auction...",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kModernTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "This might take a few moments",
            style: TextStyle(
              fontSize: 14,
              color: kModernTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case PostStep.selectPhotos:
        return "Select Photos";
      case PostStep.editPhotos:
        return "Edit Photos";
      case PostStep.addDetails:
        return "Add Details";
      case PostStep.sharePost:
        return "Create Auction";
    }
  }

  String _getNextButtonText() {
    switch (_currentStep) {
      case PostStep.selectPhotos:
        return "Next";
      case PostStep.editPhotos:
        return "Next";
      case PostStep.addDetails:
        return "Create";
      case PostStep.sharePost:
        return "Done";
    }
  }

  void _handleBackAction() {
    if (_currentStep == PostStep.selectPhotos) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        switch (_currentStep) {
          case PostStep.editPhotos:
            _currentStep = PostStep.selectPhotos;
            break;
          case PostStep.addDetails:
            _currentStep = PostStep.editPhotos;
            break;
          case PostStep.sharePost:
            _currentStep = PostStep.addDetails;
            break;
          case PostStep.selectPhotos:
            break;
        }
      });
      _stepAnimationController.reset();
      _stepAnimationController.forward();
    }
  }

  void _handleNextAction() {
    switch (_currentStep) {
      case PostStep.selectPhotos:
        if (_imageFiles.isNotEmpty) {
          setState(() => _currentStep = PostStep.editPhotos);
          _stepAnimationController.reset();
          _stepAnimationController.forward();
        }
        break;
      case PostStep.editPhotos:
        setState(() => _currentStep = PostStep.addDetails);
        _stepAnimationController.reset();
        _stepAnimationController.forward();
        break;
      case PostStep.addDetails:
        if (_isFormValid) {
          _submitForm();
        }
        break;
      case PostStep.sharePost:
        Navigator.of(context).pop();
        break;
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final cats = await _apiService.getCategories();
      if (mounted && cats != null) {
        setState(() => _categories = cats);
        _validateForm();
      }
    } catch (e) {
      _showSnackBar("Failed to load categories: ${e.toString()}", isError: true);
    }
  }

  Future<void> _pickImages() async {
    try {
      final pickedFiles = await ImagePicker().pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _imageFiles.addAll(pickedFiles.map((xFile) => File(xFile.path)));
        });
        _validateForm();
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      _showSnackBar("Error picking images: ${e.toString()}", isError: true);
    }
  }

  Future<void> _pickDateTime() async {
    try {
      final date = await showDatePicker(
        context: context,
        initialDate: DateTime.now().add(const Duration(days: 1)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: const Color(0xFF2196F3),
                surface: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E1E1E)
                    : Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );
      
      if (date == null) return;

      if (!mounted) return;
      
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: const Color(0xFF2196F3),
              ),
            ),
            child: child!,
          );
        },
      );
      
      if (time == null) return;

      setState(() {
        _selectedDate = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        _endTimeController.text = DateFormat('MMM dd, yyyy • HH:mm').format(_selectedDate!);
      });
      _validateForm();
      HapticFeedback.selectionClick();
    } catch (e) {
      _showSnackBar("Error selecting date: ${e.toString()}", isError: true);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 4 : 3),
        content: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isError 
                  ? [kModernError, const Color(0xFFDC2626)]
                  : [kModernGreen, kModernAccent],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (isError ? kModernError : kModernGreen).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  msg,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar("Please complete all required fields", isError: true);
      return;
    }

    // Validate price
    final price = double.tryParse(_priceController.text);
    if (price == null || price <= 0) {
      _showSnackBar("Please enter a valid price", isError: true);
      return;
    }

    // Validate end time
    if (_selectedDate?.isBefore(DateTime.now().add(const Duration(hours: 1))) == true) {
      _showSnackBar("End time must be at least 1 hour from now", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      setState(() => _isLoading = false);
      _showSnackBar("Authentication error. Please login again", isError: true);
      return;
    }

    final data = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'starting_price': price.toString(),
      'category_id': _selectedCategoryId.toString(),
      'end_time': _selectedDate!.toIso8601String(),
    };

    try {
      final created = await _apiService.createAuction(
        token: token,
        data: data,
        images: _imageFiles,
      );
      
      if (created != null && mounted) {
        HapticFeedback.heavyImpact();
        setState(() {
          _currentStep = PostStep.sharePost;
          _isLoading = false;
        });
        _stepAnimationController.reset();
        _stepAnimationController.forward();
        
        // Navigate back after showing success for 2 seconds
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainScreen()),
            (r) => false,
          );
        }
      } else {
        _showSnackBar("Failed to create auction. Please try again", isError: true);
      }
    } catch (e) {
      _showSnackBar("Network error: ${e.toString()}", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _removeImage(File file) {
    setState(() => _imageFiles.remove(file));
    _validateForm();
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kModernSurface,
      extendBodyBehindAppBar: true,
      appBar: _buildInstagramAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _isLoading ? _buildLoadingState() : _buildStepContent(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildInstagramAppBar() {
    return PreferredSize(
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
            backgroundColor: Colors.transparent,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            title: Text(
              _getStepTitle(),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _currentStep == PostStep.selectPhotos ? Icons.close : Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              onPressed: _handleBackAction,
            ),
            actions: [
              if (_currentStep != PostStep.selectPhotos)
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: TextButton(
                    onPressed: _handleNextAction,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getNextButtonText(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kModernPrimary, kModernAccent],
              ),
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: kModernPrimary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            "Creating your auction...",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kModernTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "This might take a few moments",
            style: TextStyle(
              fontSize: 14,
              color: kModernTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
      child: Column(
        children: [
          _buildStepIndicator(),
          const SizedBox(height: 24),
          Expanded(
            child: _buildCurrentStepWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: PostStep.values.map((step) {
          final index = PostStep.values.indexOf(step);
          final currentIndex = PostStep.values.indexOf(_currentStep);
          final isActive = index <= currentIndex;
          final isCurrent = index == currentIndex;
          
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? LinearGradient(
                            colors: [kModernPrimary, kModernAccent],
                          )
                        : null,
                    color: isActive ? null : kModernBorder,
                    shape: BoxShape.circle,
                    border: isCurrent
                        ? Border.all(
                            color: kModernPrimary,
                            width: 3,
                          )
                        : null,
                  ),
                  child: Center(
                    child: isActive
                        ? Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          )
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: kModernTextSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
                if (index < PostStep.values.length - 1)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: isActive
                            ? LinearGradient(
                                colors: [kModernPrimary, kModernAccent],
                              )
                            : null,
                        color: isActive ? null : kModernBorder,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCurrentStepWidget() {
    switch (_currentStep) {
      case PostStep.selectPhotos:
        return _buildSelectPhotosStep();
      case PostStep.editPhotos:
        return _buildEditPhotosStep();
      case PostStep.addDetails:
        return _buildAddDetailsStep();
      case PostStep.sharePost:
        return _buildSharePostStep();
    }
  }

  Widget _buildModernSectionTitle(String title, IconData icon) {
    return Container(
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kModernPrimary, kModernAccent],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: kModernTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernImagePicker() {
    return Container(
      constraints: const BoxConstraints(minHeight: 200),
      child: _imageFiles.isEmpty ? _buildModernEmptyImageState() : _buildModernImageGrid(),
    );
  }

  Widget _buildModernEmptyImageState() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              kModernPrimary.withOpacity(0.05),
              kModernAccent.withOpacity(0.05),
            ],
          ),
          border: Border.all(
            color: kModernBorder,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: kModernPrimary.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kModernPrimary, kModernAccent],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kModernPrimary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.add_photo_alternate_outlined,
                size: 36,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Add Photos",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: kModernTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Tap to select multiple images",
              style: TextStyle(
                fontSize: 14,
                color: kModernTextSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kModernOrange.withOpacity(0.1), kModernPink.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "First image will be the cover",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: kModernOrange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernImageGrid() {
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemCount: _imageFiles.length + 1,
          itemBuilder: (context, index) {
            if (index == _imageFiles.length) {
              return _buildModernAddMoreButton();
            }
            return _buildModernImageTile(_imageFiles[index], index);
          },
        ),
      ],
    );
  }

  Widget _buildModernAddMoreButton() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              kModernAccent.withOpacity(0.1),
              kModernPrimary.withOpacity(0.1),
            ],
          ),
          border: Border.all(
            color: kModernBorder,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kModernAccent, kModernPrimary],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.add,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Add More",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: kModernTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernImageTile(File file, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kModernPrimary.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    kModernPrimary.withOpacity(0.1),
                    kModernAccent.withOpacity(0.1),
                  ],
                ),
              ),
              child: Image.file(
                file,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (index == 0)
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kModernPrimary, kModernAccent],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: kModernPrimary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  "Cover",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _removeImage(file),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kModernError, const Color(0xFFDC2626)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kModernError.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    FocusNode? focusNode,
    String? Function(String?)? validator,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    String? prefix,
    void Function(String)? onSubmitted,
  }) {
    return Column(
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
            focusNode: focusNode,
            validator: validator,
            keyboardType: keyboard,
            maxLines: maxLines,
            textInputAction: maxLines > 5 ? TextInputAction.newline : TextInputAction.next,
            onFieldSubmitted: onSubmitted,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: kModernTextPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
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
              prefixText: prefix,
              prefixStyle: TextStyle(
                color: kModernTextPrimary,
                fontWeight: FontWeight.w600,
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
          ),
        ),
      ],
    );
  }

  Widget _buildModernDateTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            "End Time",
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
            controller: _endTimeController,
            readOnly: true,
            onTap: _pickDateTime,
            validator: (v) => v?.isEmpty == true ? "Please select an end time" : null,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: kModernTextPrimary,
            ),
            decoration: InputDecoration(
              hintText: "Select when the auction ends",
              hintStyle: TextStyle(
                color: kModernTextLight,
                fontSize: 14,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kModernOrange.withOpacity(0.1), kModernPink.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.schedule_outlined,
                  size: 20,
                  color: kModernOrange,
                ),
              ),
              suffixIcon: Container(
                margin: const EdgeInsets.all(12),
                child: Icon(
                  Icons.arrow_drop_down,
                  color: kModernTextSecondary,
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
                  color: kModernOrange,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            "Category",
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
          child: DropdownButtonFormField<int>(
            value: _selectedCategoryId,
            items: _categories.map((category) {
              return DropdownMenuItem(
                value: category.id,
                child: Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: kModernTextPrimary,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedCategoryId = value);
              _validateForm();
              HapticFeedback.selectionClick();
            },
            validator: (v) => v == null ? "Please select a category" : null,
            decoration: InputDecoration(
              hintText: "Choose a category",
              hintStyle: TextStyle(
                color: kModernTextLight,
                fontSize: 14,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kModernGreen.withOpacity(0.1), kModernAccent.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.category_outlined,
                  size: 20,
                  color: kModernGreen,
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
                  color: kModernGreen,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(16),
            icon: Container(
              margin: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.arrow_drop_down,
                color: kModernTextSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernSubmitButton() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: _isFormValid
            ? LinearGradient(
                colors: [kModernPrimary, kModernSecondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  kModernTextLight.withOpacity(0.3),
                  kModernTextLight.withOpacity(0.2),
                ],
              ),
        boxShadow: _isFormValid
            ? [
                BoxShadow(
                  color: kModernPrimary.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: _isFormValid ? _submitForm : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rocket_launch_outlined,
              color: _isFormValid ? Colors.white : kModernTextLight,
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              "Create Auction",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: 0.5,
                color: _isFormValid ? Colors.white : kModernTextLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectPhotosStep() {
    return Column(
      children: [
        Expanded(
          child: _imageFiles.isEmpty
              ? _buildEmptyPhotoState()
              : _buildSelectedPhotosGrid(),
        ),
        const SizedBox(height: 20),
        _buildPhotoActionButtons(),
      ],
    );
  }

  Widget _buildEmptyPhotoState() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            kModernPrimary.withOpacity(0.05),
            kModernAccent.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: kModernBorder,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kModernPrimary, kModernAccent],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: kModernPrimary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.photo_camera_outlined,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Select Photos",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: kModernTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Choose photos from your gallery or camera",
            style: TextStyle(
              fontSize: 16,
              color: kModernTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedPhotosGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: _imageFiles.length + 1,
      itemBuilder: (context, index) {
        if (index == _imageFiles.length) {
          return _buildAddMoreButton();
        }
        return _buildPhotoTile(_imageFiles[index], index);
      },
    );
  }

  Widget _buildAddMoreButton() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              kModernAccent.withOpacity(0.1),
              kModernPrimary.withOpacity(0.1),
            ],
          ),
          border: Border.all(
            color: kModernBorder,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kModernAccent, kModernPrimary],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.add,
                size: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Add More",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kModernTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoTile(File image, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentImageIndex = index;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: index == _currentImageIndex ? kModernPrimary : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: kModernPrimary.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                image,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            if (index == 0)
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kModernPrimary, kModernAccent],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Cover",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _removeImage(image),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kModernError, const Color(0xFFDC2626)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            "Gallery",
            Icons.photo_library_outlined,
            [kModernPrimary, kModernAccent],
            () => _pickImages(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            "Camera",
            Icons.camera_alt_outlined,
            [kModernOrange, kModernPink],
            () => _pickImagesFromCamera(),
          ),
        ),
        if (_imageFiles.isNotEmpty) ...[
          const SizedBox(width: 16),
          _buildIconActionButton(
            Icons.arrow_forward,
            [kModernGreen, kModernAccent],
            () => _handleNextAction(),
          ),
        ],
        const SizedBox(height: 160),
      ],
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    List<Color> gradientColors,
    VoidCallback onPressed,
  ) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(
          icon,
          color: Colors.white,
          size: 18,
        ),
        label: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildIconActionButton(
    IconData icon,
    List<Color> gradientColors,
    VoidCallback onPressed,
  ) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildEditPhotosStep() {
    if (_imageFiles.isEmpty) return Container();
    
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _buildFilteredImage(_imageFiles[_currentImageIndex]),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildPhotoEditControls(),
        if (_imageFiles.length > 1) ...[
          const SizedBox(height: 16),
          _buildImageSelector(),
        ],
      ],
    );
  }

  Widget _buildFilteredImage(File image) {
    return ColorFiltered(
      colorFilter: ColorFilter.matrix([
        _contrast + _saturation, 0, 0, 0, _brightness * 255,
        0, _contrast + _saturation, 0, 0, _brightness * 255,
        0, 0, _contrast + _saturation, 0, _brightness * 255,
        0, 0, 0, 1, 0,
      ]),
      child: Image.file(
        image,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildPhotoEditControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSlider(
            "Brightness",
            Icons.brightness_6_outlined,
            _brightness,
            -0.5,
            0.5,
            (value) => setState(() => _brightness = value),
          ),
          const SizedBox(height: 16),
          _buildSlider(
            "Contrast",
            Icons.contrast_outlined,
            _contrast,
            0.5,
            2.0,
            (value) => setState(() => _contrast = value),
          ),
          const SizedBox(height: 16),
          _buildSlider(
            "Saturation",
            Icons.color_lens_outlined,
            _saturation,
            0.0,
            2.0,
            (value) => setState(() => _saturation = value),
          ),
          const SizedBox(height: 16),
          _buildSlider(
            "Blur",
            Icons.blur_on_outlined,
            _blur,
            0.0,
            10.0,
            (value) => setState(() => _blur = value),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(
    String label,
    IconData icon,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        Container(
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
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: kModernTextPrimary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: kModernPrimary,
              inactiveTrackColor: kModernBorder,
              thumbColor: kModernPrimary,
              overlayColor: kModernPrimary.withOpacity(0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSelector() {
    return Container(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _imageFiles.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _currentImageIndex = index;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              width: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: index == _currentImageIndex ? kModernPrimary : Colors.transparent,
                  width: 3,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _imageFiles[index],
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddDetailsStep() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview of main image
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _imageFiles.isNotEmpty
                    ? Image.file(
                        _imageFiles[0],
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: kModernSurface,
                        child: Icon(
                          Icons.image,
                          size: 48,
                          color: kModernTextSecondary,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            
            _buildModernTextField(
              controller: _titleController,
              focusNode: _titleFocus,
              label: "Auction Title",
              hint: "Enter a catchy title for your auction",
              icon: Icons.title_outlined,
              validator: (v) => v?.isEmpty == true ? "Title is required" : null,
              onSubmitted: (_) => _descriptionFocus.requestFocus(),
            ),
            
            const SizedBox(height: 20),
            _buildModernTextField(
              controller: _descriptionController,
              focusNode: _descriptionFocus,
              label: "Description",
              hint: "Describe your item in detail",
              icon: Icons.description_outlined,
              maxLines: 3,
              validator: (v) => v?.isEmpty == true ? "Description is required" : null,
              onSubmitted: (_) => _priceFocus.requestFocus(),
            ),
            
            const SizedBox(height: 20),
            _buildModernTextField(
              controller: _priceController,
              focusNode: _priceFocus,
              label: "Starting Price",
              hint: "0.00",
              icon: Icons.attach_money_outlined,
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v?.isEmpty == true) return "Starting price is required";
                final price = double.tryParse(v!);
                if (price == null || price <= 0) return "Enter a valid price";
                return null;
              },
              prefix: "\$",
            ),
            
            const SizedBox(height: 20),
            _buildModernDateTimePicker(),
            
            const SizedBox(height: 20),
            _buildModernCategoryDropdown(),
            
            const SizedBox(height: 40),
            _buildCreateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: _isFormValid
            ? LinearGradient(
                colors: [kModernPrimary, kModernSecondary],
              )
            : LinearGradient(
                colors: [
                  kModernTextLight.withOpacity(0.3),
                  kModernTextLight.withOpacity(0.2),
                ],
              ),
        boxShadow: _isFormValid
            ? [
                BoxShadow(
                  color: kModernPrimary.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: _isFormValid ? () => _handleNextAction() : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rocket_launch_outlined,
              color: _isFormValid ? Colors.white : kModernTextLight,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              "Create Auction",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: _isFormValid ? Colors.white : kModernTextLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSharePostStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kModernGreen, kModernAccent],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: kModernGreen.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            "Auction Created!",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: kModernTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Your auction has been created successfully",
            style: TextStyle(
              fontSize: 16,
              color: kModernTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildActionButton(
            "Done",
            Icons.home_outlined,
            [kModernPrimary, kModernAccent],
            () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImagesFromCamera() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _imageFiles.add(File(pickedFile.path));
        });
        _validateForm();
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      _showSnackBar("Error taking photo: ${e.toString()}", isError: true);
    }
  }
}