import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

class PermissionService {

  static Future<bool> requestPhotosPermission() async {
    PermissionStatus status;

    if (Platform.isAndroid) {

      status = await Permission.photos.request();
    } else if (Platform.isIOS) {
      status = await Permission.photos.request();
    } else {
      // สำหรับแพลตฟอร์มอื่นๆ
      return false;
    }

    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      // ถ้าผู้ใช้เลือก "Don't ask again"
      openAppSettings();
      return false;
    } else {
      // ผู้ใช้ปฏิเสธ
      return false;
    }
  }

  static Future<bool> requestCameraPermission() async {
    PermissionStatus status = await Permission.camera.request();
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
      return false;
    } else {
      return false;
    }
  }
}