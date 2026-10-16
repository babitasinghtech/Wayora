import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:login_learn_new_app/core/constants/app_color.dart';

import 'package:login_learn_new_app/widgets/common.dart';
import 'package:login_learn_new_app/services/db.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _text = TextEditingController();
  Uint8List? _bytes;
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final x = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1000, // keep the picture small: it is stored inside Firestore
        imageQuality: 60,
      );
      if (x == null) return;
      final b = await x.readAsBytes();
      setState(() => _bytes = b);
    } catch (e) {
      showToast('Could not pick image', '$e', ok: false);
    }
  }

  Future<void> _publish() async {
    final text = _text.text.trim();
    if (text.isEmpty && _bytes == null) {
      showToast('Nothing to post', 'Write something or add a photo.', ok: false);
      return;
    }
    String? b64;
    if (_bytes != null) {
      b64 = base64Encode(_bytes!);
      if (b64.length > 900 * 1024) {
        showToast('Photo too large', 'Please pick a smaller photo.', ok: false);
        return;
      }
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await Db.addPost(text: text, imageB64: b64);
      Get.back();
      showToast('Posted', 'Your post is live.');
    } catch (e) {
      showToast('Could not post', '$e', ok: false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = Db.nameOf(Db.me);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColor.kInk),
          onPressed: Get.back,
        ),
        title: const Text(
          'New post',
          style: TextStyle(color: AppColor.kInk, fontWeight: FontWeight.w800),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: SizedBox(
                height: 38,
                child: ElevatedButton(
                  onPressed: _busy ? null : _publish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.kPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                        )
                      : const Text('Post', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    InitialAvatar(name: name, radius: 22),
                    const SizedBox(width: 12),
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppColor.kInk,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _text,
                  maxLines: null,
                  minLines: 4,
                  maxLength: 600,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 17),
                  decoration: const InputDecoration(
                    hintText: 'Share your travel moment...',
                    border: InputBorder.none,
                  ),
                ),
                if (_bytes != null)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.memory(_bytes!, width: double.infinity, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: GestureDetector(
                          onTap: () => setState(() => _bytes = null),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.06))),
              ),
              child: Row(
                children: [
                  _sourceButton(Icons.photo_library_rounded, 'Gallery', () => _pick(ImageSource.gallery)),
                  const SizedBox(width: 12),
                  _sourceButton(Icons.photo_camera_rounded, 'Camera', () => _pick(ImageSource.camera)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sourceButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColor.kPrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColor.kPrimary, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: AppColor.kDark, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
