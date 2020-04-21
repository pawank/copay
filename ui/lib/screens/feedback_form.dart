// Create a Form widget.
import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:copay/common_widgets/loading.dart';
import 'package:copay/common_widgets/platform_alert_dialog.dart';
import 'package:copay/models/feedback.dart';
import 'package:copay/screens/txn.dart';
import 'package:copay/services/feedback_api.dart';
import 'package:copay/services/feedback_api_impl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'dart:io';
//For getTemporaryDirectory
import 'package:path_provider/path_provider.dart';
import 'package:copay/screens/camera_app.dart';
import 'package:copay/services/auth_service.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class DonationFeedbackForm extends StatefulWidget {
  DonationFeedbackForm(@required this.user, @required this.feedbackBy,
      @required this.feedbackOwner, @required this.code);
  final User user;
  final String feedbackBy;
  final String feedbackOwner;
  String code;
  @override
  DonationFeedbackFormState createState() {
    return DonationFeedbackFormState(user, feedbackBy, feedbackOwner, code);
  }
}

// Create a corresponding State class.
// This class holds data related to the form.
class DonationFeedbackFormState extends State<DonationFeedbackForm> {
  DonationFeedbackFormState(
      this.user, this.feedbackBy, this.feedbackOwner, this.code);
  final User user;
  final String feedbackBy;
  final String feedbackOwner;
  String code;
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a GlobalKey<FormState>,
  // not a GlobalKey<DonationFeedbackFormState>.
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _feedbackController =
      TextEditingController(text: '');
  double rating;
  String imageUrl;
  String videoUrl;
  DonationFeedbackRepo feedbackRepo;
  Image imageThumbnail;
  Image videoThumbnail;
  String _loadingMessage = 'Loading...';
  bool _isLoading = true;
  //List<DonationFeedback> feedbacks = List();
  bool isScrollingDown = false;
  ScrollController _scrollBottomBarController = new ScrollController();

  void callsScroll() async {
    _scrollBottomBarController.addListener(() {
      if (_scrollBottomBarController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (!isScrollingDown) {
          isScrollingDown = true;
        }
      }
      if (_scrollBottomBarController.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (isScrollingDown) {
          isScrollingDown = false;
        }
      }
    });
  }

  @override
  void initState() {
    setState(() {
      rating = 0.00;
    });

    callsScroll();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    feedbackRepo = Provider.of<DonationFeedbackRepo>(context, listen: false);
    /*
    if (feedbackRepo != null) {
      feedbackRepo.fetchDonationFeedbacksByCodeAndEmail(code, feedbackBy).then((xs){
        setState(() {
          feedbacks = xs;
          _isLoading = false;
        });
      });
    }
    */
  }

  @override
  void dispose() {
    _feedbackController?.dispose();
    _scrollBottomBarController.removeListener(() {});
    super.dispose();
  }

  Future<void> uploadDonationFeedback() async {
    final yesno = await PlatformAlertDialog(
      title: 'Submit Feedback',
      content: 'Saving your feedback on the donation',
      cancelActionText: 'Cancel',
      defaultActionText: 'Save',
    ).show(context);
    if (yesno == true) {
      setState(() {
        _loadingMessage = 'Please wait...';
        _isLoading = true;
      });
      DonationFeedback obj = DonationFeedback(
          feedback: _feedbackController.text.trim(),
          userId: user.uid,
          feedbackBy: feedbackBy,
          feedbackOwner: feedbackOwner,
          donationCode: code,
          imageUrl: imageUrl,
          videoUrl: videoUrl,
          rating: rating,
          at: Timestamp.now());
      bool status = await feedbackRepo.saveDonationFeedback(obj);
      if (status) {
        Fluttertoast.showToast(
            msg: 'Feedback has been successfully submitted',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.black54,
            textColor: Colors.white,
            fontSize: 16.0);
      } else {
        Fluttertoast.showToast(
            msg: 'Feedback cannot be saved. Please try again.',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0);
      }
      setState(() {
        _loadingMessage = 'Loading...';
        _isLoading = false;
      });
    }
  }

