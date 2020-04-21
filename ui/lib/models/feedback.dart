import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DonationFeedback {
  String id;
  String userId;
  String feedback;
  String imageUrl;
  String videoUrl;
  double rating = 0.00;
  String donationCode;
  String feedbackBy;
  String feedbackOwner;
  Timestamp at;

  DonationFeedback(
      {this.id,
        @required this.userId,
        @required this.feedback,
        this.imageUrl,
        this.videoUrl,
        this.rating,
        this.donationCode,
        this.feedbackBy,
        this.feedbackOwner,
        this.at
      });

  DonationFeedback.fromMap(Map snapshot, String id)
      : id = id ?? null,
        userId = id ?? '',
        feedback = snapshot['feedback'] ?? '',
        imageUrl = snapshot['imageUrl'] ?? '',
        videoUrl = snapshot['videoUrl'] ?? '',
        rating = snapshot['rating'].toDouble() ?? 0.00,
        donationCode = snapshot['donationCode'] ?? '',
        feedbackBy = snapshot['feedbackBy'] ?? '',
        feedbackOwner = snapshot['feedbackOwner'] ?? '',
        at = snapshot['at'] != null
            ? (snapshot['at'] as Timestamp)
            : null;
  
  DonationFeedback.fromSnapshot(DocumentSnapshot snapshot, String id)
      : id = id ?? null,
        userId = id ?? '',
        feedback = snapshot['feedback'] ?? '',
        imageUrl = snapshot['imageUrl'] ?? '',
        videoUrl = snapshot['videoUrl'] ?? '',
        rating = snapshot['rating'].toDouble() ?? 0.00,
        donationCode = snapshot['donationCode'] ?? '',
        feedbackBy = snapshot['feedbackBy'] ?? '',
        feedbackOwner = snapshot['feedbackOwner'] ?? '',
        at = snapshot['at'] != null
            ? (snapshot['at'] as Timestamp)
            : null;

  dynamic toJson() {
    return {
      'id': id,
      'userId': userId,
      'feedback': feedback,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'rating': rating,
      'donationCode': donationCode,
      'feedbackBy': feedbackBy,
      'feedbackOwner': feedbackOwner,
      'at': Timestamp.now()
    };
  }
}
