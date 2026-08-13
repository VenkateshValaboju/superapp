import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sharehandscustomer/constants.dart';
import 'package:sharehandscustomer/main.dart';
import 'package:sharehandscustomer/model/CodModel.dart';
import 'package:sharehandscustomer/model/FlutterWaveSettingDataModel.dart';
import 'package:sharehandscustomer/model/MercadoPagoSettingsModel.dart';
import 'package:sharehandscustomer/model/PayFastSettingData.dart';
import 'package:sharehandscustomer/model/PayStackSettingsModel.dart';
import 'package:sharehandscustomer/model/RazorPayFailedModel.dart';

import 'package:sharehandscustomer/model/TaxModel.dart';
import 'package:sharehandscustomer/model/User.dart';
import 'package:sharehandscustomer/model/conversation_model.dart';
import 'package:sharehandscustomer/model/createRazorPayOrderModel.dart';
import 'package:sharehandscustomer/model/getPaytmTxtToken.dart';
import 'package:sharehandscustomer/model/offer_model.dart';
import 'package:sharehandscustomer/model/payStackURLModel.dart';
import 'package:sharehandscustomer/model/payment_model/mid_trans.dart';
import 'package:sharehandscustomer/model/payment_model/orange_money.dart';
import 'package:sharehandscustomer/model/payment_model/xendit.dart';
import 'package:sharehandscustomer/model/paypalSettingData.dart';
import 'package:sharehandscustomer/model/paytmSettingData.dart';
import 'package:sharehandscustomer/model/razorpayKeyModel.dart';
import 'package:sharehandscustomer/model/stripeSettingData.dart';
import 'package:sharehandscustomer/parcel_delivery/parcel_model/parcel_order_model.dart';
import 'package:sharehandscustomer/payment/midtrans_screen.dart';
import 'package:sharehandscustomer/payment/orangePayScreen.dart';
import 'package:sharehandscustomer/payment/xenditModel.dart';
import 'package:sharehandscustomer/payment/xenditScreen.dart';
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
import 'package:flutter/services.dart';
import 'package:flutter_paypal_native/flutter_paypal_native.dart';
import 'package:flutter_paypal_native/models/custom/currency_code.dart';
import 'package:flutter_paypal_native/models/custom/environment.dart';
import 'package:flutter_paypal_native/models/custom/order_callback.dart';
import 'package:flutter_paypal_native/models/custom/purchase_unit.dart';
import 'package:flutter_paypal_native/models/custom/user_action.dart';
import 'package:flutter_paypal_native/str_helper.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe1;

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:chapa_unofficial/chapa_unofficial.dart';

class CartParcelScreen extends StatefulWidget {
  ParcelOrderModel parcelOrder;
  List<XFile>? images;

  CartParcelScreen({
    Key? key,
    required this.parcelOrder,
    required this.images,
  }) : super(key: key);

  @override
  State<CartParcelScreen> createState() => _CartParcelScreenState();
}

class _CartParcelScreenState extends State<CartParcelScreen> {
  late Future<List<OfferModel>> coupon;
  late Future<List<OfferModel>> publiccoupon;
  final FireStoreUtils _fireStoreUtils = FireStoreUtils();
  List<OfferModel> couponList = [];

  @override
  void initState() {
    super.initState();
    publiccoupon = _fireStoreUtils.getOfferByParcelID(widget.parcelOrder.parcelCategoryID);
    coupon = _fireStoreUtils.getParcelCoupan();
    getTexDetails();
    getPaymentSettingData();
  }

  double subTotal = 0.0;

  double discountAmount = 0.0;
  String discountType = "";
  String discountLable = "";
  String offerCode = "";

  getTexDetails() async {
    subTotal = double.parse(widget.parcelOrder.subTotal.toString());
    publiccoupon.then((value) {
      couponList = value;
    });
    setState(() {});
  }

