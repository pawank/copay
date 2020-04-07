
import 'package:copay/app/landing_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum RequestSummaryType { sent, received, pending }

class RequestSummary extends StatelessWidget {
  const RequestSummary(
      {Key key,
      this.code,
      this.txnType,
      this.amount,
      this.currency,
      this.info,
      this.date,
      this.receiver})
      : super(key: key);
  final RequestSummaryType txnType;
  final String code, amount, currency, info, date, receiver;
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
                  child: Image.network(
                    'https://ombagoes.com/wp-content/uploads/2019/10/flutter.jpg',
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
            child: Column(
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
                      '\$ $amount',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      '$info - $date',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    Text(
                      '$transactionName',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
