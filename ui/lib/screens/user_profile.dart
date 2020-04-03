import 'package:copay/common_widgets/avatar.dart';
import 'package:copay/models/enhanced_user.dart';
import 'package:copay/services/enhanced_user_impl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
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

class UserProfile extends StatefulWidget {
  UserProfile({@required this.user});
  final User user;
  @override
  _UserProfileState createState() => _UserProfileState(user);
}

class _UserProfileState extends State<UserProfile> {
  _UserProfileState(this.user);
  final User user;
  EnhancedProfileRepo profileRepo;
  var index = 0;
  String email;
  EnhancedProfile _enhancedProfile;
  TextEditingController _phoneNoController = TextEditingController(text: '');
  TextEditingController _addressController = TextEditingController(text: '');
  TextEditingController _fullnameController = TextEditingController(text: '');
  TextEditingController _emailController = TextEditingController(text: '');

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

  @override
  void didChangeDependencies() {
    profileRepo = Provider.of<EnhancedProfileRepo>(context);
    if (profileRepo != null)
      profileRepo.fetchEnhancedProfilesByUsername(email).then((users) {
        users.forEach((u) {
          setState(() {
            _enhancedProfile = u;
            //_emailController.text = u.email;
            _fullnameController.text = u.name;
            if (u.name == null) {
              _fullnameController.text = '';
            }
    else if ((user != null) && (user.displayName != null)) {
              _fullnameController.text = user.displayName;
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
    super.didChangeDependencies();
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      final AuthService auth = Provider.of<AuthService>(context);
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

  @override
  Widget build(BuildContext context) {
    final EnhancedProfileRepo profileRepo = Provider.of<EnhancedProfileRepo>(context);
    String nameOfPerson = 'Hello, Guest';
    String fullname = '';
    String phoneno = '';
    String address = '';
    if ((user != null) && (user.displayName != null)) {
      nameOfPerson = 'Hello, ${user.displayName}';
      fullname = user.displayName;
    }
    if (_enhancedProfile != null) {
      phoneno = _enhancedProfile.mobile;
      if (phoneno == null) {
        phoneno = '';
      }
      address = _enhancedProfile.address;
      if (address == null) {
        address = '';
      }
    }
    String email = null;
    if ((user != null) && (user.email != null)) {
      email = user.email;
    }
    String socialUrl = null;
    bool isShowAvatar = (user != null) && (user.photoUrl != null);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Container(
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: <Widget>[
              IconButton(
                icon: Icon(CommunityMaterialIcons.close_circle),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: 5),
                if (isShowAvatar)
                  Avatar(
                    photoUrl: user.photoUrl,
                    radius: 50,
                    borderColor: Colors.amberAccent,
                    borderWidth: 2.0,
                  ),
                Text(
                  nameOfPerson,
                  style: TextStyle(
                      fontFamily: 'worksans',
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black),
                ),
                SizedBox(height: 10),
                if (socialUrl != null)
                  SizedBox(
                    height: 25,
                    child: FlatButton(
                      color: CustomColors.LightGrey,
                      textColor: CustomColors.DarkBlue,
                      child: Text(
                        socialUrl,
                        style: TextStyle(
                            fontFamily: 'worksans',
                            color: CustomColors.DarkBlue,
                            fontSize: 14),
                      ),
                      onPressed: () {
                        /*
                        Navigator.of(context).push(
                          MaterialPageRoute<Null>(
                            builder: (BuildContext context) {
                              return Profile();
                            },
                            fullscreenDialog: true,
                          ),
                        );
                        */
                        print('Saving profile..');
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                  ),
                SizedBox(height: 10),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        controller: _fullnameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
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
                        readOnly: true,
                        enabled: false,
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'E-mail',
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
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
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
                        decoration: InputDecoration(
                          labelText: 'Address',
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
                      'Save',
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
                        title: 'Update Profile',
                        content: 'Do you really want to update?',
                        cancelActionText: Strings.cancel,
                        defaultActionText: 'Yes',
                      ).show(context);
                      if (yesno == true) {
                        EnhancedProfile data = EnhancedProfile(
                            userId: user.uid,
                            email: user.email,
                            mobile: _phoneNoController.text,
                            address: _addressController.text);
                        final bool status =
                            await profileRepo.saveEnhancedProfile(data);
                        if (status) {
                        print('Saved profile information');
                        Fluttertoast.showToast(
        msg: 'Profile has been updated for ${user.email}',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 16.0
    );
                        } else {
                        Fluttertoast.showToast(
        msg: 'Profile cannot be updated for ${user.email}',
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