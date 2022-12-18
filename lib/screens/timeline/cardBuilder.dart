import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:pawprints/globals.dart' as global;

const double avatar_radius = 25;

class CardBuilder extends StatefulWidget {
  RecordModel postData;

  CardBuilder({Key? key, required RecordModel this.postData}) : super(key: key);

  @override
  _CardBuilderState createState() => _CardBuilderState(postData: postData);
}

class _CardBuilderState extends State<CardBuilder> {
  RecordModel postData;
  late RecordModel? originatorData;
  _CardBuilderState({Key? key, required RecordModel this.postData}) {
    var originatorDataList = postData.expand['originator'];
    this.originatorData = originatorDataList?[0];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                Text(originatorData?.data['name'] ?? "")
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  "${global.pocketBaseUrl}api/files/${postData.collectionId}/${postData.id}/${postData.data["image"]}",
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
  }
}
