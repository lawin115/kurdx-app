import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/category_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'main_screen.dart'; // Ensure MainScreen is imported if used for navigation

class AddAuctionScreen extends StatefulWidget {
  const AddAuctionScreen({super.key});

  @override
  State<AddAuctionScreen> createState() => _AddAuctionScreenState();
}

class _AddAuctionScreenState extends State<AddAuctionScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService(); // Use final for services

  // --- Controllers for form fields ---
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  // --- State variables ---
  List<Category> _categories = [];
  int? _selectedCategoryId;
  List<File> _imageFiles = []; // Changed to List<File> for multiple images
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  /// Fetches categories from the API.
  /// Handles potential errors and updates the UI if the widget is still mounted.
  Future<void> _fetchCategories() async {
    try {
      final cats = await _apiService.getCategories();
      if (mounted && cats != null) {
        setState(() => _categories = cats);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to load categories: ${e.toString()}',
            isError: true);
      }
    }
  }

  /// Allows picking multiple images from the gallery.
  /// Adds selected images to the `_imageFiles` list.
  Future<void> _pickImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _imageFiles.addAll(pickedFiles.map((xFile) => File(xFile.path)));
      });
    }
  }

  /// Shows a date and time picker to select the auction end time.
  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;

    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _endTimeController.text = DateFormat('yyyy-MM-dd HH:mm').format(_selectedDate!);
    });
  }

  /// Displays a SnackBar with a message.
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  /// Submits the auction form.
  /// Validates input, handles API calls, and navigates on success or shows errors.
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fill in all required fields.', isError: true);
      return;
    }
    if (_selectedCategoryId == null) {
      _showSnackBar('Please select a category.', isError: true);
      return;
    }
    if (_imageFiles.isEmpty) {
      _showSnackBar('Please select at least one image for the auction.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      setState(() => _isLoading = false);
      _showSnackBar('Authentication token not found. Please log in again.',
          isError: true);
      return;
    }

    final data = {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'starting_price': _priceController.text,
      'category_id': _selectedCategoryId.toString(),
      'end_time': _selectedDate!.toIso8601String(),
    };

    try {
      final createdAuction =
          await _apiService.createAuction(token: token, data: data, images: _imageFiles);

      if (mounted) {
        setState(() => _isLoading = false);
        if (createdAuction != null) {
          _showSnackBar('Auction successfully created!');
          // Navigate to MainScreen and clear previous routes
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const MainScreen(),
            ),
            (route) => false, // Clears all routes from the stack
          );
        } else {
          _showSnackBar('An error occurred while creating the auction.',
              isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('An unexpected error occurred: ${e.toString()}',
            isError: true);
      }
    }
  }

   @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
         title: Text(
    'Create New Auction',
    style: TextStyle(color: colorScheme.primary),
  ),
   
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.background,
        foregroundColor: colorScheme.onPrimary,
     
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Image Picker Section ---
                    _buildImagePicker(theme),
                    const SizedBox(height: 24),

                    // --- Auction Details Card ---
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                             ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // Title Field
                            TextFormField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                labelText: 'Item Title',
                                prefixIcon: Icon(Icons.title, color: colorScheme.primary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (v) => v!.isEmpty ? 'Title cannot be empty' : null,
                            ),
                            const SizedBox(height: 16),
                            
                            // Description Field
                            TextFormField(
                              controller: _descriptionController,
                              decoration: InputDecoration(
                                labelText: 'Description',
                                prefixIcon: Icon(Icons.description, color: colorScheme.primary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              maxLines: 4,
                              validator: (v) => v!.isEmpty ? 'Description cannot be empty' : null,
                            ),
                            const SizedBox(height: 16),
                            
                            // Price Field
                            TextFormField(
                              controller: _priceController,
                              decoration: InputDecoration(
                                labelText: 'Starting Price',
                                prefixIcon: Icon(Icons.attach_money, color: colorScheme.primary),
                                prefixText: '\$ ',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Price cannot be empty' : null,
                            ),
                            const SizedBox(height: 16),
                            
                            // End Time Field
                            TextFormField(
                              controller: _endTimeController,
                              decoration: InputDecoration(
                                labelText: 'End Time',
                                prefixIcon: Icon(Icons.calendar_today, color: colorScheme.primary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              readOnly: true,
                              onTap: _pickDateTime,
                              validator: (v) => v!.isEmpty ? 'End time cannot be empty' : null,
                            ),
                            const SizedBox(height: 16),
                            
                            // Category Dropdown
                            if (_categories.isNotEmpty)
                              DropdownButtonFormField<int>(
                                value: _selectedCategoryId,
                                items: _categories
                                    .map((cat) => DropdownMenuItem(
                                          value: cat.id,
                                          child: Text(cat.name),
                                        ))
                                    .toList(),
                                onChanged: (value) =>
                                    setState(() => _selectedCategoryId = value),
                                decoration: InputDecoration(
                                  labelText: 'Category',
                                  prefixIcon: Icon(Icons.category, color: colorScheme.primary),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                validator: (v) => v == null ? 'Please select a category' : null,
                                borderRadius: BorderRadius.circular(12),
                                elevation: 2,
                                isExpanded: true,
                              )
                            else
                              const Center(child: CircularProgressIndicator()),
                          ],
                        ),
                      ),
                      
                    ),
                      
                    const SizedBox(height: 24),
                    
                    // Submit Button
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Create Auction',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                      const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImagePicker(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Auction Images',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add at least one image (max 5)',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
        
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.5),
                ),
                     ),
                child: _imageFiles.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 50,
                            color: theme.colorScheme.primary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to add images',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Text(
                          '${_imageFiles.length} image(s) selected. Tap to add more.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
              ),
            ),
            if (_imageFiles.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imageFiles.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _imageFiles[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _imageFiles.removeAt(index);
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.errorContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: 20,
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}