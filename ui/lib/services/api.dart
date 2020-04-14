import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:intl/intl.dart';

class HttpApi {
  static String BASE_API = 'https://api.copay.foundation';
  static String bearer_token = 'RuA7ruzNqodqR_fzWysojAmTxMgxE3JR3UoI';
  String formatDateAs(DateTime dt) {
    final formatter = new DateFormat('dd-MM-yyyy');
    return formatter.format(dt);
  }

  static String datesAsRangeForDisplay(DateTime start, DateTime end) {
    final formatter = new DateFormat('dd-MMM-yyyy');
    final String startDate = formatter.format(start);
    final String endDate = formatter.format(end);
    return 'From ' + startDate + ' till ' + endDate;
  }

  static Future<Map<String, dynamic>> raiseCompaignRequestDonor(String code, 
      Map<String, dynamic> payload) async {
    final url = code != null ? BASE_API + '/campaign/$code/request' : '/campaign/1/request';
    try {
      final body = jsonEncode(payload);
      final response = await http.post(url,
          headers: {'Authorization': 'Bearer $bearer_token', 'Content-Type': 'application/json', 'cache-control': 'no-cache'}, body: body);
      //print(response.body);
      //print( 'LOCATION request, ${payload} save response: ${response.statusCode}');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } on Exception {
      print('NETWORK ERROR: Cannot reach url - $url now.');
      return null;
    }
  }
  
  static Future<Map<String, dynamic>> confimDonationPaid(String code, 
      Map<String, dynamic> payload) async {
    final url = code != null ? BASE_API + '/campaign/$code/paid' : '/campaign/1/paid';
    try {
      final body = jsonEncode(payload);
      final response = await http.post(url,
          headers: {'Authorization': 'Bearer $bearer_token', 'Content-Type': 'application/json', 'cache-control': 'no-cache'}, body: body);
      //print(response.body);
      //print( 'LOCATION request, ${payload} save response: ${response.statusCode}');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } on Exception {
      print('NETWORK ERROR: Cannot reach url - $url now.');
      return null;
    }
  }
}