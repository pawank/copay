import 'dart:ffi';
import 'dart:io';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contact_picker/contact_picker.dart' as contact_select;
import 'package:contacts_service/contacts_service.dart';
import 'package:copay/app/landing_page.dart';
import 'package:copay/common_widgets/avatar.dart';
import 'package:copay/common_widgets/loading.dart';
import 'package:copay/common_widgets/video_player_app.dart';
import 'package:copay/constants/keys.dart';
import 'package:copay/models/cloud_store_convertor.dart';
import 'package:copay/models/enhanced_user.dart';
import 'package:copay/models/request_call.dart';
import 'package:copay/screens/camera_app.dart';
import 'package:copay/screens/feedback_form.dart';
import 'package:copay/screens/request_calls.dart';
import 'package:copay/screens/txn.dart';
import 'package:copay/screens/upi_app.dart';
import 'package:copay/services/api.dart';
import 'package:copay/services/donation_api_impl.dart';
import 'package:copay/services/enhanced_user_api.dart';
import 'package:copay/services/enhanced_user_impl.dart';
import 'package:copay/services/request_call_impl.dart';
import 'package:currency_pickers/country.dart';
import 'package:currency_pickers/currency_picker_dropdown.dart';
import 'package:currency_pickers/utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_masked_text/flutter_masked_text.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upi_india/upi_india.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import '../util.dart';
import 'package:community_material_icon/community_material_icon.dart';
import 'dart:async';
import '../common_widgets/platform_alert_dialog.dart';
import '../common_widgets/platform_exception_alert_dialog.dart';
import '../constants/strings.dart';
import '../constants/constants.dart';
import '../services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class RaiseRequest extends StatefulWidget {
  RaiseRequest({@required this.user, @required this.code, this.callbackCamera, this.callbackVideo, @required this.requestOrDonation});
  final User user;
  final String code;
  final String callbackCamera;
  final String callbackVideo;
  final String requestOrDonation;
  @override
  _RaiseRequestState createState() => _RaiseRequestState(user, code,callbackCamera,callbackVideo, requestOrDonation);
}

class _RaiseRequestState extends State<RaiseRequest> {
  _RaiseRequestState(this.user, this.code, this.callbackCamera, this.callbackVideo, this.requestOrDonation);
  final User user;
  final String code;
  final String callbackCamera;
  final String callbackVideo;
  final String requestOrDonation;
  bool _isLoading = true;
  String _loadingMessage = 'Loading...';
  RequestCallRepo profileRepo;
  DonationRepo donationRepo;
  bool _saveEnabled = true;
  var index = 0;
  String email;
  bool individual = true;
  double amount = 0.00;
  String currency = '';
  String _identityType = '';
  String upiId = '';
  String imageUrl = null;
  String mediaUrl = null;
  RequestCall _requestCall;
  TextEditingController _titleController = TextEditingController(text: '');
  TextEditingController _fullnameController = TextEditingController(text: '');
  TextEditingController _phoneNoController = TextEditingController(text: '');
  TextEditingController _emailController = TextEditingController(text: '');
  TextEditingController _addressController = TextEditingController(text: '');
  TextEditingController _identityNoController = TextEditingController(text: '');
  TextEditingController _gstinController = TextEditingController(text: '');
  TextEditingController _upiIdController = TextEditingController(text: '');
  TextEditingController _medialController = TextEditingController(text: '');
  //TextEditingController _amountController = TextEditingController(text: '');
  MoneyMaskedTextController _amountController = new MoneyMaskedTextController(
      decimalSeparator: '.', thousandSeparator: ',', rightSymbol: ' US\$');
  TextEditingController _feedbackController = TextEditingController(text: '');
  File _image;
  String _profileUrl;
  String _imageUrl;
  String _mediaUrl;
  DialogState _dialogState = DialogState.DISMISSED;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  //Stream<QuerySnapshot> _callStream = null;
  //Function _callbackCameraF;
  //Function _callbackVideoF;
  String callbackCameraLink;
  String callbackVideoLink;
  int _selectedIndex = 0;
  final contact_select.ContactPicker _contactPicker = new contact_select.ContactPicker();
  contact_select.Contact _contact;
  String _friendContactEmail;
  dynamic _paymentData;
  UpiIndiaResponse2 _upiResponse;
  int _radioValue1 = -1;
  
  void _handleRadioValueChange1(int value) {
    setState(() {
      _radioValue1 = value;
      if (_radioValue1 == 0) {
                              _requestCall.individual = true;
                              individual = true;
      } else if (_radioValue1 == 1) {
                              _requestCall.individual = false;
                              individual = false;

      }
    });
  }

