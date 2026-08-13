import 'package:sharehandsprovider/model/onprovider_order_model.dart';
import 'package:sharehandsprovider/model/worker_model.dart';
import 'package:sharehandsprovider/services/firebase_helper.dart';
import 'package:get/get.dart';

class AssignWorkerController extends GetxController {
  RxString selectedWorkerRadioTile = ''.obs;
  RxString fcmToken = ''.obs;
  RxBool select = false.obs;
  RxList<WorkerModel> workerModel = <WorkerModel>[].obs;
  Rx<OnProviderOrderModel> onProviderOrder = OnProviderOrderModel().obs;
  @override
  void onInit() {
    getArgument();
    getData();
    super.onInit();
  }

  void getArgument() async {

    dynamic argumentData = Get.arguments;
    if (argumentData != null) {

      onProviderOrder.value = argumentData['onProviderOrder'];

    }
    update();
  }

  getData() async {
    await FireStoreUtils.getAllOnlineWorkers().then((value) {
      workerModel.value = value;
    });
    update();
  }
}