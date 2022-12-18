import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:pawprints/helpers/widgets/TextFieldRound.dart';

class PrepostCard extends StatelessWidget {
  late Image image;
  late String? description;
  late Function(String?) onTextChanged;
  PrepostCard(
      {Key? key,
      required Image this.image,
      required String? this.description,
      required Function(String?) this.onTextChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Card(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0), child: image),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: TextFieldRound(
                prompt: "Description",
                isParagraph: true,
                onChanged: onTextChanged,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
