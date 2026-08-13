import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sharehandscustomer/constants.dart';
import 'package:sharehandscustomer/main.dart';
import 'package:sharehandscustomer/model/CabOrderModel.dart';
import 'package:sharehandscustomer/model/CodModel.dart';
import 'package:sharehandscustomer/model/FlutterWaveSettingDataModel.dart';
import 'package:sharehandscustomer/model/MercadoPagoSettingsModel.dart';
import 'package:sharehandscustomer/model/PayFastSettingData.dart';
import 'package:sharehandscustomer/model/PayStackSettingsModel.dart';
import 'package:sharehandscustomer/model/RazorPayFailedModel.dart';

import 'package:sharehandscustomer/model/TaxModel.dart';
import 'package:sharehandscustomer/model/User.dart';
import 'package:sharehandscustomer/model/offer_model.dart';
import 'package:sharehandscustomer/model/payment_model/mid_trans.dart';
import 'package:sharehandscustomer/model/payment_model/orange_money.dart';
import 'package:sharehandscustomer/model/payment_model/xendit.dart';
import 'package:sharehandscustomer/model/paypalSettingData.dart';
import 'package:sharehandscustomer/model/paytmSettingData.dart';
import 'package:sharehandscustomer/model/razorpayKeyModel.dart';
import 'package:sharehandscustomer/model/stripeSettingData.dart';
import 'package:sharehandscustomer/model/topupTranHistory.dart';
import 'package:sharehandscustomer/services/FirebaseHelper.dart';
import 'package:sharehandscustomer/services/helper.dart';
import 'package:sharehandscustomer/services/show_toast_dialog.dart';
import 'package:sharehandscustomer/theme/app_them_data.dart';
import 'package:sharehandscustomer/theme/round_button_fill.dart';
import 'package:sharehandscustomer/userPrefrence.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:chapa_unofficial/chapa_unofficial.dart';

class CabPaymentScreen extends StatefulWidget {
  final CabOrderModel? cabOrderModel;
  final List<TaxModel>? taxModel;

  const CabPaymentScreen({Key? key, required this.cabOrderModel, this.taxModel}) : super(key: key);

  @override
  _CabPaymentScreenState createState() => _CabPaymentScreenState();
}

class _CabPaymentScreenState extends State<CabPaymentScreen> {
  late Future<List<OfferModel>> coupon;
  late Future<List<OfferModel>> publicoupon;
  TextEditingController txt = TextEditingController(text: '');
  final FireStoreUtils _fireStoreUtils = FireStoreUtils();
  var tipValue = 0.0;
  bool isTipSelected = false, isTipSelected1 = false, isTipSelected2 = false, isTipSelected3 = false;
  final TextEditingController _textFieldController = TextEditingController();

  final Razorpay _razorPay = Razorpay();

