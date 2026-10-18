import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:login_learn_new_app/controllers/add_post_controller.dart';
import 'package:login_learn_new_app/core/constants/app_color.dart';
import 'package:login_learn_new_app/widgets/common.dart';

/// "New post" screen. UI only - logic lives in [AddPostController].
class AddPostScreen extends StatelessWidget {
  const AddPostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AddPostController>(
      init: AddPostController(),
      builder: (c) => Scaffold(
        backgroundColor: Colors.white,
        appBar: _appBar(c),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      InitialAvatar(name: c.authorName, radius: 22),
                      const SizedBox(width: 12),
                      Text(
                        c.authorName,
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
                    controller: c.text,
                    maxLines: null,
                    minLines: 4,
                    maxLength: AddPostController.maxChars,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(fontSize: 17),
                    decoration: const InputDecoration(
                      hintText: 'Share your travel moment...',
                      border: InputBorder.none,
                    ),
                  ),
                  if (c.imageBytes != null) _preview(c),
                ],
              ),
            ),
            _bottomBar(c),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar(AddPostController c) {
    return AppBar(
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
            // re-evaluates "can post" while the user types
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: c.text,
              builder: (context, value, child) => SizedBox(
                height: 38,
                child: ElevatedButton(
                  onPressed: (c.isBusy || !c.canPost)
                      ? null
                      : () async {
                          FocusScope.of(context).unfocus();
                          if (await c.publish()) Get.back();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.kPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(19),
                    ),
                  ),
                  child: c.isBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Post',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _preview(AddPostController c) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.memory(
            c.imageBytes!,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: GestureDetector(
            onTap: c.removeImage,
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
    );
  }

  Widget _bottomBar(AddPostController c) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
          ),
        ),
        child: Row(
          children: [
            _sourceButton(
              Icons.photo_library_rounded,
              'Gallery',
              () => c.pickImage(ImageSource.gallery),
            ),
            const SizedBox(width: 12),
            _sourceButton(
              Icons.photo_camera_rounded,
              'Camera',
              () => c.pickImage(ImageSource.camera),
            ),
          ],
        ),
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
            Text(
              label,
              style: const TextStyle(
                color: AppColor.kDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
