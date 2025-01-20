import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dartz/dartz.dart' as dartz;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:movie_reviews/widgets/bottom_sheet_take_image.dart';
import 'package:movie_reviews/widgets/custom_loading.dart';

import '../api_service.dart';

class AddEditReviewScreen extends StatefulWidget {
  final String username;
  final Map<String, dynamic>? review;

  const AddEditReviewScreen({super.key, required this.username, this.review});

  @override
  State<AddEditReviewScreen> createState() => _AddEditReviewScreenState();
}

class _AddEditReviewScreenState extends State<AddEditReviewScreen> {
  final _titleController = TextEditingController();
  final _ratingController = TextEditingController();
  final _commentController = TextEditingController();
  final _apiService = ApiService();
  File? _dataImage;
  String? _base64Image;

  @override
  void initState() {
    super.initState();
    if (widget.review != null) {
      _titleController.text = widget.review!['title'];
      _ratingController.text = widget.review!['rating'].toString();
      _commentController.text = widget.review!['comment'];

      if (widget.review!['comment'] != "") {
        _base64Image = widget.review!['image'];
      }
    }
  }

  void _saveReview() async {
    // Show loading
    CustomLoading.show();

    final title = _titleController.text.trim();
    final rating = int.tryParse(_ratingController.text) ?? 0;
    final comment = _commentController.text.trim();

    if (_dataImage != null) {
      await compressImage(_dataImage!.readAsBytesSync()).then((compressBytes) {
        _base64Image = base64Encode(compressBytes);
      });
    }

    // Validasi input
    if (title.isEmpty ||
        rating < 1 ||
        rating > 10 ||
        comment.isEmpty ||
        _base64Image == null) {
      // Dismiss loading
      CustomLoading.dismiss();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Data tidak valid. Judul, komentar, rating (1-10) dan image harus diisi.',
          ),
        ),
      );
      return;
    }

    bool success;
    if (widget.review == null) {
      // Tambah review baru
      success = await _apiService.addReview(
        widget.username,
        title,
        rating,
        comment,
        _base64Image,
      );
    } else {
      // Edit review
      success = await _apiService.updateReview(
        widget.username,
        widget.review!['_id'],
        title,
        rating,
        comment,
        _base64Image,
      );
    }

    if (success) {
      // Dismiss loading
      CustomLoading.dismiss();

      Navigator.pop(context, true); // Berhasil, kembali ke layar sebelumnya
    } else {
      // Dismiss loading
      CustomLoading.dismiss();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan review')),
      );
    }
  }

  void _setFileImage({
    required ImageSource source,
  }) async {
    final fileImage = await pickImage(source: source);

    fileImage.fold(
      (errorMsg) {
        if (errorMsg != "Cancel Pick Image") {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg)),
          );
        }
      },
      (data) async {
        if (data != null) {
          _dataImage = data;

          setState(() {
            _base64Image = base64Encode(data.readAsBytesSync());
          });
        }
      },
    );
  }

  Future<dartz.Either<String, File?>> pickImage({
    required ImageSource source,
  }) async {
    try {
      final image = await ImagePicker().pickImage(
        source: source,
        imageQuality: 30,
      );

      if (image == null) {
        return const dartz.Left("Cancel Pick Image");
      }
      final File fileImage = File(image.path);

      return dartz.Right(fileImage);
    } on PlatformException catch (e) {
      log('Failed to pick image: $e');
      return dartz.Left("Failed to pick image: $e");
    }
  }

  Future<List<int>> compressImage(
    List<int> imageBytes, {
    int targetWidth = 500,
    int quality = 85,
  }) async {
    // Decode the image from the byte list
    final image = img.decodeImage(Uint8List.fromList(imageBytes));

    if (image == null) {
      throw Exception("Failed to decode image.");
    }

    // Calculate the aspect ratio and target height to maintain the aspect ratio
    final aspectRatio = image.width / image.height;
    final targetHeight = (targetWidth / aspectRatio).round();

    // Resize the image while maintaining the aspect ratio
    final resizedImage = img.copyResize(
      image,
      width: targetWidth,
      height: targetHeight,
    );

    // Compress the image by encoding it to a lower quality JPEG
    final compressedImageBytes = img.encodeJpg(resizedImage, quality: quality);

    return compressedImageBytes;
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.review != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditMode ? 'Edit Review' : 'Tambah Review')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Judul Film'),
              readOnly: isEditMode, // Nonaktifkan input jika dalam mode edit
            ),
            TextField(
              controller: _ratingController,
              decoration: const InputDecoration(labelText: 'Rating (1-10)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(labelText: 'Komentar'),
            ),
            const SizedBox(
              height: 20.0,
            ),
            Builder(builder: (context) {
              if (_base64Image != null) {
                return InkWell(
                  onTap: () {
                    BottomSheetTakeImage.show(
                      context: context,
                      title: "Upload Image",
                      onFromCamera: () {
                        _setFileImage(source: ImageSource.camera);
                        Navigator.pop(context);
                      },
                      onFromFolder: () {
                        _setFileImage(source: ImageSource.gallery);
                        Navigator.pop(context);
                      },
                    );
                  },
                  child: Image.memory(
                    base64Decode(_base64Image ?? ""),
                    fit: BoxFit.cover,
                  ),
                );
              }
              return ElevatedButton(
                onPressed: () {
                  BottomSheetTakeImage.show(
                    context: context,
                    title: "Upload Image",
                    onFromCamera: () {
                      _setFileImage(source: ImageSource.camera);
                      Navigator.pop(context);
                    },
                    onFromFolder: () {
                      _setFileImage(source: ImageSource.gallery);
                      Navigator.pop(context);
                    },
                  );
                },
                child: const Text("Upload Image"),
              );
            }),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveReview,
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
