import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutterquiz/app/appLocalization.dart';
import 'package:flutterquiz/features/profileManagement/cubits/uploadProfileCubit.dart';
import 'package:flutterquiz/ui/screens/battle/widgets/customDialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutterquiz/app/routes.dart';
import 'package:flutterquiz/utils/stringLabels.dart';
import 'package:flutterquiz/utils/uiUtils.dart';
import 'package:image/image.dart' as img;

import 'package:permission_handler/permission_handler.dart';


class ChooseProfileDialog extends StatefulWidget {
  final String id;
  final UploadProfileCubit bloc;
  ChooseProfileDialog({required this.id, required this.bloc});
  @override
  _ChooseProfileDialog createState() => _ChooseProfileDialog();
}

class _ChooseProfileDialog extends State<ChooseProfileDialog> {
  File? image;
  // get image File camera
  Future<bool> _permissionToPickImage() async {
    bool permissionGiven = await Permission.storage.isGranted;
    if (!permissionGiven) {
      permissionGiven = (await Permission.storage.request()).isGranted;
      return permissionGiven;
    }
    return permissionGiven;
  }

  Future<void> _fixImageOriention(String imagePath) async {
    final img.Image? capturedImage =
    img.decodeImage(await File(imagePath).readAsBytes());
    final img.Image orientedImage = img.bakeOrientation(capturedImage!);
    image = await File(imagePath).writeAsBytes(img.encodeJpg(orientedImage));
  }

  _getFromCamera(BuildContext context) async {
    Navigator.of(context)
        .pushNamed<String?>(Routes.captureImage)
        .then((capturedImagePath) async {
      if (capturedImagePath != null && capturedImagePath.isNotEmpty) {
        await _fixImageOriention(capturedImagePath);
        widget.bloc.uploadProfilePicture(image, widget.id);
      }
    });
  }

//get image file from library
  _getFromGallery(BuildContext context) async {
    if (await _permissionToPickImage()) {
      final pickedFile = await FilePicker.platform
          .pickFiles(allowMultiple: false, type: FileType.image);

      if (pickedFile == null) {
        return;
      }
      await _fixImageOriention(pickedFile.files.first.path!);

      widget.bloc.uploadProfilePicture(image, widget.id);
    } else {
      UiUtils.setSnackbar(
          AppLocalization.of(context)!
              .getTranslatedValues(pleaseGivePickImagePermissionKey) ??
              pleaseGivePickImagePermissionKey,
          context,
          false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
        height: MediaQuery.of(context).size.height * .2,
        //shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)), //this right here
        child: Container(
            decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TextButton.icon(
                        icon: Icon(
                          Icons.photo_library,
                          color: Theme.of(context).primaryColor,
                        ),
                        label: Text(
                          AppLocalization.of(context)!
                              .getTranslatedValues("photoLibraryLbl")!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          _getFromGallery(context);
                          Navigator.of(context).pop();
                        }),
                    TextButton.icon(
                      icon: Icon(
                        Icons.photo_camera,
                        color: Theme.of(context).primaryColor,
                      ),
                      label: Text(
                        AppLocalization.of(context)!
                            .getTranslatedValues("cameraLbl")!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _getFromCamera(context);
                      },
                    )
                  ]),
            )));
  }
}
