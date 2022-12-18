import 'package:flutter/material.dart';

class TextFieldRound extends StatelessWidget {
  final Function(String p1) onChanged;
  final String? prompt;
  final bool isPassword;
  final bool isParagraph;

  const TextFieldRound({
    Key? key,
    required Function(String) this.onChanged,
    String? this.prompt,
    bool this.isPassword = false, // CANNOT be both password and paragraph
    bool this.isParagraph = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int? maxLines;
    if (isPassword) {
      maxLines = 1;
    } else if (isParagraph) {
      maxLines = 10;
    }
    return TextField(
      textAlign: TextAlign.center,
      keyboardType: TextInputType.text,
      onChanged: onChanged,
      obscureText: isPassword,
      minLines: isParagraph ? 5 : null,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: prompt,
        hintStyle: TextStyle(fontSize: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            width: 0,
            style: BorderStyle.none,
          ),
        ),
        filled: true,
        contentPadding: EdgeInsets.all(16),
        fillColor: Colors.white,
      ),
    );
  }
}
