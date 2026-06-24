// ------------------------------------------------------------------------------
// File: image_helper.dart
// Purpose: Unified Media Processing Engine.
// Rationale: Centralizes the image acquisition and transformation pipeline, 
//   orchestrating picking (image_picker) and precision cropping (image_cropper) 
//   to ensure data uniformity across product and profile modules.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // Styling: Platform UI themes
import 'package:image_picker/image_picker.dart'; // Hardware: Media capture
import 'package:image_cropper/image_cropper.dart'; // Logic: Spatial transformation
import 'package:frontend/core/theme/app_colors.dart'; // Styling: Design system tokens

class ImageHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Captures or selects an image then triggers the precision cropping interface.
  /// 
  /// [source] determines whether to use the Camera or Gallery.
  /// [isProfile] if true, enforces a circular/square crop suited for avatars.
  static Future<XFile?> pickAndCropImage({
    required BuildContext context,
    required ImageSource source,
    bool isProfile = false,
  }) async {
    // Phase 1: Raw Acquisition
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 1200, // Balanced resolution for Cloudinary storage
      maxHeight: 1200,
      imageQuality: 85, // Optimized compression
    );

    if (pickedFile == null) return null;
    if (!context.mounted) return null;

    // Phase 2: Spatial Normalization (Cropping)
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0), // Force square aspect for products/profiles
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Edit Image',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: 'Edit Image',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
        WebUiSettings(
          context: context,
          presentStyle: WebPresentStyle.dialog,
          customDialogBuilder: (cropper, initCropper, crop, rotate, scale) {
            return _WebCropperDialog(
              cropper: cropper,
              initCropper: initCropper,
              crop: crop,
            );
          },
        ),
      ],
    );

    if (croppedFile == null) return null;

    return XFile(croppedFile.path);
  }
}

/// Logic: Premium Web Cropping Interface.
/// Rationale: Provides a high-end, branded experience for browser-based 
///   media processing, ensuring UI consistency with the mobile application.
class _WebCropperDialog extends StatefulWidget {
  final Widget cropper;
  final VoidCallback initCropper;
  final Future<String?> Function() crop;

  const _WebCropperDialog({
    required this.cropper,
    required this.initCropper,
    required this.crop,
  });

  @override
  State<_WebCropperDialog> createState() => _WebCropperDialogState();
}

class _WebCropperDialogState extends State<_WebCropperDialog> {
  @override
  void initState() {
    super.initState();
    // Trace: Initialize the underlying CropperJS engine.
    widget.initCropper();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: size.width > 600 ? 520 : size.width * 0.9,
        height: size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header: Minimalist branding (No Divider)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                children: [
                  Text(
                    'Crop Image',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Content: The interactive cropping canvas
            Expanded(
              child: widget.cropper,
            ),

            // Actions: Branded button suite
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final result = await widget.crop();
                      if (context.mounted) {
                        Navigator.of(context).pop(result);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Crop',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