  // double getTaxAmount() {
  //   double totalTax = 0.0;
  //   if (taxActive == true) {
  //     if (taxType == "percent") {
  //       totalTax = (subTotal - discountAmount) * taxAmount / 100;
  //     } else {
  //       totalTax = taxAmount;
  //     }
  //   }
  //   return totalTax;
  // }

  placeParcelOrder() async {
    print("------>" + paymentCollectByReceiverString!);
    List<dynamic> parcelImages = [];
    if (widget.images != null) {
      for (var element in widget.images!) {
        Url url = await _fireStoreUtils.uploadChatImageToFireStorage(File(element.path), context);
        parcelImages.add(url.url);
      }
    }

    ParcelOrderModel parcelOrderModel = widget.parcelOrder;
    parcelOrderModel.discount = discountAmount.toString();
    parcelOrderModel.discountType = discountType.toString();
    parcelOrderModel.discountLabel = discountLable.toString();
    /* if (taxActive != null && taxActive == true) {
      parcelOrderModel.taxType = taxType.toString();
      parcelOrderModel.tax = taxAmount.toString();
      parcelOrderModel.taxLabel = taxLable.toString();
    }*/
    parcelOrderModel.taxModel = taxList;
    parcelOrderModel.parcelImages = parcelImages;
    parcelOrderModel.adminCommission = sectionConstantModel!.adminCommision!.commission.toString();
    parcelOrderModel.adminCommissionType = sectionConstantModel!.adminCommision!.type;
    parcelOrderModel.status = ORDER_STATUS_PLACED;
    parcelOrderModel.createdAt = Timestamp.now();
    parcelOrderModel.author = MyAppState.currentUser;
    parcelOrderModel.authorID = MyAppState.currentUser!.userID;
    parcelOrderModel.paymentMethod = paymentCollectByReceiverString == "Receiver" ? "cod".tr() : paymentType;
    parcelOrderModel.paymentCollectByReceiver = paymentCollectByReceiverString == "Receiver" ? true : false;

    print("----------->${parcelOrderModel.toJson()}");
    await FireStoreUtils().parcelOrderPlace(parcelOrderModel, getTotalAmount());
    await FireStoreUtils.sendParcelBookEmail(orderModel: parcelOrderModel);
    final SnackBar snackBar = SnackBar(
      content: Text(
        "Order Place successfully".tr(),
        textAlign: TextAlign.start,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: AppThemeData.primary300,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    Navigator.pop(context);
    Navigator.pop(context);
  }

  double getTotalAmount() {
    double taxAmount = 0.0;
    if (taxList != null) {
      for (var element in taxList!) {
        taxAmount = taxAmount + getTaxValue(amount: (subTotal - discountAmount).toString(), taxModel: element);
      }
    }
    return subTotal - discountAmount + taxAmount;
  }

  /*double getTotalAmount() {
    return subTotal - discountAmount + getTaxAmount();
  }
*/
  int selectedIndex = 0;
  String? paymentCollectByReceiverString = "Sender";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _globalKey,
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back_ios)),
          centerTitle: true,
          title: Text("Confirm Order".tr())),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            showOrderOverView(),
            couponList.isNotEmpty ? buildListPromoCode() : Container(),
            buildPromoCode(),
            buildTotalRow(),
            paymentCollectBy(),
            Visibility(visible: paymentCollectByReceiverString == "Sender" ? true : false, child: paymentListView()),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: RoundedButtonFill(
            title: "Continue".tr(),
            color: AppThemeData.primary300,
            textColor: AppThemeData.grey50,
            onPress: () async {
              if (paymentCollectByReceiverString == "Sender") {
                if (chapa) {
                  showLoadingAlert();
                  chapapay(getTotalAmount().toString());
                } else if (cod) {
                  paymentType = 'cod';
                  placeParcelOrder();
                } else if (wallet && walletBalanceError == false) {
                  paymentType = 'wallet';

                  placeParcelOrder();
                } else {
                  ShowToastDialog.showToast("Select Payment Method");
                }
              } else {
                placeParcelOrder();
              }
            },
          )),
    );
  }

  /// show Order Detail
  showOrderOverView() {
    return Container(
      margin: const EdgeInsets.only(left: 13, top: 10, right: 13, bottom: 13),
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
        padding: const EdgeInsets.symmetric(vertical: 15.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildLine(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      buildUsersDetails(context, userDetails: widget.parcelOrder.sender!),
                      const SizedBox(
                        height: 5,
                      ),
                      buildUsersDetails(context, isSender: false, userDetails: widget.parcelOrder.receiver!),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            const Divider(
              color: Colors.black12,
              thickness: 1,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                showParcelDetails(
                  title: "Distance".tr(),
                  value: widget.parcelOrder.distance.toString() + " " "km".tr(),
                ),
                showParcelDetails(
                  title: "Weight".tr(),
                  value: widget.parcelOrder.parcelWeight!,
                ),
                //showParcelDetails(title: "Rate".tr(), value: "$symbol${subTotal.toStringAsFixed(decimal)}", color: AppThemeData.primary300),
                showParcelDetails(title: "Rate".tr(), value: amountShow(amount: subTotal.toString()), color: AppThemeData.primary300),
              ],
            ),
          ],
        ),
      ),
    );
  }

  ///show User Details
  buildUsersDetails(context, {bool isSender = true, required ParcelUserDetails userDetails}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Text(
                  isSender ? "Sender".tr() + " " : "Receiver".tr() + " ",
                  style: TextStyle(fontSize: 18, color: AppThemeData.primary300),
                ),
                Text(
                  userDetails.name!,
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          Text(
            userDetails.phone!,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            userDetails.address!,
            maxLines: 3,
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  /// show parcel details
  showParcelDetails({
    required String title,
    required String value,
    Color color = Colors.black,
  }) {
    return GestureDetector(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(title, style: const TextStyle(color: Colors.grey)),
            const SizedBox(
              height: 5,
            ),
            Text(value),
          ],
        ),
      ),
    );
  }

  ///createLine
  buildLine() {
    return Column(
      children: [
        const SizedBox(
          height: 6,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8.0,
          ),
          child: Image.asset("assets/images/circle.png", height: 20),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 2),
          child: SizedBox(
            width: 1.3,
            child: ListView.builder(
                shrinkWrap: true,
                itemCount: 18,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Container(
                      color: Colors.black38,
                      height: 2.5,
                    ),
                  );
                }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Image.asset("assets/images/parcel_Image.png", height: 20),
        ),
      ],
    );
  }

  /// TO show PromoCode
  buildListPromoCode() {
    return GestureDetector(
      child: Container(
        margin: const EdgeInsets.only(left: 13, top: 10, right: 13, bottom: 13),
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
          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15),
          child: SizedBox(
            height: 85,
            child: ListView.builder(
                itemCount: couponList.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      if (couponList[index].discountTypeOffer == 'Percentage' || couponList[index].discountTypeOffer == 'Percent') {
                        discountAmount = subTotal * double.parse(couponList[index].discountOffer!) / 100;
                        discountType = couponList[index].discountTypeOffer.toString();
                        discountLable = couponList[index].discountOffer.toString();
                        offerCode = couponList[index].offerCode.toString();
                      } else {
                        discountAmount = double.parse(couponList[index].discountOffer!);
                        discountType = couponList[index].discountTypeOffer.toString();
                        discountLable = couponList[index].discountOffer.toString();
                        offerCode = couponList[index].offerCode.toString();
                      }

                      setState(() {});
                    },
                    child: buildOfferItem(couponList, index),
                  );
                }),
          ),
        ),
      ),
    );
  }

  buildPromoCode() {
    return GestureDetector(
      child: Container(
        margin: const EdgeInsets.only(left: 13, top: 10, right: 13, bottom: 13),
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
          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset("assets/images/reedem.png", height: 50),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Promo Code".tr(), style: const TextStyle(fontSize: 18)),
                        const SizedBox(
                          height: 5,
                        ),
                        Text("Apply promo code".tr(), style: const TextStyle(fontSize: 15)),
                      ],
                    ),
                  ),
                ],
              ),
              FloatingActionButton(
                onPressed: () {
                  showModalBottomSheet(
                      isScrollControlled: true,
                      isDismissible: true,
                      context: context,
                      backgroundColor: Colors.transparent,
                      enableDrag: true,
                      builder: (BuildContext context) => sheet());
                },
                mini: true,
                backgroundColor: Colors.blueGrey.shade50,
                elevation: 0,
                child: const Icon(
                  Icons.add,
                  color: Colors.black54,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildOfferItem(List<OfferModel> snapshot, int index) {
    return Container(
      margin: const EdgeInsets.fromLTRB(7, 10, 7, 10),
      height: 85,
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: const Radius.circular(2),
        padding: const EdgeInsets.all(2),
        color: const Color(COUPON_DASH_COLOR),
        strokeWidth: 2,
        dashPattern: const [5],
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 5, 12, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Image(
                    image: AssetImage('assets/images/offer_icon.png'),
                    height: 25,
                    width: 25,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 3),
                    child: Text(
                      //"${snapshot[index].discountTypeOffer == "Fix Price" ? currencyData!.symbol : ""}${snapshot[index].discountOffer}${snapshot[index].discountTypeOffer == "Percentage" ? "% OFF" : " OFF"}",
                      snapshot[index].discountTypeOffer == "Fix Price"
                          ? (currencyData!.symbolatright == true)
                              ? "${snapshot[index].discountOffer}${currencyData!.symbol.toString()} OFF"
                              : "${currencyData!.symbol.toString()}${snapshot[index].discountOffer} OFF"
                          : "${snapshot[index].discountOffer} % Off",
                      style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 5,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    snapshot[index].offerCode!,
                    textAlign: TextAlign.left,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, letterSpacing: 0.5),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 15, right: 15, top: 3),
                    width: 1,
                    color: const Color(COUPON_DASH_COLOR),
                  ),
                  Text("valid till ".tr() + getDate(snapshot[index].expireOfferDate!.toDate().toString())!, style: const TextStyle(letterSpacing: 0.5))
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? getDate(String date) {
    final format = DateFormat("MMM dd, yyyy");
    String formattedDate = format.format(DateTime.parse(date));
    return formattedDate;
  }

  TextEditingController txt = TextEditingController(text: '');

  sheet() {
    return Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height / 4.3, left: 25, right: 25),
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(color: Colors.transparent, border: Border.all(style: BorderStyle.none)),
        child: FutureBuilder<List<OfferModel>>(
            future: coupon,
            initialData: const [],
            builder: (context, snapshot) {
              snapshot = snapshot;
              print(snapshot.data!.length.toString() + "[][]][][][][][][][][]][][====");
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation(AppThemeData.primary300),
                  ),
                );
              }

              // coupon = snapshot.data as Future<List<CouponModel>> ;
              return Column(children: [
                InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 0.3), color: Colors.transparent, shape: BoxShape.circle),

                      // radius: 20,
                      child: const Center(
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    )),
                const SizedBox(
                  height: 25,
                ),
                Expanded(
                    child: Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.white),
                  alignment: Alignment.center,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                            padding: const EdgeInsets.only(top: 30),
                            child: const Image(
                              image: AssetImage('assets/images/redeem_coupon.png'),
                              width: 100,
                            )),
                        Container(
                            padding: const EdgeInsets.only(top: 20),
                            child: Text(
                              'Redeem Your Coupons'.tr(),
                              style: const TextStyle(color: Color(0XFF2A2A2A), fontSize: 16),
                            )),
                        Center(
                          child: Container(
                              padding: const EdgeInsets.only(top: 10, left: 22, right: 22),
                              child: const Text(
                                "Voucher or Coupon code",
                                style: TextStyle(color: Color(0XFF9091A4), letterSpacing: 0.5, height: 2),
                              ).tr()),
                        ),
                        Container(
                            padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
                            // height: 120,
                            child: DottedBorder(
                                borderType: BorderType.RRect,
                                radius: const Radius.circular(12),
                                dashPattern: const [4, 2],
                                color: const Color(0XFFB7B7B7),
                                child: ClipRRect(
                                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                                    child: Container(
                                        padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20),
                                        color: const Color(0XFFF1F4F7),
                                        // height: 120,
                                        alignment: Alignment.center,
                                        child: TextFormField(
                                          textAlign: TextAlign.center,
                                          controller: txt,
                                          style: TextStyle(color: Colors.black),

                                          // textAlignVertical: TextAlignVertical.center,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            hintText: "Write Coupon Code".tr(),
                                            hintStyle: const TextStyle(color: Color(0XFF9091A4)),
                                            labelStyle: const TextStyle(color: Color(0XFF333333)),
                                            //  hintTextDirection: TextDecoration.lineThrough
                                            // contentPadding: EdgeInsets.only(left: 80,right: 30),
                                          ),
                                        ))))),
                        Padding(
                          padding: const EdgeInsets.only(top: 30, bottom: 30),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                              backgroundColor: AppThemeData.primary300,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                for (int a = 0; a < snapshot.data!.length; a++) {
                                  OfferModel couponModel = snapshot.data![a];

                                  if (txt.text.toString() == couponModel.offerCode!.toString()) {
                                    if (couponModel.discountTypeOffer == 'Percentage' || couponModel.discountTypeOffer == 'Percent') {
                                      discountAmount = subTotal * double.parse(couponModel.discountOffer!) / 100;
                                      discountType = couponModel.discountTypeOffer.toString();
                                      discountLable = couponModel.discountOffer.toString();
                                      offerCode = couponModel.offerCode.toString();
                                      break;
                                    } else {
                                      discountAmount = double.parse(couponModel.discountOffer!);
                                      discountType = couponModel.discountTypeOffer.toString();
                                      discountLable = couponModel.discountOffer.toString();
                                      offerCode = couponModel.offerCode.toString();
                                    }
                                  }

                                  // if (txt.text.toString() == couponModel.offerCode!.toString()) {
                                  //   if (couponModel.discountTypeOffer == 'Percentage' || couponModel.discountTypeOffer == 'Percent') {
                                  //     discountAmount = subTotal * double.parse(couponModel.discountOffer!) / 100;
                                  //     discountType = couponModel.discountTypeOffer.toString();
                                  //     discountLable = couponModel.discountOffer.toString();
                                  //     break;
                                  //   } else {
                                  //     discountAmount = double.parse(couponModel.discountOffer!);
                                  //     discountType = couponModel.discountTypeOffer.toString();
                                  //     discountLable = couponModel.discountOffer.toString();
                                  //   }
                                }
                              });

                              Navigator.pop(context);
                            },
                            child: Text(
                              "REDEEM NOW".tr(),
                              style: TextStyle(color: isDarkMode(context) ? Colors.black : Colors.white, fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
                //buildcouponItem(snapshot)
                //  listData(snapshot)
              ]);
            }));
  }

  Widget buildTotalRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 13, top: 10, right: 13, bottom: 13),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 10, bottom: 10),
                child: Text(
                  'Order Summary'.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    letterSpacing: 0.5,
                    color: isDarkMode(context) ? Colors.white : const Color(0XFF000000),
                  ),
                ),
              ),
              const Divider(
                thickness: 1,
              ),
              Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Subtotal".tr(),
                        style: TextStyle(color: isDarkMode(context) ? const Color(0xffFFFFFF) : const Color(0xff888888), fontSize: 16),
                      ),
                      Text(
                        amountShow(amount: subTotal.toString()),
                        style: TextStyle(fontWeight: FontWeight.w600, color: isDarkMode(context) ? const Color(0xffFFFFFF) : const Color(0xff333333), fontSize: 16),
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
                        "Discount".tr(),
                        style: TextStyle(color: isDarkMode(context) ? const Color(0xffFFFFFF) : const Color(0xff888888), fontSize: 16),
                      ),
                      Text(
                        "(-" + amountShow(amount: discountAmount.toString()) + ")",
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red, fontSize: 16),
                      ),
                    ],
                  )),
              const Divider(
                thickness: 1,
              ),
              Visibility(
                visible: offerCode.isNotEmpty,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                      child: Text(
                        "Coupon code".tr() + " : $offerCode",
                        style: TextStyle(fontWeight: FontWeight.w600, color: AppThemeData.primary300, fontSize: 16),
                      ),
                    ),
                    const Divider(
                      thickness: 1,
                    ),
                  ],
                ),
              ),

              ListView.builder(
                itemCount: taxList!.length,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  TaxModel taxModel = taxList![index];
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                "${taxModel.title.toString()} (${taxModel.type == "fix" ? amountShow(amount: taxModel.tax) : "${taxModel.tax}%"})",
                                style: TextStyle(color: isDarkMode(context) ? const Color(0xffFFFFFF) : const Color(0xff888888), fontSize: 16),
                              ),
                            ),
                            Text(
                              amountShow(amount: getTaxValue(amount: (subTotal - discountAmount).toString(), taxModel: taxModel).toString()),
                              style: TextStyle(fontWeight: FontWeight.w600, color: isDarkMode(context) ? const Color(0xffFFFFFF) : const Color(0xff333333), fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      const Divider(
                        thickness: 1,
                      ),
                    ],
                  );
                },
              ),
              /* Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ((taxLable.isNotEmpty) ? taxLable.toString() : "Tax".tr()) + " ${(taxType == "fix") ? "" : "($taxAmount %)"}",
                        style: TextStyle(color: isDarkMode(context) ? const Color(0xffFFFFFF) : const Color(0xff888888), fontSize: 16),
                      ),
                      Text(
                        //symbol + getTaxAmount().toStringAsFixed(decimal),
                        amountShow(amount: getTaxAmount().toString()),
                        style: TextStyle(fontWeight: FontWeight.w600, color: isDarkMode(context) ? const Color(0xffFFFFFF) : const Color(0xff333333), fontSize: 16),
                      ),
                    ],
                  ))*/
              // const Padding(
              //   padding: EdgeInsets.symmetric(horizontal: 20),
              //   child: Divider(
              //     color: Color(0xffE2E8F0),
              //     thickness: 1,
              //   ),
              // ),
              Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Order Total".tr(),
                        style: TextStyle(color: isDarkMode(context) ? const Color(0xffFFFFFF) : const Color(0xff333333), fontSize: 16),
                      ),
                      Text(
                        //  symbol + getTotalAmount().toStringAsFixed(decimal),
                        amountShow(amount: getTotalAmount().toString()),
                        style: TextStyle(fontWeight: FontWeight.w600, color: isDarkMode(context) ? const Color(0xffFFFFFF) : const Color(0xff333333), fontSize: 16),
                      ),
                    ],
                  )),
              const SizedBox(
                height: 10,
              )
            ],
          ),
        ),
      ],
    );
  }

  paymentCollectBy() {
    return GestureDetector(
      child: Container(
        margin: const EdgeInsets.only(left: 13, top: 10, right: 13, bottom: 13),
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
          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Payment by",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ).tr(),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Radio<String>(
                          value: 'Sender',
                          groupValue: paymentCollectByReceiverString,
                          onChanged: (value) {
                            setState(() {
                              paymentCollectByReceiverString = value!;
                            });
                          },
                        ),
                        const Text("Sender").tr()
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Radio<String>(
                          value: 'Receiver',
                          groupValue: paymentCollectByReceiverString,
                          onChanged: (value) {
                            setState(() {
                              paymentCollectByReceiverString = value!;
                            });
                          },
                        ),
                        const Text("Receiver").tr()
                      ],
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ///to show Button
  // buildButton({title}) {
  //   final size = MediaQuery.of(context).size;
  //   return SizedBox(
  //     width: size.width * 0.7,
  //     child: MaterialButton(
  //       height: 45,
  //       color: AppThemeData.primary300,
  //       onPressed: () async {
  //         if(paymentCollectByReceiver == "Sender"){
  //           await FireStoreUtils.createPaymentId();
  //           if (razorPay) {
  //             paymentType = 'razorpay';
  //             showLoadingAlert();
  //             RazorPayController().createOrderRazorPay(amount: getTotalAmount().toInt()).then((value) {
  //               if (value == null) {
  //                 Navigator.pop(context);
  //                 showAlert(_globalKey.currentContext!, response: "contact-admin".tr(), colors: Colors.red);
  //               } else {
  //                 CreateRazorPayOrderModel result = value;
  //                 openCheckout(
  //                   amount: getTotalAmount(),
  //                   orderId: result.id,
  //                 );
  //               }
  //             });
  //           } else if (payTm) {
  //             paymentType = 'paytm';
  //             showLoadingAlert();
  //             getPaytmCheckSum(context, amount: getTotalAmount());
  //           } else if (stripe) {
  //             paymentType = 'stripe';
  //             showLoadingAlert();
  //             stripeMakePayment(amount: getTotalAmount().toString());
  //           } else if (payFast) {
  //             paymentType = 'payfast';
  //             showLoadingAlert();
  //             PayStackURLGen.getPayHTML(payFastSettingData: payFastSettingData!, amount: getTotalAmount().toString()).then((value) async {
  //               bool isDone = await Navigator.of(context).push(MaterialPageRoute(
  //                   builder: (context) => PayFastScreen(
  //                     htmlData: value,
  //                     payFastSettingData: payFastSettingData!,
  //                   )));
  //
  //               print(isDone);
  //               if (isDone) {
  //                 placeParcelOrder();
  //                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //                   content: const Text(
  //                     "Payment Successful!!\n",
  //                   ).tr(),
  //                   backgroundColor: Colors.green.shade400,
  //                   duration: const Duration(seconds: 6),
  //                 ));
  //               } else {
  //                 Navigator.pop(context);
  //                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //                   content: Builder(
  //                       builder: (context) {
  //                         return const Text(
  //                           "Payment UnSuccessful!!\n",
  //                         ).tr();
  //                       }
  //                   ),
  //                   backgroundColor: Colors.red.shade400,
  //                   duration: const Duration(seconds: 6),
  //                 ));
  //               }
  //             });
  //           } else if (payStack) {
  //             paymentType = 'paystack';
  //             showLoadingAlert();
  //             payStackPayment(context);
  //           } else if (flutterWave) {
  //             paymentType = 'flutterwave';
  //             _flutterWaveInitiatePayment(context);
  //           } else if (paypal) {
  //             paymentType = 'paypal';
  //             showLoadingAlert();
  //             _makePaypalPayment(amount: getTotalAmount().toString());
  //           } else if (wallet && walletBalanceError == false) {
  //             paymentType = 'wallet';
  //
  //             placeParcelOrder();
  //             // showLoadingAlert();
  //
  //           } else {
  //             final SnackBar snackBar = SnackBar(
  //               content: Text(
  //                 "Select Payment Method".tr(),
  //                 textAlign: TextAlign.center,
  //                 style: const TextStyle(color: Colors.white),
  //               ),
  //               backgroundColor: AppThemeData.primary300,
  //             );
  //             ScaffoldMessenger.of(context).showSnackBar(snackBar);
  //           }
  //         }else{
  //           placeParcelOrder();
  //         }
  //
  //         // Navigator.push(context, MaterialPageRoute(builder: (context)=> const HistoryScreen()));
  //       },
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  //       child: Text(
  //         title,
  //         style: const TextStyle(color: Colors.white),
  //       ),
  //     ),
  //   );
  // }

  final Razorpay _razorPay = Razorpay();

  Stream<DocumentSnapshot<Map<String, dynamic>>>? userQuery;
  final fireStoreUtils = FireStoreUtils();

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
    userQuery = FireStoreUtils.firestore.collection(USERS).doc(MyAppState.currentUser!.userID).snapshots();
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
      children: [
        Visibility(
          visible: UserPreference.getWalletData() ?? false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 15, top: 10),
                child: Text(
                  'Select payment method'.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    letterSpacing: 0.5,
                    color: isDarkMode(context) ? Colors.white : const Color(0XFF000000),
                  ),
                ),
              ),
              const Divider(thickness: 1),
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: userQuery,
                  builder: (context, AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> asyncSnapshot) {
                    if (asyncSnapshot.hasError) {
                      return Text(
                        "error".tr(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      );
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

                    walletBalanceError = userData.wallet_amount < getTotalAmount() ? true : false;
                    return Column(
                      children: [
                        buildPaymentTile(
                            isVisible: UserPreference.getWalletData() ?? false,
                            selectedPayment: wallet,
                            walletError: walletBalanceError,
                            image: "assets/images/wallet_icon.png",
                            value: "Wallet".tr(),
                            childWidget: Text(
                              // currencyData!.symbol + double.parse(userData.wallet_amount.toString()).toStringAsFixed(decimal),
                              amountShow(amount: userData.wallet_amount.toString()),
                              style: TextStyle(
                                color: walletBalanceError ? Colors.red : Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            )),
                        Padding(
                          padding: const EdgeInsets.only(right: 15.0),
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
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 10),
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
                              child: Image.asset(
                                image,
                              ),
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
            placeParcelOrder();
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

  ///MercadoPago Payment Method
  mercadoPagoMakePayment() async {
    final headers = {
      'Authorization': 'Bearer ${mercadoPagoSettingData!.accessToken}',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      "items": [
        {
          "title": "Test",
          "description": "Test Payment",
          "quantity": 1,
          "currency_id": "BRL", // or your preferred currency
          "unit_price": double.parse(amount),
        }
      ],
      "payer": {"email": MyAppState.currentUser!.email},
      "back_urls": {
        "failure": "${GlobalURL}payment/failure",
        "pending": "${GlobalURL}payment/pending",
        "success": "${GlobalURL}payment/success",
      },
      "auto_return": "approved" // Automatically return after payment is approved
    });

    final response = await http.post(
      Uri.parse("https://api.mercadopago.com/checkout/preferences"),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final bool isDone = await Navigator.push(context, MaterialPageRoute(builder: (context) => MercadoPagoScreen(initialURl: data['init_point'])));

      if (isDone) {
        Navigator.pop(context);
        ShowToastDialog.showToast("Payment Successful!!");
        placeParcelOrder();
      } else {
        ShowToastDialog.showToast("Payment UnSuccessful!!");
      }
    } else {
      print('Error creating preference: ${response.body}');
      return null;
    }
  }

  ///PayStack Payment Method
  payStackPayment(BuildContext context) async {
    await PayStackURLGen.payStackURLGen(
      amount: (getTotalAmount() * 100).toString(),
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
                  amount: getTotalAmount().toString(),
                  reference: _payStackModel.data.reference,
                )));
        //Navigator.pop(_globalKey.currentContext!);

        if (isDone) {
          placeParcelOrder();
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

  //Midtrans payment
  midtransMakePayment({required String amount, required BuildContext context}) async {
    await createPaymentLink(amount: amount).then((url) async {
      ShowToastDialog.closeLoader();
      if (url != '') {
        final bool isDone = await Navigator.push(context, MaterialPageRoute(builder: (context) => MidtransScreen(initialURl: url)));
        if (isDone) {
          ShowToastDialog.showToast("Payment Successful!!");
          placeParcelOrder();
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
        placeParcelOrder();
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
          placeParcelOrder();
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
}
