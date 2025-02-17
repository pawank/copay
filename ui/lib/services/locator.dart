import 'package:copay/services/donation_api.dart';
import 'package:copay/services/donation_api_impl.dart';
import 'package:copay/services/enhanced_user_api.dart';
import 'package:copay/services/enhanced_user_impl.dart';
import 'package:copay/services/feedback_api.dart';
import 'package:copay/services/feedback_api_impl.dart';
import 'package:copay/services/firebase_api.dart';
import 'package:copay/services/request_call_api.dart';
import 'package:copay/services/request_call_impl.dart';
import 'package:get_it/get_it.dart';

GetIt locator = GetIt();

void setupLocator() {
  locator.registerLazySingleton(() => Api('users'));
  locator.registerLazySingleton(() => EnhancedUserApi('profiles'));
  locator.registerLazySingleton(() => EnhancedProfileRepo());
  locator.registerLazySingleton(() => RequestCallApi('request_calls'));
  locator.registerLazySingleton(() => RequestCallRepo());
  locator.registerLazySingleton(() => DonationApi('donations'));
  locator.registerLazySingleton(() => DonationRepo());
  locator.registerLazySingleton(() => DonationFeedbackApi('feedbacks'));
  locator.registerLazySingleton(() => DonationFeedbackRepo());
}
