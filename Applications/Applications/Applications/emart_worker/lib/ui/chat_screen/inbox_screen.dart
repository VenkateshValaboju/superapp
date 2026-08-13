import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sharehands_worker/constant/constants.dart';
import 'package:sharehands_worker/constant/show_toast_dialog.dart';
import 'package:sharehands_worker/main.dart';
import 'package:sharehands_worker/model/inbox_model.dart';
import 'package:sharehands_worker/model/user.dart';
import 'package:sharehands_worker/model/worker_model.dart';
import 'package:sharehands_worker/services/firebase_helper.dart';
import 'package:sharehands_worker/themes/app_colors.dart';
import 'package:sharehands_worker/ui/chat_screen/chat_screen.dart';
import 'package:sharehands_worker/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutterflow_paginate_firestore/paginate_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeChange.getTheme() ? AppColors.colorDark : AppColors.colorWhite,
        title: Text(
          'Inbox',
          style: TextStyle(color: themeChange.getTheme() ? AppColors.colorWhite : Colors.black, fontSize: 18, fontFamily: AppColors.medium),
        ),
        leading: InkWell(
            onTap: () {
              Get.back();
            },
            child: const Icon(
              Icons.arrow_back,
            )),
      ),
      body: PaginateFirestore(
        //item builder type is compulsory.
        shrinkWrap: true,
        itemBuilder: (context, documentSnapshots, index) {
          final data = documentSnapshots[index].data() as Map<String, dynamic>?;
          InboxModel inboxModel = InboxModel.fromJson(data!);
          return InkWell(
            onTap: () async {
              ShowToastDialog.showLoader("Please wait");

              User? customer = await FireStoreUtils.getUser(inboxModel.customerId.toString());
              WorkerModel? provider = await FireStoreUtils.getWorkerCurrentUser(inboxModel.restaurantId.toString());
              ShowToastDialog.closeLoader();
              Get.to(
                  ChatScreens(
                    customerName: "${customer!.firstName} ${customer.lastName}",
                    restaurantName: "${provider!.firstName!} ${provider.lastName!}",
                    orderId: inboxModel.orderId,
                    restaurantId: provider.id,
                    customerId: customer.userID,
                    customerProfileImage: customer.profilePictureURL,
                    restaurantProfileImage: provider.profilePictureURL,
                    token: customer.fcmToken,
                    chatType: inboxModel.chatType,
                  ));
            },
            child: ListTile(
              leading: ClipOval(
                child: CachedNetworkImage(
                    width: 50,
                    height: 50,
                    imageUrl: inboxModel.customerProfileImage.toString(),
                    imageBuilder: (context, imageProvider) => Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                              image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          )),
                        ),
                    errorWidget: (context, url, error) => ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Image.network(
                          placeholderImage,
                          fit: BoxFit.cover,
                        ))),
              ),
              title: Row(
                children: [
                  Expanded(child: Text(inboxModel.customerName.toString())),
                  Text(DateFormat('MMM d, yyyy').format(DateTime.fromMillisecondsSinceEpoch(inboxModel.createdAt!.millisecondsSinceEpoch)),
                      style: const TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
              subtitle: Text("Order Id : #${inboxModel.orderId}"),
            ),
          );
        },
        onEmpty: const Center(child: Text("No Conversion found")),
        // orderBy is compulsory to enable pagination
        query: FirebaseFirestore.instance.collection(ChatWorker).where("restaurantId", isEqualTo: MyAppState.currentUser!.id).orderBy('createdAt', descending: true),
        //Change types customerId
        itemBuilderType: PaginateBuilderType.listView,
        // to fetch real-time data
        isLive: true,
      ),
    );
  }
}
