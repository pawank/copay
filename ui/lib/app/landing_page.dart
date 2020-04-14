import 'package:circular_profile_avatar/circular_profile_avatar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:copay/screens/contacts.dart';
import 'package:copay/screens/donations.dart';
import 'package:copay/screens/raise_a_request.dart';
import 'package:copay/screens/request_calls.dart';
import 'package:copay/screens/txn.dart';
import 'package:copay/screens/user_profile.dart';
import 'package:copay/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  final String title;
  LandingPage({this.title});

  Widget _buildUserInfo(BuildContext context, User user) {
    String name = null;
    if ((user.email != null) && (user.displayName == null)) {
      name = user.email.toUpperCase().substring(0, 2);
    } else if (user.displayName != null) {
      name = user.displayName.toUpperCase().substring(0, 2);
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

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User>(context, listen: false);
    String name = user.email;
    if (user.displayName != null) {
      name = user.displayName;
    }
    final String username = user.email != null ? user.email : '';
    final streamQS = Firestore.instance
        .collection('request_calls')
        .where('email', isEqualTo: username.toLowerCase())
        .snapshots();
    final List<RequestSummary> txns = [
      RequestSummary(
        receiver: 'Pawan Kumar',
        amount: '5000.00',
        currency: '\$',
        date: '4 April 2020',
        info: 'Housemaid',
        txnType: RequestSummaryType.sent,
      ),
      RequestSummary(
        receiver: 'Nitish Jain',
        amount: '15000.00',
        currency: '',
        date: '3 April 2020',
        info: 'Gatekeeper',
        txnType: RequestSummaryType.received,
      ),
      RequestSummary(
        receiver: 'Alok Jain',
        amount: '25000.00',
        currency: '\$',
        date: '30 March 2020',
        info: 'Others',
        txnType: RequestSummaryType.pending,
      ),
    ];
    return SafeArea(
      child: Scaffold(
        body: StreamBuilder<QuerySnapshot>(
            stream: streamQS,
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) return Text('Error: ${snapshot.error}');
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  return Text('Loading..');
                default:
                  child:
                  final List<DocumentSnapshot> docs = snapshot.data.documents;
                  print('Doc size = ${docs.length}');
                  double totalPaid = 0.00;
                  double totalReceived = 0.00;
                  String lastDate = '';
                  docs.forEach((doc){
                    totalPaid += doc['amount'];
                    if ((doc['txnType'] != null) && (doc['txnType'] == 'received')) {
                      totalReceived += doc['amount'];
                    } else if ((doc['status'] != null) && (doc['status'] == 'Paid')) {
                      totalReceived += doc['amount'];
                    }
                          DateTime dt = (doc['createdOn'] as Timestamp).toDate();
                          lastDate = 'Till ' + new DateFormat.yMMMMd('en_US').format(dt);
                  });
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
                                          Text(
                                            'Hello $name,',
                                            style: Theme.of(context)
                                                .textTheme
                                                .title,
                                          ),
                                          Text(
                                            'What would you do like to do today ?',
                                            style: TextStyle(
                                                color: Colors.white70),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  Flexible(
                                    child: CustomButton(
                                        buttonType: ButtonType.payBills,
                                        user: user),
                                  ),
                                  Flexible(
                                    child: CustomButton(
                                        buttonType: ButtonType.receiptients,
                                        user: user),
                                  ),
                                  Flexible(
                                    child: CustomButton(
                                        buttonType: ButtonType.donate,
                                        user: user),
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
                                'SCORE BOARD',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 15.0,
                                ),
                              ),
                              Expanded(
                                child: ListView(
                                  children: [
                                    Card(child: ListTile(key: Key('1'),
                                    leading: Text(totalPaid.toInt().toString(), style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),),
                                      title: Text('TOTAL RAISED'),
                                      subtitle: Text(lastDate),
                                      isThreeLine: false,
                                      trailing: Icon(Icons.arrow_upward),
                                      ),
                                    ),
                                      Divider(height: 5,),
                                    Card(child: ListTile(key: Key('2'),
                                    leading: Text(totalReceived.toInt().toString(), style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),),
                                      title: Text('TOTAL RECEIVED'),
                                      subtitle: Text(lastDate),
                                      isThreeLine: true,
                                      trailing: Icon(Icons.arrow_downward),
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
            }),
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
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final ButtonType buttonType;
  final User user;
  const CustomButton({Key key, this.buttonType, this.user}) : super(key: key);
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
        onTap: () {
          print('Clicked: ${buttonText}');
          if (buttonText == 'Raise Request') {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) {
                  return RaiseRequest(user: user, code: null,);
                },
              ),
            );
          }
          else if (buttonText == 'My Requests') {
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
          }
          else if (buttonText == 'Donate') {
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
