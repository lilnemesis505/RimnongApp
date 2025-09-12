import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

class PermissionService {
  /// ขอสิทธิ์การเข้าถึง Photos/Storage จากผู้ใช้
  ///
  /// ฟังก์ชันนี้จะขอสิทธิ์ที่จำเป็นสำหรับการเลือกรูปภาพ
  /// โดยจะขอสิทธิ์ที่ถูกต้องตามแต่ละแพลตฟอร์ม (Android หรือ iOS)
  ///
  /// returns:
  ///   `true` หากได้รับอนุญาต
  ///   `false` หากไม่ได้รับอนุญาต
  static Future<bool> requestPhotosPermission() async {
    PermissionStatus status;

    if (Platform.isAndroid) {
      // สำหรับ Android จะใช้ Permission.photos สำหรับ API 33 ขึ้นไป
      // และ Permission.storage สำหรับเวอร์ชันที่เก่ากว่า
      // แต่ในความเป็นจริง การใช้ Permission.photos จะครอบคลุมได้ดีกว่า
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

  /// ขอสิทธิ์การเข้าถึงกล้องจากผู้ใช้
  ///
  /// returns:
  ///   `true` หากได้รับอนุญาต
  ///   `false` หากไม่ได้รับอนุญาต
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