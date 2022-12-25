import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pawprints/screens/posting/prepostCard.dart';
import 'package:video_player/video_player.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:pawprints/globals.dart';
import 'package:http/http.dart' as http;
import 'package:blobs/blobs.dart';

enum postingScreenState {
  noImageSelected,
  selectingImage,
  imageSelected,
  postSent,
  postSentSuccesfully,
  error,
}

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  @override
  String? description = "";

  dynamic _pickImageError;
  bool isVideo = false;

  VideoPlayerController? _controller;
  VideoPlayerController? _toBeDisposed;
  String? _retrieveDataError;

  bool userRecordFutureResolved = false;
  RecordModel? userRecord;

  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;

  Future<void> _onImageButtonPressed(ImageSource source,
      {BuildContext? context, bool isMultiImage = false}) async {
    if (_controller != null) {
      await _controller!.setVolume(0.0);
    }
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 100,
        maxHeight: 1080,
        maxWidth: 1080,
      );
      setState(() {
        _imageFile = pickedFile;
      });
    } catch (e) {
      setState(() {
        _pickImageError = e;
      });
    }
  }

  Future<RecordModel?> _updateUserStreak() async {
    RecordModel activeUserRecord =
        await pb.collection('users').getOne(pb.authStore.model.id.toString());
    Map<String, dynamic> data = activeUserRecord.data;
    DateTime lastPostDate = DateTime.now();
    if (data['lastPost'] != null && data['lastPost'] != "") {
      DateTime lastPostDate = DateTime.parse(data['lastPost']);
    } else {
      DateTime lastPostDate = DateTime.now();
    }
    int lastPostDay = (lastPostDate.millisecondsSinceEpoch * 8.64e+7).toInt();
    int currentDay = (DateTime.now().millisecondsSinceEpoch * 8.64e+7).toInt();
    debugPrint("streak: ${data['streak'].toString()}");
    if (currentDay - lastPostDay == 1) {
      // Update streak if it's been exactly 1 day between posts
      data['streak'] = (int.tryParse(data['streak'])! + 1).toString();
    } else if (currentDay - lastPostDay > 1) {
      data['streak'] = 0.toString(); // Kill streak if its more than one day
    } else if (data['streak'] == null || data['lastPost'] == null) {
      data['streak'] = 0.toString(); //Initialize
    }
    data['lastPost'] =
        DateFormat('yyyy-MM-dd kk:mm:00').format(DateTime.now().toUtc());
    debugPrint(data.toString());
    return await pb
        .collection('users')
        .update(pb.authStore.model.id.toString(), body: data)
        .then((value) {
      // debugPrint(value.toString());
      return value;
    }).onError((error, stackTrace) {
      debugPrint(error.toString());
      return RecordModel();
    });
  }

  Future<RecordModel> _submitPost(
      {required XFile? raw_image, String? description}) async {
    debugPrint("submit post reached");
    var image = await http.MultipartFile.fromPath("image", raw_image!.path);
    final record = await pb.collection('posts').create(
      body: {
        "caption": description,
        "originator": pb.authStore.model.id.toString()
      },
      files: [image],
    );
    await _updateUserStreak(); // Update user streak on their profile
    return record;
  }

  Widget build(BuildContext context) {
    // Set to image selection
    if (_imageFile == null) // If we haven't picked an image
    {
      // _onImageButtonPressed(kIsWeb ? ImageSource.gallery : ImageSource.camera);
      if (!userRecordFutureResolved) {
        Future<RecordModel?> activeUserRecord = pb
            .collection('users')
            .getOne(pb.authStore.model.id.toString())
            .then((rm) {
          debugPrint("active user loaded");
          setState(() {
            userRecordFutureResolved = true;
            userRecord = rm;
          });
        });
      } // Get logged in users record so we can check the date of last post
      return Scaffold(
        body: Center(
          child: Stack(children: [
            Align(
              alignment: Alignment.center,
              child: Blob.random(
                size: 450,
                styles: BlobStyles(
                    gradient: LinearGradient(
                  colors: userGradient,
                ).createShader(
                        Rect.fromCircle(center: Offset(200, 0), radius: 150))),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: userRecordFutureResolved
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("${userRecord?.data['streak']} day streak"),
                          (userRecord?.data['streak'] > 0)
                              ? Text("keep it going!")
                              : Text("Get started!"),
                          IconButton(
                            onPressed: () => _onImageButtonPressed(kIsWeb
                                ? ImageSource.gallery
                                : ImageSource.camera),
                            icon: Icon(Icons.add_a_photo_outlined),
                          )
                        ],
                      ),
                    )
                  : CircularProgressIndicator(color: Colors.black),
            ),
          ]),
        ),
      );
    } else {
      Widget card = PrepostCard(
        image: kIsWeb
            ? Image.network(_imageFile!.path)
            : Image.file(File(_imageFile!.path)),
        description: description,
        onTextChanged: (str) {
          description = str;
        },
      );
      FloatingActionButton sendButton = FloatingActionButton(
        onPressed: () {
          _submitPost(raw_image: _imageFile, description: description)
              .then((value) {
            setState(() {
              _imageFile = null;
            });
          });
        },
        heroTag: 'image2',
        tooltip: 'Send',
        child: const Icon(Icons.send),
        backgroundColor: Colors.black,
      );
      return Scaffold(
        body: card,
        floatingActionButton: sendButton,
      );
    }
  }
}
