
import 'package:copay/app/landing_page.dart';
import 'package:copay/screens/raise_a_request.dart';
import 'package:copay/services/auth_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum RequestSummaryType { sent, received, pending, failed }

class RequestSummary extends StatelessWidget {
  const RequestSummary(
      {Key key,
      this.code,
      this.txnType,
      this.amount,
      this.currency,
      this.info,
      this.date,
      this.receiver,
      this.imageUrl,
      this.mediaUrl,
      this.user,
      this.requestOrDonation
      })
      : super(key: key);
  final RequestSummaryType txnType;
  final String code, amount, currency, info, date, receiver, imageUrl, mediaUrl, requestOrDonation;
  final User user;
  
  Widget getMediaIconType(String value) {
    if ((value == null) || (value.isEmpty)) {
      return Text('');
    }
    return Icon(Icons.videocam, color: Colors.black);
  }


  Widget getIconType(String value) {
    if ((value == null) || (value.isEmpty)) {
      return Text('');
    }
    return Icon(Icons.image, color: Colors.black);
  }

  @override
  Widget build(BuildContext context) {
    String transactionName;
    IconData transactionIconData;
    Color color;
    switch (txnType) {
      case RequestSummaryType.sent:
        transactionName = 'Sent';
        transactionIconData = Icons.arrow_upward;
        color = Theme.of(context).primaryColor;
        break;
      case RequestSummaryType.received:
        transactionName = 'Received';
        transactionIconData = Icons.arrow_downward;
        color = Colors.green;
        break;
      case RequestSummaryType.pending:
        transactionName = 'Pending';
        transactionIconData = Icons.arrow_downward;
        color = Colors.orange;
        break;
      case RequestSummaryType.failed:
        transactionName = 'Payment Failed';
        transactionIconData = Icons.error;
        color = Colors.red;
        break;
    }
    return Container(
      margin: EdgeInsets.fromLTRB(0, 9, 0, 9),
      padding: EdgeInsets.all(9.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 5.0,
            color: Colors.grey[350],
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Flexible(
            flex: 1,
            child: Stack(
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(15.0),
                  child: imageUrl != null ? Image.asset(
                    'assets/app-logo.png'
                  )
                   : Image.asset(
                    'assets/app-logo.png'
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 15.0,
                    height: 15.0,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: FittedBox(
                      child: Icon(
                        transactionIconData,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          SizedBox(width: 5.0),
          Flexible(
            flex: 4,
            child: 
            new InkWell(
             key: key, 
             highlightColor: Colors.blueAccent,
             hoverColor: Colors.blue,
             splashColor: Colors.deepOrange,
        onTap: (){
            print('On tap called');
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) {
                  return RaiseRequest(user: user, code: code, requestOrDonation: requestOrDonation);
                },
              ),
            );
        },
        onDoubleTap: () {
            print('On double tap called');
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) {
                  return RaiseRequest(user: user, code: code, requestOrDonation: requestOrDonation);
                },
              ),
            );
        },
        child:
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      receiver,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$currency $amount',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      '$info',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      '$date',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    if (imageUrl != null) getIconType(imageUrl),
                    if (mediaUrl != null) getMediaIconType(mediaUrl),
                  ],
                ),
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }
}
