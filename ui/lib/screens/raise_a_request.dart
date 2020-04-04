import 'dart:ffi';
import 'dart:io';

import 'package:copay/common_widgets/avatar.dart';
import 'package:copay/constants/keys.dart';
import 'package:copay/models/enhanced_user.dart';
import 'package:copay/models/request_call.dart';
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
  RaiseRequest({@required this.user});
  final User user;
  @override
  _RaiseRequestState createState() => _RaiseRequestState(user);
}

class _RaiseRequestState extends State<RaiseRequest> {
  _RaiseRequestState(this.user);
  final User user;
  RequestCallRepo profileRepo;
  var index = 0;
  String email;
  bool individual = true;
  double amount = 0.00;
  String currency = '';
  RequestCall _requestCall;
  TextEditingController _titleController = TextEditingController(text: '');
  TextEditingController _fullnameController = TextEditingController(text: '');
  TextEditingController _phoneNoController = TextEditingController(text: '');
  TextEditingController _emailController = TextEditingController(text: '');
  TextEditingController _addressController = TextEditingController(text: '');
  TextEditingController _identityNoController = TextEditingController(text: '');
  //TextEditingController _amountController = TextEditingController(text: '');
  MoneyMaskedTextController _amountController = new MoneyMaskedTextController(decimalSeparator: '.', thousandSeparator: ',', rightSymbol: ' US\$');
  TextEditingController _summaryController = TextEditingController(text: '');
  File _image;
  String _profileUrl;

String getLocalCurrency(BuildContext context) {
    Locale locale = Localizations.localeOf(context);
    final format = NumberFormat.simpleCurrency(locale: locale.toString());
    //print('CURRENCY SYMBOL ${format.currencySymbol}'); // $
    //print('CURRENCY NAME ${format.currencyName}'); // USD
    //final curr = '${format.currencyName}${format.currencySymbol} ';
    const String curr = 'INR ';
    return curr;
}
  @override
  void initState() {
    super.initState();
    if (user.email != null) {
      email = user.email;
    }

    /*
      final Future<QuerySnapshot> userJobsF = Firestore.instance
          .collection(Constants.jobsCollection)
          .getDocuments();
      userJobsF.then((docs) {
        print('No of matches docs: ${docs.documents.length}');
        docs.documents.forEach((doc) {
          print('DOC: $doc');
          if (doc.documentID == documentID) {
            setState(() {
              document = doc;
              print('Doc state updated: $document');
            });
    }
        });
      });*/
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
       Future<StorageReference> firebaseStorageRefF = FirebaseStorage.instance.getReferenceFromUrl(bucket);
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
      _amountController = new MoneyMaskedTextController(decimalSeparator: '.', thousandSeparator: ',', leftSymbol: getLocalCurrency(context));
    });
    if (profileRepo != null) {
      profileRepo.fetchRequestCallsByUsername(email).then((users) {
        if ((users != null) && (users.isEmpty)) {
           if ((user != null) && (user.displayName != null)) {
              _fullnameController.text = user.displayName;
            }
           if ((user != null) && (user.email != null)) {
              _emailController.text = user.email;
            }
            _requestCall = RequestCall(userId: '', email: '', name: '', mobile: '', infoType: '', identityType: '', identityNo: '', txnRef: '', address: null);
        }
        users.forEach((u) {
          setState(() {
            _requestCall = u;
            //_emailController.text = u.email;
            loadImageFromFirebase(u);
            _fullnameController.text = u.name;
            if ((u.name == null) || (u.name.isEmpty)) {
              _fullnameController.text = '';
            }
           if ((user != null) && (user.displayName != null)) {
             if (_fullnameController.text.isEmpty) {
              _fullnameController.text = user.displayName;
             }
            }
            _phoneNoController.text = u.mobile;
            if (u.mobile == null) {
              _phoneNoController.text = '';
            }
            _addressController.text = u.address;
            if (u.address == null) {
              _addressController.text = '';
            }
            if (u.email != null) {
              _emailController.text = u.email;
            }
          });
        });
      });
    } else {
           if ((user != null) && (user.displayName != null)) {
              _fullnameController.text = user.displayName;
            }
           if ((user != null) && (user.email != null)) {
              _emailController.text = user.email;
            }
            _requestCall = RequestCall(userId: '', email: '', name: '', mobile: '', infoType: '', identityType: '', identityNo: '', txnRef: '', address: null);
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

  Future uploadPic() async{
      String fileName = getImageFilename(_image);
       StorageReference firebaseStorageRef = FirebaseStorage.instance.ref().child(fileName);
       StorageUploadTask uploadTask = firebaseStorageRef.putFile(_image);
       StorageTaskSnapshot taskSnapshot=await uploadTask.onComplete;
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
        fontSize: 16.0
    );
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
    final RequestCallRepo profileRepo = Provider.of<RequestCallRepo>(context, listen: false);
    String nameOfPerson = 'Hello, Guest';
    String fullname = '';
    String phoneno = '';
    String address = '';
    if ((user != null) && (user.displayName != null)) {
      nameOfPerson = 'Hello, ${user.displayName}';
      fullname = user.displayName;
    }
    if (_requestCall != null) {
      phoneno = _requestCall.mobile;
      if (phoneno == null) {
        phoneno = '';
      }
      address = _requestCall.address;
      if (address == null) {
        address = '';
      }
    }
    String email = null;
    if ((user != null) && (user.email != null)) {
      email = user.email;
    }
    String socialUrl = null;
    bool isShowAvatar = (user != null) && ((user.photoUrl != null) || (_profileUrl != null)); 
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Container(
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text('Raise A Request', style: TextStyle(fontSize: 20, color: Colors.white),),
            backgroundColor: Colors.blue,
            elevation: 0,
            leading: new IconButton(
    icon: new Icon(Icons.arrow_back, color: Colors.white,),
    onPressed: () {
                              Navigator.of(context).pop();
    },
  ),
            actions: <Widget>[
              IconButton(
                key: Key(Keys.logout),
                icon: Icon(CommunityMaterialIcons.logout_variant),
                color: Colors.black54,
                onPressed: () async {
                  await _confirmSignOut(context);
                }
              ),
            ],
          ),
          body: SingleChildScrollView(
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
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.next,
                        maxLength: 300,
                        maxLengthEnforced: true,
                        decoration: InputDecoration(
                          labelText: 'Call Reason',
                          labelStyle: TextStyle(color: Colors.black),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          // contentPadding: EdgeInsets.only(top: 40, bottom: 20),
                          suffixIcon: 
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                                top: 18, start: 50),
                            child: getIconType(fullname),
                               
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
      _amountController = new MoneyMaskedTextController(decimalSeparator: '.', thousandSeparator: ',', leftSymbol: curr);
    });
            },
          ),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.numberWithOptions(signed:false, decimal: true),
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          labelStyle: TextStyle(color: Colors.black),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          // contentPadding: EdgeInsets.only(top: 40, bottom: 20),
                          suffixIcon: 
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                                top: 18, start: 50),
                            child: getIconType(fullname),
                               
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
  value: _requestCall != null && _requestCall.individual != null ? _requestCall.individual : true,
  onChanged: (bool val) =>
      setState(() => _requestCall.individual = val)
),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _fullnameController,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Person / Company',
                          labelStyle: TextStyle(color: Colors.black),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          // contentPadding: EdgeInsets.only(top: 40, bottom: 20),
                          suffixIcon: 
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                                top: 18, start: 50),
                            child: getIconType(fullname),
                               
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
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Primary Email Address',
                          labelStyle: TextStyle(color: Colors.black),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          // contentPadding: EdgeInsets.only(top: 40, bottom: 20),
                          suffixIcon: Padding(
                            padding: const EdgeInsetsDirectional.only(
                                top: 18, start: 50),
                            child:getIconType(email),
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
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Contact Number',
                          labelStyle: TextStyle(color: Colors.black),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          // contentPadding: EdgeInsets.only(top: 40, bottom: 20),
                          suffixIcon: Padding(
                            padding: const EdgeInsetsDirectional.only(
                                top: 18, start: 50),
                            child:getIconType(phoneno),
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
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.next,
                        maxLines: null,
                        decoration: InputDecoration(
                          labelText: 'Valid Full Address',
                          labelStyle: TextStyle(color: Colors.black),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          // contentPadding: EdgeInsets.only(top: 40, bottom: 20),
                          suffixIcon: Padding(
                            padding: const EdgeInsetsDirectional.only(
                                top: 18, start: 50),
                            child: getIconType(address),
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
    value: _requestCall != null && _requestCall.identityType != null ? _requestCall.identityType : 'Aadhaar No',
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
    items: <String>['Aadhaar No', 'PAN Card', 'Voter ID', 'Passport No', 'Social Security No', '']
      .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      })
      .toList(),
  ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _identityNoController,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Identity No',
                          labelStyle: TextStyle(color: Colors.black),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          // contentPadding: EdgeInsets.only(top: 40, bottom: 20),
                          suffixIcon: 
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                                top: 18, start: 50),
                            child: getIconType(fullname),
                               
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
                  child: FlatButton(
                    color: CustomColors.LightGrey,
                    textColor: CustomColors.DarkBlue,
                    child: Text(
                      'Save Request',
                      style: TextStyle(
                          fontFamily: 'worksans',
                          color: CustomColors.DarkBlue,
                          fontSize: 18),
                    ),
                    onPressed: () async {
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
                      final yesno = await PlatformAlertDialog(
                        title: 'Send Request',
                        content: 'Please allow us to validate the request for you',
                        cancelActionText: Strings.cancel,
                        defaultActionText: 'Validate and Save',
                      ).show(context);
                      if (yesno == true) {
                        RequestCall data = RequestCall(
                            userId: user.uid,
                            email: user.email,
                            purpose: _titleController.text,
                            name: _fullnameController.text,
                            mobile: _phoneNoController.text,
                            address: _addressController.text,
                            identityType: '',
                            identityNo: _identityNoController.text,
                            individual: individual ? individual : _requestCall.individual,
                            amount:  _amountController.numberValue,
                            currency: _amountController.leftSymbol,
                            profileUrl: getImageFilename(_image), 
                            );
                        final String validationResult = data.validate();
                        bool status = validationResult == '';
                        if (status) {
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
        fontSize: 16.0
    );
                        } else {
                        Fluttertoast.showToast(
        msg: 'Request Call cannot be saved',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0
    );

                        }
                        } else {

                        Fluttertoast.showToast(
        msg: validationResult,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0
    );
                        }
                      }
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}