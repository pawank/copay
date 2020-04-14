import 'dart:async';
import 'package:copay/models/request_call.dart';
import 'package:copay/services/donation_api.dart';
import 'package:copay/services/locator.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DonationRepo extends ChangeNotifier {
  DonationApi _api = locator<DonationApi>();

  List<RequestCall> _profiles;

  Future<List<RequestCall>> fetchRequestCalls() async {
    var result = await _api.getDataCollection();
    _profiles = result.documents
        .map((doc) => RequestCall.fromMap(doc.data, doc.documentID))
        .toList();
    return _profiles;
  }

  Future<List<RequestCall>> fetchRequestCallsByCode(
      String code, String donorEmail) async {
    var result = await _api.getDataCollection();
    _profiles = result.documents
        .where((doc) => code != null && doc.data['code'] == code && code.isNotEmpty)
        .where((doc) => donorEmail != null && doc.data['donor']['email'] == donorEmail && donorEmail.isNotEmpty)
        .map((doc) => RequestCall.fromMap(doc.data, doc.documentID))
        .toList();
    return _profiles;
  }

  Stream<QuerySnapshot> fetchRequestCallsAsStream() {
    return _api.streamDataCollection();
  }

  Future<RequestCall> getRequestCallById(String id) async {
    var doc = await _api.getDocumentById(id);
    return RequestCall.fromMap(doc.data, doc.documentID);
  }

  Future removeRequestCall(String id) async {
    await _api.removeDocument(id);
    return;
  }
  Future<void> removeRequestByCode(
      String code) async {
    var result = await _api.getDataCollection();
    result.documents
        .where((doc) => code != null && doc.data['code'] == code && code.isNotEmpty)
        .forEach((doc) {
          removeRequestCall(doc.documentID);
        });
  }

  Future updateRequestCall(RequestCall data, String id) async {
    await _api.updateDocument(data.toJson(), id);
    return;
  }

  Future addRequestCall(RequestCall data) async {
    final result = await _api.addDocument(data.toJson());
    return;
  }

  Future<List<RequestCall>> fetchRequestCallsByEmail(
      String email) async {
    final resultF = _api.getDataCollection();
    return resultF.then((result) {
      final _profiles = result.documents
          .where((doc) => email != null && doc.data['donor']['email'] == email && email.isNotEmpty)
          .map((doc) => RequestCall.fromMap(doc.data, doc.documentID))
          .toList();
      return _profiles;
    });
  }

  Future<bool> saveRequestCall(RequestCall data) async {
    final List<RequestCall> users =
        await fetchRequestCallsByCode(data.code, data.donor['email']);
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
