import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sharehandscustomer/constants.dart';
import 'package:sharehandscustomer/main.dart';
import 'package:sharehandscustomer/model/CabOrderModel.dart';
import 'package:sharehandscustomer/model/CodModel.dart';
import 'package:sharehandscustomer/model/FlutterWaveSettingDataModel.dart';
import 'package:sharehandscustomer/model/PayFastSettingData.dart';
import 'package:sharehandscustomer/model/PayStackSettingsModel.dart';
import 'package:sharehandscustomer/model/VehicleType.dart';
import 'package:sharehandscustomer/model/payment_model/mid_trans.dart';
import 'package:sharehandscustomer/model/payment_model/orange_money.dart';
import 'package:sharehandscustomer/model/payment_model/xendit.dart';
import 'package:sharehandscustomer/model/paypalSettingData.dart';
import 'package:sharehandscustomer/model/paytmSettingData.dart';
import 'package:sharehandscustomer/model/razorpayKeyModel.dart';
import 'package:sharehandscustomer/model/stripeSettingData.dart';
import 'package:sharehandscustomer/services/FirebaseHelper.dart';
import 'package:sharehandscustomer/theme/app_them_data.dart';
import 'package:sharehandscustomer/userPrefrence.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe1;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../model/MercadoPagoSettingsModel.dart';

class CabPaymentSelectionScreen extends StatefulWidget {
  final LatLng? departureLatLong;
  final LatLng? destinationLatLong;
  final String? departureName;
  final String? destinationName;
  final String? subTotal;
  final VehicleType? vehicleType;
  final String? vehicleId;
  final String? distance;
  final String? duration;

  CabPaymentSelectionScreen(
      {Key? key,
      this.departureLatLong,
      this.destinationLatLong,
      this.departureName,
      this.destinationName,
      this.subTotal,
      this.vehicleType,
      this.vehicleId,
      this.distance,
      this.duration})
      : super(key: key);

  @override
  State<CabPaymentSelectionScreen> createState() =>
      _CabPaymentSelectionScreenState();
}

class _CabPaymentSelectionScreenState extends State<CabPaymentSelectionScreen> {
  final fireStoreUtils = FireStoreUtils();

  String paymentOption = "Pay Via Wallet".tr();
  RazorPayModel? razorPayData = UserPreference.getRazorPayData();

  CodModel? futurecod;
  StripeSettingData? stripeData;
  PaytmSettingData? paytmSettingData;
  PaypalSettingData? paypalSettingData;
  PayStackSettingData? payStackSettingData;
  FlutterWaveSettingData? flutterWaveSettingData;
  MercadoPagoSettingData? mercadoPagoSettingData;
  PayFastSettingData? payFastSettingData;
  MidTrans? midTransModel;
  OrangeMoney? orangeMoneyModel;
  Xendit? xenditModel;

  String paymentType = "";
  bool isStaging = true;
  bool restrictAppInvoke = false;
  bool enableAssist = true;
  String result = "";

  bool isLoading = true;

  getPaymentSettingData() async {
    // await UserPreference.getStripeData().then((value) async {
    //   stripeData = value;
    //   stripe1.Stripe.publishableKey = stripeData!.clientpublishableKey;
    //   stripe1.Stripe.merchantIdentifier = PAYID;
    //   await stripe1.Stripe.instance.applySettings();
    // });
    razorPayData = await UserPreference.getRazorPayData();
    paytmSettingData = await UserPreference.getPaytmData();
    paypalSettingData = await UserPreference.getPayPalData();
    payStackSettingData = await UserPreference.getPayStackData();
    flutterWaveSettingData = await UserPreference.getFlutterWaveData();
    mercadoPagoSettingData = await UserPreference.getMercadoPago();
    payFastSettingData = await UserPreference.getPayFastData();
    midTransModel = await UserPreference.getMidTransData();
    orangeMoneyModel = await UserPreference.getOrangeData();
    xenditModel = await UserPreference.getXenditData();
    await fireStoreUtils.getCod().then((value) {
      setState(() {
        futurecod = value;
      });
    });
    isLoading = false;
  }

  showAlert(BuildContext context123,
      {required String response, required Color colors}) {
    return ScaffoldMessenger.of(context123).showSnackBar(SnackBar(
      content: Text(response),
      backgroundColor: colors,
    ));
  }

