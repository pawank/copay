// Create a Form widget.
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'dart:io';
//For getTemporaryDirectory
import 'package:path_provider/path_provider.dart';
import 'package:copay/screens/camera_app.dart';
import 'package:copay/services/auth_service.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class FeedbackForm extends StatefulWidget {
  FeedbackForm(@required this.user, @required this.code);
  final User user;
  String code;
  @override
  FeedbackFormState createState() {
    return FeedbackFormState(user, code);
  }
}

// Create a corresponding State class.
// This class holds data related to the form.
class FeedbackFormState extends State<FeedbackForm> {
  FeedbackFormState(this.user, this.code);
  final User user;
  String code;
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a GlobalKey<FormState>,
  // not a GlobalKey<FeedbackFormState>.
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _feedbackController =
      TextEditingController(text: '');
  double rating;
  String imageUrl;
  String videoUrl;

  Image imageThumbnail;
  Image videoThumbnail;

  @override
  void dispose() {
    _feedbackController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    setState(() {
      rating = 0.00;
    });

    super.initState();
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
      home: Container(
        color: Theme.of(context).primaryColor,
        child: Scaffold(
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
          body: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.only(left: 20, right: 20),
                  //width: sizeQ.width * 0.8,
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
                            labelText: 'Feedback',
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
                        SizedBox(
                          height: 10,
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
                          onRatingUpdate: (rating) {
                            print(rating);
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: RaisedButton(
                            color: Colors.indigo,
                            onPressed: () {
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
          ),
        ),
      ),
    );
  }
}
