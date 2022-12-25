import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pawprints/screens/timeline/cardBuilder.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:async/async.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:pawprints/globals.dart' as global;

const POSTS_PER_PAGE = 15;

class ProfileProvider with ChangeNotifier {
  ProfileProvider() {
    // Constructor
    lastRefreshStr =
        DateFormat('yyyy-MM-dd kk:mm:00').format(lastRefreshTime.toUtc());
    _profilePosts = <Widget>[
      PaddedProgressIndicator(onVisibilityChanged: scrollLimitReached)
    ];
  }
  // Code here!
  DateTime lastRefreshTime = DateTime.now();
  late String lastRefreshStr;

  bool endOfPostsReached = false; // Signifies that we our out of posts

  int pageEntry = 1;

  late List<Widget> _profilePosts;
  List<Widget> get profilePosts => _profilePosts;

  late List<RecordModel?> postsRecordBatch = [];

  void refreshTime() {
    lastRefreshTime = DateTime.now();
    lastRefreshStr =
        DateFormat('yyyy-MM-dd kk:mm:00').format(lastRefreshTime.toUtc());
  }

  Future<void> refreshAll() {
    refreshTime();
    endOfPostsReached = false;
    pageEntry = 1;
    _profilePosts = <Widget>[
      PaddedProgressIndicator(
        showWidget: !endOfPostsReached,
        onVisibilityChanged: scrollLimitReached,
      )
    ]; //clearProfileTimeline
    notifyListeners();
    return fetchPosts();
  }

  void scrollLimitReached(VisibilityInfo visibility) {
    if (visibility.visibleFraction > 0) {
      fetchPosts();
    }
  }

  Future<void> fetchPosts() async {
    if (!endOfPostsReached) {
      global.pb
          .collection('posts')
          .getList(
            page: pageEntry,
            perPage: POSTS_PER_PAGE,
            filter:
                'created <= "${lastRefreshStr}" && originator = "${global.pb.authStore.model.id.toString()}"',
            sort: '-created',
            expand: 'originator',
          )
          .then(
        (value) {
          postsRecordBatch.addAll(value.items);
          if (value.items.length < POSTS_PER_PAGE) {
            endOfPostsReached = true;
          }
          for (RecordModel post in value.items) {
            _profilePosts.insert(
                _profilePosts.length - 1, PostTile(post: post));
            notifyListeners();
            if (endOfPostsReached) {
              _profilePosts[_profilePosts.length - 1] = PaddedProgressIndicator(
                showWidget: false,
                onVisibilityChanged: scrollLimitReached,
              );
              notifyListeners();
            }
          }
          debugPrint("FINISHED");
          pageEntry++; // Get next page when scroll limit is reached
        },
      );
    }
  }
}

class PaddedProgressIndicator extends StatelessWidget {
  bool showWidget;
  late Function(VisibilityInfo) onVisibilityChanged;
  PaddedProgressIndicator(
      {Key? key,
      bool this.showWidget = true,
      required Function(VisibilityInfo) this.onVisibilityChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: VisibilityDetector(
          key: const Key("ProfileLoading"),
          onVisibilityChanged: (visibilityInfo) {
            onVisibilityChanged(visibilityInfo);
          },
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: CircularProgressIndicator(
              color: showWidget ? Colors.black : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}

class PostTile extends StatelessWidget {
  PostTile({Key? key, required RecordModel this.post}) : super(key: key) {
    imageUrl =
        "${global.pocketBaseUrl}api/files/${post.collectionId}/${post.id}/${post.data["image"]}";
  }
  RecordModel post;
  late String imageUrl;

  @override
  Widget build(BuildContext context) {
    Future<void> _popUpPostCard(RecordModel currentPost) async {
      return showDialog<void>(
        context: context,
        barrierDismissible: true, // user can tap away from the card
        builder: (BuildContext context) {
          return SingleChildScrollView(
            child: CardBuilder(
              postData: post,
            ),
          );
        },
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: GestureDetector(
        onTap: () => _popUpPostCard(post),
        child: Padding(
          padding: const EdgeInsets.all(3.0),
          child: Hero(tag: post.id, child: Image.network(imageUrl)),
        ),
      ),
    );
  }
}
