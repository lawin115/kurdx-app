import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
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

enum PostStep { selectPhoto, editPhoto, addCaption, sharePost }

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _captionController = TextEditingController();
  final PageController _pageController = PageController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  PostStep _currentStep = PostStep.selectPhoto;
  List<File> _selectedImages = [];
  int _currentImageIndex = 0;
  bool _isLoading = false;
  bool _canPost = false;

  // Photo editing variables
  double _brightness = 0.0;
  double _contrast = 1.0;
  double _saturation = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _captionController.addListener(_validatePost);
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

  void _validatePost() {
    final hasImages = _selectedImages.isNotEmpty;
    final hasCaption = _captionController.text.trim().isNotEmpty;
    
    setState(() {
      _canPost = hasImages && hasCaption;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _captionController.dispose();
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
                  _currentStep == PostStep.selectPhoto ? Icons.close : Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              onPressed: _handleBackAction,
            ),
            actions: [
              if (_currentStep != PostStep.selectPhoto)
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

  String _getStepTitle() {
    switch (_currentStep) {
      case PostStep.selectPhoto:
        return "Select Photos";
      case PostStep.editPhoto:
        return "Edit Photo";
      case PostStep.addCaption:
        return "Add Caption";
      case PostStep.sharePost:
        return "Share Post";
    }
  }

  String _getNextButtonText() {
    switch (_currentStep) {
      case PostStep.selectPhoto:
        return "Next";
      case PostStep.editPhoto:
        return "Next";
      case PostStep.addCaption:
        return "Share";
      case PostStep.sharePost:
        return "Done";
    }
  }

  void _handleBackAction() {
    if (_currentStep == PostStep.selectPhoto) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        switch (_currentStep) {
          case PostStep.editPhoto:
            _currentStep = PostStep.selectPhoto;
            break;
          case PostStep.addCaption:
            _currentStep = PostStep.editPhoto;
            break;
          case PostStep.sharePost:
            _currentStep = PostStep.addCaption;
            break;
          case PostStep.selectPhoto:
            break;
        }
      });
    }
  }

  void _handleNextAction() {
    switch (_currentStep) {
      case PostStep.selectPhoto:
        if (_selectedImages.isNotEmpty) {
          setState(() {
            _currentStep = PostStep.editPhoto;
          });
        }
        break;
      case PostStep.editPhoto:
        setState(() {
          _currentStep = PostStep.addCaption;
        });
        break;
      case PostStep.addCaption:
        if (_canPost) {
          _sharePost();
        }
        break;
      case PostStep.sharePost:
        Navigator.of(context).pop();
        break;
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
            "Sharing your post...",
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
      case PostStep.selectPhoto:
        return _buildSelectPhotoStep();
      case PostStep.editPhoto:
        return _buildEditPhotoStep();
      case PostStep.addCaption:
        return _buildAddCaptionStep();
      case PostStep.sharePost:
        return _buildSharePostStep();
    }
  }

  Widget _buildEditPhotoStep() {
    if (_selectedImages.isEmpty) return Container();
    
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
              child: ColorFiltered(
                colorFilter: ColorFilter.matrix([
                  _contrast, 0, 0, 0, _brightness * 255,
                  0, _contrast, 0, 0, _brightness * 255,
                  0, 0, _contrast, 0, _brightness * 255,
                  0, 0, 0, 1, 0,
                ]),
                child: Image.file(
                  _selectedImages[_currentImageIndex],
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildPhotoEditControls(),
        if (_selectedImages.length > 1) ...[
          const SizedBox(height: 16),
          _buildImageSelector(),
        ],
      ],
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
        itemCount: _selectedImages.length,
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
                  _selectedImages[index],
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddCaptionStep() {
    return Column(
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
            child: _selectedImages.isNotEmpty
                ? Image.file(
                    _selectedImages[0],
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
        // Caption input
        Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
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
                        Icons.edit_outlined,
                        size: 20,
                        color: kModernPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Write a caption",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: kModernTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: TextFormField(
                  controller: _captionController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: "What's on your mind?",
                    hintStyle: TextStyle(
                      color: kModernTextLight,
                      fontSize: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: kModernSurface,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    color: kModernTextPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Share button
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: _canPost
                ? LinearGradient(
                    colors: [kModernPrimary, kModernSecondary],
                  )
                : LinearGradient(
                    colors: [
                      kModernTextLight.withOpacity(0.3),
                      kModernTextLight.withOpacity(0.2),
                    ],
                  ),
            boxShadow: _canPost
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
            onPressed: _canPost ? () => _handleNextAction() : null,
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
                  Icons.share_outlined,
                  color: _canPost ? Colors.white : kModernTextLight,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "Share Post",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: _canPost ? Colors.white : kModernTextLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
            "Post Shared!",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: kModernTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Your post has been shared successfully",
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

  Widget _buildSelectPhotoStep() {
    return Column(
      children: [
        Expanded(
          child: _selectedImages.isEmpty
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
      itemCount: _selectedImages.length + 1,
      itemBuilder: (context, index) {
        if (index == _selectedImages.length) {
          return _buildAddMoreButton();
        }
        return _buildPhotoTile(_selectedImages[index], index);
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
                    "Main",
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
                onTap: () => _removeImage(index),
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
            () => _pickImages(source: ImageSource.gallery),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            "Camera",
            Icons.camera_alt_outlined,
            [kModernOrange, kModernPink],
            () => _pickImages(source: ImageSource.camera),
          ),
        ),
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(width: 16),
          _buildIconActionButton(
            Icons.arrow_forward,
            [kModernGreen, kModernAccent],
            () => _handleNextAction(),
          ),
        ],
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

  Future<void> _pickImages({ImageSource? source}) async {
    try {
      if (source != null) {
        // Single image from camera or specific source
        final pickedFile = await _picker.pickImage(
          source: source,
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
        );
        
        if (pickedFile != null) {
          setState(() {
            _selectedImages.add(File(pickedFile.path));
          });
          _validatePost();
          HapticFeedback.lightImpact();
        }
      } else {
        // Multiple images from gallery
        final pickedFiles = await _picker.pickMultiImage(
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
        );
        
        if (pickedFiles.isNotEmpty) {
          setState(() {
            _selectedImages.addAll(pickedFiles.map((xFile) => File(xFile.path)));
          });
          _validatePost();
          HapticFeedback.lightImpact();
        }
      }
    } catch (e) {
      _showErrorSnackbar('Error picking images: ${e.toString()}');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      if (_currentImageIndex >= _selectedImages.length) {
        _currentImageIndex = _selectedImages.length - 1;
      }
      if (_currentImageIndex < 0) {
        _currentImageIndex = 0;
      }
    });
    _validatePost();
    HapticFeedback.lightImpact();
  }

  Future<void> _sharePost() async {
    if (!_canPost) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) {
        _showErrorSnackbar('Authentication error. Please login again');
        return;
      }

      // Call the API service to create the post
      final result = await _apiService.createPost(
        token: token,
        caption: _captionController.text.trim(),
        images: _selectedImages,
      );

      if (result != null && mounted) {
        setState(() {
          _currentStep = PostStep.sharePost;
          _isLoading = false;
        });
        _showSuccessSnackbar('Post shared successfully! 🎉');
        HapticFeedback.heavyImpact();
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          _showErrorSnackbar('Failed to share post. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackbar('Failed to share post: ${e.toString()}');
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
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
}