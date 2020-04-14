import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:copay/models/request_call.dart';

class CloudStoreConvertor {
  static void showInfo(dynamic value) {
    print('Showing type for $value = ${value.runtimeType}');
  }

  static String getValue(DocumentSnapshot doc, String value) {
    if (doc[value] != null) {
      return doc[value];
    }
    return '';
  }

  static RequestCall toObject(DocumentSnapshot doc) {
    try {
      final List<String> _tags = doc['tags'] != null ? List<String>.from(doc['tags']) : List<String>();
      final Map<String, String> owner = doc['owner'] != null
          ? Map<String, String>.from(doc['owner'])
          : Map<String, String>();
      final Map<String, String> donor = doc['donor'] != null
          ? Map<String, String>.from(doc['donor'])
          : Map<String, String>();

      return RequestCall(userId: getValue(doc, 'userId'),
          code: getValue(doc, 'code'),
          email: getValue(doc, 'email'),
          purpose: getValue(doc, 'purpose'),
          name: getValue(doc, 'name'),
          mobile: getValue(doc, 'mobile'),
          infoType: getValue(doc, 'infoType'),
          address: getValue(doc, 'address'),
          identityType: getValue(doc, 'identityType'),
          identityNo: getValue(doc, 'identityNo'),
          createdOn: doc['createdOn'] != null ? doc['createdOn'] as Timestamp : Timestamp.now(),
          profileUrl: getValue(doc, 'profileUrl'),
          individual: doc['individual'] != null ? doc['individual'] as bool : true,
          amount: doc['amount'],
          currency: getValue(doc, 'currency'),
          txnRef: getValue(doc, 'txnRef'),
          txnType: getValue(doc, 'txnType'),
          status: getValue(doc, 'status'),
          imageUrl: getValue(doc, 'imageUrl'),
          mediaUrl: getValue(doc, 'mediaUrl'),
          feedback: getValue(doc, 'feedback'),
          upiId: getValue(doc, 'upiId'),
          website: getValue(doc, 'website'),
          updatedOn: doc['updatedOn'] != null ? doc['updatedOn'] as Timestamp : Timestamp.now(),
          requestedOn: doc['requestedOn'] != null ? doc['requestedOn'] as Timestamp : Timestamp.now(),
          owner: owner,
          donor: donor,
          paymentOn: doc['paymentOn'] != null ? doc['paymentOn'] as Timestamp : Timestamp.now()
          );
    
    } catch (e) {
      print(e);
    }
    return null;
  }
}