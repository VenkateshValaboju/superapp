import 'dart:async';

import 'package:sharehands_worker/constant/constants.dart';
import 'package:sharehands_worker/main.dart';
import 'package:sharehands_worker/model/worker_model.dart';
import 'package:sharehands_worker/services/firebase_helper.dart';
import 'package:sharehands_worker/services/preferences.dart';
import 'package:sharehands_worker/ui/dashboard/dashboard_screen.dart';
import 'package:sharehands_worker/ui/login/login_screen.dart';
import 'package:sharehands_worker/ui/on_boarding_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
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
        WorkerModel? user = await FireStoreUtils.getWorkerCurrentUser(firebaseUser.uid);

        if (user != null) {
          if (user.active == true) {
            user.active = true;
            FireStoreUtils.firebaseMessaging.getToken().then((value) async {
              user.fcmToken = value!;
              await FireStoreUtils.firestore.collection(WORKERS).doc(user.id).update({"fcmToken": user.fcmToken});
            });
            MyAppState.currentUser = user;
            Get.offAll(const DashBoardScreen(), arguments: {'user': user});
          } else {
            await FireStoreUtils.firestore.collection(WORKERS).doc(user.id).update({"fcmToken": ""});
            await auth.FirebaseAuth.instance.signOut();
            MyAppState.currentUser = null;
            Get.offAll(const LoginScreen());
          }
        } else {
          Get.offAll(const LoginScreen());
        }
      } else {
        Get.offAll(const LoginScreen());
      }
    }
  }
}
