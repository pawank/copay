import 'package:copay/app/sign_in/sign_in_page.dart';
import 'package:copay/models/page_modal.dart';
import 'package:copay/screens/app_tutorial_view_indicator.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTutorial extends StatelessWidget {
  const AppTutorial({Key key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFf7fbff),
      body: AppTutorialBody(),
    );
  }
}

class AppTutorialBody extends StatefulWidget {

  @override
  AppTutorialBodyState createState() => AppTutorialBodyState();
}

class AppTutorialBodyState extends State<AppTutorialBody> {
  PageController _pageController;
  CrossFadeState _bottomState = CrossFadeState.showFirst;
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_pageListener);
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.removeListener(_pageListener);
    _pageController.dispose();
  }

  void _pageListener() {
    if (_pageController.hasClients) {
      double page = _pageController.page ?? _pageController.initialPage;
      setState(() {
        if (page >= 1.5) {
          _bottomState = CrossFadeState.showSecond;
        } else {
          _bottomState = CrossFadeState.showFirst;
        }
      });
    }
  }
  
  Future<bool> setDemoSplashViewed() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool('copay_demo_splash', false);
  }


  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        PageView.builder(
          controller: _pageController,
          itemCount: pages.length,
          itemBuilder: (BuildContext context, int index) {
            return 
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: 50.0),
                CircleAvatar(
                  backgroundColor: Color(0xFFf7fbff),
                  backgroundImage: AssetImage(pages[index].assetImagePath),
                  radius: 130.0,
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      top: 50.0, left: 60.0, right: 40.0, bottom: 100.0),
                  child: Text(
                    pages[index].text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Color(0xFF475d9a),
                        fontWeight: FontWeight.w600,
                        fontSize: 20.0),
                  ),
                ),
              ],
            );
          },
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 96.0,
            alignment: Alignment.center,
            child: AnimatedCrossFade(
              crossFadeState: _bottomState,
              duration: Duration(milliseconds: 300),
              firstChild: PageIndicators(
                pageController: _pageController,
              ),
              secondChild: FlatButton(
                //color: Colors.greenAccent,
                color: Colors.blue,
                onPressed: () async {
                  await setDemoSplashViewed();
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) {
                  return SignInPageBuilder();
                },
              ),
            );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 18.0, horizontal: 98.0),
                  child: Text(
                    'Get Started',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PageIndicators extends StatelessWidget {
  final PageController pageController;

  const PageIndicators({Key key, this.pageController}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Image.asset('assets/app-logo.png'),
        Align(
            alignment: Alignment.center,
            child: PageViewIndicator(
              controller: pageController,
              pageCount: 3,
              color: Colors.blueGrey,
            )),
        Align(
          alignment: Alignment.centerRight,
          child: InkWell(
            onTap: () {
              pageController.animateToPage(2,
                  curve: Curves.decelerate,
                  duration: Duration(milliseconds: 500));
            },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
              child: Text(
                'Skip',
                textAlign: TextAlign.end,
                style: TextStyle(
                    color: Color(0xFF475d9a),
                    fontWeight: FontWeight.w700,
                    fontSize: 19.0),
              ),
            ),
          ),
        ),
      ],
    );
  }
}