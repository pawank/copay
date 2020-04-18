import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:copay/app/sign_in/sign_in_page.dart';
import 'package:copay/models/cloud_store_convertor.dart';
import 'package:copay/models/request_call.dart';
import 'package:copay/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:copay/screens/txn.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:contacts_service/contacts_service.dart';

class ContactScreen extends StatefulWidget {
  ContactScreen({@required this.user, @required this.code});
  final User user;
  final String code;
  @override
  _ContactScreenState createState() => _ContactScreenState(user, code);
}

class _ContactScreenState extends State<ContactScreen> {
  _ContactScreenState(this.user, this.code);
  final User user;
  final String code;
  final int maxInfoLength = 30;
  ScrollController _scrollBottomBarController = new ScrollController();
  bool isScrollingDown = false;
  bool _isLoading = true;
  bool _showAppbar = true; //this is to show app bar
  bool _show = true;
  Iterable<Contact> contacts = [];
  Iterable<Contact> _contacts;
  List<RequestSummary> friendList;
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

  Future<bool> checkAndRequestPermissionForContacts() async {
    var status = await Permission.contacts.status;
    PermissionStatus permStatus = null;
    if (status.isUndetermined) {
      // We didn't ask for permission yet.
      permStatus = await Permission.contacts.request();
    } else if (status.isDenied) {
      permStatus = await Permission.contacts.request();
    } else if (status.isGranted) {
      permStatus = status;
    }
    if (permStatus.isGranted) {
      return Future.value(true);
    }
    return Future.value(false);
  }

  Card getContactCard(Contact c) {
    String initial = c.displayName;
    if (initial != null) {
      if (initial.length > 2) {
        initial = initial.substring(0, 2).toUpperCase();
      } else {}
    } else {
      initial = '';
    }
    String no = '';
    if (c.phones != null) {
      c.phones.forEach((f) {
        if ((f.value != null) && (f.value.isNotEmpty)) {
          no = f.value;
        }
      });
    }
    return Card(
      child: ListTile(
        key: Key(c.identifier),
        onTap: () {
        },
        leading: (c.avatar != null && c.avatar.isNotEmpty)
            ? CircleAvatar(backgroundImage: MemoryImage(c.avatar))
            : CircleAvatar(
                child: c.initials() != null && c.initials().isNotEmpty
                    ? Text(c.initials())
                    : Text(initial)),
        title: Text(c.displayName ?? ''),
        subtitle: Text(no ?? ''),
      ),
    );
  }

  List<Card> getContactCards() {
    final xs = _contacts.map((c) {
      getContactCard(c);
    }).toList();
    //print('No of contacts = ${xs.length}');
    return xs;
  }

  List<RequestSummary> loadAllContacts(List<Contact> tmpcontacts) {
    List<RequestSummary> contacts = [];
    tmpcontacts.forEach((document) {
      print(document);
      contacts.add(RequestSummary(
        key: Key(document.identifier),
        code: document.identifier,
        receiver: document.displayName,
        amount: '0',
        currency: '',
        date: '',
        info: document.birthday.toString(),
        txnType: RequestSummaryType.sent,
        user: user,
      ));
    });
    return contacts;
  }

  void refreshContacts() async {
    bool permissionStatus = await checkAndRequestPermissionForContacts();
    if (permissionStatus) {
      // Load without thumbnails initially.
      var contacts =
          (await ContactsService.getContacts(withThumbnails: false)).toList();
//      var contacts = (await ContactsService.getContactsForPhone("8554964652"))
//          .toList();
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });

      // Lazy load thumbnails after rendering initial contacts.
      for (final contact in contacts) {
        ContactsService.getAvatar(contact).then((avatar) {
          if (avatar == null) return; // Don't redraw if no change.
          setState(() => contact.avatar = avatar);
        });
      }
    } else {
      throw PlatformException(
          code: 'PERMISSION_DENIED',
          message: 'Access to contacts service denied',
          details: null);
    }
  }

  @override
  void initState() {
    super.initState();
    //callsScroll();
    refreshContacts();
    /*
    checkAndRequestPermissionForContacts().then((onValue){
        if (onValue) {
          refreshContacts();
        }
    });
    */
  }

  @override
  void dispose() {
    _scrollBottomBarController.removeListener(() {});
    _contacts = null;
    contacts = null;
    friendList = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Text('Contacts'),
        centerTitle: true,
      ),
      body: _contacts == null
          ? Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
              ? Container(
                  height: _height * 0.8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          'No contact(s) found for you.',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          'Please grant persmission to access your contact list',
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _contacts?.length ?? 0,
                  itemBuilder: (BuildContext context, int index) {
                    Contact c = _contacts?.elementAt(index);
                    return getContactCard(c);
                  }),
    );
  }
}

class ItemsTile extends StatelessWidget {
  ItemsTile(this._title, this._items);
  final Iterable<Item> _items;
  final String _title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ListTile(title: Text(_title)),
        Column(
          children: _items
              .map(
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0.0),
                  child: ListTile(
                    title: Text(i.label ?? ''),
                    trailing: Text(i.value ?? ''),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
