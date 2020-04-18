import 'package:flutter/material.dart';

@immutable
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({
    Key key,
    this.child,
    this.message,
  }) : super(key: key);
  final Widget child;
  final String message;

  @override
  Widget build(BuildContext context) {
        return Center(child: 
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
          Image.asset('assets/app-logo.png'),
          if (child != null)
            child,
          Text(message != null ? message : 'Loading...', style: TextStyle(fontSize: 20, color: Colors.blue),),
    ],),);
  }
}
