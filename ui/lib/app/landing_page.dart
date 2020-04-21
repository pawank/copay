import 'package:circular_profile_avatar/circular_profile_avatar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:copay/common_widgets/loading.dart';
import 'package:copay/common_widgets/stateful_wrapper.dart';
import 'package:copay/models/enhanced_user.dart';
import 'package:copay/screens/contacts.dart';
import 'package:copay/screens/donations.dart';
import 'package:copay/screens/raise_a_request.dart';
import 'package:copay/screens/request_calls.dart';
import 'package:copay/screens/txn.dart';
import 'package:copay/screens/user_profile.dart';
import 'package:copay/services/auth_service.dart';
import 'package:copay/services/donation_api.dart';
import 'package:copay/services/enhanced_user_impl.dart';
import 'package:copay/services/request_call_api.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loader/loader.dart';
import 'package:provider/provider.dart';

enum ButtonType { payBills, donate, receiptients, offers }

/*
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primaryColor: Color(0xff2931a5),
        textTheme: TextTheme(
          title: TextStyle(
            fontSize: 27,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: LandingPage(title: 'Flutter Demo Home Page'),
    );
  }
}
*/
class LandingPage extends StatelessWidget {
  LandingPage({this.title});

  final String title;
  AsyncSnapshot<User> userSnapshot;

  EnhancedProfile _profile;
  User _user;

  Widget _buildUserInfo(BuildContext context, User user) {
    String name = null;
    if ((user.email != null) &&
        ((user.displayName == null) || (user.displayName == ''))) {
      if (user.email.length > 2) {
        name = user.email.toUpperCase().substring(0, 2);
      }
    }
    if (user.displayName != null) {
      if (user.displayName.length > 2) {
        name = user.displayName.toUpperCase().substring(0, 2);
        //name = user.displayName;
      } else {}
    }
    String fullname = user.displayName;
    if ((fullname == null) || (fullname == '')) {
      fullname = user.email;
      if (fullname != null) {
        fullname = user.email.split('@').first;
      }
    }
    String url = '';
    if (user.photoUrl != null) {
      url = user.photoUrl;
      name = '';
    }
    final avatar = CircularProfileAvatar(
      url,
      radius: 30, // sets radius, default 50.0
      backgroundColor:
          Colors.transparent, // sets background color, default Colors.white
      borderWidth: 2, // sets border, default 0.0
      initialsText: Text(
        name,
        style: TextStyle(fontSize: 20, color: Colors.white),
      ), // sets initials text, set your own style, default Text('')
      borderColor: Colors.brown, // sets border color, default Colors.white
      elevation:
          5.0, // sets elevation (shadow of the profile picture), default value is 0.0
      //foregroundColor: Colors.brown.withOpacity(0.5), //sets foreground colour, it works if showInitialTextAbovePicture = true , default Colors.transparent
      cacheImage: true, // allow widget to cache image against provided url
      onTap: () {
        final route = MaterialPageRoute<void>(
          builder: (context) {
            //final EnhancedProfileRepo profileRepo = Provider.of<EnhancedProfileRepo>(context);
            return UserProfile(user: user);
          },
        );
        Navigator.of(context).push(route);
      }, // sets on tap
      showInitialTextAbovePicture:
          true, // setting it true will show initials text above profile picture, default false
    );
    return Column(
      children: [
        if (name != null) avatar,
        /*
          Text(
            name,
            style: TextStyle(color: Colors.white, fontSize: 30),
          ),*/
        SizedBox(height: 5),
      ],
    );
  }

  Future _getThingsOnStartup() async {
    await Future<dynamic>.delayed(Duration(seconds: 2));
  }

