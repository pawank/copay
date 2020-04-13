import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RequestCall extends ChangeNotifier {
  String userId;
  String code;
  String purpose;
  String name;
  String email;
  String mobile;
  String infoType;
  String address;
  String identityType;
  String identityNo;
  Timestamp createdOn;
  String profileUrl;
  bool individual;
  String website;
  String upiId;
  double amount;
  String currency;
  String txnRef;
  String txnType;
  String status;
  String feedback;
  String imageUrl;
  String mediaUrl;
  Timestamp updatedOn;

  RequestCall(
      {
        @required this.userId,
        @required this.code,
      this.email,
      @required this.purpose,
      @required this.name,
      @required this.mobile,
      @required this.infoType,
      @required this.address,
      this.identityType,
      this.identityNo,
      @required this.createdOn,
      this.profileUrl,
      this.individual,
      this.website,
      this.upiId,
      @required this.amount,
      @required this.currency,
      this.txnRef,
      this.txnType,
      @required this.status,
      this.feedback,
      this.imageUrl,
      this.mediaUrl,
      this.updatedOn});

  RequestCall.fromMap(Map snapshot, String id)
      : userId = id ?? '',
        code = snapshot['code'] ?? '',
        email = snapshot['email'] ?? '',
        purpose = snapshot['purpose'] ?? '',
        name = snapshot['name'] ?? '',
        mobile = snapshot['mobile'] ?? '',
        infoType = snapshot['infoType'] ?? '',
        address = snapshot['address'] ?? '',
        identityType = snapshot['identityType'] ?? '',
        identityNo = snapshot['identityNo'] ?? '',
        createdOn = snapshot['createdOn'] != null
            ? (snapshot['createdOn'] as Timestamp)
            : null,
        profileUrl = snapshot['profileUrl'] ?? '',
        individual = snapshot['individual'] ?? false,
        website = snapshot['website'] ?? '',
        upiId = snapshot['upiId'] ?? '',
        amount = snapshot['amount'] ?? 0.00,
        currency = snapshot['currency'] ?? '',
        txnRef = snapshot['txnRef'] ?? '',
        txnType = snapshot['txnType'] ?? '',
        status = snapshot['status'] ?? '',
        feedback = snapshot['feedback'] ?? '',
        imageUrl = snapshot['imageUrl'] ?? '',
        mediaUrl = snapshot['mediaUrl'] ?? '',
        updatedOn = snapshot['updatedOn'] != null
            ? (snapshot['updatedOn'] as Timestamp)
            : null;

  dynamic toJson() {
    return {
      'userId': userId,
      'code': code,
      'email': email,
      'purpose': purpose,
      'name': name,
      'mobile': mobile,
      'infoType': infoType,
      'address': address,
      'identityType': identityType,
      'identityNo': identityNo,
      'createdOn': Timestamp.now(),
      'profileUrl': profileUrl,
      'individual': individual,
      'website': website,
      'upiId': upiId,
      'amount': amount,
      'currency': currency,
      'txnRef': txnRef,
      'txnType': txnType,
      'status': status,
      'feedback': feedback,
      'imageUrl': imageUrl,
      'mediaUrl': mediaUrl,
      'updatedOn': updatedOn
    };
  }

  String validate() {
    var status = '';
    if (purpose == '') {
      status = status + 'Please provide purpose.';
    }
    if (name == '') {
      status = status + 'You must provide full name.';
    }
    if (mobile == '') {
      status = status + 'Please provide primary mobile number.';
    }
    if (amount <= 0) {
      status = status + 'Amount must be more than 0.00.';
    }
    if (currency == '') {
      status = status + 'You must select the currency value.';
    }
    if (identityNo == '') {
      //status = status + 'You must provide a valid identity ID.';
    }
    return status;
  }

  void onChange() {
  notifyListeners();
}

  static RequestCall empty() {
    return new RequestCall(userId: null, code: null, purpose: null, name: '', mobile: null, infoType: null, address: null, createdOn: null, amount: null, currency: null, status: null);
  }
}