  @override
  void initState() {
    selectedRadioTile = '';
    getPaymentSettingData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode(context) ? AppThemeData.surfaceDark : AppThemeData.surface,
      extendBody: true,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(6.0),
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(4),
            ),
            child: const Center(
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Text("Select Payment Method".tr()),
                buildPaymentTile(
                  isVisible: UserPreference.getWalletData() ?? false,
                  selectedPayment: wallet,
                  image: "assets/images/wallet_icon.png",
                  value: "Wallet".tr(),
                ),

                buildPaymentTile(
                  isVisible: UserPreference.getWalletData() ?? false,
                  selectedPayment: codPay,
                  image: "assets/images/cash.png",
                  value: "Cash".tr(),
                ),
                buildPaymentTile(
                  isVisible: true,
                  selectedPayment: telebirr,
                  image: "assets/images/telebirr.png",
                  value: "Telebirr".tr(),
                ),
                buildPaymentTile(
                  isVisible: true,
                  selectedPayment: ebirr,
                  image: "assets/images/ebirr.png",
                  value: "eBirr".tr(),
                ),
                buildPaymentTile(
                  isVisible: true,
                  selectedPayment: cbebirr,
                  image: "assets/images/cbebirr.png",
                  value: "CBE Birr".tr(),
                ),
                buildPaymentTile(
                  isVisible: true,
                  selectedPayment: wegagen,
                  image: "assets/images/wegagen.png",
                  value: "Wegagen".tr(),
                ),
                buildPaymentTile(
                  isVisible: true,
                  selectedPayment: paypal,
                  image: "assets/images/paypal_@3x.png",
                  value: "Paypal".tr(),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: AppThemeData.primary300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      if (selectedRadioTile.toString().toLowerCase() == "telebirr" || selectedRadioTile.toString().toLowerCase() == "cbebirr" 
                      || selectedRadioTile.toString().toLowerCase() == "ebirr" || selectedRadioTile.toString().toLowerCase() == "wegagen" 
                      || selectedRadioTile.toString().toLowerCase() == "paypal" || selectedRadioTile.toString().toLowerCase() == "wallet"
                      || selectedRadioTile.toString().toLowerCase() == "cash") {
                        paymentType = 'chapa';
                        placeRides();
                      } else {
                        final SnackBar snackBar = SnackBar(
                          content: Text(
                            "Select Payment Method".tr(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: AppThemeData.primary300,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      }
                    },
                    child: Text(
                      "Continue".tr(),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  bool isDarkMode(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.light) {
      return false;
    } else {
      return true;
    }
  }

  setAllFalse({required String value}) {
    setState(() {
      telebirr = false;
      cbebirr = false;
      ebirr = false;
      wegagen = false;
      paypal = false;
      wallet = false;
      codPay = false;

      if (value == "Cash") {
        codPay = true;
      }
      if (value == "Wallet") {
        wallet = true;
      }
      if (value == "PayPal") {
        paypal = true;
      }

      if (value == "Telebirr") {
        telebirr = true;
      }

      if (value == "eBirr") {
        ebirr = true;
      }

      if (value == "CBE Birr") {
        cbebirr = true;
      }

      if (value == "Wegagen") {
        wegagen = true;
      }
    });
  }

  String? selectedRadioTile;

  buildPaymentTile({
    bool walletError = false,
    Widget childWidget = const Center(),
    required bool isVisible,
    String value = "Stripe",
    image = "assets/images/stripe.png",
    required selectedPayment,
  }) {
    return Visibility(
      visible: isVisible,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            color: isDarkMode(context) ? AppThemeData.grey900 : AppThemeData.grey50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            shadows: [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 32,
                offset: Offset(0, 0),
                spreadRadius: 0,
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: RadioListTile(
              controlAffinity: ListTileControlAffinity.trailing,
              value: value ?? '',
              groupValue: selectedRadioTile,
              onChanged: walletError != true
                  ? (String? value) {
                      setState(() {
                        print('value: $value ##############');
                        setAllFalse(value: value!);
                        selectedPayment = true;
                        selectedRadioTile = value;
                      });
                    }
                  : (String? value) {},
              selected: selectedPayment,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 6,
              ),

              toggleable: true,
              activeColor: AppThemeData.primary300,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4.0, horizontal: 10),
                            child: SizedBox(
                              width: 60,
                              height: 35,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6.0),
                                child: Image.asset(image),
                              ),
                            ),
                          )),
                      const SizedBox(
                        width: 10,
                      ),
                      Text(value,
                          style: TextStyle(
                            color: isDarkMode(context)
                                ? const Color(0xffFFFFFF)
                                : Colors.black,
                          )),
                    ],
                  ),
                  childWidget
                ],
              ),
              //toggleable: true,
            ),
          ),
        ),
      ),
    );
  }

  placeRides() async {
    LocationDatas sourceLocation = LocationDatas(
      latitude: widget.departureLatLong!.latitude,
      longitude: widget.departureLatLong!.longitude,
    );

    LocationDatas destinationLocation = LocationDatas(
      latitude: widget.destinationLatLong!.latitude,
      longitude: widget.destinationLatLong!.longitude,
    );

    CabOrderModel orderModel = CabOrderModel(
        author: MyAppState.currentUser,
        authorID: MyAppState.currentUser!.userID,
        createdAt: Timestamp.now(),
        status: ORDER_STATUS_PLACED,
        paymentMethod: paymentType,
        vehicleType: widget.vehicleType,
        vehicleId: widget.vehicleId,
        duration: widget.duration,
        distance: widget.distance,
        subTotal: widget.subTotal,
        destinationLocation: destinationLocation,
        destinationLocationName: widget.destinationName.toString(),
        sourceLocationName: widget.departureName.toString(),
        sourceLocation: sourceLocation,
        sectionId: sectionConstantModel!.id,
        rideType: "ride",
        scheduleDateTime: Timestamp.now(),
        scheduleReturnDateTime: Timestamp.now());

    await FireStoreUtils().cabOrderPlace(orderModel, false);

    Navigator.pop(context, true);
  }

  bool telebirr = false;
  bool cbebirr = false;
  bool ebirr = false;
  bool wegagen = false;
  bool paypal = false;
  bool wallet = false;
  bool codPay = false;
}
