import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageViewPage extends StatefulWidget {
  final File imageFile;
  final Map location;

  const ImageViewPage({
    super.key,
    required this.imageFile,
    required this.location,
  });

  @override
  State<ImageViewPage> createState() => _ImageViewPageState();
}

ScreenshotController screenshotController = ScreenshotController();
Uint8List? _imageFile;
String? time;
bool isLoading = false;

class _ImageViewPageState extends State<ImageViewPage> {
  @override
  void initState() {
    super.initState();
    time = '${DateTime.now()}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: widget.imageFile.existsSync()
              ? _renderBody()
              : const Text('No image selected.'),
        ),
      ),
    );
  }

  Widget _renderBody() {
    return Column(
      children: [_renderImage(), const SizedBox(height: 10), _renderButton()],
    );
  }

  Widget _renderImage() {
    return Screenshot(
      controller: screenshotController,
      child: Stack(
        children: [
          Image.file(widget.imageFile),
          Positioned(
            bottom: 16.0,
            left: 16.0,
            right: 16.0,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Absens',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    time ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        widget.location['lat'].toString(),
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        widget.location['long'].toString(),
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    widget.location['address'],
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> uploadData(Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance.collection('attendance').add(data);
      _showSnackBar('Data uploaded successfully', false);
    } catch (e) {
      _showSnackBar('Error uploading data: $e', true);
    }
  }

  Future<String> uploadImage(File image) async {
    try {
      String fileName = 'images/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageReference =
          FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageReference.putFile(image);
      await uploadTask.whenComplete(() => null);
      String downloadURL = await storageReference.getDownloadURL();
      return downloadURL;
    } catch (e) {
      _showSnackBar('Error uploading image: $e', true);
      return 'null';
    }
  }

  void _showSnackBar(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red : Colors.teal,
      ),
    );
  }

  void upload() async {
    try {
      setState(() {
        isLoading = true;
      });
      // Capture screenshot
      Uint8List? image = await screenshotController.capture();

      if (image != null) {
        setState(() {
          _imageFile = image;
        });
        _showSnackBar('Image created', false);
      } else {
        _showSnackBar('Image capture failed.', true);
        return; // Exit if image capture failed
      }

      // Convert Uint8List to File
      final directory = await getTemporaryDirectory();
      final filePath = path.join(directory.path, 'screenshot.png');
      File imgFile = File(filePath);
      await imgFile.writeAsBytes(image);
      _showSnackBar('Image saved', false);

      // Upload image and get URL
      String imageUrl = await uploadImage(imgFile);
      _showSnackBar('Image uploaded', false);

      // Prepare data to upload
      Map<String, dynamic> tempData = {
        'position': {
          'lat': widget.location['lat'],
          'long': widget.location['long'],
          'address': widget.location['address'],
        },
        'time': DateTime.now(),
        'image': imageUrl,
      };

      // Upload data to Firestore
      await uploadData(tempData);
      setState(() {
        isLoading = false;
      });

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showSnackBar("Error during upload process: $e", true);
    }
  }

  Widget _renderButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          if (isLoading) const CircularProgressIndicator(),
          if (!isLoading)
            InkWell(
              onTap: () => upload(),
              child: Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  height: 50,
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                  child: const Text(
                    'Absen Sekarang',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  )),
            ),
        ],
      ),
    );
  }
}
