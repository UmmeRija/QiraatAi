import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';

class ToastHelper {
  static void show(
    String message, {
    BuildContext? context,
    Toast toastLength = Toast.LENGTH_SHORT,
    ToastGravity gravity = ToastGravity.BOTTOM,
  }) {
    // ✅ Android/iOS pe Fluttertoast
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      Fluttertoast.showToast(
        msg: message,
        toastLength: toastLength,
        gravity: gravity,
      );
      return;
    }

    // ✅ Windows/Web pe SnackBar fallback
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
