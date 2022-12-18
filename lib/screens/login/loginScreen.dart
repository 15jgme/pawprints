import 'package:flutter/material.dart';
import 'package:pawprints/providers/login/loginProvider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animated_button/flutter_animated_button.dart';
import 'package:blobs/blobs.dart';
import 'package:flutter/gestures.dart';
import 'package:pawprints/globals.dart';
import 'package:pawprints/helpers/widgets/TextFieldRound.dart';

const MIN_PASSWORD_LENGTH = 8;

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if ((context.watch<LoginProvider>().loginState == state.success) &
        (!context.watch<LoginProvider>().userHasInteracted)) {
      Navigator.pushNamed(context, '/primary');
    }

    Future<void> _showMyDialog(String errorMessage) async {
      return showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            // title: Center(child: const Text('Error')),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Icon(
                      Icons.cancel_rounded,
                      size: 45,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(child: Text(errorMessage)),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text(
                  'Okay',
                  style: TextStyle(color: Colors.black),
                ),
                onPressed: () {
                  context.read<LoginProvider>().setLoginState(state.waiting);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    Future<void> _showMessage(String message) async {
      return showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            // title: Center(child: const Text('Error')),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Icon(
                      Icons.check,
                      size: 45,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(child: Text(message)),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text(
                  'Okay',
                  style: TextStyle(color: Colors.black),
                ),
                onPressed: () {
                  context.read<LoginProvider>().setLoginState(state.waiting);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    return Scaffold(
      body: Center(
        child: Stack(
          alignment: AlignmentDirectional.topCenter,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: Blob.random(
                size: 1200,
                styles: BlobStyles(
                    gradient: const LinearGradient(
                  colors: [Colors.pinkAccent, Colors.purpleAccent],
                ).createShader(
                        Rect.fromCircle(center: Offset(200, 0), radius: 150))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TextFieldRound(
                    onChanged: (email) {
                      context.read<LoginProvider>().setUserHasInteracted();
                      context.read<LoginProvider>().setUsername(email.trim());
                    },
                    prompt: "email",
                  ),
                  SizedBox(height: 10),
                  TextFieldRound(
                    onChanged: (pwd) {
                      context.read<LoginProvider>().setUserHasInteracted();
                      context.read<LoginProvider>().setPassword(pwd);
                      context.read<LoginProvider>().setPassword(pwd);
                    },
                    prompt: "password",
                    isPassword: true,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const OptionalPasswordConfirm(),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 40,
                    width: 40,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: context.watch<LoginProvider>().loginState ==
                              state.checking
                          ? const CircularProgressIndicator(
                              color: Colors.black,
                            )
                          : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClickableText(
                        prompt: context.watch<LoginProvider>().appStateSignin
                            ? "sign-up"
                            : "log-in",
                        onPress: () {
                          context.read<LoginProvider>().setUserHasInteracted();
                          context.read<LoginProvider>().setAppStateSignin(
                              !context.read<LoginProvider>().appStateSignin);
                        }),
                  ),
                  SubmitButton(
                      showErrorDialog: _showMyDialog,
                      showDialog: _showMessage,
                      text: !context.watch<LoginProvider>().appStateSignin
                          ? "sign-up"
                          : "log-in"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClickableText extends StatelessWidget {
  late String prompt;
  late Function() onPress;
  ClickableText(
      {required String this.prompt, required Function() this.onPress, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
          text: prompt,
          style: const TextStyle(
            color: Colors.black,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()..onTap = onPress),
    );
  }
}

class OptionalPasswordConfirm extends StatelessWidget {
  const OptionalPasswordConfirm({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: !context.watch<LoginProvider>().appStateSignin
          ? TextFieldRound(
              onChanged: (pwdc) {
                context.read<LoginProvider>().setPasswordConfirm(pwdc);
              },
              isPassword: true,
              prompt: "confirm password",
            )
          : SizedBox(height: 51),
    );
  }
}

class SubmitButton extends StatelessWidget {
  late String text;

  Function(String) showErrorDialog;
  Function(String) showDialog;

  SubmitButton(
      {required String this.text,
      required Function(String) this.showErrorDialog,
      required Function(String) this.showDialog,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    void _onPress() {
      debugPrint("foooooo");
      context.read<LoginProvider>().setButtonState(true);
      if (!context.read<LoginProvider>().appStateSignin &&
          (context.read<LoginProvider>().password !=
              context.read<LoginProvider>().password_confirm)) {
        showErrorDialog("Passwords don't match");
        context.read<LoginProvider>().setLoginState(state.waiting);
        Future.delayed(Duration(milliseconds: 500)).then(
            (value) => context.read<LoginProvider>().setButtonState(false));
      } else if (!context.read<LoginProvider>().appStateSignin &&
          (context.read<LoginProvider>().password.length <
              MIN_PASSWORD_LENGTH)) {
        showErrorDialog("Passwords must be at least 8 characters");
        context.read<LoginProvider>().setLoginState(state.waiting);
        Future.delayed(Duration(milliseconds: 500)).then(
            (value) => context.read<LoginProvider>().setButtonState(false));
      } else {
        context.read<LoginProvider>().submitHandler().then(
          (value) {
            context.read<LoginProvider>().setButtonState(false);
            if (context.read<LoginProvider>().loginState == state.error) {
              showErrorDialog(context.read<LoginProvider>().errorMessage);
            } else
            // Check if we are ok to login
            if (context.read<LoginProvider>().loginState == state.success) {
              Navigator.pushNamed(context, '/primary');
            } else if (context.read<LoginProvider>().loginState ==
                state.accountCreated) {
              showDialog(context.read<LoginProvider>().dialogMessage);
            }
          },
        );
      }
    }

    if (!context.read<LoginProvider>().triedInitialAuth) {
      // Once and only once we hit the sign in button to try to auto-login
      Future.delayed(Duration(milliseconds: 1500)).then((value) => _onPress());
      context.read<LoginProvider>().setTriedInitialAuth(true);
    }

    return AbsorbPointer(
      absorbing: context.watch<LoginProvider>().loginState == state.checking,
      child: AnimatedButton(
        height: 70,
        width: 200,
        text: text,
        selectedText: 'waiting',
        isSelected: context.watch<LoginProvider>().buttonState,
        isReverse: true,
        selectedTextColor: Colors.black,
        transitionType: TransitionType.BOTTOM_CENTER_ROUNDER,
        // textStyle: submitTextStyle,
        backgroundColor: Colors.black,
        borderColor: Colors.white,
        selectedGradientColor:
            LinearGradient(colors: [Colors.pinkAccent, Colors.purpleAccent]),
        borderRadius: 50,
        borderWidth: 2,
        onPress: _onPress,
      ),
    );
  }
}
