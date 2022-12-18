import 'package:flutter/material.dart';
import 'package:pawprints/globals.dart' as global;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:async/async.dart';

class LoginProvider with ChangeNotifier {
  bool _triedInitialAuth =
      false; // True if we've tried our one and only initial login
  bool get triedInitialAuth => _triedInitialAuth;
  void setTriedInitialAuth(bool b) {
    _triedInitialAuth = b;
    notifyListeners();
  }

  bool _appStateSignin = true; // True when we are asking for signin state
  bool get appStateSignin => _appStateSignin;

  bool _userHasInteracted = false;
  bool get userHasInteracted => _userHasInteracted;
  void setUserHasInteracted() {
    _userHasInteracted = true;
  }

  void setAppStateSignin(bool s) {
    _appStateSignin = s;
    notifyListeners();
  }

  Color _buttonColour = Colors.purple[200]!;
  Color get buttonColor => _buttonColour;

  String _errorMessage = "";
  String get errorMessage => _errorMessage;

  String _dialogMessage = "";
  String get dialogMessage => _dialogMessage;

  state _loginState = state.waiting;
  state get loginState => _loginState;
  void setLoginState(state s) {
    _loginState = s;
    notifyListeners();
  }

  // Constructor
  LoginProvider() {
    initSharedPref();
  }

  // final global.pb = PocketBase('http://192.168.2.80:8090/');
  PocketBase get pb => global.pb; // Getter for pocketbase
  PocketBase getPb() {
    return global.pb;
  }

  Future<RecordAuth?> authReq() {
    return global.pb.collection('users').authWithPassword(_username, _password);
  }

  Future<dynamic?> signupReq() {
    setLoginState(state.checking);
    return pb.collection('users').create(body: {
      'email': _username,
      'password': _password,
      'passwordConfirm': _password,
      'name': _username,
    }).then((value) {
      setLoginState(state.accountCreated);
      _dialogMessage = "Account created please log in";
    }).onError((error, stackTrace) {
      setLoginState(state.error);
      if (error.toString().contains("404")) {
        _errorMessage = "Cannot connect to Pawprints";
      } else if (error.toString().contains("400")) {
        _errorMessage = "Username taken";
      } else {
        _errorMessage = "Unknown error, try again later";
      }
      return null;
    }).timeout(Duration(seconds: 10), onTimeout: () {
      setLoginState(state.error);
      return null;
    });
  }

  bool _buttonState = false;
  void setButtonState(bool b) {
    _buttonState = b;
    notifyListeners();
  }

  bool get buttonState => _buttonState;

  Future<dynamic?> submitHandler() {
    if (_appStateSignin) {
      return tryLogIn();
    } else {
      return signupReq();
    }
  }

  Future<void> sendVerifReq({required String email}) {
    return pb.collection('users').requestVerification(email);
  }

  Future<void> sendResetReq({required String email}) {
    return pb.collection('users').requestPasswordReset(email);
  }

  /* Initialize the username/password to null */
  // late String _username; // Username
  String _username = "asda@adasd"; // Username
  String get username => _username; // Getters
  void setUsername(usr) {
    _username = usr;
    debugPrint(_username);
    // notifyListeners();
  } // Setters

  // late String _password; // Password
  String _password = "foo";
  String get password => _password;
  void setPassword(pwd) {
    _password = pwd;
    // notifyListeners();
  }

  String _password_confirm = "foo";
  String get password_confirm => _password_confirm;
  void setPasswordConfirm(pwdc) {
    _password_confirm = pwdc;
    notifyListeners();
  }

  late RecordAuth authData; // Authentication data

  late bool
      _rememberCredentials; // Checks if the user wants us to remember credentials
  bool get rememberCredentials => _rememberCredentials; // Getter
  void setRememberCredentials(rc) {
    _rememberCredentials = rc;
    notifyListeners();
  }

  late SharedPreferences prefs; // For saving credentials to local storage

  bool _loginSuccess =
      false; // Initialize not logged in unless otherwise changed
  bool checkAndUpdateAuthStatus() {
    // updates auth status, returns result
    _loginSuccess = pb.authStore.isValid;
    notifyListeners();
    return _loginSuccess;
  }

  late RecordAuth _auth; // authentication return

  // Function to initiate access to local storage
  void initSharedPref() async {
    await SharedPreferences.getInstance().then((value) {
      prefs = value; // Assign sharedPref obj
      _username = prefs.getString('username') ?? ""; // Check for username
      _password = prefs.getString('password') ?? ""; // Check for password
      _rememberCredentials = prefs.getBool('rememberCredentials') ??
          false; // Check if we should remember credentials
      notifyListeners();
      // tryLogIn();
    });
  } // Set shared pref instance

  /* 
    This function takes in a pocketbase instance, username, and password
    and checks if the user can be authenticated. The function returns a 
    future of RecordAuth
  */
  Future<dynamic?> tryLogIn() async {
    debugPrint("Trying login");
    setLoginState(state.checking);
    final future_auth = await global.pb
        .collection('users')
        .authWithPassword(_username, _password)
        .then((value) {
      _auth = value;
      _loginSuccess = global.pb.authStore.isValid; // Check if token is valid
      setLoginState(state.success);
      var a = pb.authStore.model;
      debugPrint(
          "${pb.authStore.model.data['id']} and  and ${pb.authStore.token.toString()}");
      notifyListeners();
      prefs.setString('username', _username);
      prefs.setString('password', _password);
    }).onError((error, stackTrace) {
      setLoginState(state.error);
      debugPrint(error.toString());
      debugPrint("bingbong");
      if (error.toString().contains("404")) {
        _errorMessage = "Cannot connect to Pawprints";
      } else if (error.toString().contains("400")) {
        _errorMessage = "Incorrect username/password";
      } else {
        _errorMessage = "Unknown error, try again later";
      }
      return null;
    }).timeout(Duration(seconds: 10), onTimeout: () {
      debugPrint("Timeout");
      setLoginState(state.error);
      return null;
    });
    return future_auth;
  }
}

enum state { waiting, checking, success, error, accountCreated }
