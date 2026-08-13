// ignore_for_file: unused_local_variable

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sharehandscustomer/constants.dart';
import 'package:sharehandscustomer/main.dart';
import 'package:sharehandscustomer/model/CodModel.dart';
import 'package:sharehandscustomer/model/FlutterWaveSettingDataModel.dart';
import 'package:sharehandscustomer/model/MercadoPagoSettingsModel.dart';
import 'package:sharehandscustomer/model/PayFastSettingData.dart';
import 'package:sharehandscustomer/model/PayStackSettingsModel.dart';
import 'package:sharehandscustomer/model/RazorPayFailedModel.dart';

import 'package:sharehandscustomer/model/User.dart';
import 'package:sharehandscustomer/model/createRazorPayOrderModel.dart';
import 'package:sharehandscustomer/model/getPaytmTxtToken.dart';
import 'package:sharehandscustomer/model/payStackURLModel.dart';
import 'package:sharehandscustomer/model/payment_model/mid_trans.dart';
import 'package:sharehandscustomer/model/payment_model/orange_money.dart';
import 'package:sharehandscustomer/model/payment_model/xendit.dart';
import 'package:sharehandscustomer/model/paypalSettingData.dart';
import 'package:sharehandscustomer/model/paytmSettingData.dart';
import 'package:sharehandscustomer/model/razorpayKeyModel.dart';
import 'package:sharehandscustomer/model/stripeSettingData.dart';
import 'package:sharehandscustomer/model/topupTranHistory.dart';
import 'package:sharehandscustomer/onDemand_service/onDemand_model/onprovider_order_model.dart';
import 'package:sharehandscustomer/onDemand_service/onDemand_ui/onDemand_dashboard.dart';
import 'package:sharehandscustomer/onDemand_service/onDemand_ui/order_screen/ondemand_order_screen.dart';
import 'package:sharehandscustomer/payment/midtrans_screen.dart';
import 'package:sharehandscustomer/payment/orangePayScreen.dart';
import 'package:sharehandscustomer/payment/xenditModel.dart';
import 'package:sharehandscustomer/payment/xenditScreen.dart';
import 'package:sharehandscustomer/send_notification.dart';
import 'package:sharehandscustomer/services/FirebaseHelper.dart';
import 'package:sharehandscustomer/services/helper.dart';
import 'package:sharehandscustomer/services/paystack_url_genrater.dart';
import 'package:sharehandscustomer/services/rozorpayConroller.dart';
import 'package:sharehandscustomer/services/show_toast_dialog.dart';
import 'package:sharehandscustomer/theme/app_them_data.dart';
import 'package:sharehandscustomer/theme/round_button_fill.dart';
import 'package:sharehandscustomer/ui/wallet/MercadoPagoScreen.dart';
import 'package:sharehandscustomer/ui/wallet/PayFastScreen.dart';
import 'package:sharehandscustomer/ui/wallet/payStackScreen.dart';
import 'package:sharehandscustomer/userPrefrence.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:chapa_unofficial/chapa_unofficial.dart';

class OnDemandPaymentScreen extends StatefulWidget {
  final OnProviderOrderModel? onDemandOrderModel;
  final double totalAmount;
  final bool isExtra;

  OnDemandPaymentScreen({Key? key, this.onDemandOrderModel, this.totalAmount = 0, required this.isExtra}) : super(key: key);

  @override
  State<OnDemandPaymentScreen> createState() => _OnDemandPaymentScreenState();
}

class _OnDemandPaymentScreenState extends State<OnDemandPaymentScreen> {
  OnProviderOrderModel? onDemandOrderModel;

  @override
  void initState() {
    super.initState();
    setState(() {
      onDemandOrderModel = widget.onDemandOrderModel;
    });
    getPaymentSettingData();
  }

