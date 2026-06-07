import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import '../core/api_service.dart';
import '../models/upload_models.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _areaCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _restaurantCtrl = TextEditingController();
  XFile? _image;

  bool _isUploading = false;
  bool _isProcessing = false;

  String? _error;

  @override
  void dispose() {
    _areaCtrl.dispose();
    _cityCtrl.dispose();
    _restaurantCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _image = picked;
        _error = null;
      });
    }
  }

  Future<void> _upload() async {
    final area = _areaCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    final restaurant = _restaurantCtrl.text.trim();

    if (_image == null) {
      setState(() => _error = 'Please select a menu image first.');
      return;
    }
    if (area.isEmpty || city.isEmpty) {
      setState(() => _error = 'Area Name and City are required.');
      return;
    }
    if (restaurant.isEmpty) {
      setState(() => _error = 'Restaurant Name is required.');
      return;
    }

    setState(() {
      _isUploading = true;
      _error = null;
    });

    try {
      final res = await ApiService().uploadMenu(
        imageFile: _image!,
        areaName: area,
        city: city,
        restaurantName: restaurant,
      );

      setState(() {
        _isUploading = false;
        _isProcessing = true;
      });

      _pollStatus(res.uploadId);
    } on ApiException catch (e) {
      setState(() {
        _isUploading = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _error = 'Failed to upload image. Check your connection.';
      });
    }
  }

  Future<void> _pollStatus(String uploadId) async {
    if (!mounted) return;
    try {
      final st = await ApiService().getUploadStatus(uploadId);
      setState(() {});

      if (st.isCompleted) {
        setState(() => _isProcessing = false);
        _showSuccess(st);
      } else if (st.isFailed) {
        setState(() {
          _isProcessing = false;
          _error = st.errorMessage ?? 'OCR Processing failed.';
        });
      } else {
        // Still processing, poll again in 2s
        await Future.delayed(const Duration(seconds: 2));
        _pollStatus(uploadId);
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _error = 'Lost connection while processing.';
      });
    }
  }

  void _showSuccess(UploadStatus st) {
    final itemCount = st.itemsCount ?? 0;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                itemCount > 0
                    ? 'Menu processed! $itemCount items extracted.'
                    : 'Menu processed successfully!',
                style: GoogleFonts.outfit(),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.success,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
    setState(() {
      _image = null;
      _areaCtrl.clear();
      _cityCtrl.clear();
      _restaurantCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Menu'),
        backgroundColor: AppTheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImagePicker(),
            const SizedBox(height: 24),
            _buildForm(),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppTheme.error.withValues(alpha: 0.5)),
                ),
                child: Text(_error!,
                    style: GoogleFonts.outfit(color: AppTheme.error)),
              ).animate().fadeIn(),
            ],
            const SizedBox(height: 32),
            _buildSubmitButton(),
            if (_isProcessing) ...[
              const SizedBox(height: 32),
              _buildProcessingIndicator(),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: (_isUploading || _isProcessing) ? null : _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _image == null ? AppTheme.divider : AppTheme.primary,
            width: 2,
            style: BorderStyle.solid,
          ),
          image: _image != null
              ? DecorationImage(image: kIsWeb ? NetworkImage(_image!.path) : FileImage(File(_image!.path)) as ImageProvider, fit: BoxFit.cover)
              : null,
        ),
        child: _image == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryGlow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_a_photo_rounded,
                        color: AppTheme.primary, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text('Tap to select menu image',
                      style: GoogleFonts.outfit(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500)),
                ],
              )
            : Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.black45,
                ),
                child: const Center(
                  child:
                      Icon(Icons.edit_rounded, color: Colors.white, size: 32),
                ),
              ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location details',
          style: GoogleFonts.outfit(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _cityCtrl,
          enabled: !_isUploading && !_isProcessing,
          decoration: const InputDecoration(
            labelText: 'City *',
            hintText: 'e.g. Nagpur',
            prefixIcon: Icon(Icons.location_city_rounded),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _areaCtrl,
          enabled: !_isUploading && !_isProcessing,
          decoration: const InputDecoration(
            labelText: 'Area / Neighborhood *',
            hintText: 'e.g. Dharampeth',
            prefixIcon: Icon(Icons.map_rounded),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Restaurant info',
          style: GoogleFonts.outfit(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _restaurantCtrl,
          enabled: !_isUploading && !_isProcessing,
          decoration: const InputDecoration(
            labelText: 'Restaurant Name *',
            hintText: 'e.g. Pranil Da Dhaba',
            prefixIcon: Icon(Icons.storefront_rounded),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: (_isUploading || _isProcessing) ? null : _upload,
        icon: _isUploading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.cloud_upload_rounded),
        label: Text(_isUploading ? 'Uploading...' : 'Process Menu'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return Column(
      children: [
        const CircularProgressIndicator(color: AppTheme.accent),
        const SizedBox(height: 16),
        Text(
          'AI is extracting items from the image...',
          style: GoogleFonts.outfit(
              color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
        )
            .animate(onPlay: (c) => c.repeat())
            .fadeIn(duration: 500.ms)
            .then()
            .fadeOut(duration: 500.ms),
        const SizedBox(height: 8),
        Text(
          'This may take 10-30 seconds depending on menu size.',
          style:
              GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    ).animate().fadeIn();
  }
}
