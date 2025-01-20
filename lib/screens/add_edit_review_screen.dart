import 'dart:convert';
import 'dart:developer';
import 'dart:io';


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/foundation.dart';

import '../api_service.dart';
import '../widgets/bottom_sheet_take_image.dart';
import '../widgets/custom_loading.dart';

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

  String? _base64Image;

  @override
  void initState() {
    super.initState();
    if (widget.review != null) {
      _titleController.text = widget.review!['title'];
      _ratingController.text = widget.review!['rating'].toString();
      _commentController.text = widget.review!['comment'];

      if (widget.review!['image'] != null) {
        _base64Image = widget.review!['image'];
      }
    }
  }

  Future<void> _saveReview() async {
    // Show loading
    CustomLoading.show();

    final title = _titleController.text.trim();
    final rating = int.tryParse(_ratingController.text) ?? 0;
    final comment = _commentController.text.trim();

    // Validate input
    if (title.isEmpty || rating < 1 || rating > 10 || comment.isEmpty || _base64Image == null) {
      CustomLoading.dismiss();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua data harus diisi dengan benar.')),
      );
      return;
    }

    bool success;
    if (widget.review == null) {
      // Add new review
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

    CustomLoading.dismiss();

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan review.')),
      );
    }
  }

  Future<void> _setFileImage({required ImageSource source}) async {
    try {
      final pickedImage = await ImagePicker().pickImage(source: source);
      if (pickedImage == null) return;

      if (kIsWeb) {
        // Untuk Web: Gunakan `readAsBytes` langsung dari XFile
        final imageBytes = await pickedImage.readAsBytes();
        setState(() {
          _base64Image = base64Encode(imageBytes);
        });
      } else {
        // Untuk Mobile: Kompres dan ubah ke Base64
        final file = File(pickedImage.path);
        final compressedFile = await _compressImage(file);

        if (compressedFile != null) {
          final compressedBytes = await compressedFile.readAsBytes();
          setState(() {
            _base64Image = base64Encode(compressedBytes);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kompresi gambar gagal.')),
          );
        }
      }
    } catch (e) {
      log('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<File?> _compressImage(File file) async {
    if (kIsWeb) {
      // Tidak perlu kompresi di Web
      return file;
    } else {
      final targetPath = file.path;
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 80,
        minWidth: 500,
        minHeight: 500,
      );
      return compressedFile;
    }
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
              readOnly: isEditMode,
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
            const SizedBox(height: 20),
            Builder(
              builder: (context) {
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
                      base64Decode(_base64Image!),
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
                },
            ),
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
