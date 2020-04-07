import 'package:circular_profile_avatar/circular_profile_avatar.dart';
import 'package:copay/screens/raise_a_request.dart';
import 'package:copay/screens/request_calls.dart';
import 'package:copay/screens/txn.dart';
import 'package:copay/screens/user_profile.dart';
import 'package:copay/services/auth_service.dart';
import 'package:flutter/material.dart';
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
      name = user.email.toUpperCase().substring(0,2);
    } else if (user.displayName != null) {
      name = user.displayName.toUpperCase().substring(0,2);
    }
    String url = '';
    if (user.photoUrl != null) {
      url = user.photoUrl;
      name = '';
    }
    final avatar = CircularProfileAvatar(
          url,
          radius: 30, // sets radius, default 50.0              
          backgroundColor: Colors.transparent, // sets background color, default Colors.white
          borderWidth: 2,  // sets border, default 0.0
          initialsText: Text(
            name,
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),  // sets initials text, set your own style, default Text('')
          borderColor: Colors.brown, // sets border color, default Colors.white
          elevation: 5.0, // sets elevation (shadow of the profile picture), default value is 0.0
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
          showInitialTextAbovePicture: true, // setting it true will show initials text above profile picture, default false  
    );
    return Column(
      children: [
        if (name != null) 
          avatar,
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
        body: Column(
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Hello ${name},',
                                  style: Theme.of(context).textTheme.title,
                                ),
                                Text(
                                  'What would you do like to do today ?',
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
                    child: 
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Flexible(
                          child: CustomButton(buttonType: ButtonType.payBills, user: user),
                        ),
                        Flexible(
                          child: CustomButton(buttonType: ButtonType.donate, user: user),
                        ),
                        Flexible(
                          child:
                              CustomButton(buttonType: ButtonType.receiptients, user: user),
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
                      'RECENT TRANSACTIONS / DONATIONS',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 15.0,
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        children: txns,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
        ),
      ),
    );
  }
}

class SendReceiveSwitch extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white54,
      ),
      padding: EdgeInsets.all(21.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          DragTarget(
            builder: (context, List<int> candidateData, rejectedData) {
              return Container(
                padding: EdgeInsets.all(5.0),
                child: Text(
                  'Donate',
                  style: TextStyle(color: Colors.white),
                ),
              );
            },
            onWillAccept: (dynamic data) {
              return true;
            },
            onAccept: (dynamic data) {
              Scaffold.of(context).showSnackBar(
                SnackBar(
                  content: Text('Receive!'),
                ),
              );
            },
          ),
          Draggable(
            data: 5,
            child: Container(
              width: 51,
              height: 51,
              padding: EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [Colors.white54, Theme.of(context).primaryColor],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.3, 1]),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.attach_money,
                color: Theme.of(context).primaryColor,
              ),
            ),
            feedback: Container(
              width: 51,
              height: 51,
              padding: EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [Colors.white54, Theme.of(context).primaryColor],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.3, 1]),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.attach_money,
                color: Theme.of(context).primaryColor,
              ),
            ),
            axis: Axis.horizontal,
            childWhenDragging: Container(
              width: 51,
              height: 51,
            ),
          ),
          DragTarget(
            builder: (context, List<int> candidateData, rejectedData) {
              return Container(
                padding: EdgeInsets.all(10.0),
                child: Text(
                  'Pay',
                  style: TextStyle(color: Colors.white),
                ),
              );
            },
            onWillAccept: (dynamic data) {
              return true;
            },
            onAccept: (dynamic data) {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) {
                    return SendScreen();
                  },
                ),
              );
            },
          ),
        ],
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
        buttonText = 'Friends';
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
                    return RaiseRequest(user: user);
                  },
                ),
              );
          }
          if (buttonText == 'Donate') {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) {
                    return RequestCallScreen(user: user, code: '',);
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

class SendScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Send Money'),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Text(
                'Select Payee',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19.0),
              ),
              IconButton(
                icon: Icon(Icons.search),
                onPressed: () {},
              )
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 4,
              itemBuilder: (context, payees) {
                return ListTile(
                  title: PayeeContainer(),
                  onTap: () {},
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class PayeeContainer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Flexible(
            flex: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                'https://cdn.pixabay.com/photo/2017/11/02/14/26/model-2911329_960_720.jpg',
              ),
            ),
          ),
          Flexible(
            flex: 6,
            child: Container(
              padding: EdgeInsets.all(13.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'John Doe',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '+213123456789',
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
