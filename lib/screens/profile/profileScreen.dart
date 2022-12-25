import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pawprints/providers/profile/profileProvider.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:pawprints/globals.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;

const double avatar_radius = 40;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  RecordModel? userRecord;

  @override
  void initState() {
    super.initState();
    fetchUserRecord = () {
      pb
          .collection('users')
          .getOne(pb.authStore.model.id.toString())
          .then((value) {
        setState(() {
          userRecord = value;
        });
      });
    };
    fetchUserRecord();
  }

  late VoidCallback fetchUserRecord;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              UserCard(
                userRecord: userRecord,
                fetchUserCard: fetchUserRecord,
              ),
              RefreshIndicator(
                color: Colors.black,
                onRefresh: context.read<ProfileProvider>().refreshAll,
                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  children: [...context.watch<ProfileProvider>().profilePosts],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserCard extends StatelessWidget {
  UserCard({
    Key? key,
    required this.userRecord,
    required VoidCallback this.fetchUserCard,
  }) : super(key: key);

  final RecordModel? userRecord;
  late VoidCallback fetchUserCard;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: (userRecord != null)
              ? Row(
                  children: [
                    CircleAvatar(
                      radius: avatar_radius,
                      backgroundImage: NetworkImage(
                        "${pocketBaseUrl}api/files/${userRecord?.collectionId}/${userRecord?.id}/${userRecord?.data['avatar']}",
                      ),
                      child: Stack(children: [
                        Align(
                          alignment: Alignment.bottomRight,
                          child: SizedBox(
                            width: 25,
                            height: 25,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white70,
                              child: GestureDetector(
                                onTap: () =>
                                    updatePhoto(onFinish: fetchUserCard),
                                child: const Icon(
                                  Icons.add_a_photo,
                                  size: 15,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(
                      width: 40,
                    ),
                    Text(userRecord?.data['name']),
                  ],
                )
              : const SizedBox(
                  height: 40,
                  width: 40,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.black,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

void updatePhoto({required VoidCallback onFinish}) async {
  VideoPlayerController? controller;

  final ImagePicker picker = ImagePicker();
  if (controller != null) {
    await controller.setVolume(0.0);
  }
  try {
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      // source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
      imageQuality: 100,
      maxHeight: 1080,
      maxWidth: 1080,
    );
    var image = await http.MultipartFile.fromPath("image", pickedFile!.path);
    await pb.collection('users').update(
      pb.authStore.model.id,
      files: [image],
    );
  } catch (e) {
    debugPrint(e.toString());
  }
  onFinish!();
}
