
import 'package:sharehandsprovider/model/currency_model.dart';
import 'package:sharehandsprovider/model/mail_setting.dart';
import 'package:sharehandsprovider/model/tax_model.dart';
import 'package:sharehandsprovider/themes/app_colors.dart';
import 'package:sharehandsprovider/utils/dark_theme_provider.dart';
import 'package:sharehandsprovider/widgets/permission_dialog.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mailer/smtp_server.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mailer/mailer.dart';

// ignore: constant_identifier_names

const PROVIDERS_SERVICES = 'providers_services';
const FAVORITE_PROVIDER = 'favorite_provider';
const FAVORITE_SERVICES = 'favorite_service';
const CATEGORIES = 'provider_categories';
const STORAGE_ROOT = 'emart';
String senderId = '';
String jsonNotificationFileURL = '';
String GOOGLE_API_KEY = 'AIzaSyAvpV1E5NMbugsNcp2QLBNkPax-9r9a4l8';
String selectedMapType = '';
const USER_ROLE_PROVIDER = 'provider';
const USERS = 'users';
const Setting = 'settings';
const Currency = 'currencies';
const Order_Rating = 'items_review';
const WALLET = "wallet";
const PAYOUTS = "payouts";
const WORKERS = 'providers_workers';
const COUPONS = 'providers_coupons';
const emailTemplates = 'email_templates';
const payoutRequest = "payout_request";
const ChatWorker = "chat_worker";
const ChatProvider = "chat_provider";
const sections = "sections";
const REFERRAL = 'referral';

const PROVIDER_ORDER = "provider_orders";
const ORDER_STATUS_PLACED = "Order Placed";
const ORDER_STATUS_ACCEPTED = "Order Accepted";
const ORDER_STATUS_ASSIGNED = "Order Assigned";
const ORDER_STATUS_ONGOING = "Order Ongoing";
const ORDER_STATUS_COMPLETED = "Order Completed";
const ORDER_STATUS_REJECTED = "Order Rejected";
const ORDER_STATUS_CANCELLED = "Order Cancelled";

const dynamicNotification = 'dynamic_notification';

const providerAccepted = "provider_accepted";
const providerRejected = "provider_rejected";
const providerServiceInTransit = "service_intransit";
const providerServiceCompleted = "service_completed";
const providerServiceExtraCharges = "service_charges";
const providerBookingPlaced = "booking_placed";
const workerRejected = "worker_rejected";
const workerBookingAssigned = "worker_assigned";
const providerStopTime = "stop_time";

CurrencyModel? currencyData;
String placeholderImage = '';
String appVersion = '';

String? validateName(String? value) {
  String pattern = r'(^[a-zA-Z ]*$)';
  if (value!.isEmpty) {
    return 'Name is required'.tr;
  }
  return null;
}

String? validateOthers(String? value) {
  if (value?.length == 0) {
    return '*required'.tr;
  }
  return null;
}

String durationToString(int minutes) {
  return '${(minutes/60).toDouble().toStringAsFixed(2)}';
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

String? validateConfirmPassword(String? password, String? confirmPassword) {
  if (password != confirmPassword) {
    return 'Password must match'.tr;
  } else if (confirmPassword!.isEmpty) {
    return 'Confirm password is required'.tr;
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

Widget emptyView({required String text, required DarkThemeProvider themeChange}) {
  return Center(
    child: Text(
      text,
      style: TextStyle(color: themeChange.getTheme() ? AppColors.colorLightGrey : AppColors.assetColorGrey600, fontFamily: AppColors.semiBold, fontSize: 20),
    ),
  );
}

Future<void> makePhoneCall(String phoneNumber) async {
  final Uri launchUri = Uri(
    scheme: 'tel',
    path: phoneNumber,
  );
  await launchUrl(launchUri);
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

void checkPermission(Function() onTap,BuildContext context) async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied) {
    SnackBar snack = SnackBar(
      content:  Text(
        'You have to allow location permission to use your location'.tr,
        style: TextStyle(color: Colors.white),
      ),
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.black,
    );
    ScaffoldMessenger.of(context).showSnackBar(snack);
  } else if (permission == LocationPermission.deniedForever) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PermissionDialog();
      },
    );
  } else {
    onTap();
  }
}

String? dateFormatYYYYMMDD(String date) {
  final format = DateFormat("yyyy-MM-dd");
  String formattedDate = format.format(DateTime.parse(date));
  return formattedDate;
}

String? dateFormatDDMMMYYYY(String date) {
  final format = DateFormat("dd MMM, yyyy");
  String formattedDate = format.format(DateTime.parse(date));
  return formattedDate;
}

MailSettings? mailSettings;

final smtpServer = SmtpServer(mailSettings!.host.toString(),
    username: mailSettings!.userName.toString(), password: mailSettings!.password.toString(), port: 465, ignoreBadCertificate: false, ssl: true, allowInsecure: true);

sendMail({String? subject, String? body, bool? isAdmin = false, List<dynamic>? recipients}) async {
  // Create our message.

  print("SENDGMAIL");
  print(isAdmin);
  if (isAdmin == true) {
    print("SENDGMAIL11");
    recipients!.add(mailSettings!.userName.toString());
    print(recipients);
  }
  final message = Message()
    ..from = Address(mailSettings!.userName.toString(), mailSettings!.fromName.toString())
    ..recipients = recipients!
    ..subject = subject
    ..text = body
    ..html = body;

  try {
    final sendReport = await send(message, smtpServer);
    print('Message sent: ' + sendReport.toString());
  } on MailerException catch (e) {
    print(e);
    print('Message not sent.');
    for (var p in e.problems) {
      print('Problem: ${p.code}: ${p.msg}');
    }
  }
}