  Widget generateUI(BuildContext context, User user, EnhancedProfile profile) {
    //final userProfile = Provider.of<EnhancedProfile>(context, listen: false);
    String name = user.email;
    if (user.displayName != null) {
      name = user.displayName.split(' ').first;
    }
    if (name != null) {
      if (name.contains('@')) {
        name = name.split('@').first;
      }
    }
    String fullname = user.displayName;
    if (((fullname == null) || (fullname == '')) && (profile != null)) {
      fullname = profile.name.split(' ').first;
    }
    if ((fullname == null) || (fullname == '')) {
      fullname = user.email;
      if (fullname != null) {
        fullname = user.email.split('@').first;
      }
    }
    final String username =
        user.email != null ? user.email : profile != null ? profile.email : '';
    final streamQS = Firestore.instance
        .collection(DonationApi.db_name)
        .where('owner.email', isEqualTo: username.toLowerCase())
        .snapshots();
    return StreamBuilder<QuerySnapshot>(
        stream: streamQS,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) return Text('Error: ${snapshot.error}');
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return Center(
                child: LoadingScreen(),
              );
            default:
              child:
              //print('Doc size = ${docs.length}');
              double totalRaised = profile != null ? profile.totalRaised : 0.00;
              double totalReceived = 0.00;
              double totalShare = profile != null ? profile.totalDonated : 0.00;
              String lastDate = '';
              String ownerName = null;
              String shareMsg = '';
              String donationMsg = '';
              Set<String> codes = Set();
              int shareNo = 0;
              int donationNo = 0;
              snapshot.data.documents.forEach((doc) {
                ownerName = doc['owner']['name'];
                if (ownerName != null) {
                  ownerName = ownerName.split(' ').first;
                }
                codes.add(doc['code']);
                //totalPaid += doc['amount'];
                if ((doc['txnType'] != null) &&
                    (doc['txnType'] == 'received')) {
                  totalReceived += doc['amount'];
                } else if ((doc['status'] != null) &&
                    (doc['status'] == 'Paid')) {
                  totalReceived += doc['amount'];
                }
                DateTime dt = (doc['createdOn'] as Timestamp).toDate();
                lastDate = 'Till ' + new DateFormat.yMMMMd('en_US').format(dt);
                /*
                if ((doc['shared'] == null) || (doc['shared'] == 0)) {
                  shareMsg = 'Pending Sharing';
                  shareNo += 1;
                }
                if ((doc['donated'] == null) || (doc['donated'] == 0)){
                  donationMsg = 'Pending Donation';
                  donationNo += 1;
                }
                */
                if ((doc['donor'] != null) && (doc['donor']['email'] == user.email)){
                  donationNo += 1;
                }
              });
              int noRequests = codes.length;
              shareNo = (profile != null ? profile.raisedCount : 0) - noRequests;
              if (shareNo < 0) {
                  shareNo = 0;
              }
              donationNo = donationNo - (profile != null ? profile.donatedCount : 0);
              return Column(
                children: <Widget>[
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          padding: EdgeInsets.all(21),
                          color: Theme.of(context).primaryColor,
                          child: Column(
                            children: <Widget>[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Wrap(
                                        alignment: WrapAlignment.spaceAround,
                                        children: <Widget>[
                                          Text(
                                            ownerName != null
                                                ? 'Hello $ownerName,'
                                                : 'Hello $fullname,',
                                            style: Theme.of(context)
                                                .textTheme
                                                .title,
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'What would you do like to do today?',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black45,
                                          blurRadius: 5.0,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                      shape: BoxShape.circle,
                                      color: Colors.transparent,
                                    ),
                                    child: _buildUserInfo(context, user),
                                    /*
                                CircleAvatar(
                                backgroundImage: NetworkImage(
                                  avatarUrl
                                ),
                              ),*/
                                  )
                                ],
                              ),
                              SizedBox(
                                height: 15.0,
                              ),
                              //SendReceiveSwitch(),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(11),
                          color: Color(0xfff4f5f9),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              Flexible(
                                child: CustomButton(
                                    buttonType: ButtonType.payBills,
                                    user: user, message: '',),
                              ),
                              Flexible(
                                child: CustomButton(
                                    buttonType: ButtonType.receiptients,
                                    user: user, message: shareNo.toString(),),
                              ),
                              Flexible(
                                child: CustomButton(
                                    buttonType: ButtonType.donate, user: user, message: donationNo.toString(),),
                              ),
                              /*
                        Flexible(
                          child: CustomButton(buttonType: ButtonType.offers),
                        ),*/
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(21.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          Text(
                            'YOUR LEDGER',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 15.0,
                            ),
                          ),
                          Expanded(
                            child: ListView(
                              children: [
                                Card(
                                  child: ListTile(
                                    key: Key('1'),
                                    leading: Text(
                                      totalRaised.toInt().toString(),
                                      style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    title: Text('TOTAL RAISED'),
                                    subtitle: Text(lastDate),
                                    isThreeLine: false,
                                    trailing: Icon(Icons.arrow_upward),
                                  ),
                                ),
                                Divider(
                                  height: 5,
                                ),
                                Card(
                                  child: ListTile(
                                    key: Key('2'),
                                    leading: Text(
                                      totalReceived.toInt().toString(),
                                      style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    title: Text('TOTAL RECEIVED'),
                                    subtitle: Text(lastDate),
                                    isThreeLine: true,
                                    trailing: Icon(Icons.arrow_downward),
                                  ),
                                ),
                                Divider(
                                  height: 5,
                                ),
                                Card(
                                  child: ListTile(
                                    key: Key('3'),
                                    leading: Text(
                                      totalShare.toInt().toString(),
                                      style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    title: Text('YOUR CONTRIBUTIONS'),
                                    subtitle: Text(lastDate),
                                    isThreeLine: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
          }
        });
    /*
        bottomNavigationBar: BottomNavigationBar(
          unselectedItemColor: Theme.of(context).primaryColor,
          selectedItemColor: Theme.of(context).primaryColor,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              title: Text('Home'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.access_time),
              title: Text('History'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.message),
              title: Text('Notifications'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              title: Text('Settings'),
            ),
          ],
        ),*/
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User>(context, listen: false);
    //return generateUI(context, user);
    return SafeArea(
      child: Scaffold(
        body: FutureBuilder<EnhancedProfile>(
          future: load(
              context, user), // a previously-obtained Future<String> or null
          builder:
              (BuildContext context, AsyncSnapshot<EnhancedProfile> snapshot) {
            Widget children;

            if (snapshot.hasData) {
              children = generateUI(context, user, snapshot.data);
            } else if (snapshot.hasError) {
              children = generateUI(context, user, null);
            } else {
              children = Column(
                children: <Widget>[
                  LoadingScreen(),
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text('Awaiting result...'),
                  )
                ],
              );
            }
            return children;
          },
        ),
      ),
    );
  }

  Future<EnhancedProfile> load(BuildContext context, User user) async {
    //print('Loading..');
    EnhancedProfile data = EnhancedProfile(
        userId: user.uid,
        name: user.displayName,
        email: user.email,
        mobile: '',
        address: '',
        profileUrl: null,
        totalRaised: 0.00,
        totalDonated: 0.00,
        raisedCount: 0,
        donatedCount: 0);
    if (user != null) {
      EnhancedProfileRepo profileRepo = EnhancedProfileRepo();
      final Future<List<EnhancedProfile>> records =
          profileRepo.fetchEnhancedProfilesByEmail(user.email);
      await records.then((users) async {
        users.forEach((u) {
          if (_profile == null) {
            _profile = u;
            //print('Profile = $_profile');
          }
        });
      });
      final bool status = await profileRepo
          .saveEnhancedProfile(_profile != null ? _profile : data);
      if (status) {
        //print('Profile saved');
      }
      //return _profile != null ? _profile : data;
    }
    return _profile != null ? _profile : data;
  }
}

class CustomButton extends StatelessWidget {
  final ButtonType buttonType;
  final User user;
  final String message;
  const CustomButton({Key key, this.buttonType, this.user, this.message}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    String buttonText = '', buttonImage;
    switch (buttonType) {
      case ButtonType.payBills:
        buttonText = 'Raise Request';
        buttonImage = 'assets/receipt.png';
        break;
      case ButtonType.donate:
        buttonText = 'Donate';
        buttonImage = 'assets/donation.png';
        break;
      case ButtonType.receiptients:
        buttonText = 'My Requests';
        buttonImage = 'assets/users.png';
        break;
      case ButtonType.offers:
        buttonText = 'Offers';
        buttonImage = 'assets/discount.png';
        break;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        //highlightColor: Colors.blue,
        splashColor: Colors.orangeAccent,
        onTap: () {
          //print('Clicked: ${buttonText}');
          if (buttonText == 'Raise Request') {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) {
                  return RaiseRequest(
                    user: user,
                    code: null,
                  );
                },
              ),
            );
          } else if (buttonText == 'My Requests') {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) {
                  return RequestCallScreen(
                    user: user,
                    code: '',
                  );
                },
              ),
            );
          } else if (buttonText == 'Donate') {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) {
                  return DonationScreen(
                    user: user,
                    code: '',
                  );
                },
              ),
            );
          }
        },
        child: Container(
          padding: EdgeInsets.all(15.0),
          child: Column(
            children: <Widget>[
              Stack(
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7.0),
                      gradient: LinearGradient(
                        colors: [Colors.white10, Colors.black12],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5.0,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      buttonImage,
                    ),
                  ),
                  if ((buttonText != 'Raise Request') && message != '0')
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 20.0,
                      height: 20.0,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: FittedBox(
                        child: Text(message, style: TextStyle(color: Colors.white),), 
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 5.0,
              ),
              FittedBox(
                child: Text(buttonText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
