import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sharehandsprovider/constant/constants.dart';
import 'package:sharehandsprovider/main.dart';
import 'package:sharehandsprovider/model/user.dart';
import 'package:sharehandsprovider/services/firebase_helper.dart';
import 'package:sharehandsprovider/services/preferences.dart';
import 'package:sharehandsprovider/ui/dashboard/dashboard_screen.dart';
import 'package:sharehandsprovider/ui/on_boarding_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:sharehandsprovider/ui/auth/auth_screen.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:get/get.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    Timer(const Duration(seconds: 3), () => redirectScreen());
    super.onInit();
  }

  redirectScreen() async {
    if (Preferences.getBoolean(Preferences.isFinishOnBoardingKey) == false) {
      Get.offAll(const OnBoardingScreen());
    } else {

      auth.User? firebaseUser = auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        User? user = await FireStoreUtils.getCurrentUser(firebaseUser.uid);

        if (user != null && user.role == USER_ROLE_PROVIDER) {
          if (user.active == true) {
            user.active = true;
            user.role = USER_ROLE_PROVIDER;
            FireStoreUtils.firebaseMessaging.getToken().then((value) async {
              user.fcmToken = value!;
              await FireStoreUtils.firestore.collection(USERS).doc(user.userID).update({"fcmToken": user.fcmToken});

            });
            MyAppState.currentUser = user;
            Get.offAll(const DashBoardScreen(), arguments: {'user': user});
          } else {
            user.lastOnlineTimestamp = Timestamp.now();
            await FireStoreUtils.firestore.collection(USERS).doc(user.userID).update({"fcmToken": ""});

            await auth.FirebaseAuth.instance.signOut();
            await FacebookAuth.instance.logOut();
            MyAppState.currentUser = null;
            Get.offAll(AuthScreen());
          }
        } else {
          Get.offAll(AuthScreen());
        }
      } else {

        Get.offAll(AuthScreen());
      }
    }

  }
}
