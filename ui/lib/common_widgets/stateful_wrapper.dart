import 'package:copay/models/enhanced_user.dart';
import 'package:copay/services/auth_service.dart';
import 'package:copay/services/enhanced_user_impl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StatefulWrapper extends StatefulWidget {
  final Function onInit;
  final Widget child;
  const StatefulWrapper({@required this.onInit, @required this.child});
  @override
  _StatefulWrapperState createState() => _StatefulWrapperState();
}
class _StatefulWrapperState extends State<StatefulWrapper> {

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

@override
  void initState() {
    if(widget.onInit != null) {
      widget.onInit();
    }
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}