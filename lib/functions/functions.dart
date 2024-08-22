// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

//languages code
dynamic phcode;
dynamic platform;
dynamic pref;
String isActive = '';
double duration = 30.0;
var audio = 'audio/notification_sound.mp3';
bool internet = true;
int waitingTime = 0;
String gender = '';
String packageName = 'com.kuilingatech.voxbox';
String signKey = '';

//base url
String url = 'https://vtc.sdfvoyage.online/public/';
String mapkey = (Platform.isAndroid)
    ? 'AIzaSyAndV89GbgUhvqjsVOntsz2W-JuI7VclRs'
    : 'AIzaSyAndV89GbgUhvqjsVOntsz2W-JuI7VclRs';

String mapType = '';

//check internet connection

//internet true
internetTrue() {
  internet = true;
  valueNotifierHome.incrementNotifier();
}

openBrowser(browseUrl) async {
  // ignore: deprecated_member_use
  if (await canLaunch(browseUrl)) {
    // ignore: deprecated_member_use
    await launch(browseUrl);
  } else {
    throw 'Could not launch $browseUrl';
  }
}

checkInternetConnection() {
  Connectivity().onConnectivityChanged.listen((connectionState) {
    if (connectionState == ConnectivityResult.none) {
      internet = false;
      valueNotifierHome.incrementNotifier();
      valueNotifierBook.incrementNotifier();
    } else {
      internet = true;
      valueNotifierHome.incrementNotifier();
      valueNotifierBook.incrementNotifier();
    }
  });
}

// dynamic timerLocation;
dynamic locationAllowed;

bool positionStreamStarted = false;
StreamSubscription<Position>? positionStream;

//validate email already exist

//language code
var choosenLanguage = '';
var languageDirection = '';

List languagesCode = [
  {'name': 'English (US)', 'code': 'en'},
  {'name': 'French', 'code': 'fr'},
];

//getting country code