  @override
  void initState() {
    super.initState();
    print("----->${widget.cabOrderModel!.paymentMethod}");
    setAllFalse(value: widget.cabOrderModel!.paymentMethod.toString() == "cod" ? "Cash".tr() : widget.cabOrderModel!.paymentMethod.toString());

    if (widget.cabOrderModel!.paymentMethod == "cod") {
      selectedRadioTile = "Cash";
    }
    if (widget.cabOrderModel!.paymentMethod == "wallet") {
      selectedRadioTile = "Wallet";
    }
    if (widget.cabOrderModel!.paymentMethod == "chapa") {
      selectedRadioTile = "Chapa";
    }


    getTexDetails();
    getPaymentSettingData();
    _razorPay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorPay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWaller);
    _razorPay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    publicoupon = _fireStoreUtils.getOfferByCabCoupons();
    coupon = _fireStoreUtils.getCabCoupons();
    setState(() {});
  }

  double subTotal = 0.0;

  double discountAmount = 0.0;
  String discountType = "";
  String discountLable = "";
  String offerCode = "";

  List<OfferModel> couponList = [];

  getTexDetails() async {
    subTotal = double.parse(widget.cabOrderModel!.subTotal.toString());
    //await coupon.then((value) {
    await publicoupon.then((value) {
      couponList = value;
    });
    setState(() {});
  }

  // double getTaxAmount() {
  //   double totalTax = 0.0;
  //
  //   if (taxActive == true) {
  //     if (taxType == "percent") {
  //       totalTax = (subTotal - discountAmount) * taxAmount / 100;
  //     } else {
  //       totalTax = taxAmount;
  //     }
  //   }
  //   return totalTax;
  // }

  double getTotalAmount() {
    double taxAmount = 0.0;
    if (taxList != null) {
      for (var element in taxList!) {
        taxAmount = taxAmount + getTaxValue(amount: (subTotal - discountAmount).toString(), taxModel: element);
      }
    }
    return subTotal - discountAmount + taxAmount + tipValue;
  }

  // double getTotalAmount() {
  // return subTotal - discountAmount + getTaxAmount() + tipValue;
  //}

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    //setPrefData();
  }

  placeOrderChanges() async {
    CabOrderModel? orderModel = widget.cabOrderModel;
    orderModel!.tipValue = tipValue.toString();
    orderModel.paymentMethod = paymentType;
    /* if (taxActive != null && taxActive == true) {
      orderModel.taxType = taxType.toString();
      orderModel.tax = taxAmount.toString();
    }*/
    orderModel.discount = discountAmount;
    orderModel.adminCommission = sectionConstantModel!.adminCommision!.commission.toString();
    orderModel.adminCommissionType = sectionConstantModel!.adminCommision!.type;
    orderModel.paymentStatus = true;
    orderModel.taxModel = taxList;

    await FireStoreUtils().cabOrderPlace(orderModel, true);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode(context) ? AppThemeData.surfaceDark : AppThemeData.surface,
      key: _globalKey,
      appBar: AppBar(
        title: Text(
          'Payment'.tr(),
          style: TextStyle(color: isDarkMode(context) ? const Color(0xffFFFFFF) : Colors.black),
        ).tr(),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            couponList.isNotEmpty ? buildListPromoCode() : Container(),
            buildTotalRow(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: paymentListView(),
            )
          ],
        ),
      ),
      bottomNavigationBar: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: RoundedButtonFill(
            title: "Proceed".tr(),
            color: AppThemeData.primary300,
            textColor: AppThemeData.grey50,
            width: 18,
            height: 4,
            onPress: () async {
              if (chapa) {
                paymentType = 'chapa';
                showLoadingAlert();
                chapapay(getTotalAmount().toString(), context);
              } else if (wallet && walletBalanceError == false) {
                paymentType = 'wallet';

                showLoadingAlert();

                TopupTranHistoryModel wallet = TopupTranHistoryModel(
                    amount: getTotalAmount(),
                    order_id: widget.cabOrderModel!.id,
                    serviceType: 'cab-service',
                    id: Uuid().v4(),
                    user_id: MyAppState.currentUser!.userID,
                    date: Timestamp.now(),
                    isTopup: false,
                    payment_method: "wallet",
                    payment_status: "success",
                    transactionUser: "customer",
                    note: 'Cab Booking Amount Payment');

                await FireStoreUtils.firestore.collection("wallet").doc(wallet.id).set(wallet.toJson()).then((value) {
                  FireStoreUtils.updateWalletAmount(amount: -getTotalAmount()).then((value) {
                    Navigator.pop(context, true);
                  }).whenComplete(() {
                    placeOrderChanges();
                    showAlert(_globalKey.currentContext!, response: "Payment Successful Via Wallet".tr(), colors: Colors.green);
                  });
                });
              } else if (codPay) {
                paymentType = 'cod';
                placeOrderChanges();

                // print(DateTime.now().millisecondsSinceEpoch.toString());
                // if (widget.take_away!) {
                //   placeOrder(_globalKey.currentContext!);
                // } else {
                //   toCheckOutScreen(false, context);
                // }
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

                      print(discountAmount);
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
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
              ),
              margin: const EdgeInsets.only(top: 4),
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
                          snapshot[index].discountTypeOffer == "Fix Price"
                              ? (currencyData!.symbolatright == true)
                                  ? "${snapshot[index].discountOffer}${currencyData!.symbol.toString()} OFF"
                                  : "${currencyData!.symbol.toString()}${snapshot[index].discountOffer} OFF"
                              : "${snapshot[index].discountOffer} % Off",
                          style: const TextStyle(color: Color(GREY_TEXT_COLOR), fontWeight: FontWeight.bold, letterSpacing: 0.7),
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
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal, letterSpacing: 0.5, color: Color(GREY_TEXT_COLOR)),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 15, right: 15, top: 3),
                        width: 1,
                        color: const Color(COUPON_DASH_COLOR),
                      ),
                      Text("valid till ".tr() + getDate(snapshot[index].expireOfferDate!.toDate().toString())!,
                          style: const TextStyle(letterSpacing: 0.5, color: Color(0Xff696A75)))
                    ],
                  ),
                ],
              )),
        ),
      ),
    );
  }

  String? getDate(String date) {
    final format = DateFormat("MMM dd, yyyy");
    String formattedDate = format.format(DateTime.parse(date));
    return formattedDate;
  }

  Widget buildTotalRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            margin: const EdgeInsets.only(left: 13, top: 13, right: 13, bottom: 13),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Image(
                    image: AssetImage("assets/images/reedem.png"),
                    width: 50,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Column(
                      children: [
                        Text(
                          "Redeem Coupon".tr(),
                          style: const TextStyle(),
                        ),
                        Text("Add coupon code".tr(), style: const TextStyle()),
                      ],
                    ),
                  )
                ]),
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                        isScrollControlled: true,
                        isDismissible: true,
                        context: context,
                        backgroundColor: Colors.transparent,
                        enableDrag: true,
                        builder: (BuildContext context) => sheet());
                  },
                  child: const Image(image: AssetImage("assets/images/add.png"), width: 40),
                )
              ],
            )),
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
              Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Subtotal".tr(),
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        amountShow(amount: subTotal.toString()),
                        style: TextStyle(color: isDarkMode(context) ? const Color(0xffFFFFFF) : const Color(0xff333333), fontSize: 16),
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
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        "(-" + amountShow(amount: discountAmount.toString()) + ")",
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ],
                  )),
              Visibility(
                visible: offerCode.isNotEmpty,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Text(
                    "Coupon code :".tr() + "${offerCode}",
                    style: TextStyle(fontFamily: AppThemeData.medium, color: AppThemeData.primary300, fontSize: 16),
                  ),
                ),
              ),
              const Divider(
                thickness: 1,
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
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            Text(
                              amountShow(amount: getTaxValue(amount: (subTotal - discountAmount).toString(), taxModel: taxModel).toString()),
                              style: TextStyle(color: isDarkMode(context) ? const Color(0xffFFFFFF) : const Color(0xff333333), fontSize: 16),
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
              // Container(
              //     padding:
              //         const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              //     child: Row(
              //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //       children: [
              //         Text(
              //           ((taxLable.isNotEmpty)
              //                   ? taxLable.toString()
              //                   : "Tax".tr()) +
              //               " ${(taxType == "fix") ? "(${taxAmount} ${currencyData!.symbol})" : "($taxAmount %)"}",
              //           style: const TextStyle(fontSize: 16),
              //         ),
              //         Text(
              //           amountShow(amount:getTaxAmount().toString()),
              //           style: TextStyle(
              //               color: isDarkMode(context)
              //                   ? const Color(0xffFFFFFF)
              //                   : const Color(0xff333333),
              //               fontSize: 16),
              //         ),
              //       ],
              //     )),
              // const Divider(
              //   color: Color(0xffE2E8F0),
              //   height: 0.1,
              // ),
              Visibility(
                  visible: ((tipValue) > 0),
                  child: Column(
                    children: [
                      Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Tip amount".tr(),
                                style: TextStyle(color: isDarkMode(context) ? const Color(0xffFFFFFF) : const Color(0xff333333), fontSize: 16),
                              ),
                              Text(
                                amountShow(amount: tipValue.toString()),
                                style: TextStyle(color: isDarkMode(context) ? const Color(0xffFFFFFF) : const Color(0xff333333), fontSize: 16),
                              ),
                            ],
                          )),
                      const Divider(
                        thickness: 1,
                      ),
                    ],
                  )),

              Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Order Total".tr(),
                        style: TextStyle(color: isDarkMode(context) ? const Color(0xffFFFFFF) : const Color(0xff333333), fontSize: 16),
                      ),
                      Text(
                        amountShow(amount: getTotalAmount().toString()),
                        style: TextStyle(color: isDarkMode(context) ? const Color(0xffFFFFFF) : const Color(0xff333333), fontSize: 16),
                      ),
                    ],
                  )),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Tip your delivery partner".tr(),
                textAlign: TextAlign.start,
                style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode(context) ? const Color(0xffFFFFFF) : const Color(0xff333333), fontSize: 15),
              ),
              Text(
                "100% of the tip will go to your delivery partner".tr(),
                style: const TextStyle(color: Color(0xff9091A4), fontSize: 14),
              ),
              const SizedBox(
                height: 15,
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isTipSelected) {
                          isTipSelected = false;
                          tipValue = 0;
                        } else {
                          tipValue = 10;
                          isTipSelected = true;
                        }

                        isTipSelected1 = false;
                        isTipSelected2 = false;
                        isTipSelected3 = false;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 5),
                      padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                      decoration: BoxDecoration(
                        color: tipValue == 10 && isTipSelected
                            ? AppThemeData.primary300
                            : isDarkMode(context)
                                ? Colors.black
                                : const Color(0xffFFFFFF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xff9091A4), width: 1),
                      ),
                      child: Center(
                          child: Text(
                        amountShow(amount: "10"),
                        style: TextStyle(color: isDarkMode(context) ? const Color(0xffFFFFFF) : const Color(0xff333333), fontSize: 14),
                      )),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isTipSelected1) {
                          isTipSelected1 = false;
                          tipValue = 0;
                        } else {
                          tipValue = 20;
                          isTipSelected1 = true;
                        }
                        isTipSelected = false;
                        isTipSelected2 = false;
                        isTipSelected3 = false;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 5),
                      padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                      decoration: BoxDecoration(
                        color: tipValue == 20 && isTipSelected1
                            ? AppThemeData.primary300
                            : isDarkMode(context)
                                ? Colors.black
                                : const Color(0xffFFFFFF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xff9091A4), width: 1),
                      ),
                      child: Center(
                          child: Text(
                        amountShow(amount: "20"),
                        style: TextStyle(color: isDarkMode(context) ? const Color(0xffFFFFFF) : const Color(0xff333333), fontSize: 14),
                      )),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isTipSelected2) {
                          isTipSelected2 = false;
                          tipValue = 0;
                        } else {
                          tipValue = 30;
                          isTipSelected2 = true;
                        }

                        isTipSelected = false;
                        isTipSelected1 = false;

                        isTipSelected3 = false;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 5),
                      padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                      decoration: BoxDecoration(
                        color: tipValue == 30 && isTipSelected2
                            ? AppThemeData.primary300
                            : isDarkMode(context)
                                ? Colors.black
                                : const Color(0xffFFFFFF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xff9091A4), width: 1),
                      ),
                      child: Center(
                          child: Text(
                        //symbol + "30",
                        amountShow(amount: "30"),
                        style: TextStyle(color: isDarkMode(context) ? const Color(0xffFFFFFF) : const Color(0xff333333), fontSize: 14),
                      )),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (isTipSelected3) {
                          setState(() {
                            if (isTipSelected3) {
                              isTipSelected3 = false;
                              tipValue = 0;
                            }
                            isTipSelected = false;
                            isTipSelected1 = false;
                            isTipSelected2 = false;
                            // grandtotal += tipValue;
                          });
                        } else {
                          _displayDialog(context);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                        decoration: BoxDecoration(
                          color: isTipSelected3
                              ? AppThemeData.primary300
                              : isDarkMode(context)
                                  ? Colors.black
                                  : const Color(0xffFFFFFF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xff9091A4), width: 1),
                        ),
                        child: Center(
                            child: Text(
                          "Other".tr(),
                          style: TextStyle(color: isDarkMode(context) ? const Color(0xffFFFFFF) : const Color(0xff333333), fontSize: 14),
                        )),
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        )
      ],
    );
  }

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
                        Container(
                            padding: const EdgeInsets.only(top: 10),
                            child: const Text(
                              "Voucher or Coupon code",
                              style: TextStyle(color: Color(0XFF9091A4), letterSpacing: 0.5, height: 2),
                            ).tr()),
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
                          child: RoundedButtonFill(
                            title: "REDEEM NOW".tr(),
                            color: AppThemeData.primary300,
                            textColor: AppThemeData.grey50,
                            onPress: () async {
                              setState(() {
                                for (int a = 0; a < snapshot.data!.length; a++) {
                                  OfferModel couponModel = snapshot.data![a];
                                  if (txt.text.toString() == couponModel.offerCode!.toString()) {
                                    if (couponModel.discountTypeOffer == 'Percentage' || couponModel.discountTypeOffer == 'Percent') {
                                      discountAmount = subTotal * double.parse(couponModel.discountOffer!) / 100;
                                      offerCode = couponModel.offerCode.toString();
                                      break;
                                    } else {
                                      discountAmount = double.parse(couponModel.discountOffer!);
                                      offerCode = couponModel.offerCode.toString();
                                    }
                                  }
                                }
                              });

                              Navigator.pop(context);
                            },
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

  _displayDialog(BuildContext context) async {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: Text('Tip your driver partner'.tr()),
            content: TextField(
              controller: _textFieldController,
              textInputAction: TextInputAction.go,
              keyboardType: const TextInputType.numberWithOptions(),
              decoration: InputDecoration(hintText: "Enter your tip".tr()),
            ),
            actions: <Widget>[
              RoundedButtonFill(
                title: "cancel".tr(),
                color: AppThemeData.primary300,
                textColor: AppThemeData.grey50,
                onPress: () async {
                  Navigator.pop(context);
                },
              ),
              RoundedButtonFill(
                title: "Submit".tr(),
                color: AppThemeData.primary300,
                textColor: AppThemeData.grey50,
                onPress: () async {
                  setState(() {
                    var value = _textFieldController.text.toString();
                    if (value.isEmpty) {
                      isTipSelected3 = false;
                      tipValue = 0;
                    } else {
                      isTipSelected3 = true;
                      tipValue = double.parse(value);
                    }
                    isTipSelected = false;
                    isTipSelected1 = false;
                    isTipSelected2 = false;

                    Navigator.of(context).pop();
                  });
                },
              )
            ],
          );
        });
  }

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

  RazorPayModel? razorPayData = UserPreference.getRazorPayData();

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

    futurecod = fireStoreUtils.getCod();
  }

  Widget paymentListView() {
    return Column(
      children: [
        Visibility(
          visible: UserPreference.getWalletData() ?? false,
          child: Column(
            children: [
              const Divider(),
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

                    walletBalanceError = userData.wallet_amount < getTotalAmount() ? true : false;
                    return Column(
                      children: [
                        // CheckboxListTile(
                        //   onChanged: (bool? value) {
                        //     setState(() {
                        //       if (!walletBalanceError) {
                        //         wallet = true;
                        //       } else {
                        //         wallet = false;
                        //       }
                        //
                        //       razorPay = false; //razorPay ? false : true;
                        //       codPay = false;
                        //       payTm = false;
                        //       payStack = false;
                        //       flutterWave = false;
                        //       pay = false;
                        //       paypal = false;
                        //       payFast = false;
                        //       stripe = false;
                        //       selectedCardID = '';
                        //       paymentOption = "Pay Online Via Wallet".tr();
                        //     });
                        //   },
                        //   value: wallet,
                        //   contentPadding: const EdgeInsets.all(0),
                        //   secondary: const FaIcon(FontAwesomeIcons.wallet),
                        //   title: Row(
                        //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        //     children: [
                        //       Text('Wallet'.tr()),
                        //       Column(
                        //         children: [
                        //           Text(
                        //             currencyData!.symbol + double.parse(userData.wallet_amount.toString()).toStringAsFixed(decimal),
                        //             style: TextStyle(
                        //                 color: walletBalanceError ? Colors.red : Colors.green,  fontFamily: AppThemeData.medium, fontSize: 18),
                        //           ),
                        //         ],
                        //       )
                        //     ],
                        //   ),
                        // ),

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
                                fontWeight: FontWeight.w600,
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
          isVisible: UserPreference.getWalletData() ?? false,
          selectedPayment: codPay,
          image: "assets/images/cash.png",
          value: "Cash".tr(),
        ),
        buildPaymentTile(
          isVisible: true,
          selectedPayment: chapa,
          image: "assets/images/telebirr.png",
          value: "Telebirr, CBE Birr, ...".tr(),
        ),
      
        const Divider(),
      ],
    );
  }

  bool walletBalanceError = false;
  bool wallet = false;
  bool codPay = false;
  bool chapa = false;

  String selectedCardID = '';
  bool isStaging = true;
  bool enableAssist = true;
  bool restrictAppInvoke = false;
  String result = "";

  Future<CodModel?>? futurecod;
  String paymentOption = 'Pay Via Wallet'.tr();
  String paymentType = "";

  setAllFalse({required String value}) {
    print("----->dd" + value);
    setState(() {
      codPay = false;
      wallet = false;
      chapa = false;

      if (value == "Telebirr, CBE Birr, ..." || value.toLowerCase() == "telebirr, cbe birr, ...") {
        chapa = true;
        print("-------->$chapa");
      }
      if (value == "Cash") {
        codPay = true;
        print("-------->$codPay");
      }
      if (value == "Wallet" || value == "wallet") {
        wallet = true;
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
                              child: Image.asset(image),
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

  //RazorPay payment function
  void openCheckout({required amount, required orderId}) async {
    var options = {
      'key': razorPayData!.razorpayKey,
      'amount': amount * 100,
      'name': PAYID,
      'order_id': orderId,
      "currency": currencyData?.code,
      'description': 'wallet Topup'.tr(),
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': MyAppState.currentUser!.phoneNumber,
        'email': MyAppState.currentUser!.email,
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorPay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    Navigator.pop(_globalKey.currentContext!, true);
    print(response.orderId);
    print(response.paymentId);

    placeOrderChanges();
    ScaffoldMessenger.of(_globalKey.currentContext!).showSnackBar(SnackBar(
      content: Text(
        "Payment Successful!!\n".tr() + response.orderId!,
      ),
      backgroundColor: Colors.green.shade400,
      duration: const Duration(seconds: 6),
    ));
  }

  void _handleExternalWaller(ExternalWalletResponse response) {
    Navigator.pop(_globalKey.currentContext!);
    ScaffoldMessenger.of(_globalKey.currentContext!).showSnackBar(SnackBar(
      content: Text(
        "Payment Proccessing Via\n".tr() + response.walletName!,
      ),
      backgroundColor: Colors.blue.shade400,
      duration: const Duration(seconds: 8),
    ));
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Navigator.pop(_globalKey.currentContext!);
    print(response.code);
    RazorPayFailedModel lom = RazorPayFailedModel.fromJson(jsonDecode(response.message!.toString()));
    ScaffoldMessenger.of(_globalKey.currentContext!).showSnackBar(SnackBar(
      content: Text(
        "Payment Failed!!\n".tr() + lom.error.description,
      ),
      backgroundColor: Colors.red.shade400,
      duration: const Duration(seconds: 8),
    ));
  }

  ///Stripe payment function

  Map<String, dynamic>? paymentIntentData;

  Future<void> chapapay(String amount, BuildContext contextt) async{
    // Generate a random transaction reference with a custom prefix
    String txRef = TxRefRandomGenerator.generate(prefix: 'sharehands');
    
    // Access the generated transaction reference
    String storedTxRef = TxRefRandomGenerator.gettxRef;
    
    // Print the generated transaction reference and the stored transaction reference
    print('Generated TxRef: $txRef');
    print('Stored TxRef: $storedTxRef');
    print(MyAppState.currentUser!.phoneNumber);
    await Chapa.getInstance.startPayment(
          // enableInAppPayment: false,
          context: contextt,
          onInAppPaymentSuccess: (successMsg) async {
            // Handle success events
            Navigator.pop(context);
            ShowToastDialog.showToast("Payment Successfully");
            placeOrderChanges();
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
          amount: '1',
          currency: 'ETB',
          txRef: storedTxRef,
        );
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
