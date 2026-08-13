import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sharehandscustomer/model/payment_model/mid_trans.dart';
import 'package:sharehandscustomer/model/payment_model/orange_money.dart';
import 'package:sharehandscustomer/model/payment_model/xendit.dart';
import 'package:sharehandscustomer/services/show_toast_dialog.dart';
import 'package:sharehandscustomer/theme/app_them_data.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:sharehandscustomer/constants.dart';
import 'package:sharehandscustomer/main.dart';
import 'package:sharehandscustomer/model/FlutterWaveSettingDataModel.dart';
import 'package:sharehandscustomer/model/MercadoPagoSettingsModel.dart';
import 'package:sharehandscustomer/model/PayFastSettingData.dart';
import 'package:sharehandscustomer/model/PayStackSettingsModel.dart';

import 'package:sharehandscustomer/model/gift_cards_model.dart';
import 'package:sharehandscustomer/model/gift_cards_order_model.dart';
import 'package:sharehandscustomer/model/paypalSettingData.dart';
import 'package:sharehandscustomer/model/paytmSettingData.dart';
import 'package:sharehandscustomer/model/razorpayKeyModel.dart';
import 'package:sharehandscustomer/model/stripeSettingData.dart';
import 'package:sharehandscustomer/services/FirebaseHelper.dart';
import 'package:sharehandscustomer/services/helper.dart';
import 'package:sharehandscustomer/userPrefrence.dart';

import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe1;
import 'package:uuid/uuid.dart';
import 'package:chapa_unofficial/chapa_unofficial.dart';

class GiftCardPurchaseScreen extends StatefulWidget {
  final GiftCardsModel giftCardModel;
  final String price;
  final String msg;

  const GiftCardPurchaseScreen({super.key, required this.giftCardModel, required this.price, required this.msg});

  @override
  State<GiftCardPurchaseScreen> createState() => _GiftCardPurchaseScreenState();
}

class _GiftCardPurchaseScreenState extends State<GiftCardPurchaseScreen> {
  GiftCardsModel giftCardModel = GiftCardsModel();
  String gradTotal = "0";

  @override
  void initState() {
    giftCardModel = widget.giftCardModel;
    gradTotal = widget.price;
    getPaymentSettingData();
    super.initState();
  }

  Razorpay _razorPay = Razorpay();
  RazorPayModel? razorPayData;
  StripeSettingData? stripeData;
  PaytmSettingData? paytmSettingData;
  PaypalSettingData? paypalSettingData;
  PayStackSettingData? payStackSettingData;
  FlutterWaveSettingData? flutterWaveSettingData;
  PayFastSettingData? payFastSettingData;
  MercadoPagoSettingData? mercadoPagoSettingData;
  MidTrans? midTransModel;
  OrangeMoney? orangeMoneyModel;
  Xendit? xenditModel;

