import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:pawprints/globals.dart' as global;

const double avatar_radius = 25;

class CardBuilder extends StatefulWidget {
  RecordModel postData;
  bool enableLiking;

  CardBuilder({
    Key? key,
    required RecordModel this.postData,
    bool this.enableLiking = false,
  }) : super(key: key);

  @override
  _CardBuilderState createState() =>
      _CardBuilderState(postData: postData, enableLiking: enableLiking);
}

class _CardBuilderState extends State<CardBuilder> {
  RecordModel postData;
  RecordModel? postDataOnDeck; // Newest update from server
  late RecordModel? originatorData;
  bool shouldUpdatePost = false; // To get around setstate in subscriber
  bool enableLiking;
  bool hasBeenLiked = false;
  _CardBuilderState({
    Key? key,
    required RecordModel this.postData,
    this.enableLiking = false,
  }) {
    var originatorDataList = postData.expand['originator'];
    this.originatorData = originatorDataList?[0];
  }

  @override
  initState() {
    super.initState();
    global.pb.collection('posts').subscribe(
      postData.id,
      (e) {
        postDataOnDeck = e.record ?? postDataOnDeck; // Only update if non-null
        shouldUpdatePost = true;
        debugPrint("updateFromServer");
      },
    );
  } // Setup realtime streaming on post}

  Future<bool> checkLikeStatus() async {
    List<dynamic?> likers = postData.data['likers'];
    return await likers.contains(global.pb.authStore.model.id.toString());
  }

  doubleTapHandler() async {
    if (!hasBeenLiked) {
      List<String> tempLikersList = List<String>.from(postData.data['likers']);
      tempLikersList.add(global.pb.authStore.model.id); // remove like
      // Like post
      await global.pb.collection('posts').update(
        postData.id,
        body: {
          'likes': (postData.data['likes'] + 1).toString(),
          'likers': tempLikersList,
        },
      );
    } else {
      // Unlike post
      debugPrint(postData.data['likers'].toString());
      debugPrint(postData.data.toString());
      List<String> existingLikersList =
          List<String>.from(postData.data['likers'] as List);
      List<dynamic> newLikersList = <dynamic>[
        existingLikersList.toList(growable: true)
      ];
      List<String> tempLikersList = List<String>.from(postData.data['likers']);
      tempLikersList.remove(global.pb.authStore.model.id); // remove like
      await global.pb.collection('posts').update(
        postData.id,
        body: {
          'likes': (postData.data['likes'] - 1).toString(),
          'likers': tempLikersList,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (shouldUpdatePost) {
      // Update post if we get new data from server
      if (mounted) {
        setState(() {
          postData = postDataOnDeck ?? postData;
        });
      } else {
        postData = postDataOnDeck ?? postData;
      }

      shouldUpdatePost = false;
    }
    checkLikeStatus().then((value) {
      if (mounted) {
        setState(() {
          hasBeenLiked = value;
        });
      }
    });
    var cardContainer = Container(
      child: Card(
        child: Column(
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    radius: avatar_radius,
                    backgroundImage: NetworkImage(
                      "${global.pocketBaseUrl}api/files/${originatorData?.collectionId}/${originatorData?.id}/${originatorData?.data['avatar']}",
                    ),
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                Text(originatorData?.data['name'] ?? ""),
                const SizedBox(
                  width: 20,
                ),
                Text(postData.data['likes'].toString() ?? ""),
                const SizedBox(
                  width: 20,
                ),
                Icon(
                  hasBeenLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: Colors.redAccent,
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Hero(
                  tag: postData.id,
                  child: Image.network(
                    "${global.pocketBaseUrl}api/files/${postData.collectionId}/${postData.id}/${postData.data["image"]}",
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  postData.data['caption'],
                  textAlign: TextAlign.left,
                ),
              ),
            )
          ],
        ),
      ),
    );
    return enableLiking
        ? GestureDetector(
            onDoubleTap: () => doubleTapHandler(),
            child: cardContainer,
          )
        : cardContainer;
  }
}