  //image / video
  Future<String> getCameraAndVideoPaths(String imageOrVideo) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (imageOrVideo != null) {
      String key = 'camera_image_path';
      if (imageOrVideo == 'video') {
        key = 'video_image_path';
      }
      if (prefs.containsKey(key)) {
        return Future.value(prefs.getString(key));
      }
    }
    return Future.value(null);
  }

  void callbackPayment(dynamic data) {
      _paymentData = data;
      print('Received payment data: $data');
  }

  String getLocalCurrency(BuildContext context) {
    Locale locale = Localizations.localeOf(context);
    final format = NumberFormat.simpleCurrency(locale: locale.toString());
    //print('CURRENCY SYMBOL ${format.currencySymbol}'); // $
    //print('CURRENCY NAME ${format.currencyName}'); // USD
    //final curr = '${format.currencyName}${format.currencySymbol} ';
    const String curr = 'INR ';
    return curr;
  }

  Future<void> getRequestByCodeStream(String code) {
    final streamQS = Firestore.instance
        .collection('request_calls')
        .where('code', isEqualTo: code)
        .snapshots();
       streamQS.toList().then((xs){
         if ((xs != null) && (xs.isNotEmpty)) {
            List<DocumentSnapshot> snapshots = xs.first.documents;
                if ((snapshots != null) && (snapshots.isNotEmpty)) {
                snapshots.forEach((document){
                    setState(() {
                    });
                });
                }
         }
       }); 
  }

  @override
  void initState() {
    super.initState();
    if ((user != null) && (user.email != null)) {
      email = user.email;
    }
    if (_requestCall != null && _requestCall.email != null) {
      email = _requestCall.email;
    }
    //getRequestByCodeStream(code);
  }

  @override
  void dispose() {
    _fullnameController?.dispose();
    _addressController?.dispose();
    _amountController?.dispose();
    _emailController?.dispose();
    _gstinController?.dispose();
    _identityNoController?.dispose();
    _upiIdController?.dispose();
    _phoneNoController?.dispose();
    _medialController?.dispose();
    _feedbackController?.dispose();
    _requestCall = null;
    _contact = null;
    profileRepo = null;
    donationRepo = null;
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
    } else if (state == AppLifecycleState.resumed) {
    setState(() {
    callbackCameraLink = callbackCamera;
    callbackVideoLink = callbackVideo;
    imageUrl = callbackCamera;
    });
    }
  }


  String getFullname() {
    if ((user != null) && (user.displayName != null)) {
      return user.displayName;
    }
    return '';
  }

  String getEmail() {
    if ((user != null) && (user.email != null)) {
      return user.email;
    }
    return '';
  }

  Future<String> loadImageFromFirebase(RequestCall u, String imageType) async {
    if (imageType == null) {
    if ((u.profileUrl != null) && (u.profileUrl.isNotEmpty)) {
      //_profileUrl = u.profileUrl;
      //StorageReference firebaseStorageRef = FirebaseStorage.instance.ref().child('gs://' + _profileUrl);
      final String bucket = 'gs://copay-9d0a7.appspot.com/' + u.profileUrl;
      print(bucket);
      Future<StorageReference> firebaseStorageRefF =
          FirebaseStorage.instance.getReferenceFromUrl(bucket);
      firebaseStorageRefF.then((firebaseStorageRef) async {
        final dynamic url = await firebaseStorageRef.getDownloadURL();
        if (url != null) {
          setState(() {
            _profileUrl = url;
          });
          return _profileUrl;
        }
      });
    }
    }
    if ((imageType != null) && (imageType == 'feedback')) {
    if ((u.imageUrl != null) && (u.imageUrl.isNotEmpty)) {
      //_profileUrl = u.profileUrl;
      //StorageReference firebaseStorageRef = FirebaseStorage.instance.ref().child('gs://' + _profileUrl);
      final String bucket = 'gs://copay-9d0a7.appspot.com/' + u.imageUrl;
      Future<StorageReference> firebaseStorageRefF =
          FirebaseStorage.instance.getReferenceFromUrl(bucket);
      firebaseStorageRefF.then((firebaseStorageRef) async {
        final dynamic url = await firebaseStorageRef.getDownloadURL();
        if (url != null) {
          setState(() {
            _imageUrl = url;
          });
          return _imageUrl;
        }
      });
    }
    }
    if ((imageType != null) && (imageType == 'video')) {
    if ((u.mediaUrl != null) && (u.mediaUrl.isNotEmpty)) {
      //_profileUrl = u.profileUrl;
      //StorageReference firebaseStorageRef = FirebaseStorage.instance.ref().child('gs://' + _profileUrl);
      final String bucket = 'gs://copay-9d0a7.appspot.com/' + u.mediaUrl;
      Future<StorageReference> firebaseStorageRefF =
          FirebaseStorage.instance.getReferenceFromUrl(bucket);
      firebaseStorageRefF.then((firebaseStorageRef) async {
        final dynamic url = await firebaseStorageRef.getDownloadURL();
        if (url != null) {
          setState(() {
            _mediaUrl = url;
          });
          return _mediaUrl;
        }
      });
    }
    }
    Future.value(null);
  }

  @override
  void didChangeDependencies() {
    profileRepo = Provider.of<RequestCallRepo>(context, listen: false);
    donationRepo = Provider.of<DonationRepo>(context, listen: false);
    setState(() {
    callbackCameraLink = callbackCamera;
    callbackVideoLink = callbackVideo;
    });
    getCameraAndVideoPaths('camera').then((onValue){
      setState(() {
        callbackCameraLink = onValue;
      });
    });
    getCameraAndVideoPaths('video').then((onValue){
      setState(() {
        callbackVideoLink = onValue;
      });
    });
    setState(() {
      _amountController = new MoneyMaskedTextController(
          decimalSeparator: '.',
          thousandSeparator: ',',
          leftSymbol: getLocalCurrency(context));
    });
    bool isrequestOrDonation = profileRepo != null && donationRepo != null;
    if (isrequestOrDonation) {
      final Future<List<RequestCall>> records = requestOrDonation == 'request' ? profileRepo.fetchRequestCallsByCode(code) : donationRepo.fetchRequestCallsByCode(code, user.email);
      records.then((users) {
        if ((users != null) && (users.isEmpty)) {
          _requestCall = RequestCall(
              userId: '',
              email: '',
              name: '',
              mobile: '',
              infoType: '',
              identityType: '',
              identityNo: '',
              txnRef: '',
              address: null,
              status: 'Pending');
        }
        users.forEach((u) {
          setState(() {
            _requestCall = u;
            //_emailController.text = u.email;
            loadImageFromFirebase(u, null);
            loadImageFromFirebase(u, 'feedback');
            loadImageFromFirebase(u, 'video');
      _saveEnabled = _requestCall.txnType != null && _requestCall.txnType != 'received';
  _titleController = TextEditingController(text: _requestCall.purpose);
  _fullnameController = TextEditingController(text: _requestCall.name);
  _phoneNoController = TextEditingController(text: _requestCall.mobile);
  _emailController = TextEditingController(text: _requestCall.email);
  _addressController = TextEditingController(text: _requestCall.address);
  _identityNoController = TextEditingController(text: _requestCall.identityNo);
  _gstinController = TextEditingController(text: _requestCall.website);
  _upiIdController = TextEditingController(text: _requestCall.upiId);
  _medialController = TextEditingController(text: _requestCall.mediaUrl);
  _feedbackController = TextEditingController(text: _requestCall.feedback);
      //email = requestOrDonation == 'request' ? _requestCall.owner['email'] : _requestCall.donor['email'];
      email = _requestCall.email;
      currency = _requestCall.currency;
      _identityType = _requestCall.identityType;
      individual = _requestCall.individual;
      upiId = _requestCall.upiId;
      imageUrl = _requestCall.imageUrl;
      mediaUrl = _requestCall.mediaUrl;
      amount = _requestCall.amount;
      _amountController.updateValue(amount);
      bool isIndividual = _requestCall != null && _requestCall.individual != null ? _requestCall.individual : true;
      if (isIndividual) {
        _radioValue1 = 0;
      } else if (isIndividual == false) {
        _radioValue1 = 1;
      }
      _saveEnabled = code == null || (code != null && code.isEmpty);
      //_isLoading = false;
          });
        });
      setState(() {
        _isLoading = false;
      });
      });
    } else {
      if ((user != null) && (user.displayName != null)) {
        _fullnameController.text = user.displayName;
      }
      if ((user != null) && (user.email != null)) {
        _emailController.text = user.email;
      }
      _requestCall = RequestCall(
          userId: '',
          email: '',
          name: '',
          mobile: '',
          infoType: '',
          identityType: '',
          identityNo: '',
          txnRef: '',
          address: null,
          status: 'Pending');
      _isLoading = false;
    }
    super.didChangeDependencies();
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      final AuthService auth = Provider.of<AuthService>(context, listen: false);
      Navigator.of(context).pop();
      await auth.signOut();
    } on PlatformException catch (e) {
      await PlatformExceptionAlertDialog(
        title: Strings.logoutFailed,
        exception: e,
      ).show(context);
    }
  }

  Future<void> sendFeedback(BuildContext context, RequestCall request) async {
            final data = await Navigator.push(
              context,
              MaterialPageRoute<String>(
                builder: (context) {
                  return FeedbackForm(user, code);
                },
              ),
            ) as String;
            print('Data found: $data');
            setState(() {
              if (data != null) {
              }
            });
  }

  Future<void> _deleteRequest(BuildContext context, RequestCall request) async {
    print('Doing deletion');
    final bool didRequestSignOut = await PlatformAlertDialog(
      title: 'Delete the Raised Request',
      content: 'The request will no longer be available for anyone to view',
      cancelActionText: Strings.cancel,
      defaultActionText: 'Delete',
    ).show(context);
    if (didRequestSignOut == true) {
    if (profileRepo != null) {
      profileRepo.removeRequestByCode(request.code).then((value){
                            Fluttertoast.showToast(
                                msg: 'Request has been successfully deleted',
                                toastLength: Toast.LENGTH_LONG,
                                gravity: ToastGravity.BOTTOM,
                                timeInSecForIosWeb: 1,
                                backgroundColor: Colors.black54,
                                textColor: Colors.white,
                                fontSize: 16.0);
                            Navigator.of(context).pop();
      });
    }
    }
  }

  Widget getMediaIconType(String value) {
    if ((value == null) || (value.isEmpty)) {
      return Icon(Icons.minimize, color: Colors.black);
    }
    return Icon(Icons.videocam, color: Colors.black);
  }


  Widget getIconType(String value) {
    if ((value == null) || (value.isEmpty)) {
      return Icon(Icons.minimize, color: Colors.black);
    }
    return Icon(Icons.check, color: Colors.black);
  }

  String getImageFilename(File _image) {
    if (_image != null) {
      String fileName = _image.path.split('/').reversed.first;
      String fullfileName = user.email != null ? user.email : 'files';
      fullfileName = fullfileName + '/' + fileName;
      return fullfileName;
    }
    return null;
  }

  String getFeedbackImage() {
    if (_imageUrl != null) {
      return _imageUrl;
    }
    if (_profileUrl != null) {
      return _profileUrl;
    }
    return null;
  }

  Future uploadPic(String imageUrl, bool isVideo) async {
    File image = _image;
    String title = 'Profile Picture uploaded';
    if (imageUrl != null) {
        image = new File(imageUrl);
        title = 'Photo Uploaded';
        if (isVideo) {
          title = 'Media Uploaded';
        }
    }
    if (image != null) {

    String fileName = getImageFilename(image);
    StorageReference firebaseStorageRef =
        FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask = firebaseStorageRef.putFile(image);
    StorageTaskSnapshot taskSnapshot = await uploadTask.onComplete;
    setState(() {
      print(title);
      //Scaffold.of(context).showSnackBar(SnackBar(content: Text('Profile Picture Uploaded')));
      Fluttertoast.showToast(
          msg: title,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black54,
          textColor: Colors.white,
          fontSize: 16.0);
    });
    }
  }
  
  Future<void> resetCameraAndVideoPaths(
      String imagePath, String videoPath) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('camera_image_path');
      await prefs.remove('video_image_path');
  }


  Future getImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);

    setState(() {
      _image = image;
      print('Image Path $_image');
      uploadPic(null, false);
    });
  }

  Widget _buildDropdownItem(Country country) => Container(
        child: Row(
          children: <Widget>[
            CurrencyPickerUtils.getDefaultFlagImage(country),
            SizedBox(
              width: 8.0,
            ),
            Text('+${country.currencyCode}(${country.isoCode})'),
          ],
        ),
      );

