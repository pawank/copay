import 'dart:async';
import 'package:copay/models/feedback.dart';
import 'package:copay/services/feedback_api.dart';
import 'package:copay/services/locator.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DonationFeedbackRepo extends ChangeNotifier {
  DonationFeedbackApi _api = locator<DonationFeedbackApi>();

  List<DonationFeedback> _profiles;

  Future<List<DonationFeedback>> fetchDonationFeedbacks() async {
    var result = await _api.getDataCollection();
    _profiles = result.documents
        .map((doc) => DonationFeedback.fromMap(doc.data, doc.documentID))
        .toList();
    return _profiles;
  }

  Future<List<DonationFeedback>> fetchDonationFeedbacksByCodeAndEmail(
      String code, String donorEmail) async {
    var result = await _api.getDataCollection();
    _profiles = result.documents
        .where((doc) =>
            code != null && doc.data['donationCode'] == code && code.isNotEmpty)
        .where((doc) =>
            donorEmail != null &&
            doc.data['feedbackBy'] == donorEmail &&
            donorEmail.isNotEmpty)
        .map((doc) => DonationFeedback.fromMap(doc.data, doc.documentID))
        .toList();
    return _profiles;
  }

  Stream<QuerySnapshot> fetchDonationFeedbacksAsStream() {
    return _api.streamDataCollection();
  }

  Future<DonationFeedback> getDonationFeedbackById(String id) async {
    var doc = await _api.getDocumentById(id);
    return DonationFeedback.fromMap(doc.data, doc.documentID);
  }

  Future removeDonationFeedback(String id) async {
    await _api.removeDocument(id);
    return;
  }

  Future<void> removeRequestByCode(String code) async {
    var result = await _api.getDataCollection();
    result.documents
        .where((doc) =>
            code != null && doc.data['donationCode'] == code && code.isNotEmpty)
        .forEach((doc) {
      removeDonationFeedback(doc.documentID);
    });
  }

  Future updateDonationFeedback(DonationFeedback data, String id) async {
    await _api.updateDocument(data.toJson(), id);
    return;
  }

  Future addDonationFeedback(DonationFeedback data) async {
    final result = await _api.addDocument(data.toJson());
    return;
  }

  Future<List<DonationFeedback>> fetchDonationFeedbacksByEmail(
      String email) async {
    final resultF = _api.getDataCollection();
    return resultF.then((result) {
      final _profiles = result.documents
          .where((doc) =>
              email != null && doc['feedbackBy'] == email && email.isNotEmpty)
          .map((doc) => DonationFeedback.fromMap(doc.data, doc.documentID))
          .toList();
      return _profiles;
    });
  }

  Future<bool> saveDonationFeedback(DonationFeedback data) async {
    final List<DonationFeedback> users =
        await fetchDonationFeedbacksByCodeAndEmail(
            data.donationCode, data.feedbackBy);
    if (users.isEmpty) {
      return _api.addDocument(data.toJson()).then((v) => v.documentID != null);
    } else {
      users.forEach((up) async {
        await _api
            .updateDocument(data.toJson(), up.userId)
            .then((v) => up.userId);
      });
      //return Future.value(users.map((f) => f.email).toList()[0]);
      return Future.value(true);
    }
  }
}