List countries = [];
getCountryCode() async {
  dynamic result;
  try {
    final response = await http.get(Uri.parse('${url}api/v1/countries-new'));

    if (response.statusCode == 200) {
      countries = jsonDecode(response.body)['data']['countries']['data'];

      phcode =
          (countries.where((element) => element['default'] == true).isNotEmpty)
              ? countries.indexWhere((element) => element['default'] == true)
              : 0;
      result = 'success';
    } else {
      debugPrint(response.body);
      result = 'error';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//login firebase

String userUid = '';
var verId = '';
int? resendTokenId;
bool phoneAuthCheck = false;
dynamic credentials;

//get local bearer token

String lastNotification = '';
List recentSearchesList = [];

//register user

List<BearerClass> bearerToken = <BearerClass>[];

updatePassword(email, password, loginby) async {
  dynamic result;

  try {
    var response =
        await http.post(Uri.parse('${url}api/v1/user/update-password'), body: {
      if (loginby == true) 'email': email,
      if (loginby == false) 'mobile': email,
      'password': password
    });
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        result = true;
      } else {
        result = jsonDecode(response.body)['message'];
      }
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = false;
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

Map<String, dynamic> userDetails = {};
List favAddress = [];
List tripStops = [];
List banners = [];
bool ismulitipleride = false;
bool polyGot = false;
bool changeBound = false;
//user current state

class BearerClass {
  final String type;
  final String token;
  BearerClass({required this.type, required this.token});

  BearerClass.fromJson(Map<String, dynamic> json)
      : type = json['type'],
        token = json['token'];

  Map<String, dynamic> toJson() => {'type': type, 'token': token};
}

Map<String, dynamic> driverReq = {};

class ValueNotifying {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

ValueNotifying valueNotifier = ValueNotifying();

class ValueNotifyingHome {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

class ValueNotifyingChat {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

class ValueNotifyingKey {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

class ValueNotifyingNotification {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

class ValueNotifyingLogin {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

ValueNotifyingHome valueNotifierHome = ValueNotifyingHome();
ValueNotifyingChat valueNotifierChat = ValueNotifyingChat();
ValueNotifyingKey valueNotifierKey = ValueNotifyingKey();
ValueNotifyingNotification valueNotifierNotification =
    ValueNotifyingNotification();
ValueNotifyingLogin valueNotifierLogin = ValueNotifyingLogin();
ValueNotifyingTimer valueNotifierTimer = ValueNotifyingTimer();

class ValueNotifyingTimer {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

class ValueNotifyingBook {
  ValueNotifier value = ValueNotifier(0);

  void incrementNotifier() {
    value.value++;
  }
}

ValueNotifyingBook valueNotifierBook = ValueNotifyingBook();

// //sound

// AudioCache audioPlayer = AudioCache();
// AudioPlayer audioPlayers = AudioPlayer();

//get reverse geo coding

var pickupAddress = '';
var dropAddress = '';

geoCoding(double lat, double lng) async {
  dynamic result;
  try {
    http.Response val;
    if (Platform.isAndroid) {
      val = await http.get(
          Uri.parse(
              'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$mapkey'),
          headers: {
            'X-Android-Package': packageName,
            'X-Android-Cert': signKey
          });
    } else {
      val = await http.get(
          Uri.parse(
              'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$mapkey'),
          headers: {'X-IOS-Bundle-Identifier': packageName});
    }
    if (val.statusCode == 200) {
      result = jsonDecode(val.body)['results'][0]['formatted_address'];
      return result;
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//lang
getlangid() async {
  dynamic result;
  try {
    var response =
        await http.post(Uri.parse('${url}api/v1/user/update-my-lang'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${bearerToken[0].token}',
            },
            body: jsonEncode({"lang": choosenLanguage}));
    // body: {
    //   'lang': choosenLanguage,
    // });
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        result = 'success';
      } else {
        debugPrint(response.body);
        result = 'failed';
      }
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else if (response.statusCode == 422) {
      debugPrint(response.body);
      var error = jsonDecode(response.body)['errors'];
      result = error[error.keys.toList()[0]]
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toString();
    } else {
      debugPrint(response.body);
      result = jsonDecode(response.body)['message'];
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//get address auto fill data
List storedAutoAddress = [];
List addAutoFill = [];

getAutocomplete(input, sessionToken, lat, lng) async {
  try {
    addAutoFill.clear();
    if (mapType == 'google') {
      http.Response val;
      if (Platform.isAndroid) {
        val = await http.get(
            Uri.parse(
                'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$mapkey&location=$lat%2C$lng&radius=10000&sessionToken=$sessionToken'),
            headers: {
              'X-Android-Package': packageName,
              'X-Android-Cert': signKey
            });
      } else {
        val = await http.get(
            Uri.parse(
                'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$mapkey&location=$lat%2C$lng&radius=10000&sessionToken=$sessionToken'),
            headers: {'X-IOS-Bundle-Identifier': packageName});
      }

      if (val.statusCode == 200) {
        var result = jsonDecode(val.body);
        for (var element in result['predictions']) {
          addAutoFill.add({
            'place': element['place_id'],
            'description': element['description'],
            'lat': '',
            'lon': ''
          });
          if (storedAutoAddress
              .where((element) => element['place'] == element['place_id'])
              .isEmpty) {
            storedAutoAddress.add({
              'place': element['place_id'],
              'description': element['description'],
              'lat': '',
              'lon': ''
            });
          }
        }
      }

      pref.setString('autoAddress', jsonEncode(storedAutoAddress).toString());
    } else {
      var result = await http.get(Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$input&format=json'));
      for (var element in jsonDecode(result.body)) {
        addAutoFill.add({
          'place': element['place_id'],
          'description': element['display_name'],
          'secondary': '',
          'lat': element['lat'],
          'lon': element['lon']
        });
      }
    }
    valueNotifierHome.incrementNotifier();
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

geoCodingForLatLng(id, sessionToken) async {
  try {
    http.Response val;
    if (Platform.isAndroid) {
      val = await http.get(
          Uri.parse(
              'https://maps.googleapis.com/maps/api/place/details/json?placeid=$id&key=$mapkey&sessionToken=$sessionToken'),
          headers: {
            'X-Android-Package': packageName,
            'X-Android-Cert': signKey
          });
    } else {
      val = await http.get(
          Uri.parse(
              'https://maps.googleapis.com/maps/api/place/details/json?placeid=$id&key=$mapkey&sessionToken=$sessionToken'),
          headers: {'X-IOS-Bundle-Identifier': packageName});
    }

    if (val.statusCode == 200) {
      var result = jsonDecode(val.body)['result']['geometry']['location'];
      return result;
    }
  } catch (e) {
    debugPrint(e.toString());
  }
}

//get goods list
List goodsTypeList = [];

getGoodsList() async {
  dynamic result;
  goodsTypeList.clear();
  try {
    var response = await http.get(Uri.parse('${url}api/v1/common/goods-types'));
    if (response.statusCode == 200) {
      goodsTypeList = jsonDecode(response.body)['data'];
      valueNotifierBook.incrementNotifier();
      result = 'success';
    } else {
      debugPrint(response.body);
      result = 'false';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

//drop stops list
List<DropStops> dropStopList = <DropStops>[];

class DropStops {
  String order;
  double latitude;
  double longitude;
  String? pocName;
  String? pocNumber;
  dynamic pocInstruction;
  String address;

  DropStops(
      {required this.order,
      required this.latitude,
      required this.longitude,
      this.pocName,
      this.pocNumber,
      this.pocInstruction,
      required this.address});

  Map<String, dynamic> toJson() => {
        'order': order,
        'latitude': latitude,
        'longitude': longitude,
        'poc_name': pocName,
        'poc_mobile': pocNumber,
        'poc_instruction': pocInstruction,
        'address': address,
      };
}

List etaDetails = [];

//eta request

sharewalletfun({mobile, role, amount}) async {
  dynamic result;
  try {
    var response = await http.post(
        Uri.parse('${url}api/v1/payment/wallet/transfer-money-from-wallet'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${bearerToken[0].token}',
        },
        body: jsonEncode({'mobile': mobile, 'role': role, 'amount': amount}));
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        result = 'success';
      } else {
        debugPrint(response.body);
        result = 'failed';
      }
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = jsonDecode(response.body)['message'];
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}

sendOTPtoEmail(String email) async {
  dynamic result;
  try {
    var response = await http
        .post(Uri.parse('${url}api/v1/send-mail-otp'), body: {'email': email});
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        result = 'success';
      } else {
        debugPrint(response.body);
        result = 'failed';
      }
    } else if (response.statusCode == 422) {
      debugPrint(response.body);
      var error = jsonDecode(response.body)['errors'];
      result = error[error.keys.toList()[0]]
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toString();
    } else {
      result = 'Something went wrong';
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

emailVerify(String email, otpNumber) async {
  dynamic val;
  try {
    var response = await http.post(Uri.parse('${url}api/v1/validate-email-otp'),
        body: {"email": email, "otp": otpNumber});
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        val = 'success';
      } else {
        debugPrint(response.body);
        val = 'failed';
      }
    } else if (response.statusCode == 422) {
      debugPrint(response.body);
      var error = jsonDecode(response.body)['errors'];
      val = error[error.keys.toList()[0]]
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toString();
    } else {
      val = 'Something went wrong';
    }
    return val;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

String isemailmodule = '1';
bool isCheckFireBaseOTP = true;
getemailmodule() async {
  dynamic res;
  try {
    final response = await http.get(
      Uri.parse('${url}api/v1/common/modules'),
    );

    if (response.statusCode == 200) {
      isemailmodule = jsonDecode(response.body)['enable_email_otp'];
      isCheckFireBaseOTP = jsonDecode(response.body)['firebase_otp_enabled'];

      res = 'success';
    } else {
      debugPrint(response.body);
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      res = 'no internet';
    }
  }

  return res;
}

sendOTPtoMobile(String mobile, String countryCode) async {
  dynamic result;
  try {
    var response = await http.post(Uri.parse('${url}api/v1/mobile-otp'),
        body: {'mobile': mobile, 'country_code': countryCode});
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        result = 'success';
      } else {
        debugPrint(response.body);
        result = 'something went wrong';
      }
    } else if (response.statusCode == 422) {
      debugPrint(response.body);
      var error = jsonDecode(response.body)['errors'];
      result = error[error.keys.toList()[0]]
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toString();
    } else {
      result = 'something went wrong';
    }
    return result;
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
}

validateSmsOtp(String mobile, String otp) async {
  dynamic result;
  try {
    var response = await http.post(Uri.parse('${url}api/v1/validate-otp'),
        body: {'mobile': mobile, 'otp': otp});
    if (response.statusCode == 200) {
      if (jsonDecode(response.body)['success'] == true) {
        result = 'success';
      } else {
        debugPrint(response.body);
        result = 'something went wrong';
      }
    } else if (response.statusCode == 422) {
      debugPrint(response.body);
      var error = jsonDecode(response.body)['errors'];
      result = error[error.keys.toList()[0]]
          .toString()
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toString();
    } else {
      result = 'something went wrong';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
    }
  }
  return result;
}

List outStationList = [];
outStationListFun() async {
  dynamic result;
  try {
    final response = await http.get(
        Uri.parse('${url}api/v1/request/outstation_rides'),
        headers: {'Authorization': 'Bearer ${bearerToken[0].token}'});

    if (response.statusCode == 200) {
      outStationList = jsonDecode(response.body)['data'];
      result = 'success';
      valueNotifierBook.incrementNotifier();
    } else if (response.statusCode == 401) {
      result = 'logout';
    } else {
      debugPrint(response.body);
      result = 'failure';
      valueNotifierBook.incrementNotifier();
    }
    outStationList.removeWhere((element) => element.isEmpty);
  } catch (e) {
    if (e is SocketException) {
      result = 'no internet';

      internet = false;
      valueNotifierBook.incrementNotifier();
    }
  }

  return result;
}

List loginImages = [];
getLandingImages() async {
  dynamic result;
  try {
    final response = await http.get(Uri.parse('${url}api/v1/countries-new'));

    if (response.statusCode == 200) {
      countries = jsonDecode(response.body)['data']['countries']['data'];
      loginImages.clear();
      List _images = jsonDecode(response.body)['data']['onboarding']['data'];
      for (var element in _images) {
        if (element['screen'] == 'user') {
          loginImages.add(element);
        }
      }
      phcode =
          (countries.where((element) => element['default'] == true).isNotEmpty)
              ? countries.indexWhere((element) => element['default'] == true)
              : 0;
      result = 'success';
    } else {
      debugPrint(response.body);
      result = 'error';
    }
  } catch (e) {
    if (e is SocketException) {
      internet = false;
      result = 'no internet';
    }
  }
  return result;
}
