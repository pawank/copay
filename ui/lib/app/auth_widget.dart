import 'package:copay/app/home_page.dart';
import 'package:copay/app/landing_page.dart';
import 'package:copay/common_widgets/loading.dart';
import 'package:copay/screens/app_tutorial.dart';
import 'package:copay/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sign_in/sign_in_page.dart';

/// Builds the signed-in or non signed-in UI, depending on the user snapshot.
/// This widget should be below the [MaterialApp].
/// An [AuthWidgetBuilder] ancestor is required for this widget to work.
/// Note: this class used to be called [LandingPage].
class AuthWidget extends StatelessWidget {
  const AuthWidget({Key key, @required this.userSnapshot}) : super(key: key);
  final AsyncSnapshot<User> userSnapshot;
  
  Future<bool> getDemoSplashViewed() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    bool status = prefs.getBool('copay_demo_splash');
    return Future.value(status == null ? true : false);
  }


  @override
  Widget build(BuildContext context) {
    //if (userSnapshot.connectionState == ConnectionState.active) {
      //return userSnapshot.hasData ? LandingPage(title: 'Home') : SignInPageBuilder();
      //return userSnapshot.hasData ? LandingPage(title: 'Home') : AppTutorial();
    //}
    return Scaffold(
      body: 
      FutureBuilder<bool>(
      future: getDemoSplashViewed(),
      builder: (context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.hasData) {
          return Center(
        child:
          userSnapshot.connectionState == ConnectionState.active ? 
          userSnapshot.hasData ? LandingPage(title: 'Home') : snapshot.data == false ? SignInPageBuilder() : AppTutorial() :
          LoadingScreen(message: 'Starting...',),
      );
    
        } else {
          return LoadingScreen();
        }
      }
    ),
    );  
  }
}
