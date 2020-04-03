import 'package:copay/services/enhanced_user_api.dart';
import 'package:copay/services/enhanced_user_impl.dart';
import 'package:copay/services/firebase_api.dart';
import 'package:get_it/get_it.dart';
import './locator.dart';

GetIt locator = GetIt();

void setupLocator() {
  locator.registerLazySingleton(() => Api('users'));
  locator.registerLazySingleton(() => EnhancedUserApi('profiles'));
  locator.registerLazySingleton(() => EnhancedProfileRepo());
}
