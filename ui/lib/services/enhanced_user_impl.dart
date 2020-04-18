import 'dart:async';
import 'package:copay/models/enhanced_user.dart';
import 'package:copay/services/enhanced_user_api.dart';
import 'package:copay/services/locator.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EnhancedProfileRepo extends ChangeNotifier {
  EnhancedUserApi _api = locator<EnhancedUserApi>();

  List<EnhancedProfile> _profiles;

  Future<List<EnhancedProfile>> fetchEnhancedProfiles() async {
    var result = await _api.getDataCollection();
    _profiles = result.documents
        .map((doc) => EnhancedProfile.fromMap(doc.data, doc.documentID))
        .toList();
    return _profiles;
  }

  Future<List<EnhancedProfile>> fetchEnhancedProfilesByUsername(
      String username) async {
    var result = await _api.getDataCollection();
    _profiles = result.documents
        .where((doc) => doc.data['email'] == username)
        .map((doc) => EnhancedProfile.fromMap(doc.data, doc.documentID))
        .toList();
    return _profiles;
  }

  Stream<QuerySnapshot> fetchEnhancedProfilesAsStream() {
    return _api.streamDataCollection();
  }

  Future<EnhancedProfile> getEnhancedProfileById(String id) async {
    var doc = await _api.getDocumentById(id);
    return EnhancedProfile.fromMap(doc.data, doc.documentID);
  }

  Future removeEnhancedProfile(String id) async {
    await _api.removeDocument(id);
    return;
  }

  Future updateEnhancedProfile(EnhancedProfile data, String id) async {
    await _api.updateDocument(data.toJson(), id);
    return;
  }

  Future addEnhancedProfile(EnhancedProfile data) async {
    final result = await _api.addDocument(data.toJson());
    return;
  }
  
  Future<EnhancedProfile> fetchSingleEnhancedProfileByEmail(
      String email, String uid) async {
    final resultF = _api.getDataCollection();
    return resultF.then((result) {
      final _profiles = result.documents
          .where((doc) => doc.data['email'] == email)
          .map((doc) => EnhancedProfile.fromMap(doc.data, doc.documentID))
          .toList();
      if (_profiles.isEmpty) {
          return EnhancedProfile(
            id: null,
            userId: uid,
            name: '',
            email: email,
            mobile: '',
            address: '',
            profileUrl: null,
            totalRaised: 0.00,
            totalDonated: 0.00,
            raisedCount: 0,
            donatedCount: 0
          );

      } else {
        return _profiles.first;
      }
    });
  }

  Future<List<EnhancedProfile>> fetchEnhancedProfilesByEmail(
      String email) async {
    final resultF = _api.getDataCollection();
    return resultF.then((result) {
      final _profiles = result.documents
          .where((doc) => doc.data['email'] == email)
          .map((doc) => EnhancedProfile.fromMap(doc.data, doc.documentID))
          .toList();
      return _profiles;
    });
  }

  Future<bool> saveEnhancedProfile(EnhancedProfile data) async {
    final List<EnhancedProfile> users =
        await fetchEnhancedProfilesByEmail(data.email);
    if (users.isEmpty) {
      return _api.addDocument(data.toJson()).then((v) => v.documentID != null);
    } else {
      users.forEach((up) async { 
        await _api.updateDocument(data.toJson(), up.userId).then((v) => up.userId);
      });
      //return Future.value(users.map((f) => f.email).toList()[0]);
      return Future.value(true);
    }
  }
}
