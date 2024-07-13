import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_native_image/flutter_native_image.dart';

class FirebaseServices {
  final FirebaseStorage _firebaseStorage =
      FirebaseStorage.instanceFor(bucket: 'gs://chattingapp-e2f20.appspot.com');

  // UPLOAD IMAGE TO FIRESTORAGE AND RETURN DOWNLOAD URL
  Future<String?> uploadPhoto(File file) async {
    try {
      String filename = DateTime.now().millisecondsSinceEpoch.toString();
      File compressedFile = await compressImage(file);

      UploadTask uploadTask =
          _firebaseStorage.ref('images/$filename').putFile(compressedFile);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // COMPRESS PHOTO
  Future<File> compressImage(File file) async {
    int targetSize = 300 * 1024; // 300 KB
    int quality = 90;
    File compressedFile = file;

    while (await compressedFile.length() > targetSize && quality > 10) {
      compressedFile = await FlutterNativeImage.compressImage(
        file.path,
        quality: quality,
        targetWidth: 1080,
        targetHeight: 1920,
      );
      quality -= 10;
    }

    print('Original size: ${file.lengthSync()}');
    print('Compressed size: ${compressedFile.lengthSync()}');
    return compressedFile;
  }
}
