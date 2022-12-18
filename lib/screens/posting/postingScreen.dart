import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:pawprints/globals.dart';
import 'package:http/http.dart' as http;
import 'package:pawprints/globals.dart';
import 'package:pawprints/helpers/widgets/TextFieldRound.dart';
import 'package:pawprints/screens/posting/prepostCard.dart';

enum screenState {
  awaitingImagePick,
  imagePicked,
}

class PostingScreen extends StatefulWidget {
  const PostingScreen({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  State<PostingScreen> createState() => _PostingScreenState();
}

class _PostingScreenState extends State<PostingScreen> {
  List<XFile>? _imageFileList;

  void _setImageFileListFromFile(XFile? value) {
    _imageFileList = value == null ? null : <XFile>[value];
  }

  bool imageSubmissionPending = false;
  bool imageSubmissionShouldPop = false;

  var currentState = screenState.awaitingImagePick;

  String? description = "";

  dynamic _pickImageError;
  bool isVideo = false;

  VideoPlayerController? _controller;
  VideoPlayerController? _toBeDisposed;
  String? _retrieveDataError;

  final ImagePicker _picker = ImagePicker();
  final TextEditingController maxWidthController = TextEditingController();
  final TextEditingController maxHeightController = TextEditingController();
  final TextEditingController qualityController = TextEditingController();

  Future<RecordModel> _submitPost(
      {required XFile raw_image, String? description}) async {
    debugPrint("submit post reached");
    var image = await http.MultipartFile.fromPath("image", raw_image.path);
    final record = await pb.collection('posts').create(
      body: {
        "caption": description,
        "originator": pb.authStore.model.id.toString()
      },
      files: [image],
    );
    return record;
  }

  Future<void> _showPostPreview(Image image, String? description) async {
    if (imageSubmissionShouldPop) {
      Navigator.of(context).pop();
    }
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          content: imageSubmissionPending
              ? CircularProgressIndicator()
              : SingleChildScrollView(
                  child: ListBody(
                    children: <Widget>[
                      PrepostCard(
                        image: image,
                        description: description,
                        onTextChanged: (text) {
                          description = text;
                        },
                      )
                    ],
                  ),
                ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Okay',
                style: TextStyle(color: Colors.black),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _onImageButtonPressed(ImageSource source,
      {BuildContext? context, bool isMultiImage = false}) async {
    if (_controller != null) {
      await _controller!.setVolume(0.0);
    }
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 25,
        maxHeight: 1080,
        maxWidth: 1080,
      );
      setState(() {
        _setImageFileListFromFile(pickedFile);
      });
      currentState = screenState.imagePicked;
      debugPrint(currentState.toString());
    } catch (e) {
      setState(() {
        _pickImageError = e;
      });
    }
  }

  @override
  void deactivate() {
    if (_controller != null) {
      _controller!.setVolume(0.0);
      _controller!.pause();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    maxWidthController.dispose();
    maxHeightController.dispose();
    qualityController.dispose();
    super.dispose();
  }

  Widget _previewImages() {
    final Text? retrieveError = _getRetrieveErrorWidget();
    if (retrieveError != null) {
      return retrieveError;
    }
    if (_imageFileList != null) {
      _showPostPreview(
          kIsWeb
              ? Image.network(_imageFileList![0].path)
              : Image.file(File(_imageFileList![0].path)),
          description);
      return CircularProgressIndicator();
    } else if (_pickImageError != null) {
      return Text(
        'Pick image error: $_pickImageError',
        textAlign: TextAlign.center,
      );
    } else {
      return AddPhotoIcon(
        onPressed: () {
          isVideo = false;
          _onImageButtonPressed(ImageSource.camera, context: context);
        },
      );
    }
  }

  Future<void> retrieveLostData() async {
    final LostDataResponse response = await _picker.retrieveLostData();
    if (response.isEmpty) {
      return;
    }
    if (response.file != null) {
      isVideo = false;
      setState(
        () {
          if (response.files == null) {
            _setImageFileListFromFile(response.file);
          } else {
            _imageFileList = response.files;
          }
        },
      );
    } else {
      _retrieveDataError = response.exception!.code;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentState == screenState.awaitingImagePick) {
      _onImageButtonPressed(ImageSource.camera, context: context);
    }
    return Scaffold(
      body: Center(
        child: !kIsWeb && defaultTargetPlatform == TargetPlatform.android
            ? FutureBuilder<void>(
                future: retrieveLostData(),
                builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.none:
                    case ConnectionState.waiting:
                      return AddPhotoIcon(
                        onPressed: () {
                          isVideo = false;
                          _onImageButtonPressed(ImageSource.camera,
                              context: context);
                        },
                      );
                    case ConnectionState.done:
                      return _previewImages();
                    default:
                      if (snapshot.hasError) {
                        return Text(
                          'Pick image/video error: ${snapshot.error}}',
                          textAlign: TextAlign.center,
                        );
                      } else {
                        return IconButton(
                          onPressed: () {
                            isVideo = false;
                            _onImageButtonPressed(ImageSource.camera,
                                context: context);
                          },
                          icon: Icon(Icons.add_a_photo_outlined),
                        );
                      }
                  }
                },
              )
            : _previewImages(),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  imageSubmissionPending = true;
                });
                _submitPost(
                        raw_image: _imageFileList![0], description: description)
                    .then((value) {
                  setState(() {
                    imageSubmissionPending = false;
                    currentState = screenState.awaitingImagePick;
                    setState(() {
                      imageSubmissionShouldPop = true;
                    });
                  });
                });
              },
              heroTag: 'image2',
              tooltip: 'Send',
              child: const Icon(Icons.send),
              backgroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Text? _getRetrieveErrorWidget() {
    if (_retrieveDataError != null) {
      final Text result = Text(_retrieveDataError!);
      _retrieveDataError = null;
      return result;
    }
    return null;
  }

  Future<void> _displayPickImageDialog(
      BuildContext context, OnPickImageCallback onPick) async {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Add optional parameters'),
            content: Column(
              children: <Widget>[
                TextField(
                  controller: maxWidthController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      hintText: 'Enter maxWidth if desired'),
                ),
                TextField(
                  controller: maxHeightController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      hintText: 'Enter maxHeight if desired'),
                ),
                TextField(
                  controller: qualityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      hintText: 'Enter quality if desired'),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('CANCEL'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                  child: const Text('PICK'),
                  onPressed: () {
                    final double? width = maxWidthController.text.isNotEmpty
                        ? double.parse(maxWidthController.text)
                        : null;
                    final double? height = maxHeightController.text.isNotEmpty
                        ? double.parse(maxHeightController.text)
                        : null;
                    final int? quality = qualityController.text.isNotEmpty
                        ? int.parse(qualityController.text)
                        : null;
                    onPick(width, height, quality);
                    Navigator.of(context).pop();
                  }),
            ],
          );
        });
  }
}

class AddPhotoIcon extends StatelessWidget {
  Function()? onPressed;
  AddPhotoIcon({
    Key? key,
    void Function()? this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
        onPressed: onPressed, iconSize: 72, icon: Icon(Icons.add_a_photo));
  }
}

typedef OnPickImageCallback = void Function(
    double? maxWidth, double? maxHeight, int? quality);
