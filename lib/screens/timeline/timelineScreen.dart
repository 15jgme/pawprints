import "package:flutter/material.dart";
import "package:provider/provider.dart";
import 'package:pawprints/providers/timeline/timelineProvider.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({Key? key}) : super(key: key);

  @override
  _TimelineScreenState createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: Colors.black,
                onRefresh: context.read<TimelineProvider>().refreshAll,
                child: SingleChildScrollView(
                  child: Column(
                    children: context.watch<TimelineProvider>().timeline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
