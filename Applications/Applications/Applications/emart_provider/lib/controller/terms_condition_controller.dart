import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sharehandsprovider/constant/constants.dart';
import 'package:get/get.dart';

class TermsConditionController extends GetxController {
  RxString termsAndCondition = ''.obs;
  RxString privacyPolicy = ''.obs;

  @override
  void onInit() {
    FirebaseFirestore.instance.collection(Setting).doc("termsAndConditions").get().then((value) {
      termsAndCondition.value = value['terms_and_condition'].toString();
    });
    FirebaseFirestore.instance.collection(Setting).doc("privacyPolicy").get().then((value) {
      privacyPolicy.value = value['privacy_policy'].toString();
    });
    update();
    super.onInit();
  }
}
