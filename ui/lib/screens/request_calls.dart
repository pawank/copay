import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:copay/app/sign_in/sign_in_page.dart';
import 'package:copay/models/cloud_store_convertor.dart';
import 'package:copay/models/request_call.dart';
import 'package:copay/services/auth_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:copay/screens/txn.dart';
import 'package:intl/intl.dart';

class RequestCallScreen extends StatefulWidget {
  RequestCallScreen({@required this.user, @required this.code});
  final User user;
  final String code;
  @override
  _RequestCallScreenState createState() => _RequestCallScreenState(user, code);
}

class _RequestCallScreenState extends State<RequestCallScreen> {
  _RequestCallScreenState(this.user, this.code);
  final User user;
  final String code;
  final int maxInfoLength = 30;
  ScrollController _scrollBottomBarController = new ScrollController();
  bool isScrollingDown = false;
  bool _showAppbar = true; //this is to show app bar
  bool _show = true;
  void showBottomBar() {
    setState(() {
      _show = true;
    });
  }

  void hideBottomBar() {
    setState(() {
      _show = false;
    });
  }

  void callsScroll() async {
    _scrollBottomBarController.addListener(() {
      if (_scrollBottomBarController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (!isScrollingDown) {
          isScrollingDown = true;
          _showAppbar = false;
          hideBottomBar();
        }
      }
      if (_scrollBottomBarController.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (isScrollingDown) {
          isScrollingDown = false;
          _showAppbar = true;
          showBottomBar();
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    callsScroll();
  }

  @override
  void dispose() {
    _scrollBottomBarController.removeListener(() {});
    super.dispose();
  }
  
  String getFinalUrl(String path) {
    if (path != null) {
      //return 'https://copay-9d0a7.appspot.com/$path';
      return path;
    }
    return null; 
  }
  

  @override
  Widget build(BuildContext context) {
    final String username = user.email != null ? user.email : '';
    final streamQS = Firestore.instance
        .collection('request_calls')
        .where('email', isEqualTo: username.toLowerCase())
        .snapshots();
    final _height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Requests'),
        centerTitle: true,
      ),
      body: 
      StreamBuilder<QuerySnapshot>(
          stream: streamQS,
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) return Text('Error: ${snapshot.error}');
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return Text('Loading...', style: TextStyle(fontSize: 20, color: Colors.blue),);
              default:
                child:
                final List<DocumentSnapshot> docs = snapshot.data.documents;
                print('Doc size for request calls = ${docs.length}');
                final docsSize = docs.length;
                if (docsSize <= 0) {
                  return Container(
                    height: _height * 0.8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.all(10),
                          child: Text(
                            'No request(s) saved by you.',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(10),
                          child: Text(
                            'You can raise a call for donation by clicking on RAISE REQUEST from the home screen.',
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                        if ((user.email == null) || (user.email.isEmpty))
                          Padding(
                            padding: EdgeInsets.all(10),
                            child: RaisedButton.icon(
                              label: Text('Register Now',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16.0)),
                              elevation: 4.0,
                              color: Colors.grey,
                              icon: Icon(Icons.account_circle),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<Null>(
                                    builder: (BuildContext context) {
                                      return SignInPageBuilder();
                                    },
                                    fullscreenDialog: true,
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  );
                } else {
                  return Container(
                    //height: _height * 0.8,
                    child: ListView(
                      controller: _scrollBottomBarController,
                      children: 
                      docs.map((DocumentSnapshot document) {
                        final RequestCall obj = CloudStoreConvertor.toObject(document);
                        if (obj != null) {
                          var txnType = RequestSummaryType.pending; 
                          if (obj.txnType == 'sent') {
                            txnType = RequestSummaryType.sent;
                          } else if (obj.txnType == 'received') {
                            txnType = RequestSummaryType.received;
                          }
                          DateTime dt = obj.createdOn.toDate();
                          String date = new DateFormat.yMMMMd('en_US').format(dt);
                          String info = '';
                          if (obj.purpose.length < maxInfoLength) {
                            info = obj.purpose;
                          } else {
                            info = obj.purpose.substring(0, maxInfoLength) + '..';
                          }
                          return RequestSummary(
                            code: obj.code,
                            receiver: obj.name,
                            amount: obj.amount.toString(),
                            currency: obj.currency,
                            date: date,
                            info: info,
                            txnType: txnType,
                            imageUrl: getFinalUrl(obj.imageUrl),
                            mediaUrl: getFinalUrl(obj.mediaUrl),
                            user: user,
                          );
                        } else {
                          return Text(
                              'Request cannot be displayed for reference no: ${document.documentID}');
                        }
                      }).toList(),
                    ),
                  );
                }
            }
          }),
    );
  }
}
