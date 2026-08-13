import 'package:sharehandsprovider/model/rating_model.dart';
import 'package:sharehandsprovider/model/worker_model.dart';
import 'package:sharehandsprovider/services/firebase_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BookingDetailsController extends GetxController {
  RxList<RatingModel> ratingService = <RatingModel>[].obs;
  Rx<TextEditingController> chargesController = TextEditingController().obs;
  Rx<TextEditingController> descriptionController = TextEditingController().obs;
  RxString workerName = ''.obs;

  Rx<WorkerModel> worker = WorkerModel().obs;

  @override
  void onInit() {
    getArgument();

    super.onInit();
  }

  Rx<DateTime> selectedDateTime = DateTime.now().obs;
  Rx<TextEditingController> dateTimeController = TextEditingController().obs;


  RxDouble subTotal = 0.0.obs;
  RxDouble price = 0.0.obs;
  RxDouble discount = 0.0.obs;
  RxDouble totalAmount = 0.0.obs;
  RxDouble adminComm = 0.0.obs;
  RxString orderId = ''.obs;

  getArgument() async {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      orderId.value = argumentData['orderId'];
    }
    await FireStoreUtils().getReviewByProviderServiceId(orderId.toString()).then((value) {
      ratingService.value = value;
    });
    update();
  }


}