  Future<void> generateThumbnails(String urlOrPath, String type) async {
    final int WIDTH = 150;
    if ((urlOrPath != null) && (urlOrPath.isNotEmpty)) {
      if (urlOrPath.startsWith('/')) {
        if (type == 'photo') {
          imageThumbnail = Image.file(new File(urlOrPath));
        } else {
          final uint8list = await VideoThumbnail.thumbnailData(
            video: urlOrPath,
            imageFormat: ImageFormat.PNG,
            maxWidth:
                WIDTH, // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
            quality: 75,
          );
          videoThumbnail = Image.memory(uint8list);
        }
      } else {
        if (type == 'photo') {
          imageThumbnail = Image.network(urlOrPath);
        } else {
          final videopath = await VideoThumbnail.thumbnailFile(
            video: urlOrPath,
            thumbnailPath: (await getTemporaryDirectory()).path,
            imageFormat: ImageFormat.WEBP,
            //maxHeight: 100, // specify the height of the thumbnail, let the width auto-scaled to keep the source aspect ratio
            maxWidth: WIDTH,
            quality: 75,
          );
          final uint8list = await VideoThumbnail.thumbnailData(
            video: videopath,
            imageFormat: ImageFormat.PNG,
            maxWidth:
                WIDTH, // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
            quality: 75,
          );
          videoThumbnail = Image.memory(uint8list);
        }
      }
      setState(() {
        imageThumbnail = imageThumbnail;
        videoThumbnail = videoThumbnail;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size sizeQ = MediaQuery.of(context).size;
    final streamQS = Firestore.instance
        .collection(DonationFeedbackApi.db_name)
        .where('donationCode', isEqualTo: code)
        .where('feedbackBy', isEqualTo: feedbackBy)
        .snapshots();
    // Build a Form widget using the _formKey created above.
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        /*
      theme: ThemeData(
        primaryColor: Colors.blue[900],
        accentColor: Colors.amber,
        accentColorBrightness: Brightness.dark
      ),
      */
        theme: ThemeData(primarySwatch: Colors.indigo),
        home: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(
              'Donation Feedback',
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
            //backgroundColor: Colors.blue,
            elevation: 0,
            leading: new IconButton(
              icon: new Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            actions: <Widget>[],
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  child: Container(
                    //height: 500,
                    padding: EdgeInsets.only(left: 20, right: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          TextFormField(
                            controller: _feedbackController,
                            //enabled: _saveEnabled,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.next,
                            maxLines: null,
                            decoration: InputDecoration(
                              labelText: 'DonationFeedback',
                              helperText:
                                  'What\'s the beneficiary\'s feedback on the donation?',
                              labelStyle: TextStyle(color: Colors.black),
                              errorStyle: TextStyle(color: Colors.red),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: _feedbackController.text != ''
                                    ? BorderSide(color: Colors.black)
                                    : BorderSide(color: Colors.black),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.black),
                              ),
                              // contentPadding: EdgeInsets.only(top: 40, bottom: 20),
                              suffixIcon: Padding(
                                padding: const EdgeInsetsDirectional.only(
                                    top: 18, start: 50),
                                child: Icon(Icons.edit),
                              ),
                            ),
                            style: TextStyle(
                                fontFamily: 'worksans',
                                color: Colors.black,
                                fontSize: 18),
                            //initialValue: address,
                            validator: (value) {
                              if (value.isEmpty) {
                                return 'Please provide your feedback.';
                              }
                              return null;
                            },
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Row(
                            children: <Widget>[
                              Text('Add Photo or Video'),
                              IconButton(
                                icon: Icon(Icons.camera_alt),
                                onPressed: () async {
                                  final data = await Navigator.push(
                                    context,
                                    MaterialPageRoute<String>(
                                      builder: (context) {
                                        return CameraAppHome(
                                            user: user,
                                            code: code,
                                            requestCall: null);
                                      },
                                    ),
                                  ) as String;
                                  print('Data from camera app: $data');
                                  if ((data != null) && (data.isNotEmpty)) {
                                    final tokens = data.split(';');
                                    setState(() {
                                      if (tokens[0].length > 0) {
                                        imageUrl = tokens[0];
                                      }
                                      if (tokens.length > 1) {
                                        if (tokens[1].length > 0) {
                                          videoUrl = tokens[1];
                                        }
                                      }
                                    });
                                    await generateThumbnails(imageUrl, 'photo');
                                    await generateThumbnails(videoUrl, 'video');
                                  }
                                },
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                if (imageThumbnail != null)
                                  Center(
                                    child: GestureDetector(
                                      child: Container(
                                        width: 150,
                                        child: Stack(
                                          children: <Widget>[
                                            imageThumbnail,
                                            Positioned(
                                              left: 50,
                                              top: 50,
                                              child: Icon(
                                                Icons.image,
                                                size: 50,
                                                color: Colors.indigo,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      onTap: () {},
                                    ),
                                  ),
                                if (videoThumbnail != null)
                                  Center(
                                    child: GestureDetector(
                                      child: Container(
                                        width: 150,
                                        child: Stack(
                                          children: <Widget>[
                                            videoThumbnail,
                                            Positioned(
                                              left: 50,
                                              top: 50,
                                              child: Icon(
                                                Icons.play_arrow,
                                                size: 50,
                                                color: Colors.indigo,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      onTap: () {},
                                    ),
                                  ),
                              ]),
                          SizedBox(
                            height: 10,
                          ),
                          RatingBar(
                            initialRating: rating,
                            minRating: 0,
                            direction: Axis.horizontal,
                            allowHalfRating: true,
                            itemCount: 5,
                            itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                            itemBuilder: (context, _) => Icon(
                              Icons.star,
                              color: Colors.amber,
                            ),
                            onRatingUpdate: (ratingValue) {
                              setState(() {
                                rating = ratingValue;
                              });
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: RaisedButton(
                              color: Colors.indigo,
                              onPressed: () async {
                                // Validate returns true if the form is valid, or false
                                // otherwise.
                                if (_formKey.currentState.validate()) {
                                  // If the form is valid, display a Snackbar.
                                  Fluttertoast.showToast(
                                      msg: 'Submitting Feedback..',
                                      toastLength: Toast.LENGTH_LONG,
                                      gravity: ToastGravity.BOTTOM,
                                      timeInSecForIosWeb: 1,
                                      backgroundColor: Colors.black54,
                                      textColor: Colors.white,
                                      fontSize: 16.0);
                                  await uploadDonationFeedback();
                                }
                              },
                              child: Text(
                                'Submit',
                                style: TextStyle(
                                    fontFamily: 'worksans',
                                    color: Colors.white,
                                    fontSize: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Divider(),
              Center(child: Text('All Feedbacks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),),
              Expanded(
                child: Container(
                  padding: EdgeInsets.only(left: 20, right: 20),
                  child: StreamBuilder<QuerySnapshot>(
                      stream: streamQS,
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.hasError)
                          return Text('Error: ${snapshot.error}');
                        switch (snapshot.connectionState) {
                          case ConnectionState.waiting:
                            return LoadingScreen();
                          default:
                            child:
                            final List<DocumentSnapshot> docs =
                                snapshot.data.documents;
                            //print('Doc size for request calls = ${docs.length}');
                            final docsSize = docs.length;
                            if (docsSize <= 0) {
                              return Container(
                                //height: _height * 0.8,
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
                                    if ((user.email == null) ||
                                        (user.email.isEmpty))
                                      Padding(
                                        padding: EdgeInsets.all(10),
                                        child: RaisedButton.icon(
                                          label: Text('Register Now',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16.0)),
                                          elevation: 4.0,
                                          color: Colors.grey,
                                          icon: Icon(Icons.account_circle),
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute<Null>(
                                                builder:
                                                    (BuildContext context) {
                                                  //return SignInPageBuilder();
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
                              final recordsOfCalls =
                                  docs.map((DocumentSnapshot document) {
                                final DonationFeedback obj =
                                    DonationFeedback.fromSnapshot(
                                        document, document.documentID);
                                if (obj != null) {
                                  DateTime dt = obj.at.toDate();
                                  final String date =
                                      new DateFormat.yMMMMd('en_US').format(dt);
                                  return RequestSummary(
                                      code: obj.donationCode,
                                      receiver: obj.feedbackOwner,
                                      amount: obj.rating.toString(),
                                      currency: '',
                                      date: date,
                                      info: obj.feedback,
                                      txnType: RequestSummaryType.sent,
                                      //imageUrl: getFinalUrl(obj.imageUrl),
                                      //mediaUrl: getFinalUrl(obj.mediaUrl),
                                      user: user,
                                      requestOrDonation: 'request');
                                } else {
                                  return Text(
                                      'Request cannot be displayed for reference no: ${document.documentID}');
                                }
                              }).toList();
                              return Container(
                                //height: _height * 0.8,
                                child: recordsOfCalls.isEmpty
                                    ? LoadingScreen()
                                    : ListView(
                                        controller: _scrollBottomBarController,
                                        children: recordsOfCalls,
                                      ),
                              );
                            }
                        }
                      }),
                ),
              ),
            ],
          ),
        ));
  }
}
