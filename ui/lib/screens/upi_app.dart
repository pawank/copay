import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:upi_india/upi_india.dart';
import 'dart:math';

import 'package:upi_pay/upi_pay.dart';

class UPIScreen extends StatefulWidget {
  UPIScreen({@required this.request, this.callbackPayment});
  UpiIndia request;
  Function callbackPayment;
  @override
  _UPIScreenState createState() => _UPIScreenState(request, callbackPayment);
}

class _UPIScreenState extends State<UPIScreen> {
  _UPIScreenState(this.request, this.callbackPayment);
  Future _transaction;
  UpiIndia request;
  Function callbackPayment;
  String _upiAddrError;
  final _upiAddressController = TextEditingController();
  final _amountController = TextEditingController();
  Future<List<ApplicationMeta>> _appsFuture;
  bool _isUpiEditable = false;
  bool _isAmountEditable = false;

  Future<String> initiateTransaction(String app) async {
    UpiIndia upi = UpiIndia(
        app: app,
        receiverUpiId: _upiAddressController != null && _upiAddressController.text.isNotEmpty ? _upiAddressController.text.trim() : request.receiverUpiId,
        receiverName: request.receiverName,
        transactionRefId: request.transactionRefId,
        transactionNote: request.transactionNote,
        amount: request.amount,
        currency: request.currency);

    //return response;
    final String response = await upi.startTransaction();
    if ((response != null) && (response.contains('Status=FAILURE'))) {
                          Fluttertoast.showToast(
                              msg: 'Payment Status: FAILURE',
                              toastLength: Toast.LENGTH_LONG,
                              gravity: ToastGravity.BOTTOM,
                              timeInSecForIosWeb: 1,
                              backgroundColor: Colors.red,
                              textColor: Colors.white,
                              fontSize: 16.0);
    }
    return Future.value(response);
  }

  @override
  void initState() {
    super.initState();

    _upiAddressController.text = request.receiverUpiId;
    _amountController.text = (request.amount).toStringAsFixed(2);
    _appsFuture = UpiPay.getInstalledUpiApplications();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _upiAddressController.dispose();
    _transaction = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('UPI Payment'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: ListView(
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(top: 10),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            controller: _upiAddressController,
                            enabled: _isUpiEditable,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'address@upi',
                              labelText: 'Receiving UPI Address',
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(left: 8),
                          child: IconButton(
                            icon: Icon(
                              _isUpiEditable ? Icons.check : Icons.edit,
                            ),
                            onPressed: () {
                              setState(() {
                                _isUpiEditable = !_isUpiEditable;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_upiAddrError != null)
                    Container(
                      margin: EdgeInsets.only(top: 4, left: 12),
                      child: Text(
                        _upiAddrError,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  Container(
                    margin: EdgeInsets.only(top: 15),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            readOnly: true,
                            enabled: false,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Amount',
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(left: 8),
                          child: IconButton(
                            icon: Icon(
                              _isAmountEditable ? Icons.check : Icons.check,
                            ),
                            onPressed: () {
                              setState(() {
                                _isAmountEditable = !_isAmountEditable;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 40, bottom: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          margin: EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Pay Using',
                            style: Theme.of(context).textTheme.caption,
                          ),
                        ),
                        FutureBuilder<List<ApplicationMeta>>(
                          future: _appsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState !=
                                ConnectionState.done) {
                              return Container();
                            }

                            return GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 1.6,
                              //physics: NeverScrollableScrollPhysics(),
                              children: snapshot.data
                                  .map((it) => Material(
                                        key: ObjectKey(it.upiApplication),
                                        color: Colors.grey[200],
                                        child: InkWell(
                                          onTap: () {
                                            _transaction = initiateTransaction(it.packageName);
                                          },
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: <Widget>[
                                              Image.memory(
                                                it.icon,
                                                width: 64,
                                                height: 64,
                                              ),
                                              Container(
                                                margin: EdgeInsets.only(top: 4),
                                                child: Text(
                                                  it.upiApplication
                                                      .getAppName(),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            /* 
            Container(
              alignment: Alignment.center,
              child: RaisedButton(
                  child: Text('PhonePe'),
                  onPressed: () {
                    _transaction = initiateTransaction(UpiIndiaApps.GooglePay);
                    setState(() {});
                  }),
            ),*/
          ),
          Expanded(
            flex: 1,
            child: FutureBuilder<dynamic>(
              future: _transaction,
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.connectionState == ConnectionState.none ||
                    snapshot.data == null)
                  return Text(' ');
                else if (snapshot.connectionState == ConnectionState.waiting) 
                  return CircularProgressIndicator();
                else {
                  switch (snapshot.data.toString()) {
                    case UpiIndiaResponseError.APP_NOT_INSTALLED:
                      return Text(
                        'App not installed.',
                      );
                      break;
                    case UpiIndiaResponseError.INVALID_PARAMETERS:
                      return Text(
                        'Requested payment is invalid.',
                      );
                      break;
                    case UpiIndiaResponseError.USER_CANCELLED:
                      return Text(
                        'It seems like you cancelled the transaction.',
                      );
                      break;
                    case UpiIndiaResponseError.NULL_RESPONSE:
                      return Text(
                        'No data received',
                      );
                      break;
                    default:
                      callbackPayment(snapshot.data);
                      UpiIndiaResponse _upiResponse;
                      _upiResponse = UpiIndiaResponse(snapshot.data);
                      String txnId = _upiResponse.transactionId;
                      String resCode = _upiResponse.responseCode;
                      String txnRef = _upiResponse.transactionRefId;
                      String status = _upiResponse.status;
                      String approvalRef = _upiResponse.approvalRefNo;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Text('Transaction Id: $txnId'),
                          Text('Response Code: $resCode'),
                          Text('Reference Id: $txnRef'),
                          Text('Status: $status'),
                          Text('Approval No: $approvalRef'),
                        ],
                      );
                  }
                }
              },
            ),
          )
        ],
      ),
    );
  }
}
