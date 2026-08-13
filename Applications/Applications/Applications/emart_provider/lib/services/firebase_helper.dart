import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:sharehandsprovider/constant/constants.dart';
import 'package:sharehandsprovider/constant/show_toast_dialog.dart';
import 'package:sharehandsprovider/main.dart';
import 'package:sharehandsprovider/model/chat_video_container.dart';
import 'package:sharehandsprovider/model/conversation_model.dart';
import 'package:sharehandsprovider/model/coupon_model.dart';
import 'package:sharehandsprovider/model/email_template_model.dart';
import 'package:sharehandsprovider/model/inbox_model.dart';
import 'package:sharehandsprovider/model/notification_model.dart';
import 'package:sharehandsprovider/model/on_boarding_model.dart';
import 'package:sharehandsprovider/model/onprovider_order_model.dart';
import 'package:sharehandsprovider/model/provider_service_model.dart';
import 'package:sharehandsprovider/model/rating_model.dart';
import 'package:sharehandsprovider/model/referral_model.dart';
import 'package:sharehandsprovider/model/sectionModel.dart';
import 'package:sharehandsprovider/model/topupTranHistory.dart';
import 'package:sharehandsprovider/model/withdrawHistoryModel.dart';
import 'package:sharehandsprovider/model/withdraw_method_model.dart';
import 'package:sharehandsprovider/model/worker_model.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:sharehandsprovider/model/category_model.dart';
import 'package:sharehandsprovider/model/currency_model.dart';
import 'package:sharehandsprovider/model/user.dart';
import 'package:flutter/material.dart';
import 'package:the_apple_sign_in/the_apple_sign_in.dart' as apple;
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:http/http.dart' as http;
import 'package:video_thumbnail/video_thumbnail.dart';

class FireStoreUtils {
  static Reference storage = FirebaseStorage.instance.ref();
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  static FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  static firebaseSignUpWithEmailAndPassword(
      String emailAddress, String password, File? image, String firstName, String lastName, String mobile, bool? auto_approve_restaurant) async {
    try {
      auth.UserCredential result = await auth.FirebaseAuth.instance.createUserWithEmailAndPassword(email: emailAddress, password: password);
      String profilePicUrl = '';
      if (image != null) {
        ShowToastDialog.showLoader('Uploading image, Please wait...'.tr);
        profilePicUrl = await uploadUserImageToFireStorage(image, result.user?.uid ?? '');
      }
      User user = User(
          email: emailAddress,
          photos: [],
          lastOnlineTimestamp: Timestamp.now(),
          active: auto_approve_restaurant == true ? true : false,
          phoneNumber: mobile,
          firstName: firstName,
          userID: result.user?.uid ?? '',
          lastName: lastName,
          role: USER_ROLE_PROVIDER,
          fcmToken: await firebaseMessaging.getToken() ?? '',
          createdAt: Timestamp.now(),
          profilePictureURL: profilePicUrl);
      String? errorMessage = await firebaseCreateNewUser(user);
      if (errorMessage == null) {
        return user;
      } else {
        return "Couldn't sign up for firebase, Please try again.".tr;
      }
    } on auth.FirebaseAuthException catch (error) {
      log('$error${error.stackTrace}');
      String message = "Couldn't sign up".tr;
      switch (error.code) {
        case 'email-already-in-use':
          message = 'Email already in use, Please pick another email!'.tr;
          break;
        case 'invalid-email':
          message = 'Enter valid e-mail'.tr;
          break;
        case 'operation-not-allowed':
          message = 'Email/password accounts are not enabled'.tr;
          break;
        case 'weak-password':
          message = 'Password must be more than 5 characters'.tr;
          break;
        case 'too-many-requests':
          message = 'Too many requests, Please try again later.'.tr;
          break;
      }
      return message;
    } catch (e) {
      return "Couldn't sign up".tr;
    }
  }

  static Future<String> uploadUserImageToFireStorage(File image, String userID) async {
    Reference upload = storage.child('$STORAGE_ROOT/images/$userID.png');
    UploadTask uploadTask = upload.putFile(image);
    var downloadUrl = await (await uploadTask.whenComplete(() {})).ref.getDownloadURL();
    return downloadUrl.toString();
  }

