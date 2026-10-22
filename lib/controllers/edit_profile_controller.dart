import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:login_learn_new_app/controllers/auth_controller.dart';
import 'package:login_learn_new_app/widgets/common.dart';

/// Form state of the Edit-profile screen.
/// Editable: name, bio, photo.  NOT editable: login phone / email.
class EditProfileController extends GetxController {
  static const maxBio = 120;
  static const _maxPhotoBase64 = 300 * 1024;

  final AuthController auth = Get.find<AuthController>();
  late final TextEditingController name = TextEditingController(text: auth.displayName);
  late final TextEditingController bio = TextEditingController(text: auth.bio);

  Uint8List? newPhoto;
  bool removePhoto = false;
  bool isSaving = false;

  Uint8List? get photo => removePhoto ? null : (newPhoto ?? auth.photoBytes);

  bool get hasChanges =>
      name.text.trim() != auth.displayName ||
      bio.text.trim() != auth.bio.trim() ||
      newPhoto != null ||
      removePhoto;

  @override
  void onClose() {
    name.dispose();
    bio.dispose();
    super.onClose();
  }

  Future<void> pickPhoto(ImageSource source) async {
    try {
      final x = await ImagePicker().pickImage(
        source: source,
        maxWidth: 512,
        imageQuality: 70,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (base64Encode(bytes).length > _maxPhotoBase64) {
        showToast('Photo too large', 'Please pick a smaller photo.', ok: false);
        return;
      }
      newPhoto = bytes;
      removePhoto = false;
      update();
    } catch (e) {
      showToast('Could not pick photo', '$e', ok: false);
    }
  }

  void deletePhoto() {
    newPhoto = null;
    removePhoto = auth.photoBytes != null;
    update();
  }

  /// Returns true when saved.
  Future<bool> save() async {
    if (isSaving) return false;
    isSaving = true;
    update();
    try {
      return await auth.updateProfile(
        name: name.text,
        bio: bio.text,
        photo: newPhoto,
        removePhoto: removePhoto,
      );
    } finally {
      isSaving = false;
      update();
    }
  }
}
