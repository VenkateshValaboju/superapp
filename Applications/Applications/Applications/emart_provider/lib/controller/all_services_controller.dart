import 'package:sharehandsprovider/model/provider_service_model.dart';
import 'package:sharehandsprovider/services/firebase_helper.dart';
import 'package:get/get.dart';

class AllServicesController extends GetxController {
  RxBool isLoading = true.obs;
  RxList<ProviderServiceModel> providerModel = <ProviderServiceModel>[].obs;

  @override
  void onInit() {
    getData();
    super.onInit();
  }

  getData() async {
    await FireStoreUtils.getProviderServices().then((value) {
      providerModel.value = value;
    });

    isLoading.value = false;
  }
}
