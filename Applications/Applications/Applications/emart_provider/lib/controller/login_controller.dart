import 'package:sharehandsprovider/constant/show_toast_dialog.dart';
import 'package:sharehandsprovider/main.dart';
import 'package:sharehandsprovider/model/user.dart';
import 'package:sharehandsprovider/services/firebase_helper.dart';
import 'package:sharehandsprovider/services/helper.dart';
import 'package:sharehandsprovider/services/preferences.dart';
import 'package:sharehandsprovider/ui/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  Rx<TextEditingController> emailController = TextEditingController().obs;
  Rx<TextEditingController> passwordController = TextEditingController().obs;
  AutovalidateMode validate = AutovalidateMode.disabled;
  Rx<GlobalKey<FormState>> key = GlobalKey<FormState>().obs;

  login(context) async {
    if (key.value.currentState?.validate() ?? false) {
      key.value.currentState!.save();
      await _loginWithEmailAndPassword(emailController.value.text.trim(), passwordController.value.text.trim(), context);
    } else {
      validate = AutovalidateMode.onUserInteraction;
    }
  }

  /// login with email and password with firebase
  /// @param email user email
  /// @param password user password
  _loginWithEmailAndPassword(String email, String password, BuildContext context) async {
    ShowToastDialog.showLoader('Logging in, please wait...'.tr);
    dynamic result = await FireStoreUtils.loginWithEmailAndPassword(email.trim(), password.trim());
    ShowToastDialog.closeLoader();
    if (result != null && result is User && result.role == 'provider') {
      if (result.active == true) {
        result.active = true;
        Preferences.setString(Preferences.passwordKey, password);
        await FireStoreUtils.updateCurrentUser(result);
        print("result ans:" + result.fcmToken);
        MyAppState.currentUser = result;
        Get.offAll(const DashBoardScreen(), arguments: {'user': result});
      } else {
        showAlertDialog(context, 'Your account has been disabled, Please contact to admin.'.tr, "", true);
      }
    } else if (result != null && result is String) {
      showAlertDialog(context, "Couldn't Authenticate".tr, result, true);
    } else {
      showAlertDialog(context, "Couldn't Authenticate".tr, 'Login failed, Please try again.'.tr, true);
      print("result ans:" + result.toString());
    }
  }

  loginWithFacebook(BuildContext context) async {
    try {
      ShowToastDialog.showLoader('Logging in, Please wait...'.tr);
      dynamic result = await FireStoreUtils.loginWithFacebook();
      ShowToastDialog.closeLoader();
      if (result != null && result is User) {
        MyAppState.currentUser = result;
        if (result.active == true) {
          Get.offAll(const DashBoardScreen(), arguments: {'userId': ''});
        } else {
          await FacebookAuth.instance.logOut();
          showAlertDialog(context, 'Your account has been disabled, Please contact to admin.'.tr, "", true);
        }
      } else if (result != null && result is String) {
        showAlertDialog(context, 'Error'.tr, "$result", true);
      } else {
        showAlertDialog(context, 'Error'.tr, "Couldn't login with facebook.".tr, true);
      }
    } catch (e, s) {
      ShowToastDialog.closeLoader();
      print('_LoginScreen.loginWithFacebook $e $s');
      showAlertDialog(context, 'Error'.tr, "Couldn't login with facebook.".tr, true);
    }
  }

  loginWithApple(BuildContext context) async {
    try {
      ShowToastDialog.showLoader('Logging in, Please wait...'.tr);
      dynamic result = await FireStoreUtils.loginWithApple();
      ShowToastDialog.closeLoader();
      if (result != null && result is User) {
        MyAppState.currentUser = result;
        if (MyAppState.currentUser!.active == true) {
          Get.offAll(const DashBoardScreen());
        } else {
          showAlertDialog(context, 'Your account has been disabled, Please contact to admin.'.tr, "", true);
        }
      } else if (result != null && result is String) {
        showAlertDialog(context, 'Error'.tr, result.tr, true);
      } else {
        showAlertDialog(context, 'Error'.tr, "Couldn't login with apple.".tr, true);
      }
    } catch (e, s) {
      ShowToastDialog.closeLoader();
      print('_LoginScreen.loginWithApple $e $s');
      showAlertDialog(context, 'Error'.tr, "Couldn't login with apple.".tr, true);
    }
  }
}
