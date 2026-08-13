import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sharehandsprovider/constant/constants.dart';
import 'package:sharehandsprovider/constant/show_toast_dialog.dart';
import 'package:sharehandsprovider/main.dart';
import 'package:sharehandsprovider/model/user.dart';
import 'package:sharehandsprovider/services/firebase_helper.dart';
import 'package:sharehandsprovider/services/helper.dart';
import 'package:sharehandsprovider/ui/dashboard/dashboard_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class OtpController extends GetxController {
  final ImagePicker imagePicker = ImagePicker();
  Rx<TextEditingController> firstNameController = TextEditingController().obs;
  Rx<TextEditingController> lastNameController = TextEditingController().obs;
  Rx<GlobalKey<FormState>> key = GlobalKey<FormState>().obs;
  RxString firstName = "".obs;
  RxString lastName = "".obs;
  RxString phoneNumber = "".obs;
  RxString verificationID = "".obs;
  RxBool isPhoneValid = false.obs, codeSent = false.obs;
  AutovalidateMode validate = AutovalidateMode.disabled;

  File? image;
  dynamic auto_approve_provider = false.obs;

  RxBool login = false.obs;

  @override
  void onInit() {
    getArgument();
    getData();
    super.onInit();
  }

  getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      login.value = argumentData['login'];
    }
  }

  getData() async {
    await FirebaseFirestore.instance.collection(Setting).doc('provider').get().then((value) {
      auto_approve_provider = value.data()!['auto_approve_provider'];
      update();
    });
  }

  /// submits the code to firebase to be validated, then get get the user
  /// object from firebase database
  /// @param code the code from input from code field
  /// creates a new user from phone login
  void submitCode(String code, BuildContext context) async {
    ShowToastDialog.showLoader(
      login.value ? 'Logging in...'.tr : 'Signing up...'.tr,
    );
    try {
      dynamic result = await FireStoreUtils.firebaseSubmitPhoneNumberCode(verificationID.toString(), code, phoneNumber.toString(),
              firstName: firstNameController.value.text, lastName: lastNameController.value.text, auto_approve_provider: auto_approve_provider)
          .onError((error, stackTrace) {
        print("==RESULT123" + error.toString());
      });
      print("==RESULT");
      print(result.toString());
      ShowToastDialog.closeLoader();
      if (result != null && result is User && result.role == USER_ROLE_PROVIDER) {
        MyAppState.currentUser = result;
        print("==RESULT");
        print(auto_approve_provider);

        if (login.value == true) {
          if (MyAppState.currentUser!.active == true) {
            Get.offAll(const DashBoardScreen(), arguments: {'user': result});
          } else {
            showAlertDialog(context, "Your account has been disabled, Please contact to admin.".tr, "", true);
          }
        } else {
          if (auto_approve_provider == true) {
            if (MyAppState.currentUser!.active == true) {
              Get.offAll(const DashBoardScreen(), arguments: {'user': result});
            } else {
              showAlertDialog(context, "Your account has been disabled, Please contact to admin.".tr, "", true);
            }
          } else {
            showAlertDialog(context, 'Signup Successfull'.tr, "Thank you for sign up, your application is under approval so please wait till that approve.".tr, true, login: true);
          }
        }
      } else if (result != null && result is String) {
        showAlertDialog(context, 'Failed'.tr, result, true);
      } else {
        showAlertDialog(context, 'Failed'.tr, "Couldn't create new user with phone number.".tr, true);
      }
    } on auth.FirebaseAuthException catch (exception) {
      print("====>${exception.code}");
      ShowToastDialog.closeLoader();
      String message = 'An error has occurred, please try again.'.tr;
      switch (exception.code) {
        case 'invalid-verification-code':
          message = 'Invalid code or has been expired.'.tr;
          break;
        case 'user-disabled':
          message = 'This user has been disabled.'.tr;
          break;
        default:
          message = 'An error has occurred, please try again.'.tr;
          break;
      }
      Get.showSnackbar(
        GetSnackBar(
          message: message.tr,
        ),
      );
    } catch (e, s) {
      print('_PhoneNumberInputScreenState._submitCode $e $s');
      ShowToastDialog.closeLoader();

      Get.showSnackbar(
        GetSnackBar(message: 'An error has occurred, please try again.'.tr),
      );
    }
  }

  signUp(BuildContext context) async {
    if (key.value.currentState?.validate() ?? false) {
      key.value.currentState!.save();
      if (isPhoneValid.value) {
        await submitPhoneNumber(phoneNumber.value.toString(), context);
      } else {
        Get.showSnackbar(
          GetSnackBar(message: 'Invalid phone number, Please try again.'.tr),
        );
      }
    } else {
      validate = AutovalidateMode.onUserInteraction;
      update();
    }
  }

  /// sends a request to firebase to create a new user using phone number and
  /// navigate to [ContainerScreen] after wards
  submitPhoneNumber(String phoneNumber, BuildContext context) async {
    //send code
    ShowToastDialog.showLoader('Sending code...'.tr);
    await FireStoreUtils.firebaseSubmitPhoneNumber(
      phoneNumber,
      (String verificationId) {
        //  if (mounted) {
        ShowToastDialog.closeLoader();
        Get.showSnackbar(
          GetSnackBar(
            message: 'Code verification timeout, request new code.'.tr,
          ),
        );
        codeSent.value = false;
        update();
        // }
      },
      (String? verificationId, int? forceResendingToken) {
        //  if (mounted) {
        ShowToastDialog.closeLoader();
        verificationID.value = verificationId.toString();

        codeSent.value = true;
        update();
        //  }
      },
      (auth.FirebaseAuthException error) {
        // if (mounted) {
        ShowToastDialog.closeLoader();
        String message = 'An error has occurred, please try again.'.tr;
        print("==================${error.message.toString()}");
        print("==================${error.code.toString()}");
        switch (error.code) {
          case 'invalid-verification-code':
            message = 'Invalid code or has been expired.'.tr;
            break;
          case 'user-disabled':
            message = 'This user has been disabled.'.tr;
            break;
          default:
            message = '${error.code}'.tr;
            break;
        }
        Get.showSnackbar(
          GetSnackBar(
            message: message.tr,
          ),
        );
      },
      (auth.PhoneAuthCredential credential) async {
        //  if (mounted) {
        auth.UserCredential userCredential = await auth.FirebaseAuth.instance.signInWithCredential(credential);
        User? user = await FireStoreUtils.getCurrentUser(userCredential.user?.uid ?? '');
        if (user != null) {
          ShowToastDialog.closeLoader();
          MyAppState.currentUser = user;
        } else {
          /// create a new user from phone login
          String profileImageUrl = '';
          if (image != null) {
            profileImageUrl = await FireStoreUtils.uploadUserImageToFireStorage(image!, userCredential.user?.uid ?? '');
          }
          User user = User(
              firstName: firstNameController.value.text,
              lastName: lastNameController.value.text,
              fcmToken: await FireStoreUtils.firebaseMessaging.getToken() ?? '',
              phoneNumber: phoneNumber.toString(),
              active: true,
              lastOnlineTimestamp: Timestamp.now(),
              photos: [],
              email: '',
              role: USER_ROLE_PROVIDER,
              profilePictureURL: profileImageUrl,
              userID: userCredential.user?.uid ?? '',
              createdAt: Timestamp.now());
          String? errorMessage = await FireStoreUtils.firebaseCreateNewUser(user);
          //    await FireStoreUtils.sendNewVendorMail(user);
          ShowToastDialog.closeLoader();
          if (errorMessage == null) {
            MyAppState.currentUser = user;
            Get.offAll(const DashBoardScreen(), arguments: {'user': user});
          } else {
            // ignore: use_build_context_synchronously
            showAlertDialog(context, 'Failed'.tr, "Couldn't create new user with phone number.".tr, true);
          }
        }
        //}
      },
    );
  }
}
