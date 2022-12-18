import "package:flutter/material.dart";
import 'package:provider/provider.dart';
import 'package:pawprints/providers/primaryProvider.dart';
import 'package:pawprints/screens/timeline/timelineScreen.dart';
import 'package:pawprints/screens/posting/postingScreen.dart';

class PrimaryScreen extends StatelessWidget {
  PrimaryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    late var screenWidget;
    switch (context.watch<PrimaryProvider>().bottom_bar_idx) {
      case 0:
        screenWidget = Center(
          child: TimelineScreen(),
        );
        break;
      case 1:
        screenWidget = Center(
          child: PostingScreen(),
        );
        break;
      case 2:
        screenWidget = Center(
          child: Text("bar"),
        );
        break;
      case 3:
        screenWidget = Center(
          child: Text("bizz"),
        );
        break;
      default:
        screenWidget = Center(
          child: Text("buzz"),
        );
        break;
    }

    return Scaffold(body: screenWidget, bottomNavigationBar: BottomBar());
  }
}

class BottomBar extends StatelessWidget {
  const BottomBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: RadiantGradientMask(
            child: Icon(
              Icons.image,
            ),
            alignment: Alignment.topRight,
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: RadiantGradientMask(
            child: Icon(
              Icons.add_circle,
            ),
            alignment: Alignment.topCenter,
          ),
          label: 'Pawprint',
        ),
        BottomNavigationBarItem(
          icon: RadiantGradientMask(
            child: Icon(Icons.person),
            alignment: Alignment.topLeft,
          ),
          label: 'Profile',
        ),
      ],
      onTap: (value) {
        debugPrint(value.toString());
        context.read<PrimaryProvider>().SetBottomBarIdx(value);
        switch (value) {
          case 1:
            break;
          case 2:
            break;
          case 3:
            Navigator.pushNamed(context, '/profile');
            break;
          default:
        }
      },
      currentIndex: context.watch<PrimaryProvider>().bottom_bar_idx,
      selectedItemColor: Colors.purple[300],
      unselectedItemColor: Colors.grey,
    );
  }
}

class RadiantGradientMask extends StatelessWidget {
  RadiantGradientMask({required this.child, required this.alignment});
  final AlignmentGeometry alignment;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => RadialGradient(
        center: alignment,
        radius: 1,
        colors: const [Colors.pinkAccent, Colors.purpleAccent],
        tileMode: TileMode.mirror,
      ).createShader(bounds),
      child: child,
    );
  }
}
