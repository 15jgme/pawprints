import 'package:flutter/material.dart';

class PrimaryProvider with ChangeNotifier {
  int _bottom_bar_idx = 0;
  int get bottom_bar_idx => _bottom_bar_idx;
  void SetBottomBarIdx(int i) {
    _bottom_bar_idx = i;
    notifyListeners();
  }
}
