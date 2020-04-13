import 'package:camera/camera.dart';
import 'package:copay/app/auth_widget_builder.dart';
import 'package:copay/app/email_link_error_presenter.dart';
import 'package:copay/app/auth_widget.dart';
import 'package:copay/services/apple_sign_in_available.dart';
import 'package:copay/services/auth_service.dart';
import 'package:copay/services/auth_service_adapter.dart';
import 'package:copay/services/enhanced_user_impl.dart';
import 'package:copay/services/firebase_email_link_handler.dart';
import 'package:copay/services/email_secure_store.dart';
import 'package:copay/services/locator.dart';
import 'package:copay/services/request_call_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

List<CameraDescription> cameras = [];

class DataKeys extends StatefulWidget {
  DataKeys({this.photoLink, this.videoLink});
  String photoLink;
  String videoLink;
  @override
  _DataKeysState createState() =>
  _DataKeysState(this.photoLink, this.videoLink);

  }
  
  class _DataKeysState extends State<DataKeys> {
    _DataKeysState(this.photoLink, this.videoLink);
  String photoLink;
  String videoLink;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return null;
  }
}

final GlobalKey<_DataKeysState> dataKeys = GlobalKey<_DataKeysState>();

Future<void> main() async {
  // Fix for: Unhandled Exception: ServicesBinding.defaultBinaryMessenger was accessed before the binding was initialized.
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  setupLocator();
  final appleSignInAvailable = await AppleSignInAvailable.check();
  runApp(MyApp(appleSignInAvailable: appleSignInAvailable));
}

class MyApp extends StatelessWidget {
  // [initialAuthServiceType] is made configurable for testing
  const MyApp(
      {this.initialAuthServiceType = AuthServiceType.firebase,
      this.appleSignInAvailable});
  final AuthServiceType initialAuthServiceType;
  final AppleSignInAvailable appleSignInAvailable;

  @override
  Widget build(BuildContext context) {
    // MultiProvider for top-level services that can be created right away
    return MultiProvider(
      providers: [
        Provider<AppleSignInAvailable>.value(value: appleSignInAvailable),
        Provider<AuthService>(
          create: (_) => AuthServiceAdapter(
            initialAuthServiceType: initialAuthServiceType,
          ),
          dispose: (_, AuthService authService) => authService.dispose(),
        ),
        Provider<EmailSecureStore>(
          create: (_) => EmailSecureStore(
            flutterSecureStorage: FlutterSecureStorage(),
          ),
        ),
        ProxyProvider2<AuthService, EmailSecureStore, FirebaseEmailLinkHandler>(
          update: (_, AuthService authService, EmailSecureStore storage, __) =>
              FirebaseEmailLinkHandler.createAndConfigure(
            auth: authService,
            userCredentialsStorage: storage,
          ),
          dispose: (_, linkHandler) => linkHandler.dispose(),
        ),
        ChangeNotifierProvider(create: (_) => 
            locator<EnhancedProfileRepo>()
        ),
        ChangeNotifierProvider(create: (_) => 
            locator<RequestCallRepo>()
        ),
      ],
      child: AuthWidgetBuilder(
          builder: (BuildContext context, AsyncSnapshot<User> userSnapshot) {
        return MaterialApp(
          theme: ThemeData(primarySwatch: Colors.indigo),
          home: EmailLinkErrorPresenter.create(
            context,
            child: AuthWidget(userSnapshot: userSnapshot),
          ),
        );
      }),
    );
  }
}