  placeOnDemandOrder(context) async {
    if (widget.isExtra == false) {
      await showProgress("Please wait...".tr(), false);
      onDemandOrderModel!.payment_method = paymentType;
      onDemandOrderModel!.paymentStatus = onDemandOrderModel!.provider.priceUnit == "Fixed" && paymentType == "cod" ? false : true;
      onDemandOrderModel!.extraPaymentStatus = true;
      await FireStoreUtils().onDemandOrderPlace(onDemandOrderModel!, double.parse(widget.totalAmount.toString())).then((value) async {});

      if (onDemandOrderModel!.status == ORDER_STATUS_PLACED) {
        await FireStoreUtils.sendOrderOnDemandServiceEmail(orderModel: onDemandOrderModel!);

        User? providerUser = await FireStoreUtils.getCurrentUser(onDemandOrderModel!.provider.author.toString());

        Map<String, dynamic> payLoad = <String, dynamic>{"type": 'provider_order', "orderId": onDemandOrderModel!.id};
        if (providerUser != null) {
          await SendNotification.sendFcmMessage(providerBookingPlaced, providerUser.fcmToken.toString(), payLoad);
        }
        ShowToastDialog.showToast("OnDemand Service successfully booked".tr());
      }
      await hideProgress();
      await push(
          context,
          OnDemandDahBoard(
            user: MyAppState.currentUser!,
            currentWidget: OnDemandOrderScreen(),
            appBarTitle: 'Booking'.tr(),
            drawerSelection: DrawerSelection.Order,
          ));
    } else {
      // ExtraCharges payment
      // onDemandOrderModel!.payment_method = paymentType;
      onDemandOrderModel!.createdAt = Timestamp.now();
      onDemandOrderModel!.extraPaymentStatus = true;
      if (paymentType != 'cod') {
        TopupTranHistoryModel extraPayment = TopupTranHistoryModel(
            amount: widget.totalAmount.toString(),
            id: Uuid().v4(),
            order_id: widget.onDemandOrderModel!.id.toString(),
            user_id: widget.onDemandOrderModel!.provider.author.toString(),
            date: Timestamp.now(),
            isTopup: true,
            payment_method: "Wallet",
            payment_status: "success",
            serviceType: 'ondemand-service',
            note: 'Extra Charge Amount Credited',
            transactionUser: "provider");

        await FireStoreUtils.firestore.collection(Wallet).doc(extraPayment.id).set(extraPayment.toJson());
        await FireStoreUtils.updateProviderWalletAmount(amount: extraPayment, userId: widget.onDemandOrderModel!.provider.author.toString());
      }
      await FireStoreUtils.updateOnDemandOrder(onDemandOrderModel!);
      await hideProgress();
      await push(
          context,
          OnDemandDahBoard(
            user: MyAppState.currentUser!,
            currentWidget: OnDemandOrderScreen(),
            appBarTitle: 'Booking'.tr(),
            drawerSelection: DrawerSelection.Order,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode(context) ? AppThemeData.surfaceDark : AppThemeData.surface,
      key: _globalKey,
      appBar: AppBar(
        leading: InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
            )),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            children: [paymentListView()],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: RoundedButtonFill(
            title: "Continue".tr(),
            color: AppThemeData.primary300,
            textColor: AppThemeData.grey50,
            onPress: () async {
              if (chapa) {
                showLoadingAlert();
                chapapay(widget.totalAmount.toString());
              } else if (cod) {
                paymentType = 'cod';
                placeOnDemandOrder(context);
              } else if (wallet && walletBalanceError == false) {
                paymentType = 'wallet';
                showLoadingAlert();

                TopupTranHistoryModel wallet = TopupTranHistoryModel(
                    amount: widget.totalAmount,
                    id: Uuid().v4(),
                    order_id: onDemandOrderModel!.id,
                    user_id: MyAppState.currentUser!.userID,
                    date: Timestamp.now(),
                    isTopup: false,
                    payment_method: "Wallet",
                    payment_status: "success",
                    transactionUser: "customer",
                    note: widget.isExtra ? 'Extra Booking Payment' : 'Booking amount payment',
                    serviceType: 'ondemand-service');

                await FireStoreUtils.firestore.collection("wallet").doc(wallet.id).set(wallet.toJson()).then((value) {
                  FireStoreUtils.updateWalletAmount(amount: -widget.totalAmount).then((value) {
                    placeOnDemandOrder(context);
                  }).whenComplete(() {
                    showAlert(context, response: "Payment Successful Via".tr() + " " "Wallet".tr(), colors: Colors.green);
                  });
                });
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
          )),
    );
  }

  final Razorpay _razorPay = Razorpay();

  Stream<DocumentSnapshot<Map<String, dynamic>>>? userQuery;
  final fireStoreUtils = FireStoreUtils();
  static FirebaseFirestore fireStore = FireStoreUtils.firestore;
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
  CodModel? codModel;

  bool walletBalanceError = false;
  RazorPayModel? razorPayData = UserPreference.getRazorPayData();
  bool cod = false;
  bool wallet = false;
  bool chapa = false;



  String selectedCardID = '';
  bool isStaging = true;
  bool enableAssist = true;
  bool restrictAppInvoke = false;

  String result = "";

  String paymentOption = 'Pay Via Wallet'.tr();
  String paymentType = "";

  showAlert(BuildContext context123, {required String response, required Color colors}) {
    return ScaffoldMessenger.of(context123).showSnackBar(SnackBar(
      content: Text(response),
      backgroundColor: colors,
    ));
  }

  getPaymentSettingData() async {
    userQuery = fireStore.collection(USERS).doc(MyAppState.currentUser!.userID).snapshots();
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
    payFastSettingData = await UserPreference.getPayFastData();
    mercadoPagoSettingData = await UserPreference.getMercadoPago();

    midTransModel = await UserPreference.getMidTransData();
    orangeMoneyModel = await UserPreference.getOrangeData();
    xenditModel = await UserPreference.getXenditData();

    codModel = await fireStoreUtils.getCod();
    setState(() {});
  }

  Widget paymentListView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
            margin: const EdgeInsets.only(left: 15),
            child: Text("Select Payment Method".tr(), style: TextStyle(fontSize: 16, color: Colors.black, letterSpacing: 1, fontFamily: AppThemeData.medium))),
        Visibility(
          visible: UserPreference.getWalletData() ?? false,
          child: Column(
            children: [
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: userQuery,
                  builder: (context, AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> asyncSnapshot) {
                    if (asyncSnapshot.hasError) {
                      return const Text(
                        "error",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ).tr();
                    }
                    if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 0.8,
                                color: Colors.white,
                                backgroundColor: Colors.transparent,
                              )));
                    }
                    if (asyncSnapshot.data == null) {
                      return Container();
                    }
                    User userData = User.fromJson(asyncSnapshot.data!.data()!);

                    walletBalanceError = userData.wallet_amount < double.parse(widget.totalAmount.toString()) ? true : false;
                    return Column(
                      children: [
                        buildPaymentTile(
                            isVisible: UserPreference.getWalletData() ?? false,
                            selectedPayment: wallet,
                            walletError: walletBalanceError,
                            image: "assets/images/wallet_icon.png",
                            value: "Wallet".tr(),
                            childWidget: Text(
                              amountShow(amount: userData.wallet_amount.toString()),
                              style: TextStyle(
                                color: walletBalanceError ? Colors.red : Colors.green,
                                fontFamily: AppThemeData.medium,
                              ),
                            )),
                        Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Visibility(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 0.0),
                                  child: walletBalanceError
                                      ? Text(
                                          "Your wallet doesn't have sufficient balance".tr(),
                                          style: const TextStyle(fontSize: 14, color: Colors.red),
                                        )
                                      : Text(
                                          'Sufficient Balance'.tr(),
                                          style: const TextStyle(fontSize: 14, color: Colors.green),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
            ],
          ),
        ),
        buildPaymentTile(
          isVisible: codModel != null ? codModel!.cod : false,
          selectedPayment: cod,
          image: "assets/images/cash.png",
          value: "Cash".tr(),
        ),
        buildPaymentTile(
          isVisible: true,
          selectedPayment: chapa,
          image: "assets/images/telebirr.png",
          value: "Telebirr, CBE Birr, ...".tr(),
        ),
      ],
    );
  }

  setAllFalse({required String value}) {
    print(value);
    setState(() {
      chapa = false;
      wallet = false;
      cod = false;

      if (value == "Cash") {
        cod = true;
      }
      if (value == "Wallet") {
        wallet = true;
      }
      if (value == "Telebirr, CBE Birr, ..." || value.toLowerCase() == "telebirr, cbe birr, ...") {
        chapa = true;
      }
    });
  }

  String? selectedRadioTile;

  ///show payment Options
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
          child: RadioListTile(
            controlAffinity: ListTileControlAffinity.trailing,
            value: value,
            groupValue: selectedRadioTile,
            onChanged: walletError != true
                ? (String? value) {
                    setState(() {
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
                          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 10),
                          child: SizedBox(
                            width: 80,
                            height: 35,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Image.asset(image,color: AppThemeData.grey400),
                            ),
                          ),
                        )),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(value,
                        style: TextStyle(
                          color: isDarkMode(context) ? const Color(0xffFFFFFF) : Colors.black,
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
    );
  }


  ///Stripe payment function

  Map<String, dynamic>? paymentIntentData;

  

  calculateAmount(String amount) {
    final a = ((double.parse(amount)) * 100).toInt();
    print(a);
    return a.toString();
  }

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
            placeOnDemandOrder(context);
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

  Future<void> showLoading({required String message, Color txtColor = Colors.black}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Container(
            margin: const EdgeInsets.fromLTRB(30, 20, 30, 20),
            width: double.infinity,
            height: 30,
            child: Text(
              message,
              style: TextStyle(color: txtColor),
            ),
          ),
        );
      },
    );
  }

  ///PayStack Payment Method
  payStackPayment(BuildContext context) async {
    await PayStackURLGen.payStackURLGen(
      amount: (double.parse(widget.totalAmount.toString()) * 100).toString(),
      currency: currencyData!.code,
      secretKey: payStackSettingData!.secretKey,
    ).then((value) async {
      if (value != null) {
        PayStackUrlModel _payStackModel = value;
        bool isDone = await Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => PayStackScreen(
                  secretKey: payStackSettingData!.secretKey,
                  callBackUrl: payStackSettingData!.callbackURL,
                  initialURl: _payStackModel.data.authorizationUrl,
                  amount: double.parse(widget.totalAmount.toString()).toString(),
                  reference: _payStackModel.data.reference,
                )));

        if (isDone) {
          placeOnDemandOrder(context);
          ScaffoldMessenger.of(_globalKey.currentContext!).showSnackBar(SnackBar(
            content: Text("Payment Successful!!\n".tr()),
            backgroundColor: Colors.green,
          ));
        } else {
          Navigator.pop(_globalKey.currentContext!);
          ScaffoldMessenger.of(_globalKey.currentContext!).showSnackBar(SnackBar(
            content: Text("Payment UnSuccessful!!\n".tr()),
            backgroundColor: Colors.red,
          ));
        }
      } else {
        Navigator.pop(_globalKey.currentContext!);
        showAlert(_globalKey.currentContext!, response: "Something went wrong, please contact admin.".tr(), colors: Colors.red);
      }
    });
  }

  //Midtrans payment
  midtransMakePayment({required String amount, required BuildContext context}) async {
    await createPaymentLink(amount: amount).then((url) async {
      ShowToastDialog.closeLoader();
      if (url != '') {
        final bool isDone = await Navigator.push(context, MaterialPageRoute(builder: (context) => MidtransScreen(initialURl: url)));
        if (isDone) {
          ShowToastDialog.showToast("Payment Successful!!");
          placeOnDemandOrder(context);
        } else {
          ShowToastDialog.showToast("Payment Unsuccessful!!");
        }
      }
    });
  }

  Future<String> createPaymentLink({required var amount}) async {
    var ordersId = const Uuid().v1();
    final url = Uri.parse(midTransModel!.isSandbox! ? 'https://api.sandbox.midtrans.com/v1/payment-links' : 'https://api.midtrans.com/v1/payment-links');

    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': generateBasicAuthHeader(midTransModel!.serverKey!),
      },
      body: jsonEncode({
        'transaction_details': {
          'order_id': ordersId,
          'gross_amount': double.parse(amount.toString()).toInt(),
        },
        'usage_limit': 2,
        "callbacks": {"finish": "https://www.google.com?merchant_order_id=$ordersId"},
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return responseData['payment_url'];
    } else {
      ShowToastDialog.showToast("something went wrong, please contact admin.");
      return '';
    }
  }

  String generateBasicAuthHeader(String apiKey) {
    String credentials = '$apiKey:';
    String base64Encoded = base64Encode(utf8.encode(credentials));
    return 'Basic $base64Encoded';
  }

  //Orangepay payment
  static String accessToken = '';
  static String payToken = '';
  static String orderId = '';
  static String amount = '';

  orangeMakePayment({required String amount, required BuildContext context}) async {
    reset();
    var id = const Uuid().v4();
    var paymentURL = await fetchToken(context: context, orderId: id, amount: amount, currency: 'USD');
    ShowToastDialog.closeLoader();
    if (paymentURL.toString() != '') {
      final bool isDone = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => OrangeMoneyScreen(
                    initialURl: paymentURL,
                    accessToken: accessToken,
                    amount: amount,
                    orangePay: orangeMoneyModel!,
                    orderId: orderId,
                    payToken: payToken,
                  )));

      if (isDone) {
        ShowToastDialog.showToast("Payment Successful!!");
        placeOnDemandOrder(context);
      } else {
        ShowToastDialog.showToast("Payment Unsuccessful!!");
      }
    } else {
      ShowToastDialog.showToast("Payment Unsuccessful!!");
    }
  }

  Future fetchToken({required String orderId, required String currency, required BuildContext context, required String amount}) async {
    String apiUrl = 'https://api.orange.com/oauth/v3/token';
    Map<String, String> requestBody = {
      'grant_type': 'client_credentials',
    };

    var response = await http.post(Uri.parse(apiUrl),
        headers: <String, String>{
          'Authorization': "Basic ${orangeMoneyModel!.auth!}",
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: requestBody);

    if (response.statusCode == 200) {
      Map<String, dynamic> responseData = jsonDecode(response.body);

      accessToken = responseData['access_token'];
      return await webpayment(context: context, amountData: amount, currency: currency, orderIdData: orderId);
    } else {
      ShowToastDialog.showToast("Something went wrong, please contact admin.");
      return '';
    }
  }

  Future webpayment({required String orderIdData, required BuildContext context, required String currency, required String amountData}) async {
    orderId = orderIdData;
    amount = amountData;
    String apiUrl =
        orangeMoneyModel!.isSandbox! == true ? 'https://api.orange.com/orange-money-webpay/dev/v1/webpayment' : 'https://api.orange.com/orange-money-webpay/cm/v1/webpayment';
    Map<String, String> requestBody = {
      "merchant_key": orangeMoneyModel!.merchantKey ?? '',
      "currency": orangeMoneyModel!.isSandbox == true ? "OUV" : currency,
      "order_id": orderId,
      "amount": amount,
      "reference": 'Y-Note Test',
      "lang": "en",
      "return_url": orangeMoneyModel!.returnUrl!.toString(),
      "cancel_url": orangeMoneyModel!.cancelUrl!.toString(),
      "notif_url": orangeMoneyModel!.notifyUrl!.toString(),
    };

    var response = await http.post(
      Uri.parse(apiUrl),
      headers: <String, String>{'Authorization': 'Bearer $accessToken', 'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: json.encode(requestBody),
    );
    print(response.statusCode);
    print(response.body);

    // Handle the response
    if (response.statusCode == 201) {
      Map<String, dynamic> responseData = jsonDecode(response.body);
      if (responseData['message'] == 'OK') {
        payToken = responseData['pay_token'];
        return responseData['payment_url'];
      } else {
        return '';
      }
    } else {
      ShowToastDialog.showToast("Something went wrong, please contact admin.");
      return '';
    }
  }

  static reset() {
    accessToken = '';
    payToken = '';
    orderId = '';
    amount = '';
  }

  //XenditPayment
  xenditPayment(context, amount) async {
    await createXenditInvoice(amount: amount).then((model) async {
      ShowToastDialog.closeLoader();
      if (model.id != null) {
        final bool isDone = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => XenditScreen(
                      initialURl: model.invoiceUrl ?? '',
                      transId: model.id ?? '',
                      apiKey: xenditModel!.apiKey!.toString() ?? "",
                    )));

        if (isDone) {
          ShowToastDialog.showToast("Payment Successful!!");
          placeOnDemandOrder(context);
        } else {
          ShowToastDialog.showToast("Payment Unsuccessful!!");
        }
      }
    });
  }

  Future<XenditModel> createXenditInvoice({required var amount}) async {
    const url = 'https://api.xendit.co/v2/invoices';
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': generateBasicAuthHeader(xenditModel!.apiKey!.toString()),
      // 'Cookie': '__cf_bm=yERkrx3xDITyFGiou0bbKY1bi7xEwovHNwxV1vCNbVc-1724155511-1.0.1.1-jekyYQmPCwY6vIJ524K0V6_CEw6O.dAwOmQnHtwmaXO_MfTrdnmZMka0KZvjukQgXu5B.K_6FJm47SGOPeWviQ',
    };

    final body = jsonEncode({
      'external_id': const Uuid().v1(),
      'amount': amount,
      'payer_email': 'customer@domain.com',
      'description': 'Test - VA Successful invoice payment',
      'currency': 'IDR', //IDR, PHP, THB, VND, MYR
    });

    try {
      final response = await http.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        XenditModel model = XenditModel.fromJson(jsonDecode(response.body));
        return model;
      } else {
        return XenditModel();
      }
    } catch (e) {
      return XenditModel();
    }
  }

  final GlobalKey<ScaffoldState> _globalKey = GlobalKey<ScaffoldState>();

  showLoadingAlert() {
    return showDialog<void>(
      context: _globalKey.currentContext!,
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
              children: [
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
}
