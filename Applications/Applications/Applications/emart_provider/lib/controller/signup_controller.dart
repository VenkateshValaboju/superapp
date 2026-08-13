import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sharehandsprovider/constant/constants.dart';
import 'package:sharehandsprovider/constant/show_toast_dialog.dart';
import 'package:sharehandsprovider/main.dart';
import 'package:sharehandsprovider/model/user.dart';
import 'package:sharehandsprovider/services/firebase_helper.dart';
import 'package:sharehandsprovider/services/helper.dart';
import 'package:sharehandsprovider/ui/dashboard/dashboard_screen.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SignUpController extends GetxController {
  Rx<TextEditingController> passwordController = TextEditingController().obs;
  Rx<GlobalKey<FormState>> key = GlobalKey<FormState>().obs;
  RxString firstName = "".obs;
  RxString lastName = "".obs;
  RxString email = "".obs;
  RxString mobile = "".obs;
  RxString password = "".obs;
  RxString confirmPassword = "".obs;
  AutovalidateMode validate = AutovalidateMode.disabled;
  File? image;
  dynamic auto_approve_provider = false;

  @override
  void onInit() {
    getData();
    super.onInit();
  }

  getData() async {
    await FirebaseFirestore.instance.collection(Setting).doc('provider').get().then((value) {
      auto_approve_provider = value.data()!['auto_approve_provider'];
      update();
    });
  }

  /// if the fields are validated and location is enabled we create a new user
  /// and navigate to [ContainerScreen] else we show error
  signUpWithEmailAndPassword(BuildContext context) async {
    if (key.value.currentState?.validate() ?? false) {
      key.value.currentState!.save();
      ShowToastDialog.showLoader('Creating new account, Please wait...'.tr);
      dynamic result = await FireStoreUtils.firebaseSignUpWithEmailAndPassword(
          email.toString().trim(), password.toString().trim(), image, firstName.toString(), lastName.toString(), mobile.toString(), auto_approve_provider);
      ShowToastDialog.closeLoader();
      if (result != null && result is User) {
        if (auto_approve_provider == true) {
          MyAppState.currentUser = result;
          Get.offAll(const DashBoardScreen(), arguments: {'user': result});
        } else {
          showAlertDialog(context, 'Signup Successfull'.tr, "Thank you for sign up, your application is under approval so please wait till that approve.".tr, true, login: true);
        }
      } else if (result != null && result is String) {
        showAlertDialog(context, 'Failed'.tr, result, true);
      } else {
        // ignore: use_build_context_synchronously
        showAlertDialog(context, 'Failed'.tr, "Couldn't sign up".tr, true);
      }
    } else {
      validate = AutovalidateMode.onUserInteraction;
      update();
    }
  }

  /// dispose text controllers to avoid memory leaks
  @override
  void dispose() {
    passwordController.value.dispose();
    image = null;
    super.dispose();
  }
}