Future<void> share(String title, String desc, String link, String amount) async {
    await FlutterShare.share(
      title: '[CoPay] Need Help For: $title',
      text: 'Purpose: $desc\nDonation Request for: $amount\n\nRegards, CoPay',
      linkUrl: link,
      chooserTitle: title
    );
  }

  Future<void> shareFile(String title, String desc, String link, String amount) async {
    /*
    await FlutterShare.shareFile(
      title: '[CoPay] Need Help For: $title',
      text: desc,
      filePath: link,
      chooserTitle: title
    );*/
    await FlutterShare.share(
      title: '[CoPay] Need Help For: $title',
      text: 'Purpose: $desc\nDonation Request for: $amount\n\nRegards, CoPay',
      linkUrl: link,
      chooserTitle: title
    );
  }
  
  Future<bool> checkAndRequestPermissionForContacts() async {
    var status = await Permission.contacts.status;
    PermissionStatus permStatus = null;
    if (status.isUndetermined) {
      // We didn't ask for permission yet.
      permStatus = await Permission.contacts.request();
    } else if (status.isDenied) {
      permStatus = await Permission.contacts.request();
    } else if (status.isGranted) {
      permStatus = status;
    }
    if (permStatus.isGranted) {
      return Future.value(true);
    }
    return Future.value(false);
  }

Future<String> _asyncInputDialog(BuildContext context, String title) async {
  String email = '';
  return showDialog<String>(
    context: context,
    barrierDismissible: false, // dialog is dismissible with a tap on the barrier
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Contact Email Address'),
        content: new Row(
          children: <Widget>[
            new Expanded(
                child: new TextField(
              autofocus: true,
              decoration: new InputDecoration(
                  labelText: 'Friend Email Address', hintText: 'No email found in your contact. Please provide the same.'),
              onChanged: (value) {
                email = value;
              },
            ))
          ],
        ),
        actions: <Widget>[
          FlatButton(
            child: Text('Submit'),
            onPressed: () {
              setState(() {
                _friendContactEmail = email;
              });
              Navigator.of(context).pop(email);
            },
          ),
        ],
      );
    },
  );
}

String getPaymentDone() {
  String msg = 'Pay';
  bool status = false;
  if (_requestCall != null) {
    status = _requestCall.txnRef != null && _requestCall.txnRef.isNotEmpty && _requestCall.status == 'Paid';
  }
  if (!status) {
    status = _upiResponse != null && _upiResponse.status.toLowerCase() == 'success' && _upiResponse.transactionId != null && _upiResponse.transactionId.isNotEmpty;
  }
  if (status) {
    msg = 'SUCCESS';
  } else {
    if (_requestCall != null) {
      status = _requestCall.txnRef == null || _requestCall.txnRef.isEmpty || _requestCall.status == 'Payment Failed';
      msg = 'FAILED';
    }
    if (!status) {
      status = _upiResponse != null && _upiResponse.status.toLowerCase() == 'failure';
      msg = 'FAILED';
    } else {
        msg = 'Pay';
    }
  }
  return msg;
}

Future sendPaidEmailAndSMS(RequestCall call) async {
    final requestJson = {
   'owner': call.owner,
   'donor': call.donor,
   'currency': call.currency,
   'amount': call.amount,
   'campaign':{
      'id': call.code,
      'url': HttpApi.BASE_API,
      'message':_requestCall.purpose,
      'receiver':{
         'name':_requestCall.name
      }
   }
  };
                        final r = await HttpApi.confimDonationPaid(call.code, requestJson);
                            Fluttertoast.showToast(
                                msg: 'Payment Confirmation Sent',
                                toastLength: Toast.LENGTH_LONG,
                                gravity: ToastGravity.BOTTOM,
                                timeInSecForIosWeb: 1,
                                backgroundColor: Colors.green,
                                textColor: Colors.white,
                                fontSize: 16.0);
}

