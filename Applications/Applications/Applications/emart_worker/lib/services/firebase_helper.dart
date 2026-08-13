import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sharehands_worker/constant/constants.dart';
import 'package:sharehands_worker/constant/show_toast_dialog.dart';
import 'package:sharehands_worker/main.dart';
import 'package:sharehands_worker/model/chat_video_container.dart';
import 'package:sharehands_worker/model/conversation_model.dart';
import 'package:sharehands_worker/model/currency_model.dart';
import 'package:sharehands_worker/model/inbox_model.dart';
import 'package:sharehands_worker/model/notification_model.dart';
import 'package:sharehands_worker/model/on_boarding_model.dart';
import 'package:sharehands_worker/model/onprovider_order_model.dart';
import 'package:sharehands_worker/model/rating_model.dart';
import 'package:sharehands_worker/model/referral_model.dart';
import 'package:sharehands_worker/model/sectionModel.dart';
import 'package:sharehands_worker/model/topupTranHistory.dart';
import 'package:sharehands_worker/model/user.dart';
import 'package:sharehands_worker/model/worker_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:http/http.dart' as http;

class FireStoreUtils {
  static Reference storage = FirebaseStorage.instance.ref();
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  static FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  Future<CurrencyModel?> getCurrency() async {
    CurrencyModel? currency;
    await firestore.collection(Currency).where("isActive", isEqualTo: true).get().then((value) {
      if (value.docs.isNotEmpty) {
        currency = CurrencyModel.fromJson(value.docs.first.data());
      }
    });
    return currency;
  }

  static Future<WorkerModel?> getWorkerCurrentUser(String uid) async {
    DocumentSnapshot<Map<String, dynamic>> userDocument = await firestore.collection(WORKERS).doc(uid).get();
    if (userDocument.data() != null && userDocument.exists) {
      return WorkerModel.fromJson(userDocument.data()!);
    } else {
      return null;
    }
  }

  static Future<User?> getUser(String uid) async {
    DocumentSnapshot<Map<String, dynamic>> userDocument = await firestore.collection(USERS).doc(uid).get();
    if (userDocument.data() != null && userDocument.exists) {
      return User.fromJson(userDocument.data()!);
    } else {
      return null;
    }
  }

  static Future providerWalletSet(OnProviderOrderModel orderModel, bool isSent) async {
    if (isSent == true) {
      double total = 0.0;
      double discount = 0.0;
      double specialDiscount = 0.0;
      double taxAmount = 0.0;

      if (orderModel.provider.disPrice == "" || orderModel.provider.disPrice == "0") {
        total += orderModel.quantity * double.parse(orderModel.provider.price.toString());
      } else {
        total += orderModel.quantity * double.parse(orderModel.provider.disPrice.toString());
      }

      if (orderModel.discount != null) {
        discount = double.parse(orderModel.discount.toString());
      }
      var totalamount = total - discount - specialDiscount;

      double adminComm = (orderModel.adminCommissionType == 'Percent' || orderModel.adminCommissionType == 'percentage')
          ? (totalamount * double.parse(orderModel.adminCommission!)) / 100
          : double.parse(orderModel.adminCommission!);

      if (orderModel.taxModel != null) {
        for (var element in orderModel.taxModel!) {
          taxAmount = taxAmount + getTaxValue(amount: totalamount.toString(), taxModel: element);
        }
      }
      double finalAmount = totalamount + taxAmount + double.parse(orderModel.extraCharges!.isEmpty ? "0.0" : orderModel.extraCharges.toString());

      if (orderModel.payment_method.toLowerCase() != "cod") {
        TopupTranHistoryModel historyModel = TopupTranHistoryModel(
            amount: finalAmount,
            id: const Uuid().v4(),
            orderId: orderModel.id,
            userId: orderModel.provider.author.toString(),
            date: Timestamp.now(),
            isTopup: true,
            paymentMethod: "Wallet",
            paymentStatus: "success",
            serviceType: 'ondemand-service',
            note: 'Booking Amount',
            transactionUser: "provider");

        await firestore.collection(WALLET).doc(historyModel.id).set(historyModel.toJson());
        await updateProviderWalletAmount(amount: finalAmount, userId: orderModel.provider.author);
      }

      TopupTranHistoryModel adminCommission = TopupTranHistoryModel(
          amount: adminComm,
          id: const Uuid().v4(),
          orderId: orderModel.id,
          userId: orderModel.provider.author.toString(),
          date: Timestamp.now(),
          isTopup: false,
          paymentMethod: "Wallet",
          paymentStatus: "success",
          serviceType: 'ondemand-service',
          note: 'Admin commission Deducted',
          transactionUser: "provider");

      await firestore.collection(WALLET).doc(adminCommission.id).set(adminCommission.toJson());
      await updateProviderWalletAmount(amount: -adminComm, userId: orderModel.provider.author);
    }
  }

