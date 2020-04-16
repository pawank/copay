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
  String profileUrl;
  bool newsletter;
  String subscribeEmail;
  double totalRaised = 0.00;
  double totalDonated = 0.00;
  int raisedCount = 0;
  int donatedCount = 0;

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
      this.profileUrl,
      this.newsletter,
      this.subscribeEmail,
      this.totalRaised,
      this.totalDonated,
      this.raisedCount,
      this.donatedCount
      });

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
        profileUrl = snapshot['profileUrl'] ?? '',
        newsletter = snapshot['newsletter'] ?? false,
        subscribeEmail = snapshot['subscribeEmail'] ?? '',
        totalRaised = snapshot['totalRaised'] ?? 0.00,
        totalDonated = snapshot['totalDonated'] ?? 0.00,
        raisedCount = snapshot['raisedCount'] ?? 0,
        donatedCount = snapshot['donatedCount'] ?? 0;

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
      'profileUrl': profileUrl,
      'newsletter': newsletter,
      'subscribeEmail': subscribeEmail,
      'totalRaised':totalRaised,
      'totalDonated':totalDonated,
      'raisedCount': raisedCount,
      'donatedCount': donatedCount
    };
  }
}
