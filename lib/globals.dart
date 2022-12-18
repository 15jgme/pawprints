library pawprints.globals;

import 'package:pocketbase/pocketbase.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// String pocketBaseUrl = 'http://192.168.2.80:8090/';
String pocketBaseUrl = 'https://84ce-67-68-188-29.ngrok.io/';
final pb = PocketBase(pocketBaseUrl);
