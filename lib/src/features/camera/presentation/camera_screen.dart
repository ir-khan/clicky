import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:clicky/src/features/camera/presentation/widgets/icon_container.dart';
import 'package:clicky/src/mixins/media_query_mixin.dart';
import 'package:clicky/src/shared/widgets/buttons_container.dart';
import 'package:clicky/src/shared/widgets/capsule_container.dart';
import 'package:clicky/src/shared/widgets/loading_widget.dart';
import 'package:clicky/src/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver, MediaQueryMixin {
  List<CameraDescription> _availableCameras = [];
  CameraController? _cameraController;
  /// TODO ( Izn ur Rehman ) : Remove this LenzDirection Enum and use CameraLensDirection directly
  LenzDirection _lenzDirection = LenzDirection.back;
  final _mediaType = ValueNotifier(MediaType.image);
  final _flash = ValueNotifier(FlashMode.off);
  final _isRecording = ValueNotifier(false);
  final _videoDuration = ValueNotifier(Duration.zero);
  Timer? _videoTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    try {
      _availableCameras = await availableCameras();
      await _changeDirection();
    } catch (e) {
      log('Init: $e');
    }
  }

  Future<void> _changeDirection() async {
    try {
      await _cameraController?.dispose();
      _cameraController = null;

      final cameraDescription = _availableCameras.firstWhere(
        (d) =>
            d.lensDirection ==
            (_lenzDirection == LenzDirection.front
                ? CameraLensDirection.front
                : CameraLensDirection.back),
      );

      await _initCameraController(cameraDescription);
    } catch (e) {
      log('Change Direction: $e');
    }
  }

  Future<void> _initCameraController(CameraDescription description) async {
    final controller = CameraController(description, ResolutionPreset.high);
    try {
      await controller.initialize();
      _cameraController = controller;
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      log('Camera init failed: $e');
    }
  }

  Future<void> _captureAndSaveImage() async {
    try {
      final file = await _cameraController?.takePicture();
      if (file == null) return;
      await Gal.putImage(file.path);
    } catch (e) {
      log('Save Image: $e');
    }
  }

  Future<void> _recordVideo() async {
    try {
      _isRecording.value = true;
      await _cameraController?.startVideoRecording();
      _videoTimer = Timer.periodic(Duration(seconds: 1), (_) {
        _videoDuration.value = Duration(
          seconds: _videoDuration.value.inSeconds + 1,
        );
      });
    } catch (e) {
      log('Video Start: $e');
    }
  }

  Future<void> _stopRecordingAndSaveVideo() async {
    try {
      _videoTimer?.cancel();
      final tempFile = await _cameraController?.stopVideoRecording();
      if (tempFile == null) return;

      final directory = await getApplicationDocumentsDirectory();
      final newFileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final newPath = path.join(directory.path, newFileName);
      final permanentFile = await File(tempFile.path).rename(newPath);

      await Gal.putVideo(permanentFile.path);
    } catch (e) {
      log('Video Record: $e');
    } finally {
      _isRecording.value = false;
      _videoDuration.value = Duration.zero;
    }
  }

  /// TODO ( Izn ur Rehman ) : Tap to Focus Functionality is not working
  Future<void> onTapForFocus(TapDownDetails details) async {
    final x = details.globalPosition.dx / size.width;
    final y = details.globalPosition.dy / size.height;
    try {
      await _cameraController?.setFocusPoint(Offset(x, y));
    } catch (e) {
      log('On Tap Focus: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _videoTimer?.cancel();
    _mediaType.dispose();
    _isRecording.dispose();
    _videoDuration.dispose();
    _flash.dispose();
    super.dispose();
  }

  /// TODO ( Izn ur Rehman ) : Prevent Multiple Inits during the Lifecycle

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _changeDirection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _cameraController == null || !_cameraController!.value.isInitialized
          ? LoadingWidget()
          : Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTapDown: onTapForFocus,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  left: 0,
                  child: ButtonsContainer(
                    topPosition: true,
                    child: Column(
                      spacing: 20,
                      children: [
                        SizedBox(),
                        ValueListenableBuilder(
                          valueListenable: _flash,
                          builder: (_, value, _) {
                            /// TODO ( Izn ur Rehman ) : Optimize switch block++
                            return Row(
                              children: FlashMode.values
                                  .where((item) => item != FlashMode.always)
                                  .map(
                                    (mode) => IconContainer(
                                      icon: switch (mode) {
                                        FlashMode.off =>
                                          Icons.flash_off_rounded,
                                        FlashMode.auto =>
                                          Icons.flash_auto_rounded,
                                        FlashMode.torch =>
                                          Icons.flash_on_rounded,
                                        FlashMode.always =>
                                          Icons.flash_on_rounded,
                                      },
                                      iconColor: mode == value
                                          ? Colors.white70
                                          : Colors.white12,
                                      onPressed: () async {
                                        _flash.value = mode;
                                        await _cameraController?.setFlashMode(
                                          mode,
                                        );
                                      },
                                    ),
                                  )
                                  .toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  left: 0,
                  bottom: 0,
                  child: ButtonsContainer(
                    child: Column(
                      spacing: 30,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: 40,
                              child: ValueListenableBuilder(
                                valueListenable: _videoDuration,
                                builder: (_, value, _) {
                                  /// TODO ( Izn ur Rehman ) : Make it developer friendly
                                  return _videoDuration.value == Duration.zero
                                      ? SizedBox.shrink()
                                      : Text(
                                          value.toString().substring(2, 7),
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        );
                                },
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                switch (_mediaType.value) {
                                  case MediaType.image:
                                    await _captureAndSaveImage();
                                    break;
                                  case MediaType.video:
                                    _isRecording.value
                                        ? await _stopRecordingAndSaveVideo()
                                        : await _recordVideo();
                                    break;
                                }
                              },
                              child: ValueListenableBuilder(
                                valueListenable: _isRecording,
                                builder: (_, value, _) {
                                  return Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: value
                                          ? Colors.red
                                          : Colors.white70,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.black),
                                    ),
                                  );
                                },
                              ),
                            ),
                            IconContainer(
                              icon: Icons.cameraswitch_rounded,
                              onPressed: () async {
                                switch (_lenzDirection) {
                                  case LenzDirection.front:
                                    _lenzDirection = LenzDirection.back;
                                  case LenzDirection.back:
                                    _lenzDirection = LenzDirection.front;
                                }
                                _flash.value = FlashMode.off;
                                _cameraController?.setFlashMode(_flash.value);
                                await _changeDirection();
                              },
                            ),
                          ],
                        ),
                        ValueListenableBuilder(
                          valueListenable: _mediaType,
                          builder: (_, value, _) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              spacing: 10,
                              children: [
                                CapsuleContainer(
                                  label: 'Photo',
                                  onTap: () {
                                    _mediaType.value = MediaType.image;
                                  },
                                  isSelected: value == MediaType.image,
                                ),
                                CapsuleContainer(
                                  label: 'Video',
                                  onTap: () {
                                    _mediaType.value = MediaType.video;
                                  },
                                  isSelected: value == MediaType.video,
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// TODO ( Izn ur Rehman ) : Pinch to Zoom in and Zoom out Functionality is not working
/// TODO ( Izn ur Rehman ) : Use riverpod
