import 'dart:ffi';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:copay/common_widgets/avatar.dart';
import 'package:copay/constants/keys.dart';
import 'package:copay/models/cloud_store_convertor.dart';
import 'package:copay/models/enhanced_user.dart';
import 'package:copay/models/request_call.dart';
import 'package:copay/screens/request_calls.dart';
import 'package:copay/screens/txn.dart';
import 'package:copay/services/enhanced_user_impl.dart';
import 'package:copay/services/request_call_impl.dart';
import 'package:currency_pickers/country.dart';
import 'package:currency_pickers/currency_picker_dropdown.dart';
import 'package:currency_pickers/utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_masked_text/flutter_masked_text.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
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
  RaiseRequest({@required this.user, @required this.code});
  final User user;
  final String code;
  @override
  _RaiseRequestState createState() => _RaiseRequestState(user, code);
}

class _RaiseRequestState extends State<RaiseRequest> {
  _RaiseRequestState(this.user, this.code);
  final User user;
  final String code;
  bool _isLoading = true;
  RequestCallRepo profileRepo;
  bool _saveEnabled = true;
  var index = 0;
  String email;
  bool individual = true;
  double amount = 0.00;
  String currency = '';
  String _identityType = '';
  RequestCall _requestCall;
  TextEditingController _titleController = TextEditingController(text: '');
  TextEditingController _fullnameController = TextEditingController(text: '');
  TextEditingController _phoneNoController = TextEditingController(text: '');
  TextEditingController _emailController = TextEditingController(text: '');
  TextEditingController _addressController = TextEditingController(text: '');
  TextEditingController _identityNoController = TextEditingController(text: '');
  //TextEditingController _amountController = TextEditingController(text: '');
  MoneyMaskedTextController _amountController = new MoneyMaskedTextController(
      decimalSeparator: '.', thousandSeparator: ',', rightSymbol: ' US\$');
  File _image;
  String _profileUrl;
  DialogState _dialogState = DialogState.DISMISSED;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  //Stream<QuerySnapshot> _callStream = null;

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
    if (user.email != null) {
      email = user.email;
    }
      //getRequestByCodeStream(code);
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

  Future<String> loadImageFromFirebase(RequestCall u) async {
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
    Future.value(null);
  }

  @override
  void didChangeDependencies() {
    profileRepo = Provider.of<RequestCallRepo>(context, listen: false);
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
            loadImageFromFirebase(u);
      _saveEnabled = _requestCall.txnType != null && _requestCall.txnType != 'received';
  _titleController = TextEditingController(text: _requestCall.purpose);
  _fullnameController = TextEditingController(text: _requestCall.name);
  _phoneNoController = TextEditingController(text: _requestCall.mobile);
  _emailController = TextEditingController(text: _requestCall.email);
  _addressController = TextEditingController(text: _requestCall.address);
  _identityNoController = TextEditingController(text: _requestCall.identityNo);
      currency = _requestCall.currency;
      _identityType = _requestCall.identityType;
      individual = _requestCall.individual;
      amount = _requestCall.amount;
      _amountController.updateValue(amount);
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

  Future<void> _confirmSignOut(BuildContext context) async {
    print('Doing logout for user');
    final bool didRequestSignOut = await PlatformAlertDialog(
      title: Strings.logout,
      content: Strings.logoutAreYouSure,
      cancelActionText: Strings.cancel,
      defaultActionText: Strings.logout,
    ).show(context);
    if (didRequestSignOut == true) {
      _signOut(context);
    }
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

  Future uploadPic() async {
    String fileName = getImageFilename(_image);
    StorageReference firebaseStorageRef =
        FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask = firebaseStorageRef.putFile(_image);
    StorageTaskSnapshot taskSnapshot = await uploadTask.onComplete;
    setState(() {
      print('Profile Picture uploaded');
      //Scaffold.of(context).showSnackBar(SnackBar(content: Text('Profile Picture Uploaded')));
      Fluttertoast.showToast(
          msg: 'Profile picture uploaded',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black54,
          textColor: Colors.white,
          fontSize: 16.0);
    });
  }

  Future getImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);

    setState(() {
      _image = image;
      print('Image Path $_image');
      uploadPic();
    });
  }

  Widget _buildDropdownItem(Country country) => Container(
        child: Row(
          children: <Widget>[
            CurrencyPickerUtils.getDefaultFlagImage(country),
            SizedBox(
              width: 8.0,
            ),
            Text("+${country.currencyCode}(${country.isoCode})"),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final RequestCallRepo profileRepo =
        Provider.of<RequestCallRepo>(context, listen: false);
    bool isShowAvatar =
        (user != null) && ((user.photoUrl != null) || (_profileUrl != null));

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
              /*
              IconButton(
                  key: Key(Keys.logout),
                  icon: Icon(CommunityMaterialIcons.logout_variant),
                  color: Colors.black54,
                  onPressed: () async {
                    await _confirmSignOut(context);
                  }),*/
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
                          //print("${country.name}");
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
                          title: const Text('Individual or Company'),
                          value: _requestCall != null &&
                                  _requestCall.individual != null
                              ? _requestCall.individual
                              : true,
                          onChanged: (bool val) =>
                              setState(() => _requestCall.individual = val)),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _fullnameController,
                        enabled: _saveEnabled,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Person / Company',
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
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                SizedBox(
                  width: 200,
                  child: _saveEnabled == false ? Text(_requestCall.status) : FlatButton(
                    color: CustomColors.LightGrey,
                    textColor: CustomColors.DarkBlue,
                    
                    child: Text(
                      'Save Request',
                      style: TextStyle(
                          fontFamily: 'worksans',
                          color: CustomColors.DarkBlue,
                          fontSize: 18),
                    ),
                    onPressed: _saveEnabled == true ? () async {
                      //await _confirmSignOut(context);
                      setState(() {
                        _saveEnabled = false;
                      });
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
                          status = await profileRepo.saveRequestCall(data);
                          if (status) {
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                ),
                MyDialog(
                  state: _dialogState,
                ),
              ],
            ),
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
                            "Exporting...",
                            style: TextStyle(
                              fontFamily: "OpenSans",
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
