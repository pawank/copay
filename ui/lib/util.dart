import 'package:flutter/material.dart';
import 'package:upi_india/upi_india.dart';

double baseHeight = 640.0;

double screenAwareSize(double size, BuildContext context) {
  return size * MediaQuery.of(context).size.height / baseHeight;
}

class CustomColors {
  static const Color GreyBackground = Color.fromRGBO(249, 252, 255, 1);
  static const Color GreyBorder = Color.fromRGBO(207, 207, 207, 1);

  static const Color GreenLight = Color.fromRGBO(93, 230, 26, 1);
  static const Color GreenDark = Color.fromRGBO(57, 170, 2, 1);
  static const Color GreenIcon = Color.fromRGBO(30, 209, 2, 1);
  static const Color GreenAccent = Color.fromRGBO(30, 209, 2, 1);
  static const Color GreenShadow = Color.fromRGBO(30, 209, 2, 0.24); // 24%
  static const Color GreenBackground =
      Color.fromRGBO(181, 255, 155, 0.36); // 36%

  static const Color OrangeAccent = Color.fromRGBO(236, 108, 11, 1);
  static const Color OrangeIcon = Color.fromRGBO(236, 108, 11, 1);
  static const Color OrangeBackground =
      Color.fromRGBO(255, 208, 155, 0.36); // 36%

  static const Color PurpleLight = Color.fromRGBO(248, 87, 195, 1);
  static const Color PurpleDark = Color.fromRGBO(224, 19, 156, 1);
  static const Color PurpleIcon = Color.fromRGBO(209, 2, 99, 1);
  static const Color PurpleAccent = Color.fromRGBO(209, 2, 99, 1);
  static const Color PurpleShadow = Color.fromRGBO(209, 2, 99, 0.27); // 27%
  static const Color PurpleBackground =
      Color.fromRGBO(255, 155, 205, 0.36); // 36%

  static const Color DeeppurlpleIcon = Color.fromRGBO(191, 0, 128, 1);
  static const Color DeeppurlpleBackground =
      Color.fromRGBO(245, 155, 255, 0.36); // 36%

  static const Color BlueLight = Color.fromRGBO(126, 182, 255, 1);
  static const Color BlueDark = Color.fromRGBO(95, 135, 231, 1);
  static const Color BlueIcon = Color.fromRGBO(9, 172, 206, 1);
  static const Color BlueBackground =
      Color.fromRGBO(155, 255, 248, 0.36); // 36%
  static const Color BlueShadow = Color.fromRGBO(104, 148, 238, 1);

  static const Color HeaderBlueLight = Color.fromRGBO(129, 199, 245, 1);
  static const Color HeaderBlueDark = Color.fromRGBO(56, 103, 213, 1);
  static const Color HeaderGreyLight =
      Color.fromRGBO(225, 255, 255, 0.31); // 31%

  static const Color YellowIcon = Color.fromRGBO(249, 194, 41, 1);
  static const Color YellowBell = Color.fromRGBO(225, 220, 0, 1);
  static const Color YellowAccent = Color.fromRGBO(255, 213, 6, 1);
  static const Color YellowShadow = Color.fromRGBO(243, 230, 37, 0.27); // 27%
  static const Color YellowBackground =
      Color.fromRGBO(255, 238, 155, 0.36); // 36%

  static const Color BellGrey = Color.fromRGBO(217, 217, 217, 1);
  static const Color BellYellow = Color.fromRGBO(255, 220, 0, 1);

  static const Color TrashRed = Color.fromRGBO(251, 54, 54, 1);
  static const Color TrashRedBackground = Color.fromRGBO(255, 207, 207, 1);

  static const Color TextHeader = Color.fromRGBO(85, 78, 143, 1);
  static const Color TextHeaderGrey = Color.fromRGBO(104, 104, 104, 1);
  static const Color TextSubHeaderGrey = Color.fromRGBO(161, 161, 161, 1);
  static const Color TextSubHeader = Color.fromRGBO(139, 135, 179, 1);
  static const Color TextBody = Color.fromRGBO(130, 160, 183, 1);
  static const Color TextGrey = Color.fromRGBO(198, 198, 200, 1);
  static const Color TextWhite = Color.fromRGBO(243, 243, 243, 1);
  static const Color HeaderCircle = Color.fromRGBO(255, 255, 255, 0.17);
  static const Color LightBlue = Color.fromRGBO(0, 154, 224, 1);
  static const Color DarkBlue = Color.fromRGBO(18, 106, 175, 1);
  static const Color LightGrey19 = Color.fromRGBO(112, 112, 112, 0.19);
  static const Color LightGrey = Color.fromRGBO(242, 242, 242, 1);
  static const Color Grey = Color.fromRGBO(157, 157, 157, 1);
  static const Color Black50 = Color.fromRGBO(0, 0, 0, 0.5);
  static const Color Green = Color.fromRGBO(61, 179, 158, 1);
}

// Class to process the response of upi request.
class UpiIndiaResponse2 {
  /// It is the Transaction ID from the response.
  String transactionId;

  /// responseCode is the UPI Response code. You don't particularly need to use this.
  /// You may refer to https://ncpi.org.in for list of responseCode.
  String responseCode;

  /// approvalRefNo is the UPI Approval reference number (beneficiary).
  /// It is optional. You may receive it as null.
  String approvalRefNo;

  /// status gives the status of Transaction.
  /// There are three approved status: success, failure, submitted.
  /// DO NOT use the string directly. Instead use [UpiIndiaResponseStatus]
  String status;

  /// txnRef gives the Transaction Reference ID passed in input.
  String transactionRefId;

  double amount;

  UpiIndiaResponse2(String responseString) {
    List<String> _parts = responseString.split('&');

    for (int i = 0; i < _parts.length; ++i) {
      String key = _parts[i].split('=')[0];
      String value = _parts[i].split('=')[1];
      if (key.toLowerCase() == "txnid") {
        transactionId = value;
      } else if (key.toLowerCase() == "responsecode") {
        responseCode = value;
      } else if (key.toLowerCase() == "approvalrefno") {
        approvalRefNo = value;
      } else if (key.toLowerCase() == "status") {
        if(value.toLowerCase() == "success") status = "success";
        else if(value.toLowerCase().contains("fail")) status = "failure";
        else if(value.toLowerCase().contains("submit")) status = "submitted";
        else status = "other";
      } else if (key.toLowerCase() == "txnref") {
        transactionRefId = value;
      } else if (key.toLowerCase() == "amount") {
        amount = double.parse(value);
      }
    }
  }
}