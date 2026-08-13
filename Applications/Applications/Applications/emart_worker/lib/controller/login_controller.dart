import 'dart:developer';

import 'package:sharehands_worker/constant/constants.dart';
import 'package:sharehands_worker/constant/show_toast_dialog.dart';
import 'package:sharehands_worker/main.dart';
import 'package:sharehands_worker/model/worker_model.dart';
import 'package:sharehands_worker/services/firebase_helper.dart';
import 'package:sharehands_worker/services/helper.dart';
import 'package:sharehands_worker/ui/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
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
    await showProgress(context, 'Logging in, please wait...'.tr, false);
    dynamic result = await FireStoreUtils.loginWithEmailAndPassword(email.trim(), password.trim());
    await hideProgress();
    if (result != null && result is WorkerModel) {
      if (result.active == true) {
        await FireStoreUtils.updateCurrentUser(result);
        log("result ans:${result.fcmToken}");
        MyAppState.currentUser = result;
        Get.offAll(const DashBoardScreen(), arguments: {'user': result});
      } else {
        ShowToastDialog.showToast("Your account is deactivate.Please contact to administrator");
      }
    } else if (result != null && result is String) {
      showAlertDialog("Couldn't Authenticate".tr, result, true);
    } else {
      showAlertDialog("Couldn't Authenticate".tr, 'Login failed, Please try again.'.tr, true);
      log("result ans:$result");
    }
  }
}
