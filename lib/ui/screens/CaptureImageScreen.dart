import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterquiz/app/appLocalization.dart';
import 'package:flutterquiz/utils/stringLabels.dart';
import 'package:flutterquiz/utils/uiUtils.dart';
import 'package:permission_handler/permission_handler.dart';

class CaptureImageScreen extends StatefulWidget {
  CaptureImageScreen({Key? key}) : super(key: key);

  @override
  _CaptureImageScreenState createState() => _CaptureImageScreenState();
}

class _CaptureImageScreenState extends State<CaptureImageScreen>
    with WidgetsBindingObserver {
  //Available camreras in device
  List<CameraDescription>? _cameras;

  //Camera controller
  CameraController? _controller;

  //Future to track if camera loaded or not
  Future<void>? _initializeControllerFuture;

  bool? _cameraLoadInProgress;

  String _capturedImagePath = "";

  bool _isFlashModeEnable = false;
  bool? _permissionGiven;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    //
    _permissionToCaptureImage().then((value) async {
      _permissionGiven = value;
      setState(() {});
      if (value) {
        _cameras = await availableCameras();
        initCameras(_cameras!.first);
      }
    });
  }

  Widget _buildCupertinoButton(String titleLabel, Function onTap) {
    return CupertinoButton(
      onPressed: () {
        onTap();
      },
      child: Text(
        AppLocalization.of(context)!.getTranslatedValues(titleLabel) ??
            titleLabel,
        style: TextStyle(color: Colors.white, fontSize: 20),
      ),
    );
  }

  Widget _buildIconButton(IconData iconData, Function onTap) {
    return IconButton(
        color: Colors.white,
        iconSize: 50,
        onPressed: () {
          onTap();
        },
        icon: Icon(iconData));
  }

  //Ask for camera permission
  Future<bool> _permissionToCaptureImage() async {
    bool permissionGiven = await Permission.camera.isGranted;
    if (!permissionGiven) {
      permissionGiven = (await Permission.camera.request()).isGranted;

      return permissionGiven;
    }
    return permissionGiven;
  }

  //Init cameras
  void initCameras(CameraDescription cameraDescription) async {
    _controller = CameraController(cameraDescription, ResolutionPreset.medium);
    _initializeControllerFuture = _controller!.initialize();
    _cameraLoadInProgress = true;
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final CameraController? cameraController = _controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      initCameras(cameraController.description);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: (_permissionGiven != null && !_permissionGiven!)
      //If permisison not given
          ? Center(
        child: Text(
          AppLocalization.of(context)!
              .getTranslatedValues(pleaseGiveCameraPermissionKey) ??
              pleaseGiveCameraPermissionKey,
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      )
          : _cameraLoadInProgress == null
          ? const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ))
          : FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                _capturedImagePath.isEmpty
                    ? CameraPreview(_controller!)
                    : Image(
                    image: FileImage(File(_capturedImagePath))),
                SizedBox(
                  height: 30,
                ),
                _capturedImagePath.isEmpty
                    ? Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceAround,
                  children: [
                    _buildIconButton(Icons.rotate_right, () {
                      final lensDirection = _controller!
                          .description.lensDirection;
                      int cameraIndex;
                      if (lensDirection ==
                          CameraLensDirection.front) {
                        cameraIndex = _cameras!.indexWhere(
                                (description) =>
                            description.lensDirection ==
                                CameraLensDirection.back);
                      } else {
                        cameraIndex = _cameras!.indexWhere(
                                (description) =>
                            description.lensDirection ==
                                CameraLensDirection.front);
                      }
                      if (cameraIndex != -1) {
                        initCameras(_cameras![cameraIndex]);
                      } else {
                        UiUtils.setSnackbar(
                            AppLocalization.of(context)!
                                .getTranslatedValues(
                                askedCameraNotAvailableKey) ??
                                askedCameraNotAvailableKey,
                            context,
                            false);
                      }
                    }),
                    _buildIconButton(Icons.camera, () async {
                      // Ensure that the camera is initialized.
                      await _initializeControllerFuture;

                      // Attempt to take a picture and get the file `image`
                      // where it was saved.
                      final image =
                      await _controller!.takePicture();

                      if (!mounted) return;
                      _capturedImagePath = image.path;
                      setState(() {});
                    }),
                    _buildIconButton(
                        _isFlashModeEnable
                            ? Icons.flash_on
                            : Icons.flash_off, () {
                      if (_controller!
                          .description.lensDirection ==
                          CameraLensDirection.front) {
                        return;
                      }
                      if (_isFlashModeEnable) {
                        _controller!
                            .setFlashMode(FlashMode.off);
                      } else {
                        _controller!
                            .setFlashMode(FlashMode.torch);
                      }
                      _isFlashModeEnable = !_isFlashModeEnable;
                      setState(() {});
                    }),
                    _buildIconButton(Icons.close, () {
                      Navigator.of(context).pop();
                    })
                  ],
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCupertinoButton(okayLbl, () {
                      Navigator.of(context)
                          .pop(_capturedImagePath);
                    }),
                    _buildCupertinoButton(retakeKey, () {
                      _capturedImagePath = "";
                      setState(() {});
                    })
                  ],
                ),
              ],
            );
          } else {
            return const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ));
          }
        },
      ),
    );
  }
}