  static Future updateProviderWalletAmount({required amount, required userId}) async {
    await firestore.collection(USERS).doc(userId).get().then((value) async {
      DocumentSnapshot<Map<String, dynamic>> userDocument = value;
      if (userDocument.data() != null && userDocument.exists) {
        try {
          print(userDocument.data());
          User user = User.fromJson(userDocument.data()!);
          user.walletAmount = user.walletAmount + amount;
          await firestore.collection(USERS).doc(userId).set(user.toJson()).then((value) => print("north"));
        } catch (error) {
          print(error);
          if (error.toString() == "Bad state: field does not exist within the DocumentSnapshotPlatform") {
            print("does not exist");
          } else {
            print("went wrong!!");
          }
        }
      } else {
        return 0.111;
      }
    });
  }



  static Future<WorkerModel?> updateCurrentUser(WorkerModel user) async {
    return await firestore.collection(WORKERS).doc(user.id).set(user.toJson()).then((document) {
      return user;
    });
  }

  static Future<dynamic> loginWithEmailAndPassword(String email, String password) async {
    try {
      auth.UserCredential result = await auth.FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      DocumentSnapshot<Map<String, dynamic>> documentSnapshot = await firestore.collection(WORKERS).doc(result.user?.uid ?? '').get();
      WorkerModel? user;

      if (documentSnapshot.exists) {
        user = WorkerModel.fromJson(documentSnapshot.data() ?? {});

        user.fcmToken = await firebaseMessaging.getToken() ?? '';

        return user;
      }
    } on auth.FirebaseAuthException catch (exception, s) {
      log('$exception$s');
      switch ((exception).code) {
        case 'invalid-email':
          return 'Email address is malformed.'.tr;
        case 'wrong-password':
          return 'Wrong password.'.tr;
        case 'user-not-found':
          return 'No user corresponding to the given email address.'.tr;
        case 'user-disabled':
          return 'This user has been disabled.'.tr;
        case 'too-many-requests':
          return 'Too many attempts to sign in as this user.'.tr;
      }
      return 'Unexpected firebase error, Please try again.'.tr;
    } catch (e, s) {
      log('$e$s');
      return 'Login failed, Please try again.'.tr;
    }
  }

  getPlaceHolderImage() async {
    var collection = FirebaseFirestore.instance.collection(Setting);
    var docSnapshot = await collection.doc('placeHolderImage').get();
    Map<String, dynamic>? data = docSnapshot.data();
    var value = data?['image'];
    placeholderImage = value;
    return const Center();
  }

  static Future<String> uploadUserImageToFireStorage(File image, String userID) async {
    Reference upload = storage.child('$STORAGE_ROOT/images/$userID.png');
    UploadTask uploadTask = upload.putFile(image);
    var downloadUrl = await (await uploadTask.whenComplete(() {})).ref.getDownloadURL();
    return downloadUrl.toString();
  }

  static Future<bool?> deleteUser() async {
   // bool? isDelete;
    try {
      await firestore.collection(ChatWorker).where("customerId", isEqualTo: MyAppState.currentUser!.id).get().then((value) async {
        for (var element in value.docs) {
          firestore.collection(ChatWorker).doc(element.id).collection('thread').get().then((snapshot) {
            for (DocumentSnapshot doc in snapshot.docs) {
              doc.reference.delete();
            }
          });
          await firestore.collection(ChatWorker).doc(element.id).delete();
        }
      });
      await firestore.collection(ChatWorker).where("restaurantId", isEqualTo: MyAppState.currentUser!.id).get().then((value) async {
        for (var element in value.docs) {
          firestore.collection(ChatWorker).doc(element.id).collection('thread').get().then((snapshot) {
            for (DocumentSnapshot doc in snapshot.docs) {
              doc.reference.delete();
            }
          });
          await firestore.collection(ChatWorker).doc(element.id).delete();
        }
      });

      await firestore.collection(WORKERS).doc(auth.FirebaseAuth.instance.currentUser!.uid).delete();

      await auth.FirebaseAuth.instance.currentUser!.delete();
     // isDelete = true;


      // delete user  from firebase auth
      // await auth.FirebaseAuth.instance.currentUser!.delete().then((value) {
      //   isDelete = true;
      // });
    } catch (e, s) {
      log('FireStoreUtils.firebaseCreateNewUser $e $s');
      return false;
    }
    return null;
 //   return isDelete;
  }

