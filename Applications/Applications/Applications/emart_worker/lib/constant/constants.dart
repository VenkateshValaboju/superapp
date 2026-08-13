import 'package:sharehands_worker/model/currency_model.dart';
import 'package:sharehands_worker/model/tax_model.dart';
import 'package:sharehands_worker/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';
import 'package:url_launcher/url_launcher.dart';

// ignore: constant_identifier_names
const STORAGE_ROOT = 'emart';
String senderId = '';
String jsonNotificationFileURL = '';
String GOOGLE_API_KEY = '';
const Setting = 'settings';
const WALLET = "wallet";
const Currency = 'currencies';
const WORKERS = 'providers_workers';
const USERS = 'users';
const PROVIDER_ORDER = "provider_orders";
const Order_Rating = 'items_review';
const ChatWorker = 'chat_worker';
const sections = "sections";
const REFERRAL = 'referral';


const dynamicNotification = 'dynamic_notification';

const ORDER_STATUS_PLACED = "Order Placed";
const ORDER_STATUS_ACCEPTED = "Order Accepted";
const ORDER_STATUS_ONGOING = "Order Ongoing";
const ORDER_STATUS_COMPLETED = "Order Completed";
const ORDER_STATUS_REJECTED = "Order Rejected";
const ORDER_STATUS_CANCELLED = "Order Cancelled";
const ORDER_STATUS_ASSIGNED = "Order Assigned";

const providerAccepted = "provider_accepted";
const providerRejected = "provider_rejected";
const providerStopTime = "stop_time";
const providerServiceInTransit = "service_intransit";
const providerServiceCompleted = "service_completed";
const providerServiceExtraCharges = "service_charges";
const providerBookingPlaced = "booking_placed";
const workerRejected = "worker_rejected";

CurrencyModel? currencyData;
String placeholderImage = '';
String appVersion = '';

String durationToString(int minutes) {
  return (minutes/60).toDouble().toStringAsFixed(2);
}

Future<void> makePhoneCall(String phoneNumber) async {
  final Uri launchUri = Uri(
    scheme: 'tel',
    path: phoneNumber,
  );
  await launchUrl(launchUri);
}

late ProgressDialog progressDialog;

showProgress(BuildContext context, String message, bool isDismissible) async {
  progressDialog = ProgressDialog(context, type: ProgressDialogType.normal, isDismissible: isDismissible);
  progressDialog.style(
      message: message,
      borderRadius: 10.0,
      backgroundColor: AppColors.colorPrimary,
      progressWidget: Container(
          padding: const EdgeInsets.all(8.0),
          child: const CircularProgressIndicator(
            backgroundColor: Colors.white,
          )),
      elevation: 10.0,
      insetAnimCurve: Curves.easeInOut,
      messageTextStyle: const TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.w600));

  await progressDialog.show();
}

updateProgress(String message) {
  progressDialog.update(message: message);
}

hideProgress() async {
  await progressDialog.hide();
}

String? validateEmail(String? value) {
  String pattern = r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
  RegExp regex = RegExp(pattern);
  if (!regex.hasMatch(value ?? '')) {
    return 'Please use a valid mail'.tr;
  } else {
    return null;
  }
}

String? validatePassword(String? value) {
  if ((value?.length ?? 0) < 6) {
    return 'Password length must be more than 6 chars.'.tr;
  } else {
    return null;
  }
}

Widget loader() {
  return Center(
    child: CircularProgressIndicator(color: AppColors.colorPrimary),
  );
}

String amountShow({required String? amount}) {
  if (currencyData!.symbolatright == true) {
    return "${double.parse(amount.toString()).toStringAsFixed(currencyData!.decimal!)} ${currencyData!.symbol.toString()}";
  } else {
    return "${currencyData!.symbol.toString()} ${double.parse(amount.toString()).toStringAsFixed(currencyData!.decimal!)}";
  }
}

double getTaxValue({String? amount, TaxModel? taxModel}) {
  double taxVal = 0.0;
  if (taxModel != null && taxModel.enable == true) {
    if (taxModel.type == "fix") {
      taxVal = double.parse(taxModel.tax.toString());
    } else {
      taxVal = (double.parse(amount.toString()) * double.parse(taxModel.tax!.toString())) / 100;
    }
  }
  return taxVal;
}
