import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EnhancedProfile {
  String userId;
  String name;
  String email;
  String mobile;
  String infoType;
  String address;
  String identityType;
  String identityNo;
  DateTime dob;
  bool newsletter;
  String subscribeEmail;

  EnhancedProfile(
      {@required this.userId,
        @required this.email,
      @required this.name,
      @required this.mobile,
      @required this.infoType,
      @required this.address,
      @required this.identityType,
      @required this.identityNo,
      this.dob,
      this.newsletter,
      this.subscribeEmail});

  EnhancedProfile.fromMap(Map snapshot, String id)
      : userId = id ?? '',
        email = snapshot['email'] ?? '',
        name = snapshot['name'] ?? '',
        mobile = snapshot['mobile'] ?? '',
        infoType = snapshot['infoType'] ?? '',
        address = snapshot['address'] ?? '',
        identityType = snapshot['identityType'] ?? '',
        identityNo = snapshot['identityNo'] ?? '',
        dob = snapshot['dob'] != null
            ? (snapshot['dob'] as Timestamp).toDate()
            : null,
        newsletter = snapshot['newsletter'] ?? false,
        subscribeEmail = snapshot['subscribeEmail'] ?? '';

  dynamic toJson() {
    return {
      'userId': userId,
      'email': email,
      'name': name,
      'mobile': mobile,
      'infoType': infoType,
      'address': address,
      'identityType': identityType,
      'identityNo': identityNo,
      'dob': Timestamp.now(),
      'newsletter': newsletter,
      'subscribeEmail': subscribeEmail
    };
  }
}
