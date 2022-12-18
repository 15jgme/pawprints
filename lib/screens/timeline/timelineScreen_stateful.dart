import "package:flutter/material.dart";
import "package:provider/provider.dart";
// import 'package:pawprints/providers/timeline/timelineProvider.dart';
import 'package:intl/intl.dart';
import 'package:pawprints/screens/timeline/cardBuilder.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:async/async.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:pawprints/globals.dart' as global;

const POSTS_PER_PAGE = 2;

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({Key? key}) : super(key: key);

  @override
  _TimelineScreenState createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  @override

  /* State */
  DateTime lastRefreshTime = DateTime.now();
  late String lastRefreshStr =
      DateFormat('yyyy-MM-dd kk:mm:00').format(lastRefreshTime.toUtc());

  bool endOfPostsReached = false; // Signifies that we our out of posts

  int pageEntry = 1;

  late List<Widget> _timeline = <Widget>[
    PaddedProgressIndicator(onVisibilityChanged: scrollLimitReached)
  ];

  late List<RecordModel?> postsRecordBatch = [];
  /* State */

  /* Functions */
  void refreshTime() {
    setState(() {
      lastRefreshTime = DateTime.now();
      lastRefreshStr =
          DateFormat('yyyy-MM-dd kk:mm:00').format(lastRefreshTime.toUtc());
    });
  }

  Future<void> refreshAll() {
    refreshTime();
    setState(() {
      endOfPostsReached = false;
      pageEntry = 1;
      _timeline = <Widget>[
        PaddedProgressIndicator(
          showWidget: !endOfPostsReached,
          onVisibilityChanged: scrollLimitReached,
        )
      ]; //clearTimeline
    });
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
            filter: 'created <= "${lastRefreshStr}"',
          )
          .then(
        (value) {
          setState(() {
            postsRecordBatch.addAll(value.items);
            if (value.items.length < POSTS_PER_PAGE) {
              endOfPostsReached = true;
            }
            for (RecordModel post in value.items) {
              setState(() {
                _timeline.insert(
                    _timeline.length - 1, CardBuilder(postData: post));
              });
            }
            pageEntry++; // Get next page when scroll limit is reached
          });
        },
      );
    }
  }
  /* Functions */

  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: Colors.black,
              onRefresh: refreshAll,
              child: ListView(
                children: _timeline,
              ),
            ),
          ),
        ],
      ),
    );
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
          key: const Key("TimelineLoading"),
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
