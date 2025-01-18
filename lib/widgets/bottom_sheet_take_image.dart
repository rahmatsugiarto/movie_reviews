import 'package:flutter/material.dart';

class BottomSheetTakeImage {
  static show({
    required BuildContext context,
    required String title,
    void Function()? onFromCamera,
    void Function()? onFromFolder,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(10),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  height: 18.0,
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(
                  height: 18.0,
                ),
                Builder(
                  builder: (context) {
                    if (onFromCamera != null) {
                      return ItemAction(
                        onTap: onFromCamera,
                        text: 'Take a photo',
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                Builder(
                  builder: (context) {
                    if (onFromFolder != null) {
                      return ItemAction(
                        onTap: onFromFolder,
                        text: 'Upload from Photos',
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(
                  height: 30.0,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class ItemAction extends StatelessWidget {
  final void Function()? onTap;
  final String text;
  final Color colorText;

  const ItemAction({
    super.key,
    this.onTap,
    this.colorText = Colors.black,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: MediaQuery.sizeOf(context).width,
        padding: const EdgeInsets.symmetric(vertical: 14),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
