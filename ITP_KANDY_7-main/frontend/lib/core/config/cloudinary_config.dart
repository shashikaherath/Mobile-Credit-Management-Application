// ------------------------------------------------------------------------------
// File: cloudinary_config.dart
// Purpose: Multi-Media Infrastructure Configuration.
// Rationale: Defines the credentials and presets for decentralized image 
//   storage and optimization. Offloads binary binary data from the primary 
//   backend to a specialized CDN, ensuring high-speed global delivery.
// ------------------------------------------------------------------------------

class CloudinaryConfig {
  /* 
   * Logic: Brand Namespace Identifier.
   * Rationale: Secure global bucket for storing application media assets.
   */
  static const String cloudName = 'danu31w3w';

  /*
   * Logic: Secure Unsigned Upload Preset.
   * Rationale: Enables direct-to-cloud uploads from the mobile handset 
   *   without exposing high-privilege private API vectors.
   */
  static const String uploadPreset = 'products_preset';
}

