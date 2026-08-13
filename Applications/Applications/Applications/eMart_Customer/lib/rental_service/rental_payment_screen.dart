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
import 'package:sharehandscustomer/rental_service/model/rental_order_model.dart';
import 'package:sharehandscustomer/rental_service/rental_booking_screen.dart';
import 'package:sharehandscustomer/rental_service/rental_service_dash_board.dart';
import 'package:sharehandscustomer/send_notification.dart';
import 'package:sharehandscustomer/services/FirebaseHelper.dart';
import 'package:sharehandscustomer/services/helper.dart';
import 'package:sharehandscustomer/services/show_toast_dialog.dart';
import 'package:sharehandscustomer/theme/app_them_data.dart';
import 'package:sharehandscustomer/theme/round_button_fill.dart';
import 'package:sharehandscustomer/userPrefrence.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:chapa_unofficial/chapa_unofficial.dart';

class RentalPaymentScreen extends StatefulWidget {
  User? driverDetails;
  RentalOrderModel? rentalOrderModel;

  RentalPaymentScreen({Key? key, required this.driverDetails, this.rentalOrderModel}) : super(key: key);

  @override
  State<RentalPaymentScreen> createState() => _RentalPaymentScreenState();
}

class _RentalPaymentScreenState extends State<RentalPaymentScreen> {
  late Future<List<OfferModel>> coupon;
  late Future<List<OfferModel>> publiccoupon;
  final FireStoreUtils _fireStoreUtils = FireStoreUtils();

  RentalOrderModel? rentalOrderModel;
  User? driverDetails;

  List<OfferModel> couponList = [];

  @override
  void initState() {
    super.initState();
    setState(() {
      driverDetails = widget.driverDetails;
      rentalOrderModel = widget.rentalOrderModel;
    });
    getTexDetails();
    getPaymentSettingData();
    publiccoupon = _fireStoreUtils.getOfferByRentalCoupons();
    coupon = _fireStoreUtils.getRentalCoupons();
  }

  bool? taxActive = false;
  double subTotal = 0.0;
  double driverRate = 0.0;

  double discountAmount = 0.0;
  String discountType = "";
  String discountLable = "";
  String offerCode = "";

  getTexDetails() async {
    int day = daysBetween(rentalOrderModel!.pickupDateTime!.toDate(), rentalOrderModel!.dropDateTime!.toDate());
    print("------->" + day.toString());
    if (rentalOrderModel!.bookWithDriver == true) {
      double carRate = double.parse(driverDetails!.carRate) * day;
      subTotal = carRate;
      driverRate = double.parse(driverDetails!.driverRate) * day;
    } else {
      subTotal = double.parse(driverDetails!.carRate) * day;
    }

    //await coupon.then((value) {
    await publiccoupon.then((value) {
      couponList = value;
    });
    setState(() {});
  }

  int daysBetween(DateTime from, DateTime to) {
    print(from);
    print(to);
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return to.difference(from).inDays + 1;
  }

  /* double getTaxAmount() {
    double totalTax = 0.0;
    if (taxActive == true) {
      if (taxType == "percent") {
        totalTax = ((subTotal + driverRate) - discountAmount) * taxAmount / 100;
      } else {
        totalTax = taxAmount;
      }
    }
    return totalTax;
  }*/

  User? comapny;

