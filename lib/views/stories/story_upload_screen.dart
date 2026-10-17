import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';

class StoryUploadScreen extends StatefulWidget {
  const StoryUploadScreen({super.key});

  @override
  State<StoryUploadScreen> createState() => _StoryUploadScreenState();
}

class _StoryUploadScreenState extends State<StoryUploadScreen> {
  CameraController? cameraController;
  List<CameraDescription> cameras = [];

  bool flashOn = false;
  int selectedFilter = 0;

  final filters = ['Normal', 'Warm', 'Cool', 'Vintage', 'B&W'];

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  Future<void> initCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras.isEmpty) return;

      cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await cameraController!.initialize();

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  Future<void> toggleFlash() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }

    flashOn = !flashOn;

    await cameraController!.setFlashMode(
      flashOn ? FlashMode.torch : FlashMode.off,
    );

    if (mounted) setState(() {});
  }

  Future<void> flipCamera() async {
    if (cameras.length < 2) return;

    final currentLens = cameraController!.description.lensDirection;

    final nextCamera = cameras.firstWhere(
      (camera) => camera.lensDirection != currentLens,
      orElse: () => cameras.first,
    );

    await cameraController?.dispose();

    cameraController = CameraController(
      nextCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await cameraController!.initialize();

    if (mounted) setState(() {});
  }

  Future<void> capturePhoto() async {
    if (cameraController == null ||
        !cameraController!.value.isInitialized ||
        cameraController!.value.isTakingPicture) {
      return;
    }

    try {
      final photo = await cameraController!.takePicture();

      if (!mounted) return;

      // TODO: Open preview screen using photo.path.
      // Add Firebase upload after the user taps Share.
      Get.snackbar('Photo captured', photo.name);
    } catch (e) {
      Get.snackbar('Camera error', 'Photo capture nahi hui.');
    }
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // TOP APP BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const Text(
                    'Create Story',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: toggleFlash,
                    icon: Icon(
                      flashOn ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),

            // LIVE CAMERA PREVIEW
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child:
                    cameraController != null &&
                        cameraController!.value.isInitialized
                    ? SizedBox(
                        width: double.infinity,
                        child: CameraPreview(cameraController!),
                      )
                    : const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // GALLERY, CAPTURE AND FLIP
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // GALLERY
                  GestureDetector(
                    onTap: () {
                      Get.snackbar(
                        'Gallery',
                        'Yahan image_picker open karna hai.',
                      );
                    },
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white38),
                      ),
                      child: const Icon(
                        Icons.photo_library_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),

                  // CAPTURE BUTTON
                  GestureDetector(
                    onTap: capturePhoto,
                    child: Container(
                      width: 76,
                      height: 76,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),

                  // FLIP CAMERA
                  GestureDetector(
                    onTap: flipCamera,
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(
                        color: Colors.white12,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.flip_camera_android,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // FILTER CAROUSEL
            SizedBox(
              height: 76,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 18),
                itemBuilder: (context, index) {
                  final selected = selectedFilter == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedFilter = index;
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: [
                              Colors.grey.shade300,
                              Colors.orange.shade200,
                              Colors.blue.shade200,
                              Colors.brown.shade300,
                              Colors.grey.shade700,
                            ][index],
                            border: Border.all(
                              color: selected
                                  ? Colors.pinkAccent
                                  : Colors.white30,
                              width: selected ? 3 : 1,
                            ),
                          ),
                          child: Icon(
                            index == 0
                                ? Icons.circle_outlined
                                : Icons.auto_awesome,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          filters[index],
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.white70,
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
