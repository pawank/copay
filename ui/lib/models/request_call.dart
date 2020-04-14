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
  Map<String, String> owner;
  Map<String, String> donor;
  Timestamp requestedOn;

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
      this.updatedOn,
      this.requestedOn,
      this.owner,
      this.donor
      });

  static Map<String, String> getOwner(Map doc) {
      final Map<String, String> owner = doc['owner'] != null
          ? Map<String, String>.from(doc['owner'])
          : Map<String, String>();
      return owner;
  }
  
  static Map<String, String> getDonor(Map doc) {
      final Map<String, String> donor = doc['donor'] != null
          ? Map<String, String>.from(doc['donor'])
          : Map<String, String>();
      return donor;
  }

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
            : null,
        requestedOn = snapshot['requestedOn'] != null
            ? (snapshot['requestedOn'] as Timestamp)
            : null,
        owner = getOwner(snapshot),
        donor = getDonor(snapshot);

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
      'updatedOn': updatedOn,
      'requestedtOn': requestedOn,
      'owner': owner,
      'donor': donor
    };
  }

  String validate() {
    var status = '';
    if (purpose == '') {
      status = status + 'Please provide purpose.';
    }
    if (name == '') {
      status = status + 'You must provide full name.';
    } else if ((name != null) && (name.isNotEmpty)) {
      final pattern = RegExp(r'^[a-zA-Z\.\s]+$');
      if (!pattern.hasMatch(name)) {
        status = status + 'Please verify your name.';
      }
    }
    if (mobile == '') {
      status = status + 'Please provide primary mobile number.';
    }else if ((mobile != null) && (mobile.isNotEmpty)) {
      final pattern = RegExp(r'^\+?[0-9]{10,12}$');
      if (!pattern.hasMatch(mobile)) {
        status = status + 'Please provide a valid mobile number.';
      }
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
    if (upiId != null) {
      final pattern = RegExp(r'^[a-zA-Z0-9\.]+\@[a-zA-Z0-9\.]+$');
      if (!pattern.hasMatch(upiId)) {
        status = status + 'UPI ID seems to be invalid.';
      }
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