  placeParcelOrder() async {
    if (driverDetails!.companyId.isNotEmpty) {
      await FireStoreUtils.getCurrentUser(driverDetails!.companyId).then((value) {
        setState(() {
          comapny = value;
        });
      });
    }

    rentalOrderModel = RentalOrderModel(
      authorID: MyAppState.currentUser!.userID,
      author: MyAppState.currentUser,
      pickupAddress: widget.rentalOrderModel!.pickupAddress,
      bookWithDriver: widget.rentalOrderModel!.bookWithDriver,
      dropAddress: widget.rentalOrderModel!.dropAddress,
      dropDateTime: widget.rentalOrderModel!.dropDateTime,
      dropLatLong: widget.rentalOrderModel!.dropLatLong,
      pickupDateTime: widget.rentalOrderModel!.pickupDateTime,
      pickupLatLong: widget.rentalOrderModel!.pickupLatLong,
      adminCommission: sectionConstantModel!.adminCommision!.commission.toString(),
      adminCommissionType: sectionConstantModel!.adminCommision!.type,
      discount: discountAmount.toString(),
      discountType: discountType,
      discountLabel: discountLable,
      status: ORDER_STATUS_PLACED,
      paymentMethod: paymentType,
      createdAt: Timestamp.now(),
      // tax: taxAmount.toString(),
      // taxLabel: taxLable,
      // taxType: taxType,
      taxModel: taxList,
      subTotal: subTotal.toString(),
      driverRate: driverRate.toString(),
      driverID: driverDetails!.userID,
      driver: driverDetails,
      company: comapny,
      companyID: driverDetails!.companyId,
      sectionId: sectionConstantModel!.id,
    );

    /* if(taxActive!=null&&taxActive==true){
      rentalOrderModel!.taxType=taxType.toString();
      rentalOrderModel!.tax=taxAmount.toString();
      rentalOrderModel!.taxLabel=taxLable.toString();
    }*/

    await FireStoreUtils().rentalOrderPlace(rentalOrderModel!, getTotalAmount()).then((value) async {
      // if (driverDetails!.companyId.isNotEmpty) {
      //   await FireStoreUtils.sendFcmMessage(rentalBooked, comapny!.fcmToken,{});
      // } else {
      Map<String, dynamic> payLoad = <String, dynamic>{"type": "rental_order", "orderId": widget.rentalOrderModel!.id};
      await SendNotification.sendFcmMessage(rentalBooked, widget.driverDetails!.fcmToken, payLoad);
      //  }
    });
    await FireStoreUtils.sendRentalBookEmail(orderModel: rentalOrderModel!);
    await FireStoreUtils.sendRentalBookDriverEmail(orderModel: rentalOrderModel!);

    final SnackBar snackBar = SnackBar(
      content: Text(
        "Ride successfully booked".tr(),
        textAlign: TextAlign.start,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: AppThemeData.primary300,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    pushAndRemoveUntil(
        context,
        RentalServiceDashBoard(
          user: MyAppState.currentUser!,
          currentWidget: const RentalBookingScreen(),
          appBarTitle: 'Booking'.tr(),
          drawerSelection: DrawerSelection.Orders,
        ));
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
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                margin: const EdgeInsets.only(left: 10, top: 10, right: 10, bottom: 10),
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
                    const Text(
                      "PickUp",
                      style: TextStyle(fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.w800),
                    ).tr(),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.access_time_rounded, color: AppThemeData.primary300, size: 18),
                        const SizedBox(
                          width: 5,
                        ),
                        Expanded(
                          child: Text(
                            DateFormat('yyyy-MM-dd hh:mm a').format(rentalOrderModel!.pickupDateTime!.toDate()),
                            style: TextStyle(letterSpacing: 1, fontFamily: AppThemeData.medium),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on, color: AppThemeData.primary300, size: 18),
                        const SizedBox(
                          width: 5,
                        ),
                        Expanded(
                          child: Text(
                            rentalOrderModel!.pickupAddress.toString(),
                            style: TextStyle(letterSpacing: 1, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                margin: const EdgeInsets.only(left: 10, top: 10, right: 10, bottom: 10),
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
                    const Text(
                      "Drop off",
                      style: TextStyle(fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.w800),
                    ).tr(),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.access_time_rounded, color: AppThemeData.primary300, size: 18),
                        const SizedBox(
                          width: 5,
                        ),
                        Expanded(
                          child: Text(
                            DateFormat('yyyy-MM-dd hh:mm a').format(rentalOrderModel!.dropDateTime!.toDate()),
                            style: TextStyle(letterSpacing: 1, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on, color: AppThemeData.primary300, size: 18),
                        const SizedBox(
                          width: 5,
                        ),
                        Expanded(
                          child: Text(
                            rentalOrderModel!.dropAddress.toString(),
                            style: TextStyle(letterSpacing: 1, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              couponList.isNotEmpty ? buildListPromoCode() : Container(),
              buildPromoCode(),
              buildTotalRow(),
              paymentListView()
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: RoundedButtonFill(
          title: "Continue".tr(),
          color: AppThemeData.primary300,
          textColor: AppThemeData.grey50,
          onPress: () async {
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
        ),
      ),
    );
  }

  Widget buildTotalRow() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Booking summary".tr(), style: const TextStyle(letterSpacing: 1, fontWeight: FontWeight.w600)),
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
                    "Driver Amount".tr(),
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    amountShow(amount: driverRate.toString()),
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
                    "Coupon code :".tr() + "$offerCode",
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
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        Text(
                          amountShow(amount: getTaxValue(amount: ((subTotal + driverRate) - discountAmount).toString(), taxModel: taxModel).toString()),
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
          /* Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ((taxLable.isNotEmpty) ? taxLable.toString() : "Tax".tr()) + " ${(taxType == "fix") ? "" : "($taxAmount %)"}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    amountShow(amount: getTaxAmount().toString()),
                    style: TextStyle(color: isDarkMode(context) ? const Color(0xffFFFFFF) : const Color(0xff333333), fontSize: 16),
                  ),
                ],
              )),*/
          // const Divider(
          //   color: Color(0xffE2E8F0),
          //   height: 0.1,
          // ),

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
    );
  }

  /*double getTotalAmount() {
    return (subTotal + driverRate) - discountAmount + getTaxAmount();
  }*/
  double getTotalAmount() {
    double taxAmount = 0.0;
    if (taxList != null) {
      for (var element in taxList!) {
        taxAmount = taxAmount + getTaxValue(amount: ((subTotal + driverRate) - discountAmount).toString(), taxModel: element);
      }
    }
    return (subTotal + driverRate) - discountAmount + taxAmount;
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
                        Text("Apply promo code".tr(), style: const TextStyle(fontSize: 15, color: Colors.grey)),
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
                                  if (txt.text.toString().toLowerCase() == couponModel.offerCode!.toString().toLowerCase()) {
                                    if (couponModel.discountTypeOffer == 'Percentage' || couponModel.discountTypeOffer == 'Percent') {
                                      discountAmount = (subTotal + driverRate) * double.parse(couponModel.discountOffer!) / 100;
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
                                }
                              });
                              print(discountAmount);

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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
            margin: const EdgeInsets.only(left: 15),
            child: Text("Select Payment Method".tr(), style: TextStyle(fontSize: 16, color: Colors.black, letterSpacing: 1, fontWeight: FontWeight.w600))),
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
          isVisible: codModel != null ? codModel!.cod : false,
          selectedPayment: cod,
          image: "assets/images/cash.png",
          value: "Cash".tr(),
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
