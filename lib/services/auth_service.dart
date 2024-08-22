import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/models/user.dart';
import 'package:voxbox/services/api_response.dart';

Future<ApiResponse> login(String phone, String password) async {
  ApiResponse apiResponse = ApiResponse();

  try {
    final response =
        await http.post(Uri.parse(AppConstance.loginURL), headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer ${AppConstance.token}',
    }, body: {
      'phone': phone,
      'password': password
    });

    print(response.statusCode.toString());
    switch (response.statusCode) {
      case 200:
        apiResponse.data = Collector.fromJson(jsonDecode(response.body));
        break;
      case 422:
        final errors = jsonDecode(response.body)['errors'];
        apiResponse.error = errors[errors.keys.elementAt(0)][0];
        break;
      case 403:
        apiResponse.error = jsonDecode(response.body)['message'];
        break;
      default:
        apiResponse.error = null;
    }
  } catch (e) {
    apiResponse.error = "serverError";
  }

  return apiResponse;
}
