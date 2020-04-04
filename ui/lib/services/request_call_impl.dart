import 'dart:async';
import 'package:copay/models/request_call.dart';
import 'package:copay/services/locator.dart';
import 'package:copay/services/request_call_api.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RequestCallRepo extends ChangeNotifier {
  RequestCallApi _api = locator<RequestCallApi>();

  List<RequestCall> _profiles;

  Future<List<RequestCall>> fetchRequestCalls() async {
    var result = await _api.getDataCollection();
    _profiles = result.documents
        .map((doc) => RequestCall.fromMap(doc.data, doc.documentID))
        .toList();
    return _profiles;
  }

  Future<List<RequestCall>> fetchRequestCallsByUsername(
      String username) async {
    var result = await _api.getDataCollection();
    _profiles = result.documents
        .where((doc) => doc.data['email'] == username)
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
          .where((doc) => doc.data['email'] == email)
          .map((doc) => RequestCall.fromMap(doc.data, doc.documentID))
          .toList();
      return _profiles;
    });
  }

  Future<bool> saveRequestCall(RequestCall data) async {
    final List<RequestCall> users =
        await fetchRequestCallsByEmail(data.email);
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
