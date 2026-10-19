import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:login_learn_new_app/services/db.dart';
import 'package:login_learn_new_app/widgets/common.dart';

class AddPostController extends GetxController {
  static const maxChars = 600;
  static const _maxBase64Length = 900 * 1024;

  final TextEditingController text = TextEditingController();
  Uint8List? imageBytes;
  bool isBusy = false;

  String get authorName => Db.nameOf(Db.me);
  bool get canPost => text.text.trim().isNotEmpty || imageBytes != null;

  @override
  void onClose() {
    text.dispose();
    super.onClose();
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final x = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1000,
        imageQuality: 60,
      );
      if (x == null) return;
      imageBytes = await x.readAsBytes();
      update();
    } catch (e) {
      showToast('Could not pick image', '$e', ok: false);
    }
  }

  void removeImage() {
    imageBytes = null;
    update();
  }

  /// Returns true when the post was published.
  Future<bool> publish() async {
    if (isBusy) return false;
    final body = text.text.trim();
    if (body.isEmpty && imageBytes == null) {
      showToast(
        'Nothing to post',
        'Write something or add a photo.',
        ok: false,
      );
      return false;
    }
    String? b64;
    if (imageBytes != null) {
      b64 = base64Encode(imageBytes!);
      if (b64.length > _maxBase64Length) {
        showToast('Photo too large', 'Please pick a smaller photo.', ok: false);
        return false;
      }
    }
    isBusy = true;
    update();
    try {
      await Db.addPost(text: body, imageB64: b64);
      showToast('Posted', 'Your post is live.');
      return true;
    } catch (e) {
      showToast('Could not post', '$e', ok: false);
      return false;
    } finally {
      isBusy = false;
      update();
    }
  }
}