Future<String> callUpiPayment(UpiIndia upi) async {
            final data = await Navigator.push(
              context,
              MaterialPageRoute<String>(
                builder: (context) {
                  return UPIScreen(request: upi, donation: _requestCall,);
                },
              ),
            ) as String;
            //print('Data found: $data');
            setState(() {
              if (data != null) {
                _upiResponse = UpiIndiaResponse2(data);
              }
            });
            bool isSuccess = false;
            if ((_requestCall != null) && (_upiResponse != null)) {
              if (_upiResponse.status == 'failure') {
                _requestCall.txnType = 'failed';
                _requestCall.status = 'Payment Failed';
              }
              if (_upiResponse.status == 'success') {
                _requestCall.txnType = 'received';
                _requestCall.status = 'Paid';
                 isSuccess = true;
              }
                _requestCall.txnRef = _upiResponse.transactionId;
                _requestCall.paymentData = data;
                _requestCall.paymentOn = Timestamp.now();
                await donationRepo.saveRequestCall(_requestCall);
                await profileRepo.saveRequestCall(_requestCall);
                if (isSuccess) {
                            final double paidAmount = _upiResponse.amount;
                            final userRepo = Provider.of<EnhancedProfileRepo>(context, listen: false);
                            if (userRepo != null) {
                              final profile = await userRepo.fetchSingleEnhancedProfileByEmail(user.email,user.uid);
                              //profile.totalDonated += paidAmount;
                              //profile.donatedCount += 1;
                              //await userRepo.saveEnhancedProfile(profile);

                            final String docid = EnhancedUserApi.db_name + '/' + profile.id;
                            final DocumentReference postRef = Firestore.instance.document(docid);
await Firestore.instance
        .collection(EnhancedUserApi.db_name)
        .document(profile.id)
        .get()
        .then((DocumentSnapshot postSnapshot) {
Firestore.instance.runTransaction((Transaction tx) async {
  if (postSnapshot.exists) {
    int cnt = profile.donatedCount + 1;
    double v = profile.totalDonated + paidAmount;
    await tx.update(postRef, <String, dynamic>{'donatedCount': cnt, 'totalDonated': v, 'raisedCount': profile.raisedCount, 'totalRaised': profile.totalRaised});
  }
});
      // use ds as a snapshot
    });
    /*
await Firestore.instance.runTransaction((Transaction tx) async {
  DocumentSnapshot postSnapshot = await tx.get(postRef);
  if (postSnapshot.exists) {
    int cnt = profile.donatedCount + 1;
    double v = profile.totalDonated + paidAmount;
    await tx.update(postRef, <String, dynamic>{'donatedCount': cnt, 'totalDonated': v});
  }
});
*/
                            }
                  //Send paid email and SMS
                  await sendPaidEmailAndSMS(_requestCall);
                }
            }
            return Future.value(data);
}


