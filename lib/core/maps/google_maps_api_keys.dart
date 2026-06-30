import 'dart:io';

class GoogleMapsApiKeys {
  GoogleMapsApiKeys._();

  static const String android = 'AIzaSyBiDQFOdrgL-nvkBYFbLAiGnqxkXADtWOk';
  static const String ios = 'AIzaSyASzDacva-y6zpovSwOkgfLKBoRekO0SiU';

  static String get current => Platform.isIOS ? ios : android;
}
