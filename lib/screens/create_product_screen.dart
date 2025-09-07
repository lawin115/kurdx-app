import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:kurdpoint/models/category_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

// Modern Professional Color Palette (matching existing design system)
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

enum ProductStep { selectPhoto, productDetails, shareProduct }

class CreateProductScreen extends StatefulWidget {
  const CreateProductScreen({super.key});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  ProductStep _currentStep = ProductStep.selectPhoto;
  List<File> _selectedImages = [];
  List<Category> _categories = [];
  int? _selectedCategoryId;
  bool _isLoading = false;
  bool _canCreateProduct = false;
  bool _isSoldOut = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCategories();
    _setupControllers();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  void _setupControllers() {
    _titleController.addListener(_validateProduct);
    _descriptionController.addListener(_validateProduct);
    _priceController.addListener(_validateProduct);
    _quantityController.addListener(_validateProduct);
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _apiService.getCategories();
      if (categories != null && mounted) {
        setState(() {
          _categories = categories;
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  void _validateProduct() {
    final hasImages = _selectedImages.isNotEmpty;
    final hasTitle = _titleController.text.trim().isNotEmpty;
    final hasDescription = _descriptionController.text.trim().isNotEmpty;
    final hasPrice = _priceController.text.trim().isNotEmpty;
    final hasQuantity = _quantityController.text.trim().isNotEmpty;
    
    setState(() {
      _canCreateProduct = hasImages && hasTitle && hasDescription && hasPrice && hasQuantity;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kModernSurface,
      extendBodyBehindAppBar: true,
      appBar: _buildModernAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _isLoading ? _buildLoadingState() : _buildStepContent(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
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
                  _currentStep == ProductStep.selectPhoto ? Icons.close : Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              onPressed: _handleBackAction,
            ),
            actions: [
              if (_currentStep == ProductStep.selectPhoto && _selectedImages.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: TextButton(
                    onPressed: _handleNextAction,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kModernPrimary, kModernAccent],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: kModernPrimary.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
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
                )
              else if (_currentStep != ProductStep.selectPhoto)
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: TextButton(
                    onPressed: _handleNextAction,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _canCreateProduct || _currentStep == ProductStep.shareProduct
                            ? Colors.white.withOpacity(0.3)
                            : Colors.white.withOpacity(0.1),
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

  String _getStepTitle() {
    switch (_currentStep) {
      case ProductStep.selectPhoto:
        return 'Select Photos';
      case ProductStep.productDetails:
        return 'Product Details';
      case ProductStep.shareProduct:
        return 'Create Product';
    }
  }

  String _getNextButtonText() {
    switch (_currentStep) {
      case ProductStep.selectPhoto:
        return 'Next';
      case ProductStep.productDetails:
        return 'Create';
      case ProductStep.shareProduct:
        return 'Done';
    }
  }

  void _handleBackAction() {
    if (_currentStep == ProductStep.selectPhoto) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        switch (_currentStep) {
          case ProductStep.productDetails:
            _currentStep = ProductStep.selectPhoto;
            break;
          case ProductStep.shareProduct:
            _currentStep = ProductStep.productDetails;
            break;
          default:
            break;
        }
      });
    }
  }

  void _handleNextAction() {
    switch (_currentStep) {
      case ProductStep.selectPhoto:
        if (_selectedImages.isNotEmpty) {
          setState(() {
            _currentStep = ProductStep.productDetails;
          });
        }
        break;
      case ProductStep.productDetails:
        if (_canCreateProduct) {
          _createProduct();
        }
        break;
      case ProductStep.shareProduct:
        Navigator.of(context).pop();
        break;
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case ProductStep.selectPhoto:
        return _buildPhotoSelectionStep();
      case ProductStep.productDetails:
        return _buildProductDetailsStep();
      case ProductStep.shareProduct:
        return _buildSuccessStep();
    }
  }

  Widget _buildPhotoSelectionStep() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [Colors.white, Colors.white.withOpacity(0.8)],
            ).createShader(bounds),
            child: Text(
              'Add Product Photos',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontSize: 28,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select high-quality photos of your product',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 32),
          _selectedImages.isEmpty
              ? _buildEmptyPhotoState()
              : _buildSelectedPhotosPreview(),
          const SizedBox(height: 32),
          _buildPhotoSelectionButtons(),
          if (_selectedImages.isNotEmpty)
            const SizedBox(height: 20),
          if (_selectedImages.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    kModernCard.withOpacity(0.2),
                    kModernSurface.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _handleNextAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        'Next',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyPhotoState() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kModernCard.withOpacity(0.9),
              kModernSurface.withOpacity(0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kModernPrimary, kModernAccent],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_a_photo_outlined,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Add Product Photos',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: kModernTextPrimary,
                        fontSize: 22,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tap to select photos from gallery or camera',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: kModernTextSecondary,
                        fontSize: 16,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedPhotosPreview() {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kModernCard.withOpacity(0.9),
            kModernSurface.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                itemCount: _selectedImages.length,
                onPageChanged: (index) {
                  // Handle page change if needed
                },
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        _selectedImages[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
              if (_selectedImages.length > 1)
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kModernPrimary, kModernAccent],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: kModernPrimary.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      '${_selectedImages.length} Photos',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 20,
                left: 20,
                child: GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.add,
                      color: kModernPrimary,
                      size: 24,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: GestureDetector(
                  onTap: () => _removeImage(0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kModernError, const Color(0xFFDC2626)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: kModernError.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 24,
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

  Widget _buildPhotoSelectionButtons() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                kModernCard.withOpacity(0.2),
                kModernSurface.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _pickImages,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: Icon(
                    Icons.photo_library_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                  label: Text(
                    'Select from Gallery',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                kModernCard.withOpacity(0.2),
                kModernSurface.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _pickFromCamera,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                  label: Text(
                    'Take Photo',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 80),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [Colors.white, Colors.white.withOpacity(0.8)],
            ).createShader(bounds),
            child: Text(
              'Product Details',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontSize: 28,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Provide information about your product',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  kModernCard.withOpacity(0.9),
                  kModernSurface.withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        controller: _titleController,
                        label: 'Product Title',
                        hint: 'Enter product title',
                        maxLines: 1,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Description',
                        hint: 'Describe your product',
                        maxLines: 4,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _priceController,
                              label: 'Price (\$)',
                              hint: '0.00',
                              maxLines: 1,
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _quantityController,
                              label: 'Quantity',
                              hint: '1',
                              maxLines: 1,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildCategorySelector(),
                      const SizedBox(height: 20),
                      _buildSoldOutSwitch(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: kModernTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: kModernBorder.withOpacity(0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: kModernTextLight,
                fontSize: 16,
              ),
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            style: TextStyle(
              fontSize: 16,
              color: kModernTextPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: kModernTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: kModernBorder.withOpacity(0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ButtonTheme(
            alignedDropdown: true,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: _selectedCategoryId,
                hint: Text(
                  'Select category',
                  style: TextStyle(
                    color: kModernTextLight,
                    fontSize: 16,
                  ),
                ),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text(
                      'No category',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ..._categories.map((category) {
                    return DropdownMenuItem<int?>(
                      value: category.id,
                      child: Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 16,
                          color: kModernTextPrimary,
                        ),
                      ),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: kModernTextSecondary,
                ),
                dropdownColor: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSoldOutSwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: kModernBorder.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mark as Sold Out',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: kModernTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Product will not be available for purchase',
                  style: TextStyle(
                    fontSize: 14,
                    color: kModernTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: _isSoldOut,
            activeColor: kModernPrimary,
            activeTrackColor: kModernPrimary.withOpacity(0.3),
            inactiveThumbColor: kModernTextLight,
            inactiveTrackColor: kModernBorder,
            onChanged: (value) {
              setState(() {
                _isSoldOut = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kModernPrimary, kModernAccent],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: kModernPrimary.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 80,
            ),
          ),
          const SizedBox(height: 30),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [Colors.white, Colors.white.withOpacity(0.8)],
            ).createShader(bounds),
            child: Text(
              'Product Created!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontSize: 32,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your product has been successfully created and is now available in the marketplace.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 18,
                ),
          ),
          const SizedBox(height: 50),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  kModernCard.withOpacity(0.2),
                  kModernSurface.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      'Done',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 4,
            ),
          ),
          const SizedBox(height: 30),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [Colors.white, Colors.white.withOpacity(0.8)],
            ).createShader(bounds),
            child: Text(
              _currentStep == ProductStep.shareProduct
                  ? 'Creating your product...'
                  : 'Loading...',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImages() async {
    try {
      final pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (pickedFiles.isNotEmpty && mounted) {
        setState(() {
          _selectedImages.addAll(pickedFiles.map((xFile) => File(xFile.path)));
        });
        _validateProduct();
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      _showErrorSnackbar('Error picking images: ${e.toString()}');
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (pickedFile != null && mounted) {
        setState(() {
          _selectedImages.add(File(pickedFile.path));
        });
        _validateProduct();
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      _showErrorSnackbar('Error taking photo: ${e.toString()}');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
    _validateProduct();
    HapticFeedback.lightImpact();
  }

  Future<void> _createProduct() async {
    if (!_canCreateProduct) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) {
        _showErrorSnackbar('Authentication error. Please login again');
        return;
      }

      // Prepare product data
      final Map<String, String> productData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': _priceController.text.trim(),
        'quantity': _quantityController.text.trim(),
        if (_selectedCategoryId != null) 'category_id': _selectedCategoryId.toString(),
        'is_sold_out': _isSoldOut.toString(),
      };

      // Call the API service to create the product
      final result = await _apiService.createProduct(
        token: token,
        data: productData,
        images: _selectedImages,
      );

      if (result != null && mounted) {
        setState(() {
          _currentStep = ProductStep.shareProduct;
          _isLoading = false;
        });
        _showSuccessSnackbar('Product created successfully! 🎉');
        HapticFeedback.heavyImpact();
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          _showErrorSnackbar('Failed to create product. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackbar('Failed to create product: ${e.toString()}');
      }
    }
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        content: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kModernGreen, kModernAccent],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: kModernGreen.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        content: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kModernError, const Color(0xFFDC2626)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: kModernError.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
}