import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sharehandsprovider/constant/show_toast_dialog.dart';
import 'package:sharehandsprovider/main.dart';
import 'package:sharehandsprovider/model/worker_model.dart';
import 'package:sharehandsprovider/services/firebase_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:get/get_rx/get_rx.dart';

class AddOrUpdateWorkerController extends GetxController {
  Rx<GlobalKey<FormState>> formKey = GlobalKey<FormState>().obs;
  AutovalidateMode validate = AutovalidateMode.disabled;
  Rx<TextEditingController> firstName = TextEditingController().obs;
  Rx<TextEditingController> lastName = TextEditingController().obs;
  Rx<TextEditingController> email = TextEditingController().obs;
  Rx<TextEditingController> mobile = TextEditingController().obs;
  Rx<TextEditingController> address = TextEditingController().obs;
  Rx<TextEditingController> salary = TextEditingController().obs;
  Rx<TextEditingController> password = TextEditingController().obs;
  RxDouble latValue = 0.0.obs, longValue = 0.0.obs;
  Rx<WorkerModel> workerModel = WorkerModel().obs;
  RxBool isActive = true.obs;

  @override
  void onInit() {
    super.onInit();
    getArgument();
  }

  void getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      workerModel.value = argumentData['workerModel'];
      await getAttribute();
    }
    update();
  }

  getAttribute() async {
    firstName.value.text = workerModel.value.firstName.toString();
    lastName.value.text = workerModel.value.lastName.toString();
    email.value.text = workerModel.value.email.toString();
    mobile.value.text = workerModel.value.phoneNumber.toString();
    address.value.text = workerModel.value.address.toString();
    salary.value.text = workerModel.value.salary.toString();
    latValue.value = workerModel.value.latitude!;
    longValue.value = workerModel.value.longitude!;
    isActive.value = workerModel.value.active!;
  }

  signUpWithWorkerEmailAndPassword(workModel, password, BuildContext context) async {
    if (formKey.value.currentState?.validate() ?? false) {
      formKey.value.currentState!.save();
      ShowToastDialog.showLoader('Creating new account worker, Please wait...'.tr);
      FirebaseApp secondaryApp = await Firebase.initializeApp(
        name: "SecondaryApp",
        options: Firebase.app().options,
      );

      try {
        final credential = await FirebaseAuth.instanceFor(app: secondaryApp).createUserWithEmailAndPassword(
          email: workModel.email.toString(),
          password: password,
        );

        WorkerModel worker = WorkerModel(
            id: credential.user?.uid ?? '',
            firstName: workModel.firstName,
            lastName: workModel.lastName,
            email: workModel.email,
            phoneNumber: workModel.phoneNumber,
            address: workModel.address,
            salary: workModel.salary,
            latitude: workModel.latitude,
            longitude: workModel.longitude,
            geoFireData: workModel.geoFireData,
            providerId: MyAppState.currentUser!.userID,
            createdAt: Timestamp.now(),
            active: true);

        await FireStoreUtils.firebaseCreateNewWorker(worker);
        ShowToastDialog.closeLoader();
        Get.back(result: true);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'weak-password') {
          ShowToastDialog.showToast("The password provided is too weak.");
        } else if (e.code == 'email-already-in-use') {
          ShowToastDialog.showToast("The account already exists for that email.");
        }
      } catch (e) {
        print(e);
      }
    } else {
      validate = AutovalidateMode.onUserInteraction;
      update();
    }
  }
}