  static Future<String?> firebaseCreateNewUser(User user) async => await firestore.collection(USERS).doc(user.userID).set(user.toJson()).then((value) => null, onError: (e) => e);

  static Future<dynamic> loginWithEmailAndPassword(String email, String password) async {
    try {
      auth.UserCredential result = await auth.FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      DocumentSnapshot<Map<String, dynamic>> documentSnapshot = await firestore
          .collection(USERS)
          .doc(result.user?.uid ?? '')
          .
          // where('role',isEqualTo: 'vendor').
          get();
      User? user;

      if (documentSnapshot.exists) {
        user = User.fromJson(documentSnapshot.data() ?? {});
        if (user.role == 'provider') {
          user.fcmToken = await firebaseMessaging.getToken() ?? '';

          return user;
        }
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

  static Future<User?> updateCurrentUser(User user) async {
    return await firestore.collection(USERS).doc(user.userID).set(user.toJson()).then((document) {
      return user;
    });
  }

  static loginWithFacebook() async {
    /// creates a user for this facebook login when this user first time login
    /// and save the new user object to firebase and firebase auth
    ///

    FacebookAuth facebookAuth = FacebookAuth.instance;
    bool isLogged = await facebookAuth.accessToken != null;
    if (!isLogged) {
      LoginResult result = await facebookAuth.login(
        permissions: ['public_profile', 'email'],
      );
      // by default we request the email and the public profile
      FacebookPermissions? permissions = await FacebookAuth.instance.permissions;
// or FacebookAuth.i.permissions

      if (result.status == LoginStatus.success) {
        // you are logged
        AccessToken? token = result.accessToken;
        return await handleFacebookLogin(await facebookAuth.getUserData(), token!);
      }
    } else {
      AccessToken? token = await facebookAuth.accessToken;

      return await handleFacebookLogin(await facebookAuth.getUserData(), token!);
    }
  }

  static handleFacebookLogin(Map<String, dynamic> userData, AccessToken token) async {
    // print(token);
    auth.UserCredential authResult = await auth.FirebaseAuth.instance.signInWithCredential(auth.FacebookAuthProvider.credential(token.token));
    User? user = await getCurrentUser(authResult.user?.uid ?? '');
    List<String> fullName = (userData['name'] as String).split(' ');
    String firstName = '';
    String lastName = '';
    if (fullName.isNotEmpty) {
      firstName = fullName.first;
      lastName = fullName.skip(1).join(' ');
    }
    if (user != null && user.role == USER_ROLE_PROVIDER) {
      if (userData['email'] == null) {
        return 'Email not added in Facebook'.tr;
      }

      user.profilePictureURL = userData['picture']['data']['url'];
      user.firstName = firstName;
      user.lastName = lastName;
      user.email = userData['email'];
      user.role = USER_ROLE_PROVIDER;
      user.fcmToken = await firebaseMessaging.getToken() ?? '';
      dynamic result = await updateCurrentUser(user);
      return result;
    } else if (user == null) {
      user = User(
        email: userData['email'] ?? '',
        firstName: firstName,
        profilePictureURL: userData['picture']['data']['url'] ?? '',
        userID: authResult.user?.uid ?? '',
        lastOnlineTimestamp: Timestamp.now(),
        lastName: lastName,
        active: true,
        role: USER_ROLE_PROVIDER,
        fcmToken: await firebaseMessaging.getToken() ?? '',
        phoneNumber: '',
      );
      String? errorMessage = await firebaseCreateNewUser(user);
      if (errorMessage == null) {
        return user;
      } else {
        return errorMessage;
      }
    }
  }

  static Future<User?> getCurrentUser(String uid) async {
    DocumentSnapshot<Map<String, dynamic>> userDocument = await firestore.collection(USERS).doc(uid).get();
    if (userDocument.data() != null && userDocument.exists) {
      return User.fromJson(userDocument.data()!);
    } else {
      return null;
    }
  }

  static loginWithApple() async {
    final appleCredential = await apple.TheAppleSignIn.performRequests([
      const apple.AppleIdRequest(requestedScopes: [apple.Scope.email, apple.Scope.fullName])
    ]);

    if (appleCredential.error != null) {
      return "Couldn't login with apple.".tr;
    }
    if (appleCredential.status == apple.AuthorizationStatus.authorized) {
      final auth.AuthCredential credential = auth.OAuthProvider('apple.com').credential(
        accessToken: String.fromCharCodes(appleCredential.credential?.authorizationCode ?? []),
        idToken: String.fromCharCodes(appleCredential.credential?.identityToken ?? []),
      );
      return await handleAppleLogin(credential, appleCredential.credential!);
    } else {
      return "Couldn't login with apple.".tr;
    }
  }

  static handleAppleLogin(
    auth.AuthCredential credential,
    apple.AppleIdCredential appleIdCredential,
  ) async {
    auth.UserCredential authResult = await auth.FirebaseAuth.instance.signInWithCredential(credential);
    User? user = await getCurrentUser(authResult.user?.uid ?? '');
    if (user != null) {
      user.role = USER_ROLE_PROVIDER;
      user.fcmToken = await firebaseMessaging.getToken() ?? '';
      dynamic result = await updateCurrentUser(user);
      return result;
    } else {
      user = User(
        email: appleIdCredential.email ?? '',
        firstName: appleIdCredential.fullName?.givenName ?? '',
        profilePictureURL: '',
        userID: authResult.user?.uid ?? '',
        lastOnlineTimestamp: Timestamp.now(),
        lastName: appleIdCredential.fullName?.familyName ?? '',
        role: USER_ROLE_PROVIDER,
        active: true,
        fcmToken: await firebaseMessaging.getToken() ?? '',
        phoneNumber: '',
      );
      String? errorMessage = await firebaseCreateNewUser(user);
      if (errorMessage == null) {
        return user;
      } else {
        return errorMessage;
      }
    }
  }

  static Future<dynamic> firebaseSubmitPhoneNumberCode(String verificationID, String code, String phoneNumber,
      {String firstName = 'Anonymous', String lastName = 'User', File? image, bool? auto_approve_provider}) async {
    auth.AuthCredential authCredential = auth.PhoneAuthProvider.credential(verificationId: verificationID, smsCode: code);
    auth.UserCredential userCredential = await auth.FirebaseAuth.instance.signInWithCredential(authCredential);
    User? user = await getCurrentUser(userCredential.user?.uid ?? '');
    if (user != null && user.role == USER_ROLE_PROVIDER) {
      return user;
    } else if (user == null) {
      /// create a new user from phone login
      String profileImageUrl = '';
      if (image != null) {
        profileImageUrl = await uploadUserImageToFireStorage(image, userCredential.user?.uid ?? '');
      }
      User user = User(
          firstName: firstName,
          lastName: lastName,
          fcmToken: await firebaseMessaging.getToken() ?? '',
          phoneNumber: phoneNumber,
          profilePictureURL: profileImageUrl,
          userID: userCredential.user?.uid ?? '',
          active: auto_approve_provider == true ? true : false,
          lastOnlineTimestamp: Timestamp.now(),
          photos: [],
          role: USER_ROLE_PROVIDER,
          email: '',
          createdAt: Timestamp.now());
      String? errorMessage = await firebaseCreateNewUser(user);
      if (errorMessage == null) {
        return user;
      } else {
        return "Couldn't create new user with phone number.".tr;
      }
    }
  }

  ///submit a phone number to firebase to receive a code verification, will
  ///be used later to login
  static firebaseSubmitPhoneNumber(
    String phoneNumber,
    auth.PhoneCodeAutoRetrievalTimeout? phoneCodeAutoRetrievalTimeout,
    auth.PhoneCodeSent? phoneCodeSent,
    auth.PhoneVerificationFailed? phoneVerificationFailed,
    auth.PhoneVerificationCompleted? phoneVerificationCompleted,
  ) {
    auth.FirebaseAuth.instance.verifyPhoneNumber(
      timeout: const Duration(minutes: 2),
      phoneNumber: phoneNumber,
      verificationCompleted: phoneVerificationCompleted!,
      verificationFailed: phoneVerificationFailed!,
      codeSent: phoneCodeSent!,
      codeAutoRetrievalTimeout: phoneCodeAutoRetrievalTimeout!,
    );
  }

  Future<CurrencyModel?> getCurrency() async {
    CurrencyModel? currency;
    await firestore.collection(Currency).where("isActive", isEqualTo: true).get().then((value) {
      if (value.docs.isNotEmpty) {
        currency = CurrencyModel.fromJson(value.docs.first.data());
      }
    });
    return currency;
  }

  static Future<ProviderServiceModel> firebaseAddOrUpdateProvider(ProviderServiceModel productModel) async {
    if ((productModel.id!).isNotEmpty) {
      await firestore.collection(PROVIDERS_SERVICES).doc(productModel.id).set(productModel.toJson());
    } else {
      DocumentReference docRef = firestore.collection(PROVIDERS_SERVICES).doc();
      productModel.id = docRef.id;
      docRef.set(productModel.toJson());
    }
    return productModel;
  }

  static Future<ProviderServiceModel?> updateProvider(ProviderServiceModel vendor) async {
    return await firestore.collection(PROVIDERS_SERVICES).doc(vendor.id).set(vendor.toJson()).then((document) {
      return vendor;
    });
  }

  static Future<List<CategoryModel>> getCategory(String sectionId) async {
    List<CategoryModel> category = [];
    QuerySnapshot<Map<String, dynamic>> productsQuery =
        await firestore.collection(CATEGORIES).where("sectionId", isEqualTo: sectionId).where("level", isEqualTo: 0).where("publish", isEqualTo: true).get();
    await Future.forEach(productsQuery.docs, (QueryDocumentSnapshot<Map<String, dynamic>> document) {
      try {
        category.add(CategoryModel.fromJson(document.data()));
      } catch (e) {
        log('**-FireStoreUtils.getCategory Parse error $e');
      }
    });

    return category;
  }

  Future<CategoryModel?> getCategoryById(String categoryId) async {
    CategoryModel? categoryModel;
    await firestore.collection(CATEGORIES).doc(categoryId).get().then((value) {
      if (value.exists) {
        categoryModel = CategoryModel.fromJson(value.data()!);
      }
    });
    return categoryModel;
  }

  static Future<List<CategoryModel>> getSubCategory(String categoryId) async {
    List<CategoryModel> category = [];

    QuerySnapshot<Map<String, dynamic>> categoryQuery =
        await firestore.collection(CATEGORIES).where("level", isEqualTo: 1).where('parentCategoryId', isEqualTo: categoryId).where("publish", isEqualTo: true).get();
    await Future.forEach(categoryQuery.docs, (QueryDocumentSnapshot<Map<String, dynamic>> document) {
      try {
        category.add(CategoryModel.fromJson(document.data()));
      } catch (e, stacksTrace) {
        log('FireStoreUtils.getProviderSubCategoryById Parse error ${document.id} $e '
            '$stacksTrace');
      }
    });
    return category;
  }

  static Future<List<ProviderServiceModel>> getProviderServices() async {
    List<ProviderServiceModel> products = [];

    QuerySnapshot<Map<String, dynamic>> productsQuery = await firestore.collection(PROVIDERS_SERVICES).where('author', isEqualTo: MyAppState.currentUser!.userID).get();
    await Future.forEach(productsQuery.docs, (QueryDocumentSnapshot<Map<String, dynamic>> document) {
      try {
        products.add(ProviderServiceModel.fromJson(document.data()));
      } catch (e) {
        log('FireStoreUtils.getVendorProducts Parse error $e');
      }
    });
    return products;
  }

  static Future<String> uploadServiceImage(File image, String progress) async {
    var uniqueID = const Uuid().v4();
    Reference upload = storage.child('$STORAGE_ROOT/provider/serviceImages/$uniqueID.png');
    UploadTask uploadTask = upload.putFile(image);
    uploadTask.snapshotEvents.listen((event) {
      ShowToastDialog.showLoader('Image Uploading..');
    });
    uploadTask.whenComplete(() {}).catchError((onError) {
      log((onError as PlatformException).message.toString());
    });
    var storageRef = (await uploadTask.whenComplete(() {})).ref;
    var downloadUrl = await storageRef.getDownloadURL();
    return downloadUrl.toString();
  }

  static Future<ProviderServiceModel?>? getProvider(id) async {
    ProviderServiceModel? providerModel;
    QuerySnapshot<Map<String, dynamic>> productsQuery =
        await firestore.collection(PROVIDERS_SERVICES).where('author', isEqualTo: MyAppState.currentUser!.userID).where('id', isEqualTo: id).get();
    await Future.forEach(productsQuery.docs, (QueryDocumentSnapshot<Map<String, dynamic>> document) {
      try {
        providerModel = ProviderServiceModel.fromJson(document.data());
      } catch (e) {
        log('FireStoreUtils.getProviderrProducts Parse error $e');
      }
    });
    return providerModel;
  }

  static deleteProduct(String providerId) async {
    await firestore.collection(PROVIDERS_SERVICES).doc(providerId).delete();
  }

  static Future<bool?> deleteUser() async {
    try {
      await firestore.collection(PROVIDERS_SERVICES).where("author", isEqualTo: MyAppState.currentUser!.userID).get().then((value) async {
        for (var element in value.docs) {
          firestore.collection(FAVORITE_SERVICES).where('service_id', isEqualTo: element.id).get().then((value0) {
            for (var element0 in value0.docs) {
              firestore.collection(FAVORITE_SERVICES).doc(element0.reference.path).delete();
            }
          });

          await firestore.collection(PROVIDERS_SERVICES).doc(element.id).delete();
        }

        await firestore.collection(FAVORITE_PROVIDER).where('provider_id', isEqualTo: MyAppState.currentUser!.userID).get().then((value0) async {
          for (var element0 in value0.docs) {
            await firestore.collection(FAVORITE_PROVIDER).doc(element0.reference.path).delete();
          }
        });
      });

      await firestore.collection(COUPONS).where("providerId", isEqualTo: MyAppState.currentUser!.userID).get().then((value) async {
        for (var element in value.docs) {
          await firestore.collection(COUPONS).doc(element.id).delete();
        }
      });
      await firestore.collection(WORKERS).where("providerId", isEqualTo: MyAppState.currentUser!.userID).get().then((value) async {
        for (var element in value.docs) {
          await firestore.collection(WORKERS).doc(element.id).delete();
        }
      });

      await firestore.collection(ChatProvider).where("customerId", isEqualTo: MyAppState.currentUser!.userID).get().then((value) async {
        for (var element in value.docs) {
          firestore.collection(ChatProvider).doc(element.id).collection('thread').get().then((snapshot) {
            for (DocumentSnapshot doc in snapshot.docs) {
              doc.reference.delete();
            }
          });
          await firestore.collection(ChatProvider).doc(element.id).delete();
        }
      });
      await firestore.collection(ChatProvider).where("restaurantId", isEqualTo: MyAppState.currentUser!.userID).get().then((value) async {
        for (var element in value.docs) {
          firestore.collection(ChatProvider).doc(element.id).collection('thread').get().then((snapshot) {
            for (DocumentSnapshot doc in snapshot.docs) {
              doc.reference.delete();
            }
          });
          await firestore.collection(ChatProvider).doc(element.id).delete();
        }
      });

      await firestore.collection(USERS).doc(auth.FirebaseAuth.instance.currentUser!.uid).delete();

      await auth.FirebaseAuth.instance.currentUser!.delete();
    } catch (e, s) {
      print('FireStoreUtils.deleteUser $e $s');
    }
    return null;
    // return isDelete;
  }

  static String getCurrentUid() {
    return auth.FirebaseAuth.instance.currentUser!.uid;
  }

  static Future updateOrder(OnProviderOrderModel onProviderOrderModel) async {
    await firestore.collection(PROVIDER_ORDER).doc(onProviderOrderModel.id).set(onProviderOrderModel.toJson(), SetOptions(merge: true));
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

  Future<List<RatingModel>> getReviewByProviderServiceId(String serviceId) async {
    List<RatingModel> providerReview = [];

    QuerySnapshot<Map<String, dynamic>> reviewQuery =
        await firestore.collection(Order_Rating).where('orderid', isEqualTo: serviceId).where('VendorId', isEqualTo: MyAppState.currentUser!.userID).get();
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

  static Future addProviderInbox(InboxModel inboxModel) async {
    return await firestore.collection(ChatProvider).doc(inboxModel.orderId).set(inboxModel.toJson()).then((document) {
      return inboxModel;
    });
  }

  static Future addProviderChat(ConversationModel conversationModel) async {
    return await firestore.collection(ChatProvider).doc(conversationModel.orderId).collection("thread").doc(conversationModel.id).set(conversationModel.toJson()).then((document) {
      return conversationModel;
    });
  }

  static Future addWorkerInbox(InboxModel inboxModel) async {
    return await firestore.collection(ChatWorker).doc(inboxModel.orderId).set(inboxModel.toJson()).then((document) {
      return inboxModel;
    });
  }

  static Future addDriverChat(ConversationModel conversationModel) async {
    return await firestore.collection("chat_driver").doc(conversationModel.orderId).collection("thread").doc(conversationModel.id).set(conversationModel.toJson()).then((document) {
      return conversationModel;
    });
  }

  static Future addWorkerChat(ConversationModel conversationModel) async {
    return await firestore.collection(ChatWorker).doc(conversationModel.orderId).collection("thread").doc(conversationModel.id).set(conversationModel.toJson()).then((document) {
      return conversationModel;
    });
  }

  static Future addRestaurantChat(ConversationModel conversationModel) async {
    return await firestore.collection("chat_store").doc(conversationModel.orderId).collection("thread").doc(conversationModel.id).set(conversationModel.toJson()).then((document) {
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

  static Future withdrawWalletAmount({required WithdrawHistoryModel withdrawHistory}) async {
    print("this is te payment id");
    print(withdrawHistory.id);
    print(MyAppState.currentUser!.userID);

    await firestore.collection(PAYOUTS).doc(withdrawHistory.id).set(withdrawHistory.toJson()).then((value) {
      firestore.collection(PAYOUTS).doc(withdrawHistory.id).get().then((value) {
        DocumentSnapshot<Map<String, dynamic>> documentData = value;
        print(documentData.data());
      });
    });
    return "updated Amount".tr;
  }

  static Future updateWalletAmount({required String userId, required amount}) async {
    dynamic walletAmount = 0;

    await firestore.collection(USERS).doc(userId).get().then((value) async {
      DocumentSnapshot<Map<String, dynamic>> userDocument = value;
      if (userDocument.data() != null && userDocument.exists) {
        try {
          print(userDocument.data());
          await firestore.collection(USERS).doc(userId).update({"wallet_amount": (num.parse(userDocument.data()!['wallet_amount'].toString()) + amount)}).then((value) {
            if (userId == MyAppState.currentUser?.userID) {
              MyAppState.currentUser!.walletAmount = num.parse(userDocument.data()!['wallet_amount'].toString()) + amount;
            }
          });
        } catch (error) {
          print(error);
          if (error.toString() == "Bad state: field does not exist within the DocumentSnapshotPlatform") {
            print("does not exist");
          } else {
            print("went wrong!!");
            walletAmount = "ERROR";
          }
        }
        print("data val");
        print(walletAmount);
        return walletAmount; //User.fromJson(userDocument.data()!);
      } else {
        return 0.111;
      }
    });
  }

  static Future createPaymentId({collectionName = "wallet"}) async {
    DocumentReference documentReference = firestore.collection(collectionName).doc();
    final paymentId = documentReference.id;
    return paymentId;
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
            id: Uuid().v4(),
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
          id: Uuid().v4(),
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

  static Future<List<WithdrawHistoryModel>> getWithdrawTransaction(String userId) async {
    List<WithdrawHistoryModel> history = [];

    QuerySnapshot<Map<String, dynamic>> categoryQuery = await firestore.collection(PAYOUTS).where('vendorID', isEqualTo: userId).orderBy('paidDate', descending: true).get();
    await Future.forEach(categoryQuery.docs, (QueryDocumentSnapshot<Map<String, dynamic>> document) {
      try {
        history.add(WithdrawHistoryModel.fromJson(document.data()));
      } catch (e, stacksTrace) {
        log('FireStoreUtils.getWithdrawTransaction Parse error ${document.id} $e '
            '$stacksTrace');
      }
    });
    return history;
  }

  static Future<List<TopupTranHistoryModel>> getTopUpTransaction(String userId) async {
    List<TopupTranHistoryModel> history = [];

    QuerySnapshot<Map<String, dynamic>> categoryQuery = await firestore.collection(WALLET).where('user_id', isEqualTo: userId).orderBy('date', descending: true).get();
    await Future.forEach(categoryQuery.docs, (QueryDocumentSnapshot<Map<String, dynamic>> document) {
      try {
        history.add(TopupTranHistoryModel.fromJson(document.data()));
      } catch (e, stacksTrace) {
        log('FireStoreUtils.getTopUpTransaction Parse error ${document.id} $e '
            '$stacksTrace');
      }
    });
    return history;
  }

  static Future topUpWalletAmount({required String userId, required amount, orderId = ""}) async {
    print("this is te payment id");
    print(MyAppState.currentUser!.userID);

    TopupTranHistoryModel adminCommission = TopupTranHistoryModel(
        amount: amount,
        id: Uuid().v4(),
        orderId: orderId,
        userId: userId,
        date: Timestamp.now(),
        isTopup: true,
        paymentMethod: "Wallet",
        paymentStatus: "success",
        transactionUser: "customer",
        note: 'Booking amount Refund',
        serviceType: 'ondemand-service');

    await firestore.collection("wallet").doc(adminCommission.id).set(adminCommission.toJson()).then((value) {
      firestore.collection("wallet").doc(adminCommission.id).get().then((value) {
        DocumentSnapshot<Map<String, dynamic>> documentData = value;
        print("nato");
        print(documentData.data());
      });
    });
    return "updated Amount".tr;
  }

  static Future<String?> firebaseCreateNewWorker(WorkerModel user) async =>
      await firestore.collection(WORKERS).doc(user.id).set(user.toJson()).then((value) => null, onError: (e) => e);

  static Future<List<WorkerModel>> getAllWorkers() async {
    List<WorkerModel> products = [];
    QuerySnapshot<Map<String, dynamic>> productsQuery = await firestore.collection(WORKERS).where('providerId', isEqualTo: MyAppState.currentUser!.userID).get();
    await Future.forEach(productsQuery.docs, (QueryDocumentSnapshot<Map<String, dynamic>> document) {
      try {
        products.add(WorkerModel.fromJson(document.data()));
      } catch (e) {
        log('FireStoreUtils.getVendorProducts Parse error $e');
      }
    });
    return products;
  }

  static Future<List<WorkerModel>> getAllOnlineWorkers() async {
    List<WorkerModel> products = [];
    QuerySnapshot<Map<String, dynamic>> productsQuery =
        await firestore.collection(WORKERS).where('providerId', isEqualTo: MyAppState.currentUser!.userID).where('online', isEqualTo: true).get();
    await Future.forEach(productsQuery.docs, (QueryDocumentSnapshot<Map<String, dynamic>> document) {
      try {
        products.add(WorkerModel.fromJson(document.data()));
      } catch (e) {
        log('FireStoreUtils.getVendorProducts Parse error $e');
      }
    });
    return products;
  }

  static Future<WorkerModel> firebaseUpdateWorker(WorkerModel workerModel) async {
    await firestore.collection(WORKERS).doc(workerModel.id).set(workerModel.toJson());

    return workerModel;
  }

  static deleteWorker(String workerId) async {
    await firestore.collection(WORKERS).doc(workerId).delete();
    HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('deleteUser');
    final resp = await callable.call(<String, dynamic>{
      'uid': workerId,
    });
  }

  getPlaceHolderImage() async {
    var collection = FirebaseFirestore.instance.collection(Setting);
    var docSnapshot = await collection.doc('placeHolderImage').get();
    Map<String, dynamic>? data = docSnapshot.data();
    var value = data?['image'];
    placeholderImage = value;
    return const Center();
  }

  static Future<WorkerModel?>? getWorker(id) async {
    WorkerModel? providerModel;
    QuerySnapshot<Map<String, dynamic>> productsQuery = await firestore.collection(WORKERS).where('id', isEqualTo: id).get();
    await Future.forEach(productsQuery.docs, (QueryDocumentSnapshot<Map<String, dynamic>> document) {
      try {
        providerModel = WorkerModel.fromJson(document.data());
      } catch (e) {
        log('FireStoreUtils.getProviderrProducts Parse error $e');
      }
    });
    return providerModel;
  }

  addOffer(CouponModel couponModel, BuildContext context) async {
    DocumentReference docRef = firestore.collection(COUPONS).doc();
    couponModel.id = docRef.id;
    docRef.set(couponModel.toJson()).then((value) {});
  }

  static Future<CouponModel> firebaseAddOrUpdateCoupon(CouponModel couponModel) async {
    if (couponModel.id != null) {
      await firestore.collection(COUPONS).doc(couponModel.id).set(couponModel.toJson());
    } else {
      DocumentReference docRef = firestore.collection(COUPONS).doc();
      couponModel.id = docRef.id;
      docRef.set(couponModel.toJson());
    }
    return couponModel;
  }

  static Future<List<CouponModel>> getCoupons() async {
    List<CouponModel> products = [];

    QuerySnapshot<Map<String, dynamic>> productsQuery = await firestore.collection(COUPONS).where('providerId', isEqualTo: MyAppState.currentUser!.userID).get();
    await Future.forEach(productsQuery.docs, (QueryDocumentSnapshot<Map<String, dynamic>> document) {
      try {
        products.add(CouponModel.fromJson(document.data()));
      } catch (e) {
        log('FireStoreUtils.getVendorProducts Parse error $e');
      }
    });
    return products;
  }

  Future<OnProviderOrderModel?> getProviderOrderById(String? orderId) async {
    DocumentSnapshot<Map<String, dynamic>> userDocument = await firestore.collection(PROVIDER_ORDER).doc(orderId).get();
    if (userDocument.data() != null && userDocument.exists) {
      return OnProviderOrderModel.fromJson(userDocument.data()!);
    } else {
      return null;
    }
  }

  static sendPayoutMail({required String amount, required String payoutrequestid}) async {
    EmailTemplateModel? emailTemplateModel = await FireStoreUtils.getEmailTemplates(payoutRequest);

    String body = emailTemplateModel!.subject.toString();
    body = body.replaceAll("{userid}", MyAppState.currentUser!.userID);

    String newString = emailTemplateModel.message.toString();
    newString = newString.replaceAll("{username}", MyAppState.currentUser!.firstName + " " + MyAppState.currentUser!.lastName);
    newString = newString.replaceAll("{userid}", MyAppState.currentUser!.userID);
    newString = newString.replaceAll("{amount}", amountShow(amount: amount));
    newString = newString.replaceAll("{date}", DateFormat('dd-MM-yyyy').format(Timestamp.now().toDate()));
    newString = newString.replaceAll("{payoutrequestid}", payoutrequestid.toString());
    newString = newString.replaceAll("{usercontactinfo}", "${MyAppState.currentUser!.email}\n${MyAppState.currentUser!.phoneNumber}");
    await sendMail(subject: body, isAdmin: emailTemplateModel.isSendToAdmin, body: newString, recipients: [MyAppState.currentUser!.email]);
  }

  static Future<EmailTemplateModel?> getEmailTemplates(String type) async {
    EmailTemplateModel? emailTemplateModel;
    await firestore.collection(emailTemplates).where('type', isEqualTo: type).get().then((value) {
      print("------>");
      if (value.docs.isNotEmpty) {
        print(value.docs.first.data());
        emailTemplateModel = EmailTemplateModel.fromJson(value.docs.first.data());
      }
    });
    return emailTemplateModel;
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
                      paymentMethod: "Referral Amount", amount: double.parse(valueSection.referralAmount.toString()), id: paymentID, userId: referralModel!.referralBy);
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
    await firestore.collection("on_boarding").where("type", isEqualTo: "provider").get().then((value) {
      for (var element in value.docs) {
        OnBoardingModel documentModel = OnBoardingModel.fromJson(element.data());
        onBoardingModel.add(documentModel);
      }
    }).catchError((error) {
      log(error.toString());
    });
    return onBoardingModel;
  }

  static Future<WithdrawMethodModel?> getWithdrawMethod() async {
    WithdrawMethodModel? withdrawMethodModel;
    await firestore.collection('withdraw_method').where("userId", isEqualTo: MyAppState.currentUser!.userID).get().then((value) async {
      if (value.docs.isNotEmpty) {
        withdrawMethodModel = WithdrawMethodModel.fromJson(value.docs.first.data());
      }
    });
    return withdrawMethodModel;
  }

  static Future<WithdrawMethodModel?> setWithdrawMethod(WithdrawMethodModel withdrawMethodModel) async {
    if (withdrawMethodModel.id == null) {
      withdrawMethodModel.id = Uuid().v4();
      withdrawMethodModel.userId = MyAppState.currentUser!.userID;
    }
    await firestore.collection('withdraw_method').doc(withdrawMethodModel.id).set(withdrawMethodModel.toJson()).then((value) async {});
    return withdrawMethodModel;
  }
}