  static String getCurrentUid() {
    return auth.FirebaseAuth.instance.currentUser!.uid;
  }

  static Future<User?> getProviderUser(String uid) async {
    DocumentSnapshot<Map<String, dynamic>> userDocument = await firestore.collection(USERS).doc(uid).get();
    if (userDocument.data() != null && userDocument.exists) {
      return User.fromJson(userDocument.data()!);
    } else {
      return null;
    }
  }

  static Future updateOrder(OnProviderOrderModel onProviderOrderModel) async {
    await firestore.collection(PROVIDER_ORDER).doc(onProviderOrderModel.id).set(onProviderOrderModel.toJson(), SetOptions(merge: true));
  }

  Future<List<RatingModel>> getReviewByProviderServiceId(String serviceId) async {
    List<RatingModel> providerReview = [];

    QuerySnapshot<Map<String, dynamic>> reviewQuery =
        await firestore.collection(Order_Rating).where('orderid', isEqualTo: serviceId).where('driverId', isEqualTo: MyAppState.currentUser!.id).get();
    await Future.forEach(reviewQuery.docs, (QueryDocumentSnapshot<Map<String, dynamic>> document) {
      print(document);
      try {
        providerReview.add(RatingModel.fromJson(document.data()));
      } catch (e) {
        print('FireStoreUtils.getReviewByProviderServiceId Parse error ${document.id} $e');
      }
    });
    return providerReview;
  }

  static Future addInbox(InboxModel inboxModel) async {
    return await firestore.collection(ChatWorker).doc(inboxModel.orderId).set(inboxModel.toJson()).then((document) {
      return inboxModel;
    });
  }

  static Future addChat(ConversationModel conversationModel) async {
    return await firestore.collection(ChatWorker).doc(conversationModel.orderId).collection("thread").doc(conversationModel.id).set(conversationModel.toJson()).then((document) {
      return conversationModel;
    });
  }

  Future<Url> uploadChatImageToFireStorage(File image) async {
    ShowToastDialog.showLoader('Uploading image...');
    var uniqueID = const Uuid().v4();
    Reference upload = FirebaseStorage.instance.ref().child('/chat/images/$uniqueID.png');
    UploadTask uploadTask = upload.putFile(image);
    var storageRef = (await uploadTask.whenComplete(() {})).ref;
    var downloadUrl = await storageRef.getDownloadURL();
    var metaData = await storageRef.getMetadata();
    ShowToastDialog.closeLoader();
    return Url(mime: metaData.contentType ?? 'image', url: downloadUrl.toString());
  }

  Future<ChatVideoContainer> uploadChatVideoToFireStorage(File video) async {
    ShowToastDialog.showLoader('Uploading video...');
    var uniqueID = const Uuid().v4();
    Reference upload = FirebaseStorage.instance.ref().child('/chat/videos/$uniqueID.mp4');
    SettableMetadata metadata = SettableMetadata(contentType: 'video');
    UploadTask uploadTask = upload.putFile(video, metadata);

    var storageRef = (await uploadTask.whenComplete(() {})).ref;
    var downloadUrl = await storageRef.getDownloadURL();
    var metaData = await storageRef.getMetadata();
    final uint8list = await VideoThumbnail.thumbnailFile(video: downloadUrl, thumbnailPath: (await getTemporaryDirectory()).path, imageFormat: ImageFormat.PNG);
    final file = File(uint8list ?? '');
    String thumbnailDownloadUrl = await uploadVideoThumbnailToFireStorage(file);
    ShowToastDialog.closeLoader();
    return ChatVideoContainer(videoUrl: Url(url: downloadUrl.toString(), mime: metaData.contentType ?? 'video'), thumbnailUrl: thumbnailDownloadUrl);
  }

  Future<String> uploadVideoThumbnailToFireStorage(File file) async {
    var uniqueID = const Uuid().v4();
    Reference upload = FirebaseStorage.instance.ref().child('/thumbnails/$uniqueID.png');
    UploadTask uploadTask = upload.putFile(file);
    var downloadUrl = await (await uploadTask.whenComplete(() {})).ref.getDownloadURL();
    return downloadUrl.toString();
  }

