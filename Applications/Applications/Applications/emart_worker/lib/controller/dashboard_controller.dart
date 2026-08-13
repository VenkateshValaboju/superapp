import 'package:sharehands_worker/main.dart';
import 'package:sharehands_worker/model/worker_model.dart';
import 'package:sharehands_worker/services/firebase_helper.dart';
import 'package:sharehands_worker/ui/booking_list/booking_list.dart';
import 'package:sharehands_worker/ui/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DashBoardController extends GetxController {
  RxBool isLoading = true.obs;
  final fireStoreUtils = FireStoreUtils();

  RxInt selectedIndex = 0.obs;

  RxList pageList = [
    const BookingListScreen(),
    ProfileScreen(),
  ].obs;

  PageController pageController = PageController(
    initialPage: 0,
  );

  void onItemTapped(int index) {
    selectedIndex.value = index;
    pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  Rx<WorkerModel> user = WorkerModel().obs;
  RxString userId = ''.obs;

  @override
  void onInit() {
    // TODO: implement onInit

    getData();
    super.onInit();
  }

  getData() {
    FireStoreUtils.getWorkerCurrentUser(MyAppState.currentUser!.id.toString()).then((value) {
      MyAppState.currentUser = value;
    });

    isLoading.value = false;
    fireStoreUtils.getPlaceHolderImage();

    /// On iOS, we request notification permissions, Does nothing and returns null on Android
    FireStoreUtils.firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }
}

class DrawerItem {
  String title;
  String icon;

  DrawerItem(this.title, this.icon);
}