Future<void> shareViaContactOrApps() async {
      final perm = await checkAndRequestPermissionForContacts();
      if (perm) {

      contact_select.Contact contact = await _contactPicker.selectContact();
              setState(() {
                _contact = contact;
              });
              if (_contact != null) {
                //print('Sending API request for contact = $_contact');
                // Get contacts matching a string
Iterable<Contact> users = await ContactsService.getContacts(query : _contact.fullName);
//print('No. of matching contact found = ${users.length} for query = ${_contact.fullName}');
users.take(1).forEach((c) async {
    String email = null;
    if (c.emails != null) {
      if (c.emails.isNotEmpty) {
        email = c.emails.firstWhere((e) => e.value.isNotEmpty).value;
      }
    }
    if ((email == null) || (email.isEmpty)) {
      final emailResult = await _asyncInputDialog(context, 'Found ${users.length} friends with matching name.');
      print(emailResult);
      email = _friendContactEmail;
    }
    final owner = {
      'name':user.displayName,
      'email':user.email
   };
   final donor = {
      'name':c.displayName,
      'email': email
   };
                final request_json = {
   'owner':owner,
   'donor': donor,
   'campaign':{
      'id': code,
      'url': HttpApi.BASE_API,
      'message':_requestCall.purpose,
      'receiver':{
         'name':_requestCall.name
      }
   }
};
                      final yesno = await PlatformAlertDialog(
                        title: 'Send Donation Request?',
                        content:
                            'You are asking ${c.displayName} for donation.',
                        cancelActionText: Strings.cancel,
                        defaultActionText: 'Send',
                      ).show(context);
                      if (yesno) {
                        setState(() {
                          _loadingMessage = 'Sending Donation Request.\nPlease wait...';
                          _isLoading = true;
                        });
                        //print('Request JSON = $request_json');
                        RequestCall donation = _requestCall;
                        donation.requestedOn = Timestamp.now();
                        donation.status = 'Created';
                        donation.donor = donor;
                        final bool status = await donationRepo.saveRequestCall(donation);
                        if (status) {
                            int shareNo = _requestCall.shared != null ? _requestCall.shared + 1 : 1;
                            //int donationNo = _requestCall.donated != null ? _requestCall.donated + 1 : 1;
                            _requestCall.shared = shareNo;
                            //_requestCall.donated = donationNo;
                            await profileRepo.saveRequestCall(_requestCall);
                            final r = await HttpApi.raiseCompaignRequestDonor(_requestCall.code, request_json);
                            Fluttertoast.showToast(
                                msg: 'Request Shared',
                                toastLength: Toast.LENGTH_LONG,
                                gravity: ToastGravity.BOTTOM,
                                timeInSecForIosWeb: 1,
                                backgroundColor: Colors.green,
                                textColor: Colors.white,
                                fontSize: 16.0);
                          };
                        } else {

                            Fluttertoast.showToast(
                                msg: 'Donation Save Error',
                                toastLength: Toast.LENGTH_LONG,
                                gravity: ToastGravity.BOTTOM,
                                timeInSecForIosWeb: 1,
                                backgroundColor: Colors.red,
                                textColor: Colors.white,
                                fontSize: 16.0);
                      }
                        setState(() {
                          _loadingMessage = 'Loading...';
                          _isLoading = false;
                        });
});
              }
      } else {

                            Fluttertoast.showToast(
                                msg: 'Contacts Permission Denied',
                                toastLength: Toast.LENGTH_LONG,
                                gravity: ToastGravity.BOTTOM,
                                timeInSecForIosWeb: 1,
                                backgroundColor: Colors.red,
                                textColor: Colors.white,
                                fontSize: 16.0);
      }
}

  Future<void> _onItemTapped(int index) async {
    //print('Tapped for action');
  setState(() {
    _selectedIndex = index;
  });
  switch(_selectedIndex) {
    case 0:
    //Navigator.of(context).pop();
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) {
                  return LandingPage(title: 'CoPay',);
                },
              ),
            );
      break;
      case 1:
      String paystatus = getPaymentDone();
      if (paystatus == 'SUCCESS') {
        String msg = 'Paid ${_requestCall.currency} ${_requestCall.amount}';
        if (_requestCall.paymentOn != null) {
                          DateTime dt = _requestCall.paymentOn.toDate();
                          String date = new DateFormat.yMMMMEEEEd('en_US').format(dt);
          msg = msg + ' on $date';
        }
                            Fluttertoast.showToast(
                                msg: msg,
                                toastLength: Toast.LENGTH_LONG,
                                gravity: ToastGravity.BOTTOM,
                                timeInSecForIosWeb: 1,
                                backgroundColor: Colors.green,
                                textColor: Colors.white,
                                fontSize: 16.0);
      } else {
    UpiIndia upi = new UpiIndia(
      app: UpiIndiaApps.GooglePay,
      receiverUpiId: _requestCall.upiId,
      receiverName: _requestCall.owner != null ? _requestCall.owner['name'] : user.displayName,
      transactionRefId: 'TXN${_requestCall.code}',
      transactionNote: 'Purpose: ${_requestCall.purpose}',
      amount: _requestCall.amount,
    );
    callUpiPayment(upi);
      }
        break;
      case 2:
                      final shareOrDonor = await PlatformAlertDialog(
                        title: 'Share with Donor via',
                        content:
                            'Your contacts or\nWhatsapp/Facebook etc',
                        cancelActionText: 'Others',
                        defaultActionText: 'Donor',
                      ).show(context);
                      if (!shareOrDonor) {
                      String amttext = '${_requestCall.currency} ${_requestCall.amount}';
                      if (_requestCall.mediaUrl != null) {
                      shareFile(_requestCall.name, _requestCall.purpose, _mediaUrl, amttext);

                      } else {
                      share(_requestCall.name, _requestCall.purpose, '', amttext);
                      }

                      } else {
                          await shareViaContactOrApps();
                      }
      break;

      default:
      break;
  }
}

  bool isDeleteAllowByStatus(RequestCall request) {
    if (request != null) {
      return !(request.status == 'Paid' || request.shared > 0 || request.donated > 0);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final RequestCallRepo profileRepo =
        Provider.of<RequestCallRepo>(context, listen: false);
    bool isShowAvatar =
        (user != null) && ((user.photoUrl != null) || (_profileUrl != null) || (callbackCameraLink != null));
      
    String feedbackurl = getFeedbackImage();
    String paystatus = getPaymentDone();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      /*
      theme: ThemeData(
        primaryColor: Colors.blue[900],
        accentColor: Colors.amber,
        accentColorBrightness: Brightness.dark
      ),
      */
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: Container(
        color: Theme.of(context).primaryColor,
        child: 
        new WillPopScope(
    onWillPop: () async => true,
    child: 
        Scaffold(
          backgroundColor: Colors.white,
          
          appBar: AppBar(
            title: Text(
              requestOrDonation == 'request' ? 'Raise A Request' : 'Donation Request',
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            //backgroundColor: Colors.blue,
            elevation: 0,
            leading: new IconButton(
              icon: new Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            actions: <Widget>[
              ((_requestCall != null) && (_requestCall.email != null) && (user != null) && (_requestCall.owner != null && _requestCall.owner['email'] == user.email) && isDeleteAllowByStatus(_requestCall)) ?
              IconButton(
                  key: Key(Keys.logout),
                  icon: Icon(CommunityMaterialIcons.trash_can),
                  color: Colors.redAccent,
                  onPressed: () async {
                    await _deleteRequest(context, _requestCall);
                  }) : Text(''),
              if (requestOrDonation == 'donation')
              IconButton(
                  key: Key('Feedback'),
                  icon: Icon(CommunityMaterialIcons.comment),
                  onPressed: () async {
                    await sendFeedback(context, _requestCall);
                  }),
            ],
          ),
          body: 
          /*
      StreamBuilder<QuerySnapshot>(
          stream: _callStream,
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) return Text('Error: ${snapshot.error}');
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return Text('Loading..');
              default:
                child:
                RequestCall obj = null;
                if (snapshot.hasData) {
                final List<DocumentSnapshot> docs = snapshot.data.documents;
                docs.forEach((document){
                        obj = CloudStoreConvertor.toObject(document);
                });
          return*/ 
          _isLoading == true ? LoadingScreen(message: _loadingMessage,) :
          SingleChildScrollView(
            child: 
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: 5),
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'Initiate Your Help',
                        style: TextStyle(
                            fontFamily: 'worksans',
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.black),
                      ),
                    ]),
                SizedBox(height: 10),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        controller: _titleController,
                        enabled: _saveEnabled,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.next,
                        maxLength: 300,
                        maxLengthEnforced: true,
                        maxLines: null,
                        decoration: InputDecoration(
                          labelText: 'Describe your cause',
                          helperText: 'What\'s your purpose of raising funds?',
                          labelStyle: TextStyle(color: Colors.black),
                          errorStyle: TextStyle(color: Colors.red),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: _titleController.text != '' ? BorderSide(color: Colors.black) : BorderSide(color: Colors.red),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          // contentPadding: EdgeInsets.only(top: 40, bottom: 20),
                          suffixIcon: Padding(
                            padding: const EdgeInsetsDirectional.only(
                                top: 18, start: 50),
                            child: getIconType(_titleController.text),
                          ),
                        ),
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Please provide reason (max 200 words)';
                          }
                        },
                        style: TextStyle(
                            fontFamily: 'worksans',
                            color: Colors.black,
                            fontSize: 18),
                        //initialValue: fullname,
                      ),
                      SizedBox(height: 10),
                      /*
                      CurrencyPickerDropdown(
                        initialValue: 'in',
                        itemBuilder: _buildDropdownItem,
                        onValuePicked: (Country country) {
                          //print(country.currencyCode);
                          //print(country.currencyName);
                          //print(country.iso3Code);
                          //print('${country.name}');
                          final String curr = '${country.currencyCode} ';
                          setState(() {
                            _amountController = new MoneyMaskedTextController(
                                decimalSeparator: '.',
                                thousandSeparator: ',',
                                leftSymbol: curr);
                          });
                        },
                      ),
                      */
                      TextFormField(
                        controller: _amountController,
                        enabled: _saveEnabled,
                        keyboardType: TextInputType.numberWithOptions(
                            signed: false, decimal: true),
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          helperText: 'How much do you want to raise?',
                          labelStyle: TextStyle(color: Colors.black),
                          errorStyle: TextStyle(color: Colors.red),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: _amountController.text != '' && _amountController.text != '0.00' ? BorderSide(color: Colors.black) : BorderSide(color: Colors.red),
                          ),
                          // contentPadding: EdgeInsets.only(top: 40, bottom: 20),
                          suffixIcon: Padding(
                            padding: const EdgeInsetsDirectional.only(
                                top: 18, start: 50),
                            child: getIconType(_amountController.text),
                          ),
                        ),
                        style: TextStyle(
                            fontFamily: 'worksans',
                            color: Colors.black,
                            fontSize: 18),
                        //initialValue: fullname,
                      ),
                      SizedBox(height: 5),
                      new Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text('For'),
                        new Radio(
                          value: 0,
                          groupValue: _radioValue1,
                          onChanged: _handleRadioValueChange1,
                        ),
                        new Text(
                          'Individual',
                          style: new TextStyle(fontSize: 16.0),
                        ),
                        new Radio(
                          value: 1,
                          groupValue: _radioValue1,
                          onChanged: _handleRadioValueChange1,
                        ),
                        new Text(
                          'Organisation',
                          style: new TextStyle(
                            fontSize: 16.0,
                          ),
                        ),
                      ],
                    ),
                    /*
                      SwitchListTile(
                          title: const Text('Individual \nor Org'),
                          secondary: Text('Campaign is for?'),
                          value: _requestCall != null &&
                                  _requestCall.individual != null
                              ? _requestCall.individual
                              : true,
                          onChanged: (bool val) =>
                              setState(() {
                                _requestCall.individual = val;
                                individual = val;
                              })),
                              */
                              Divider(),
                      SizedBox(height: 5),
                      TextFormField(
                        controller: _fullnameController,
                        enabled: _saveEnabled,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Beneficiary Details',
                          helperText: 'What\'s the full name of the beneficiary?',
                          labelStyle: TextStyle(color: Colors.black),
                          errorStyle: TextStyle(color: Colors.red),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: _fullnameController.text != '' ? BorderSide(color: Colors.black) : BorderSide(color: Colors.red),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          // contentPadding: EdgeInsets.only(top: 40, bottom: 20),
                          suffixIcon: Padding(
                            padding: const EdgeInsetsDirectional.only(
                                top: 18, start: 50),
                            child: getIconType(_fullnameController.text),
                          ),
                        ),
                        style: TextStyle(
                            fontFamily: 'worksans',
                            color: Colors.black,
                            fontSize: 18),
                        //initialValue: fullname,
                      ),
                      if (individual == false)
                      SizedBox(height: 10),
                      if (individual == false)
                      TextFormField(
                        controller: _gstinController,
                        enabled: _saveEnabled,
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Website or Organisation URL',
                          helperText: 'Where more information about the beneficiary can be obtained',
                          labelStyle: TextStyle(color: Colors.black),
                          errorStyle: TextStyle(color: Colors.red),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: _gstinController.text != '' ? BorderSide(color: Colors.black) : BorderSide(color: Colors.red),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          // contentPadding: EdgeInsets.only(top: 40, bottom: 20),
                          suffixIcon: Padding(
                            padding: const EdgeInsetsDirectional.only(
                                top: 18, start: 50),
                            child: getIconType(_gstinController.text),
                          ),
                        ),
                        style: TextStyle(
                            fontFamily: 'worksans',
                            color: Colors.black,
                            fontSize: 18),
                        //initialValue: fullname,
                      ),
                      if (requestOrDonation != 'donation')
                      SizedBox(height: 10),
                      if (requestOrDonation != 'donation')
                      TextFormField(
                        //readOnly: true,
                        //enabled: false,
                        controller: _emailController,
                        enabled: _saveEnabled,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          helperText: 'What\'s the beneficiary\'s email address? (optional)',
                          labelStyle: TextStyle(color: Colors.black),
                          errorStyle: TextStyle(color: Colors.red),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: _emailController.text != '' ? BorderSide(color: Colors.black) : BorderSide(color: Colors.black),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          // contentPadding: EdgeInsets.only(top: 40, bottom: 20),
                          suffixIcon: Padding(
                            padding: const EdgeInsetsDirectional.only(
                                top: 18, start: 50),
                            child: getIconType(_emailController.text),
                          ),
                        ),
                        style: TextStyle(
                            fontFamily: 'worksans',
                            color: Colors.black,
                            fontSize: 18),
                        //initialValue: email,
                      ),
                      if (requestOrDonation != 'donation')
                      SizedBox(height: 10),
                      if (requestOrDonation != 'donation')
                      TextFormField(
                        controller: _phoneNoController,
                        enabled: _saveEnabled,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Contact Number',
                          helperText: 'What is the beneficiary\'s phone number',
                          labelStyle: TextStyle(color: Colors.black),
                          errorStyle: TextStyle(color: Colors.red),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: _phoneNoController.text != '' ? BorderSide(color: Colors.black) : BorderSide(color: Colors.red),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          // contentPadding: EdgeInsets.only(top: 40, bottom: 20),
                          suffixIcon: Padding(
                            padding: const EdgeInsetsDirectional.only(
                                top: 18, start: 50),
                            child: getIconType(_phoneNoController.text),
                          ),
                        ),
                        style: TextStyle(
                            fontFamily: 'worksans',
                            color: Colors.black,
                            fontSize: 18),
                        //initialValue: phoneno,
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _addressController,
                        enabled: _saveEnabled,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.next,
                        maxLines: null,
                        decoration: InputDecoration(
                          labelText: 'Address',
                          helperText: 'What\'s the beneficiary\'s permanent address?',
                          labelStyle: TextStyle(color: Colors.black),
                          errorStyle: TextStyle(color: Colors.red),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: _addressController.text != '' ? BorderSide(color: Colors.black) : BorderSide(color: Colors.red),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          // contentPadding: EdgeInsets.only(top: 40, bottom: 20),
                          suffixIcon: Padding(
                            padding: const EdgeInsetsDirectional.only(
                                top: 18, start: 50),
                            child: getIconType(_addressController.text),
                          ),
                        ),
                        style: TextStyle(
                            fontFamily: 'worksans',
                            color: Colors.black,
                            fontSize: 18),
                        //initialValue: address,
                      ),
                      /*
                      SizedBox(height: 10),
                      DropdownButton<String>(
                        hint: Text('Identity Document Type'),
                        value: _requestCall != null &&
                                _requestCall.identityType != null
                            ? _requestCall.identityType
                            : 'Aadhaar No',
                        icon: Icon(Icons.arrow_downward),
                        iconSize: 24,
                        elevation: 16,
                        style: TextStyle(
                            fontFamily: 'worksans',
                            color: Colors.black,
                            fontSize: 18),
                        underline: Container(
                          height: 2,
                          color: Colors.black54,
                        ),
                        onChanged: (String newValue) {
                          setState(() {
                            _requestCall.identityType = newValue;
                          });
                        },
                        items: <String>[
                          'Aadhaar No',
                          'PAN Card',
                          'Voter ID',
                          'Passport No',
                          'Social Security No',
                          ''
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _identityNoController,
                        enabled: _saveEnabled,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Identity No',
                          labelStyle: TextStyle(color: Colors.black),
                          errorStyle: TextStyle(color: Colors.red),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: _identityNoController.text != '' ? BorderSide(color: Colors.black) : BorderSide(color: Colors.red),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          // contentPadding: EdgeInsets.only(top: 40, bottom: 20),
                          suffixIcon: Padding(
                            padding: const EdgeInsetsDirectional.only(
                                top: 18, start: 50),
                            child: getIconType(_identityNoController.text),
                          ),
                        ),
                        style: TextStyle(
                            fontFamily: 'worksans',
                            color: Colors.black,
                            fontSize: 18),
                        //initialValue: fullname,
                      ),*/
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _upiIdController,
                        enabled: _saveEnabled,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Your own UPI ID',
                          labelStyle: TextStyle(color: Colors.black),
                          errorStyle: TextStyle(color: Colors.red),
                          helperText: 'Where the payment will be desposited by the donor',
                          enabledBorder: UnderlineInputBorder(
                            borderSide: _upiIdController.text != '' ? BorderSide(color: Colors.black) : BorderSide(color: Colors.red),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          // contentPadding: EdgeInsets.only(top: 40, bottom: 20),
                          suffixIcon: Padding(
                            padding: const EdgeInsetsDirectional.only(
                                top: 18, start: 50),
                            child: getIconType(_upiIdController.text),
                          ),
                        ),
                        style: TextStyle(
                            fontFamily: 'worksans',
                            color: Colors.black,
                            fontSize: 18),
                        //initialValue: fullname,
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _medialController,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Add Photo or Video',
                          helperText: 'Use the camera button to upload a photo, video or an audio file for your campaign',
                          labelStyle: TextStyle(color: Colors.black),
                          errorStyle: TextStyle(color: Colors.red),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: _medialController.text != '' ? BorderSide(color: Colors.black) : BorderSide(color: Colors.orangeAccent),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          // contentPadding: EdgeInsets.only(top: 40, bottom: 20),
                          suffixIcon: Padding(
                            padding: const EdgeInsetsDirectional.only(
                                top: 18, start: 50),
                            child: 
                            IconButton(icon: getMediaIconType(_medialController.text),onPressed: (){
                                print('Starting media');
                final route = MaterialPageRoute<void>(
                  builder: (context) {
                    return AppVideoPlayer(title: _mediaUrl != null ? 'Playing ${_mediaUrl}' : 'Playing', mediaUrl: _mediaUrl,);
                  },
                );
             Navigator.of(context).push(route);
                            }
                            ),
                              
                          ),
                        ),
                        style: TextStyle(
                            fontFamily: 'worksans',
                            color: Colors.black,
                            fontSize: 18),
                        //initialValue: fullname,
                      ),
                SizedBox(height: 10),
                if (isShowAvatar)
                  feedbackurl != null ?
                  Avatar(
                    photoUrl: feedbackurl,
                    radius: 50,
                    borderColor: Colors.amberAccent,
                    borderWidth: 2.0,
                  ):CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.amberAccent,
                      child: ClipOval(
                        child: new SizedBox(
                          width: 90.0,
                          height: 90.0,
                          child: callbackCameraLink != null ? Image.file(
                            File(callbackCameraLink), 
                            fit: BoxFit.fill,
                          ) : Image(image: AssetImage('assets/app-logo.png')), 
                        ),
                      ),
                    ),
                  Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                Text(
                  callbackCameraLink != null ? callbackVideoLink != null ? 'Saved Photo and Media' : 'Saved Photo': 'No Photo Found',
                  semanticsLabel: 'Your uploaded media for the campaign',
                  style: TextStyle(
                      fontFamily: 'worksans',
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black),
                ),
                  Padding(
                    padding: EdgeInsets.only(left: 5.0),
                    child: IconButton(
                      icon: Icon(
                        FontAwesomeIcons.camera,
                        size: 20.0,
                      ),
                      onPressed: () {
                        //getImage();
                final route = MaterialPageRoute<void>(
                  builder: (context) {
                    _requestCall.email = user.email;
                    return CameraAppHome(user: user, code: code, requestCall: _requestCall);
                  },
                );
             Navigator.of(context).push(route);
                      },
                    ),
                  ),
                ]),
                /*
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _feedbackController,
                        enabled: _saveEnabled,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.next,
                        maxLines: null,
                        decoration: InputDecoration(
                          labelText: 'Feedback',
                          helperText: 'What\'s the beneficiary\'s feedback on the donation?',
                          labelStyle: TextStyle(color: Colors.black),
                          errorStyle: TextStyle(color: Colors.red),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: _feedbackController.text != '' ? BorderSide(color: Colors.black) : BorderSide(color: Colors.black),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          // contentPadding: EdgeInsets.only(top: 40, bottom: 20),
                          suffixIcon: Padding(
                            padding: const EdgeInsetsDirectional.only(
                                top: 18, start: 50),
                            child: getIconType(_feedbackController.text),
                          ),
                        ),
                        style: TextStyle(
                            fontFamily: 'worksans',
                            color: Colors.black,
                            fontSize: 18),
                        //initialValue: address,
                      ),
                      */
                    ],
                  ),
                ),
                SizedBox(height: 30),
                SizedBox(
                  height: 40,
                  width: double.infinity,
                  child: _saveEnabled == false ? 
                        Text('')
                  /*
                    RaisedButton(
                      color: Colors.blue,
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: Text('Share',style:
                        TextStyle(
                          fontFamily: 'worksans',
                          color: Colors.white,
                          fontSize: 18),
                    ),
                    onPressed: () {
                      String amttext = '${_requestCall.currency} ${_requestCall.amount}';
                      if (_requestCall.mediaUrl != null) {
                      shareFile(_requestCall.name, _requestCall.purpose, _mediaUrl, amttext);

                      } else {
                      share(_requestCall.name, _requestCall.purpose, '', amttext);
                      }
                    },
                    onLongPress: (){
                      String amttext = '${_requestCall.currency} ${_requestCall.amount}';
                      if (_requestCall.mediaUrl != null) {
                      shareFile(_requestCall.name, _requestCall.purpose, _mediaUrl, amttext);

                      } else {
                      share(_requestCall.name, _requestCall.purpose, '', amttext);
                      }
                    },
                    )*/
                  : 
                    RaisedButton(
                      color: Colors.indigo,
                      padding: const EdgeInsets.only(top: 10, bottom: 10),
                      child: Text('Save Request',style:
                        TextStyle(
                          fontFamily: 'worksans',
                          color: Colors.white,
                          fontSize: 18),
                    ),
                    onPressed: _saveEnabled == true ? () async {
                      //await _confirmSignOut(context);
                      print('Saving profile information');
                      /*
                      FirebaseAuth.instance.currentUser().then((val) {
                        UserUpdateInfo updateUser = UserUpdateInfo();
                        //updateUser.displayName = _;
                        //updateUser.photoUrl = ;
                        val.updateProfile(updateUser);
                      });
                      */
                        //_formKey.currentState.save();
                        setState(() => _dialogState = DialogState.LOADING);
                        String identityType = _requestCall.identityType;
                        var uuid = Uuid();
                        final owner = {
                            'name':user.displayName,
                            'email':user.email
                        };
                        RequestCall data = RequestCall(
                          userId: user.uid,
                          code: code != null && code.isNotEmpty
                              ? code
                              : uuid
                                  .v4()
                                  .split('-')
                                  .reversed
                                  .first
                                  .toUpperCase(),
                          email: _emailController.text.trim().toLowerCase(),
                          purpose: _titleController.text,
                          name: _fullnameController.text,
                          mobile: _phoneNoController.text,
                          address: _addressController.text,
                          txnType: 'pending',
                          identityType: identityType,
                          identityNo: _identityNoController.text,
                          individual:
                              individual ? individual : _requestCall.individual,
                          amount: _amountController.numberValue,
                          currency: _amountController.leftSymbol,
                          profileUrl: getImageFilename(_image),
                          website: _gstinController.text.toLowerCase(),
                          upiId: _upiIdController.text,
                          imageUrl: callbackCameraLink != null ? getImageFilename(File(callbackCameraLink)) : _requestCall.imageUrl,
                          mediaUrl: callbackVideoLink != null ? getImageFilename(File(callbackVideoLink)) : _requestCall.mediaUrl,
                          status: 'Created',
                          owner: owner
                        );
                        final String validationResult = data.validate();
                        bool status = validationResult == '';
                        if (status) {
                      
                      final yesno = await PlatformAlertDialog(
                        title: 'Send Request',
                        content:
                            'Please allow us to validate the request for you',
                        cancelActionText: Strings.cancel,
                        defaultActionText: 'Validate and Save',
                      ).show(context);
                      if (yesno == true) {
                      setState(() {
                        _saveEnabled = false;
                        _loadingMessage = 'Uploading photos, \nmedia and request. \nPlease wait...';
                        _isLoading = true;
                      });
                      
                        await uploadPic(callbackCameraLink, false);
                        await uploadPic(callbackVideoLink, true);
                          status = await profileRepo.saveRequestCall(data);
                          if (status) {
                            final userRepo = Provider.of<EnhancedProfileRepo>(context, listen: false);
                            if (userRepo != null) {
                              final profile = await userRepo.fetchSingleEnhancedProfileByEmail(user.email,user.uid);
                              //profile.totalRaised += data.amount;
                              //profile.raisedCount += 1;
                              //await userRepo.saveEnhancedProfile(profile);
                            final String docid = EnhancedUserApi.db_name + '/' + profile.id;
                            final DocumentReference postRef = Firestore.instance.document(docid);
await Firestore.instance
        .collection(EnhancedUserApi.db_name)
        .document(profile.id)
        .get()
        .then((DocumentSnapshot postSnapshot) {
Firestore.instance.runTransaction((Transaction tx) async {
  if (postSnapshot.exists) {
    int cnt = profile.raisedCount + 1;
    double v = profile.totalRaised + data.amount;
    await tx.update(postRef, <String, dynamic>{'donatedCount': profile.donatedCount, 'totalDonated': profile.totalDonated, 'raisedCount': cnt, 'totalRaised': v});
  }
});
      // use ds as a snapshot
    });
                            }
                            await resetCameraAndVideoPaths(null, null);
                            //print('Saved profile information');
                            Fluttertoast.showToast(
                                msg: 'Request has been successfully submitted',
                                toastLength: Toast.LENGTH_LONG,
                                gravity: ToastGravity.BOTTOM,
                                timeInSecForIosWeb: 1,
                                backgroundColor: Colors.black54,
                                textColor: Colors.white,
                                fontSize: 16.0);
                final route = MaterialPageRoute<void>(
                  builder: (context) {
                    //final EnhancedProfileRepo profileRepo = Provider.of<EnhancedProfileRepo>(context);
                    return RequestCallScreen(user: user, code: '');
                  },
                );
             Navigator.of(context).push(route);
                          } else {
                            Fluttertoast.showToast(
                                msg: 'Request Call cannot be saved',
                                toastLength: Toast.LENGTH_LONG,
                                gravity: ToastGravity.BOTTOM,
                                timeInSecForIosWeb: 1,
                                backgroundColor: Colors.red,
                                textColor: Colors.white,
                                fontSize: 16.0);
                          }

                          setState(() {
                            _loadingMessage = 'Loading...';
                            _isLoading = false;
                          });
                      }
                        } else {
                          Fluttertoast.showToast(
                              msg: validationResult,
                              toastLength: Toast.LENGTH_LONG,
                              gravity: ToastGravity.BOTTOM,
                              timeInSecForIosWeb: 1,
                              backgroundColor: Colors.red,
                              textColor: Colors.white,
                              fontSize: 16.0);
                        }
                        setState(() => _dialogState = DialogState.COMPLETED);
                        setState(() => _dialogState = DialogState.DISMISSED);
                    } : null,
                  ),
                ),
                MyDialog(
                  state: _dialogState,
                ),
              ],
            ),
          ),
        bottomNavigationBar: 
        _saveEnabled == false ?
        BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          unselectedItemColor: Colors.blue,
          selectedItemColor: Theme.of(context).primaryColorDark,
          //unselectedItemColor: Theme.of(context).primaryColor,
          //selectedItemColor: Theme.of(context).primaryColorDark,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              activeIcon: Icon(Icons.home),
              title: Text('Home'),
            ),
            BottomNavigationBarItem(
              icon: _upiResponse == null ? paystatus != 'SUCCESS' ? Icon(Icons.payment) : Icon(Icons.done_all) : paystatus == 'FAILED' ? Icon(Icons.error) : Icon(Icons.payment),
              title: Text(paystatus == 'SUCCESS' ? 'Paid' : 'Pay'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.share),
              activeIcon: Icon(Icons.share),
              title: Text('Share'),
            ),
            /*
            BottomNavigationBarItem(
              icon: Icon(Icons.send),
              activeIcon: Icon(Icons.send),
              title: Text('Donor'),
            ),
            */
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          ) : Text(''),
        ),
        ),
      ),
    );
  }
}

enum DialogState {
  LOADING,
  COMPLETED,
  DISMISSED,
}

class MyDialog extends StatelessWidget {
  final DialogState state;
  MyDialog({this.state});

  @override
  Widget build(BuildContext context) {
    return state == DialogState.DISMISSED
        ? Container()
        : AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(10.0),
              ),
            ),
            content: Container(
              width: 250.0,
              height: 100.0,
              child: state == DialogState.LOADING
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        Padding(
                          padding: const EdgeInsets.only(left: 10.0),
                          child: Text(
                            'Please Wait...',
                            style: TextStyle(
                              fontFamily: 'OpenSans',
                              color: Color(0xFF5B6978),
                            ),
                          ),
                        )
                      ],
                    )
                  : Center(
                      child: Text('Data loaded with success'),
                    ),
            ),
          );
  }
}
