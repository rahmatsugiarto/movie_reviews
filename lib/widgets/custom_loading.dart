import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class CustomLoading {
  static void show({
    SmartBackType? backType,
    String tag = "tag_loading",
  }) =>
      SmartDialog.show(
        keepSingle: true,
        clickMaskDismiss: false,
        animationType: SmartAnimationType.fade,
        backType: backType,
        tag: tag,
        builder: (context) {
          return Container(
            height: 100,
            width: 100,
            padding: const EdgeInsets.all(30),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(
                Radius.circular(10),
              ),
            ),
            child: const CircularProgressIndicator(),
          );
        },
      );

  static void dismiss({String tag = "tag_loading"}) =>
      SmartDialog.dismiss(tag: tag);
}