  getPaymentSettingData() async {
    // await UserPreference.getStripeData().then((value) async {
    //   stripeData = value;
    //   stripe1.Stripe.publishableKey = stripeData!.clientpublishableKey;
    //   stripe1.Stripe.merchantIdentifier = 'Foodie';
    //   await stripe1.Stripe.instance.applySettings();
    // });

    razorPayData = await UserPreference.getRazorPayData();
    paytmSettingData = await UserPreference.getPaytmData();
    paypalSettingData = await UserPreference.getPayPalData();
    payStackSettingData = await UserPreference.getPayStackData();
    flutterWaveSettingData = await UserPreference.getFlutterWaveData();
    payFastSettingData = await UserPreference.getPayFastData();
    mercadoPagoSettingData = await UserPreference.getMercadoPago();
    midTransModel = await UserPreference.getMidTransData();
    orangeMoneyModel = await UserPreference.getOrangeData();
    xenditModel = await UserPreference.getXenditData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDarkMode(context) ? AppThemeData.surfaceDark : AppThemeData.surface,
      appBar: AppBar(
        title: Text("Complete purchase", style: TextStyle(color: AppThemeData.primary300, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                  height: 200,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white, width: 5),
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: NetworkImage(
                          giftCardModel.image.toString(),
                        ),
                      ),
                    ),
                  )),
              SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppThemeData.primary300.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Text("Complete payment and share this e-gift card with loved ones using any app."),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Text("BILL SUMMARY".toUpperCase(),
                          style: TextStyle(fontSize: 16, color: isDarkMode(context) ? Colors.grey.shade700 : Colors.grey.shade700, fontWeight: FontWeight.w600)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 13),
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
                child: Column(
                  children: [
                    Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Subtotal".tr(),
                              style: TextStyle(fontFamily: "Poppinsm"),
                            ),
                            Text(
                              amountShow(amount: widget.price),
                              style: TextStyle(fontFamily: AppThemeData.regular, color: isDarkMode(context) ? const Color(0xffFFFFFF) : const Color(0xff333333)),
                            ),
                          ],
                        )),
                    const Divider(
                      thickness: 1,
                    ),
                    Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Grand Total".tr(),
                              style: TextStyle(fontFamily: "Poppinsm"),
                            ),
                            Text(
                              amountShow(amount: widget.price),
                              style: TextStyle(fontFamily: AppThemeData.regular, color: Colors.red),
                            ),
                          ],
                        )),
                  ],
                ),
              ),
              Text(
                "Gift Card expire  ${giftCardModel.expiryDay} days after purchase ",
                style: TextStyle(color: Colors.grey),
              )
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(right: 40.0, left: 40.0, top: 10, bottom: 10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: double.infinity),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemeData.primary300,
              padding: EdgeInsets.only(top: 12, bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.0),
                side: BorderSide(
                  color: AppThemeData.primary300,
                ),
              ),
            ),
            child: Text(
              'Continue'.tr(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode(context) ? Colors.black : Colors.white,
              ),
            ),
            onPressed: () {
              topUpBalance();
            },
          ),
        ),
      ),
    );
  }

  paymentCompleted({required String paymentMethod}) async {
    GiftCardsOrderModel giftCardsOrderModel = GiftCardsOrderModel();
    giftCardsOrderModel.id = Uuid().v4();
    giftCardsOrderModel.giftId = giftCardModel.id.toString();
    giftCardsOrderModel.giftTitle = giftCardModel.title.toString();
    giftCardsOrderModel.price = gradTotal.toString();
    giftCardsOrderModel.redeem = false;
    giftCardsOrderModel.message = widget.msg;
    giftCardsOrderModel.giftPin = generateGiftPin();
    giftCardsOrderModel.giftCode = generateGiftCode();
    giftCardsOrderModel.paymentType = paymentMethod;
    giftCardsOrderModel.createdDate = Timestamp.now();
    DateTime dateTime = DateTime.now().add(Duration(days: int.parse(giftCardModel.expiryDay.toString())));
    giftCardsOrderModel.expireDate = Timestamp.fromDate(dateTime);
    giftCardsOrderModel.userid = MyAppState.currentUser!.userID;

    await FireStoreUtils().placeGiftCardOrder(giftCardsOrderModel).then((value) {
      Navigator.pop(context);
    });
  }

  String generateGiftCode() {
    var rng = Random();
    String generatedNumber = '';
    for (int i = 0; i < 16; i++) {
      generatedNumber += (rng.nextInt(9) + 1).toString();
    }
    return generatedNumber;
  }

  String generateGiftPin() {
    var rng = Random();
    String generatedNumber = '';
    for (int i = 0; i < 6; i++) {
      generatedNumber += (rng.nextInt(9) + 1).toString();
    }
    return generatedNumber;
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool telebirr = false;
  bool cbebirr = false;
  bool ebirr = false;
  bool wegagen = false;
  bool paypal = false;

  String? selectedRadioTile;

  topUpBalance() {
    final size = MediaQuery.of(context).size;
    return showModalBottomSheet(
        elevation: 5,
        enableDrag: true,
        useRootNavigator: true,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15))),
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) => Container(
              width: size.width,
              height: size.height * 0.85,
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5),
                          child: RichText(
                            text: TextSpan(
                              text: "Select Payment Option".tr(),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isDarkMode(context) ? Colors.white : Colors.black,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                                            Visibility(
                          visible: true,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 20),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: telebirr ? 0 : 2,
                              child: RadioListTile(
                                shape:
                                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: telebirr ? AppThemeData.primary300 : Colors.transparent)),
                                controlAffinity: ListTileControlAffinity.trailing,
                                value: "telebirr",
                                groupValue: selectedRadioTile,
                                onChanged: (String? value) {
                                  print(value);
                                  setState(() {
                                    telebirr = true;
                                    cbebirr = false;
                                    ebirr = false;
                                    wegagen = false;
                                    paypal = false;
                                    selectedRadioTile = value!;
                                  });
                                },
                                selected: telebirr,
                                //selectedRadioTile == "strip" ? true : false,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Container(
                                        decoration: BoxDecoration(
                                          color: Colors.blueGrey.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 10),
                                          child: SizedBox(
                                            width: 80,
                                            height: 35,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                                              child: Image.asset(
                                                "assets/images/telebirr.png",
                                              ),
                                            ),
                                          ),
                                        )),
                                    const SizedBox(
                                      width: 20,
                                    ),
                                    const Text("Telebirr").tr(),
                                  ],
                                ),
                                //toggleable: true,
                              ),
                            ),
                          ),
                        ),
                      Visibility(
                        visible: true,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 20),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: cbebirr ? 0 : 2,
                            child: RadioListTile(
                              shape:
                                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: cbebirr ? AppThemeData.primary300 : Colors.transparent)),
                              controlAffinity: ListTileControlAffinity.trailing,
                              value: "cbebirr",
                              groupValue: selectedRadioTile,
                              onChanged: (String? value) {
                                print(value);
                                setState(() {
                                  telebirr = false;
                                  cbebirr = true;
                                  ebirr = false;
                                  wegagen = false;
                                  paypal = false;
                                  selectedRadioTile = value!;
                                });
                              },
                              selected: cbebirr,
                              //selectedRadioTile == "strip" ? true : false,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 10),
                                        child: SizedBox(
                                          width: 80,
                                          height: 35,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                                            child: Image.asset(
                                              "assets/images/cbebirr.png",
                                            ),
                                          ),
                                        ),
                                      )),
                                  const SizedBox(
                                    width: 20,
                                  ),
                                  const Text("Cbe Birr").tr(),
                                ],
                              ),
                              //toggleable: true,
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: true,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 20),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: ebirr ? 0 : 2,
                            child: RadioListTile(
                              shape:
                                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: ebirr ? AppThemeData.primary300 : Colors.transparent)),
                              controlAffinity: ListTileControlAffinity.trailing,
                              value: "ebirr",
                              groupValue: selectedRadioTile,
                              onChanged: (String? value) {
                                print(value);
                                setState(() {
                                  telebirr = false;
                                  cbebirr = false;
                                  ebirr = true;
                                  wegagen = false;
                                  paypal = false;
                                  selectedRadioTile = value!;
                                });
                              },
                              selected: ebirr,
                              //selectedRadioTile == "strip" ? true : false,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 10),
                                        child: SizedBox(
                                          width: 80,
                                          height: 35,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                                            child: Image.asset(
                                              "assets/images/ebirr.png",
                                            ),
                                          ),
                                        ),
                                      )),
                                  const SizedBox(
                                    width: 20,
                                  ),
                                  const Text("E-Birr").tr(),
                                ],
                              ),
                              //toggleable: true,
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: true,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 20),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: wegagen ? 0 : 2,
                            child: RadioListTile(
                              shape:
                                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: wegagen ? AppThemeData.primary300 : Colors.transparent)),
                              controlAffinity: ListTileControlAffinity.trailing,
                              value: "wegagen",
                              groupValue: selectedRadioTile,
                              onChanged: (String? value) {
                                print(value);
                                setState(() {
                                  telebirr = false;
                                  cbebirr = false;
                                  ebirr = false;
                                  wegagen = true;
                                  paypal = false;
                                  selectedRadioTile = value!;
                                });
                              },
                              selected: wegagen,
                              //selectedRadioTile == "strip" ? true : false,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 10),
                                        child: SizedBox(
                                          width: 80,
                                          height: 35,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                                            child: Image.asset(
                                              "assets/images/wegagen.png",
                                            ),
                                          ),
                                        ),
                                      )),
                                  const SizedBox(
                                    width: 20,
                                  ),
                                  const Text("Wegagen Bank").tr(),
                                ],
                              ),
                              //toggleable: true,
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: true,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 20),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: paypal ? 0 : 2,
                            child: RadioListTile(
                              shape:
                                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: paypal ? AppThemeData.primary300 : Colors.transparent)),
                              controlAffinity: ListTileControlAffinity.trailing,
                              value: "paypal",
                              groupValue: selectedRadioTile,
                              onChanged: (String? value) {
                                print(value);
                                setState(() {
                                  telebirr = false;
                                  cbebirr = false;
                                  ebirr = false;
                                  wegagen = false;
                                  paypal = true;
                                  selectedRadioTile = value!;
                                });
                              },
                              selected: paypal,
                              //selectedRadioTile == "strip" ? true : false,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 10),
                                        child: SizedBox(
                                          width: 80,
                                          height: 35,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                                            child: Image.asset(
                                              "assets/images/paypal_@3x.png",
                                            ),
                                          ),
                                        ),
                                      )),
                                  const SizedBox(
                                    width: 20,
                                  ),
                                  const Text("Paypal").tr(),
                                ],
                              ),
                              //toggleable: true,
                            ),
                          ),
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 22),
                      child: GestureDetector(
                        onTap: () async {
                          if (selectedRadioTile.toString().toLowerCase() == "telebirr" || selectedRadioTile.toString().toLowerCase() == "cbebirr" 
                      || selectedRadioTile.toString().toLowerCase() == "ebirr" || selectedRadioTile.toString().toLowerCase() == "wegagen" 
                      || selectedRadioTile.toString().toLowerCase() == "paypal" || selectedRadioTile.toString().toLowerCase() == "wallet"
                      || selectedRadioTile.toString().toLowerCase() == "cash") {
                            showLoadingAlert();
                            chapapay(gradTotal);
                          } 
                        },
                        child: Container(
                          height: 45,
                          decoration: BoxDecoration(
                            color: AppThemeData.primary300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                              child: Text(
                            "CONTINUE".tr(),
                            style: TextStyle(color: Colors.white),
                          )),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }

  showLoadingAlert() {
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const CircularProgressIndicator(),
              const Text('Please wait!!').tr(),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const SizedBox(
                  height: 15,
                ),
                Text(
                  'Please wait!! while completing Transaction'.tr(),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(
                  height: 15,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  showAlert(context, {required String response, required Color colors}) {
    return ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(response),
      backgroundColor: colors,
      duration: Duration(seconds: 8),
    ));
  }

  Map<String, dynamic>? paymentIntentData;

    Future<void> chapapay(String amount) async{
    // Generate a random transaction reference with a custom prefix
    String txRef = TxRefRandomGenerator.generate(prefix: 'sharehands');
    
    // Access the generated transaction reference
    String storedTxRef = TxRefRandomGenerator.gettxRef;
    
    // Print the generated transaction reference and the stored transaction reference
    print('Generated TxRef: $txRef');
    print('Stored TxRef: $storedTxRef');
    print(MyAppState.currentUser!.phoneNumber);
    await Chapa.getInstance.startPayment(
          context: context,
          onInAppPaymentSuccess: (successMsg) async {
            // Handle success events
            Navigator.pop(context);
            ShowToastDialog.showToast("Payment Successfully");
            await paymentCompleted(paymentMethod: "Chapa");
          },
          onInAppPaymentError: (errorMsg) {
            // Handle error
            Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                  "Payment Unsuccessful!!".tr() + "\n",
                ),
                backgroundColor: Colors.red.shade400,
                duration: const Duration(seconds: 6),
              ));
          },
          // phoneNumber: MyAppState.currentUser!.phoneNumber,
          amount: amount,
          currency: 'ETB',
          txRef: storedTxRef,
        );
  }
}