  static Future<NotificationModel?> getNotificationContent(String type) async {
    NotificationModel? notificationModel;
    await firestore.collection(dynamicNotification).where('type', isEqualTo: type).get().then((value) {
      print("------>");
      if (value.docs.isNotEmpty) {
        print(value.docs.first.data());

        notificationModel = NotificationModel.fromJson(value.docs.first.data());
      } else {
        notificationModel = NotificationModel(id: "", message: "Notification setup is pending".tr, subject: "setup notification".tr, type: "");
      }
    });
    return notificationModel;
  }

  static Future<bool> getFirestOrderOrNOt(OnProviderOrderModel orderModel) async {
    bool isFirst = true;
    await firestore.collection(PROVIDER_ORDER).where('authorID', isEqualTo: orderModel.authorID).where('section_id', isEqualTo: orderModel.sectionId).get().then((value) {
      if (value.size == 1) {
        isFirst = true;
      } else {
        isFirst = false;
      }
    });
    return isFirst;
  }

  static Future<SectionModel?> getSectionBySectionId(String uid) async {
    DocumentSnapshot<Map<String, dynamic>> userDocument = await firestore.collection(sections).doc(uid).get();
    if (userDocument.data() != null && userDocument.exists) {
      return SectionModel.fromJson(userDocument.data()!);
    } else {
      return null;
    }
  }

  static Future updateReferralAmount(OnProviderOrderModel orderModel) async {
    ReferralModel? referralModel;
    print(orderModel.authorID);
    print(orderModel.sectionId);
    await getSectionBySectionId(orderModel.sectionId.toString()).then((valueSection) async {
      await firestore.collection(REFERRAL).doc(orderModel.authorID).get().then((value) {
        if (value.data() != null) {
          referralModel = ReferralModel.fromJson(value.data()!);
        } else {
          return;
        }
      });

      print("refferealAMount----->${valueSection!.referralAmount.toString()}");
      print("refferealAMount----->${referralModel!.referralBy}");

      if (referralModel != null) {
        if (referralModel!.referralBy != null && referralModel!.referralBy!.isNotEmpty) {
          await firestore.collection(USERS).doc(referralModel!.referralBy).get().then((value) async {
            DocumentSnapshot<Map<String, dynamic>> userDocument = value;
            if (userDocument.data() != null && userDocument.exists) {
              try {
                print(userDocument.data());
                User user = User.fromJson(userDocument.data()!);
                await firestore
                    .collection(USERS)
                    .doc(user.userID)
                    .update({"wallet_amount": user.walletAmount + double.parse(valueSection.referralAmount.toString())}).then((value) => print("north"));

                await FireStoreUtils.createPaymentId().then((value) async {
                  final paymentID = value;
                  await FireStoreUtils.topUpWalletAmountRefral(
                      paymentMethod: "wallet", amount: double.parse(valueSection.referralAmount.toString()), id: paymentID, userId: referralModel!.referralBy);
                });
              } catch (error) {
                print(error);
                if (error.toString() == "Bad state: field does not exist within the DocumentSnapshotPlatform") {
                  print("does not exist");
                } else {
                  print("went wrong!!");
                }
              }
              print("data val");
            }
          });
        } else {
          return;
        }
      }
    });
  }

  static Future createPaymentId({collectionName = "wallet"}) async {
    DocumentReference documentReference = firestore.collection(collectionName).doc();
    final paymentId = documentReference.id;
    return paymentId;
  }

  static Future topUpWalletAmountRefral({String paymentMethod = "test", bool isTopup = true, required amount, required id, orderId = "", userId}) async {
    print("this is te payment id");
    print(id);
    print(userId);

    await firestore.collection(WALLET).doc(id).set({
      "user_id": userId,
      "payment_method": paymentMethod,
      "amount": amount,
      "id": id,
      "order_id": orderId,
      "isTopUp": isTopup,
      "payment_status": "success",
      "date": DateTime.now(),
      "note" :"Referral Amount",
      "transactionUser": "driver",
    }).then((value) {
      firestore.collection(WALLET).doc(id).get().then((value) {
        DocumentSnapshot<Map<String, dynamic>> documentData = value;
        print("nato");
        print(documentData.data());
      });
    });

    return "updated Amount".tr;
  }

  static Future<List<OnBoardingModel>> getOnBoardingList() async {
    List<OnBoardingModel> onBoardingModel = [];
    await firestore.collection("on_boarding").where("type", isEqualTo: "worker").get().then((value) {
      for (var element in value.docs) {
        OnBoardingModel documentModel = OnBoardingModel.fromJson(element.data());
        onBoardingModel.add(documentModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return onBoardingModel;
  }


}
