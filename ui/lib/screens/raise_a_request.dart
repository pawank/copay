import 'dart:ffi';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:chewie/chewie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contact_picker/contact_picker.dart' as contact_select;
import 'package:contacts_service/contacts_service.dart';
import 'package:copay/app/landing_page.dart';
import 'package:copay/common_widgets/avatar.dart';
import 'package:copay/common_widgets/video_player_app.dart';
import 'package:copay/constants/keys.dart';
import 'package:copay/models/cloud_store_convertor.dart';
import 'package:copay/models/enhanced_user.dart';
import 'package:copay/models/request_call.dart';
import 'package:copay/screens/camera_app.dart';
import 'package:copay/screens/request_calls.dart';
import 'package:copay/screens/txn.dart';
import 'package:copay/services/api.dart';
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
  RaiseRequest({@required this.user, @required this.code, this.callbackCamera, this.callbackVideo});
  final User user;
  final String code;
  final String callbackCamera;
  final String callbackVideo;
  @override
  _RaiseRequestState createState() => _RaiseRequestState(user, code,callbackCamera,callbackVideo);
}

class _RaiseRequestState extends State<RaiseRequest> {
  _RaiseRequestState(this.user, this.code, this.callbackCamera, this.callbackVideo);
  final User user;
  final String code;
  final String callbackCamera;
  final String callbackVideo;
  bool _isLoading = true;
  RequestCallRepo profileRepo;
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
    _requestCall = null;
    _contact = null;
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
    if (profileRepo != null) {
      profileRepo.fetchRequestCallsByCode(code).then((users) {
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
      currency = _requestCall.currency;
      _identityType = _requestCall.identityType;
      individual = _requestCall.individual;
      upiId = _requestCall.upiId;
      imageUrl = _requestCall.imageUrl;
      mediaUrl = _requestCall.mediaUrl;
      amount = _requestCall.amount;
      _amountController.updateValue(amount);
      _saveEnabled = code == null || (code != null && code.isEmpty);
      _isLoading = false;
          });
        });
      });
      setState(() {
      _isLoading = false;
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
      text: 'Purpose: $desc\nDonation Request for: $amount',
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
      text: 'Purpose: $desc\nDonation Request for: $amount',
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

Future<String> _asyncInputDialog(BuildContext context) async {
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
                  labelText: 'Friend email address', hintText: 'No email found in your contact. Please provide the same.'),
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

  Future<void> _onItemTapped(int index) async {
    print('Tapped for action');
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
                      String amttext = '${_requestCall.currency} ${_requestCall.amount}';
                      if (_requestCall.mediaUrl != null) {
                      shareFile(_requestCall.name, _requestCall.purpose, _mediaUrl, amttext);

                      } else {
                      share(_requestCall.name, _requestCall.purpose, '', amttext);
                      }
      break;
      case 2:
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
print('No. of matching contact found = ${users.length} for query = ${_contact.fullName}');
users.forEach((c) async {
    String email = null;
    if (c.emails != null) {
      if (c.emails.isNotEmpty) {
        email = c.emails.firstWhere((e) => e.value.isNotEmpty).value;
      }
    }
    if ((email == null) || (email.isEmpty)) {
      final emailResult = await _asyncInputDialog(context);
      print(emailResult);
      email = _friendContactEmail;
    }
                final request_json = {
   'owner':{
      'name':user.displayName,
      'email':user.email
   },
   'donor':{
      'name':c.displayName,
      'email': email
   },
   'campaign':{
      'id':1,
      'url':'https://api.copay.foundation',
      'message':_requestCall.purpose,
      'receiver':{
         'name':_requestCall.name
      }
   }
};
        print('Request JSON = $request_json');
        final r = await HttpApi.raiseCompaignRequestDonor(request_json);
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
      break;

      default:
      break;
  }
}

  @override
  Widget build(BuildContext context) {
    final RequestCallRepo profileRepo =
        Provider.of<RequestCallRepo>(context, listen: false);
    bool isShowAvatar =
        (user != null) && ((user.photoUrl != null) || (_profileUrl != null) || (callbackCameraLink != null));
      
    String feedbackurl = getFeedbackImage();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Container(
        child: 
        new WillPopScope(
    onWillPop: () async => true,
    child: 
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(
              'Raise A Request',
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            backgroundColor: Colors.blue,
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
              ((_requestCall != null) && (_requestCall.email != null) && (user != null) && (_requestCall.email == user.email)) ?
              IconButton(
                  key: Key(Keys.logout),
                  icon: Icon(CommunityMaterialIcons.trash_can),
                  color: Colors.redAccent,
                  onPressed: () async {
                    await _deleteRequest(context, _requestCall);
                  }) : Text(''),
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
          _isLoading == true ? Text('Loading...', style: TextStyle(fontSize: 20, color: Colors.blue),) :
          SingleChildScrollView(
            child: Column(
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
                          labelText: 'Call Reason',
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
                      TextFormField(
                        controller: _amountController,
                        enabled: _saveEnabled,
                        keyboardType: TextInputType.numberWithOptions(
                            signed: false, decimal: true),
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Amount',
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
                      SizedBox(height: 10),
                      SwitchListTile(
                          title: const Text('Individual or Org'),
                          value: _requestCall != null &&
                                  _requestCall.individual != null
                              ? _requestCall.individual
                              : true,
                          onChanged: (bool val) =>
                              setState(() {
                                _requestCall.individual = val;
                                individual = val;
                              })),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _fullnameController,
                        enabled: _saveEnabled,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Person / Organization',
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
                          labelText: 'Website / Org URL',
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
                      SizedBox(height: 10),
                      TextFormField(
                        //readOnly: true,
                        //enabled: false,
                        controller: _emailController,
                        enabled: _saveEnabled,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Primary Email Address',
                          labelStyle: TextStyle(color: Colors.black),
                          errorStyle: TextStyle(color: Colors.red),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: _emailController.text != '' ? BorderSide(color: Colors.black) : BorderSide(color: Colors.red),
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
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _phoneNoController,
                        enabled: _saveEnabled,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Contact Number',
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
                          labelText: 'Valid Full Address',
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
                          labelText: 'UPI ID',
                          labelStyle: TextStyle(color: Colors.black),
                          errorStyle: TextStyle(color: Colors.red),
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
                        enabled: _saveEnabled,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Audio / Video Link',
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
                SizedBox(height: 5),
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
                      color: Colors.blue,
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
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
                          email: user.email,
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
                          upiId: _upiIdController.text,
                          imageUrl: callbackCameraLink != null ? getImageFilename(File(callbackCameraLink)) : _requestCall.imageUrl,
                          mediaUrl: callbackVideoLink != null ? getImageFilename(File(callbackVideoLink)) : _requestCall.mediaUrl,
                          status: 'Requested',

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
                      });
                      
                        await uploadPic(callbackCameraLink, false);
                        await uploadPic(callbackVideoLink, true);
                          status = await profileRepo.saveRequestCall(data);
                          if (status) {
                            await resetCameraAndVideoPaths(null, null);
                            print('Saved profile information');
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
        bottomNavigationBar: BottomNavigationBar(
          unselectedItemColor: Theme.of(context).primaryColor,
          selectedItemColor: Theme.of(context).primaryColor,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              activeIcon: Icon(Icons.home),
              title: Text('Home'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.share),
              title: Text('Share'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.send),
              title: Text('Request Contact'),
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          ),
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
