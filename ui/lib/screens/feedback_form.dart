// Create a Form widget.
import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:copay/common_widgets/fullscreen_images.dart';
import 'package:copay/common_widgets/loading.dart';
import 'package:copay/common_widgets/platform_alert_dialog.dart';
import 'package:copay/common_widgets/video_player_app.dart';
import 'package:copay/models/feedback.dart';
import 'package:copay/models/request_call.dart';
import 'package:copay/screens/txn.dart';
import 'package:copay/services/donation_api_impl.dart';
import 'package:copay/services/feedback_api.dart';
import 'package:copay/services/feedback_api_impl.dart';
import 'package:copay/utils.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
    feedbackRepo = Provider.of<DonationFeedbackRepo>(context, listen: false);
    setState(() {
      rating = 0.00;
    });

    callsScroll();
    super.initState();
  }

  Future<DonationFeedback> getFeedback(BuildContext context) async {
    feedbackRepo = Provider.of<DonationFeedbackRepo>(context, listen: false);
    if (feedbackRepo != null) {
      final xs = await feedbackRepo.fetchDonationFeedbacksByCodeAndEmail(
          code, feedbackBy);
      //feedbackRepo.fetchDonationFeedbacksByCodeAndEmail(code, feedbackBy).then((xs){
      if (xs.isNotEmpty) {
        DonationFeedback obj = xs.first;
        /*
          setState(() {
            feedback = obj;
            _feedbackController.text = obj.feedback;
            rating = obj.rating;
            imageUrl = obj.imageUrl;
            videoUrl = obj.videoUrl;
            _isLoading = false;
          });
          */
        await loadImageFromFirebase(obj, 'photo');
        await loadImageFromFirebase(obj, 'video');
        return Future.value(obj);
      }
      //});
    }
    Future.value(null);
  }

  @override
  void dispose() {
    _feedbackController?.dispose();
    _scrollBottomBarController.removeListener(() {});
    feedbackRepo.removeListener(() {});
    imageUrl = null;
    videoUrl = null;
    imageThumbnail = null;
    videoThumbnail = null;
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
      String img = await uploadPic(user.email, null, imageUrl, false);
      String video = await uploadPic(user.email, null, videoUrl, true);
      DonationFeedback obj = DonationFeedback(
          feedback: _feedbackController.text.trim(),
          userId: user.uid,
          feedbackBy: feedbackBy,
          feedbackOwner: feedbackOwner,
          donationCode: code,
          imageUrl: img,
          videoUrl: video,
          rating: rating,
          at: Timestamp.now());
      bool status = await feedbackRepo.saveDonationFeedback(obj);
      DonationRepo repo = Provider.of<DonationRepo>(context, listen: false);
      if (status) {
        final donations = await repo.fetchRequestCallsByCode(code, feedbackBy);
        donations.forEach((d) async {
          if ((obj != null) && (obj.feedback.isNotEmpty)) {
            int old = d.feedback == null || d.feedback.isEmpty
                ? 0
                : int.parse(d.feedback);
            int recent = 1;
            RequestCall data = d;
            data.feedback = (old + recent).toString();
            await repo.saveRequestCall(data);
          }
        });
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

      repo.removeListener(() {});
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
          if (urlOrPath.startsWith('https') || urlOrPath.startsWith('http')) {
            videoThumbnail = Image.asset('assets/copay_transparent_logo.png');
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
      }
      if (mounted) {
      setState(() {
        imageThumbnail = imageThumbnail;
        videoThumbnail = videoThumbnail;
      });
      }
    }
  }

  Future<String> loadImageFromFirebase(
      DonationFeedback u, String imageType) async {
    if ((imageType != null) && (imageType == 'photo')) {
      if ((u.imageUrl != null) && (u.imageUrl.isNotEmpty)) {
        //_profileUrl = u.profileUrl;
        //StorageReference firebaseStorageRef = FirebaseStorage.instance.ref().child('gs://' + _profileUrl);
        final String bucket = 'gs://copay-9d0a7.appspot.com/' + u.imageUrl;
        final Future<StorageReference> firebaseStorageRefF =
            FirebaseStorage.instance.getReferenceFromUrl(bucket);
        firebaseStorageRefF.then<String>((firebaseStorageRef) async {
          final dynamic url = await firebaseStorageRef.getDownloadURL();
          if (url != null) {
            generateThumbnails(url, 'photo');
            if (mounted) {
            setState(() {
              imageUrl = url;
            });
            }
            return url;
          }
        });
      }
    }
    if ((imageType != null) && (imageType == 'video')) {
      if ((u.videoUrl != null) && (u.videoUrl.isNotEmpty)) {
        //_profileUrl = u.profileUrl;
        //StorageReference firebaseStorageRef = FirebaseStorage.instance.ref().child('gs://' + _profileUrl);
        final String bucket = 'gs://copay-9d0a7.appspot.com/' + u.videoUrl;
        Future<StorageReference> firebaseStorageRefF =
            FirebaseStorage.instance.getReferenceFromUrl(bucket);
        firebaseStorageRefF.then<String>((firebaseStorageRef) async {
          final dynamic url = await firebaseStorageRef.getDownloadURL();
          if (url != null) {
            generateThumbnails(url, 'video');
            if (mounted) {
            setState(() {
              videoUrl = url;
            });
            }
            return url;
          }
        });
      }
    }
    Future.value(null);
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
        body: FutureBuilder<DonationFeedback>(
            future: getFeedback(context),
            builder: (BuildContext context,
                AsyncSnapshot<DonationFeedback> snapshot) {
              if (snapshot.hasError) return Text('Error: ${snapshot.error}');
              switch (snapshot.connectionState) {
                //case ConnectionState.waiting:
                //  return _isLoading ? LoadingScreen(message: _loadingMessage,) : Text('');
                default:
                  child:
                  DonationFeedback feedback = snapshot.data;
                  if (false) {
                    return Container(
                      //height: _height * 0.8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.all(10),
                            child: Center(
                              child: Text(
                                'No feedback found for you.',
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(10),
                            child: Center(
                              child: Text(
                                'You can provide your feedback here.',
                                style: TextStyle(fontSize: 15),
                              ),
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
                    bool isFeedbackFound = feedback != null;
                    if (isFeedbackFound) {
                      _feedbackController.text = feedback.feedback;
                      //loadImageFromFirebase(feedback, 'photo');
                      //loadImageFromFirebase(feedback, 'video');
                    }
                    return SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Container(
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
                                      labelText: 'Donation Feedback',
                                      helperText:
                                          'What\'s the beneficiary\'s feedback on the donation?',
                                      labelStyle:
                                          TextStyle(color: Colors.black),
                                      errorStyle: TextStyle(color: Colors.red),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: _feedbackController.text !=
                                                ''
                                            ? BorderSide(color: Colors.black)
                                            : BorderSide(color: Colors.black),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.black),
                                      ),
                                      // contentPadding: EdgeInsets.only(top: 40, bottom: 20),
                                      suffixIcon: Padding(
                                        padding:
                                            const EdgeInsetsDirectional.only(
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
                                          await resetCameraAndVideoPaths(null, null);
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
                                          if ((data != null) &&
                                              (data.isNotEmpty)) {
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
                                            await generateThumbnails(
                                                imageUrl, 'photo');
                                            await generateThumbnails(
                                                videoUrl, 'video');
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        if (imageThumbnail != null)
                                          Center(
                                            child: GestureDetector(
                                              child: Container(
                                                padding: EdgeInsets.all(5),
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
                                              onTap: () {
                                                final route =
                                                    MaterialPageRoute<void>(
                                                  builder: (context) {
                                                    return FullScreenPage(
                                                        imageUrl);
                                                  },
                                                );
                                                Navigator.of(context)
                                                    .push(route);
                                              },
                                            ),
                                          ),
                                        if (videoThumbnail != null)
                                          Center(
                                            child: GestureDetector(
                                              child: Container(
                                                padding: EdgeInsets.all(5),
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
                                              onTap: () {
                                                final route =
                                                    MaterialPageRoute<void>(
                                                  builder: (context) {
                                                    return AppVideoPlayer(
                                                      title: videoUrl != null
                                                          ? 'Playing ${videoUrl}'
                                                          : 'Playing',
                                                      mediaUrl: videoUrl,
                                                    );
                                                  },
                                                );
                                                Navigator.of(context)
                                                    .push(route);
                                              },
                                            ),
                                          ),
                                      ]),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  RatingBar(
                                    initialRating: feedback != null
                                        ? feedback.rating
                                        : rating,
                                    minRating: 0,
                                    direction: Axis.horizontal,
                                    allowHalfRating: true,
                                    itemCount: 5,
                                    itemPadding:
                                        EdgeInsets.symmetric(horizontal: 4.0),
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
                                  if (feedback == null)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16.0),
                                      child: RaisedButton(
                                        color: Colors.indigo,
                                        onPressed: () async {
                                          // Validate returns true if the form is valid, or false
                                          // otherwise.
                                          if (_formKey.currentState
                                              .validate()) {
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
                        ],
                      ),
                    );
                  }
              }
            }),
      ),
    );
  }
}
