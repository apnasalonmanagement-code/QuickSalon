/// Optional Cloudinary configuration for service images.
///
/// Leave the values empty if Cloudinary is not configured yet. The service
/// management screens will continue to work without image upload.
class CloudinaryConfig {
  CloudinaryConfig._();

  static const String cloudName = 'ouxaq8ht';
  static const String uploadPreset = 'apna_salon';
  static const String folder = 'apna_salon/services';

  static bool get isConfigured =>
      cloudName.trim().isNotEmpty &&
      uploadPreset.trim().isNotEmpty;
}
