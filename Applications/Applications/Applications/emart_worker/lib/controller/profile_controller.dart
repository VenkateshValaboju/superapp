import 'dart:io';

import 'package:sharehands_worker/main.dart';
import 'package:sharehands_worker/model/user.dart';
import 'package:sharehands_worker/services/firebase_helper.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  Rx<User> provider = User().obs;
  RxBool online = true.obs;

  RxString firstName = ''.obs;
  RxString lastName = ''.obs;
  RxString email = ''.obs;
  File? image;

  @override
  void onInit() {
    super.onInit();
    getData();
  }

  void getData() async {
    await FireStoreUtils.getWorkerCurrentUser(MyAppState.currentUser!.id.toString()).then((value) {
      MyAppState.currentUser = value;
      firstName.value = MyAppState.currentUser!.firstName.toString();
      lastName.value = MyAppState.currentUser!.lastName.toString();
      email.value = MyAppState.currentUser!.email.toString();
      online.value = MyAppState.currentUser!.online!;
    });

    await FireStoreUtils.getProviderUser(MyAppState.currentUser!.providerId.toString()).then((value) {
      provider.value = value!;
    });
    update();
  }
}
