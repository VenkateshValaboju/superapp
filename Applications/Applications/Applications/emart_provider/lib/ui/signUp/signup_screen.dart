import 'dart:io';
import 'package:sharehandsprovider/constant/constants.dart';
import 'package:sharehandsprovider/controller/signup_controller.dart';
import 'package:sharehandsprovider/themes/app_colors.dart';
import 'package:sharehandsprovider/ui/phoneAuth/phone_number_input_screen.dart';
import 'package:sharehandsprovider/utils/dark_theme_provider.dart';
import 'package:sharehandsprovider/widgets/common_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:provider/provider.dart';

class SignUpScreen extends StatelessWidget {
  SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<SignUpController>(
        init: SignUpController(),
        builder: (controller) {
          if (Platform.isAndroid) {
            retrieveLostData(controller);
          }
          return Scaffold(
            appBar: CommonUI.customAppBar(context, isBack: true, backgroundColor: themeChange.getTheme() ? AppColors.assetColorGrey1000 : AppColors.assetColorLightGrey400),
            body: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.only(left: 16.0, right: 16, bottom: 16),
                child: Form(
                  key: controller.key.value,
                  autovalidateMode: controller.validate,
                  child: formUI(context, controller, themeChange),
                ),
              ),
            ),
          );
        });
  }

  final ImagePicker imagePicker = ImagePicker();

  Future<void> retrieveLostData(SignUpController controller) async {
    final LostDataResponse? response = await imagePicker.retrieveLostData();
    if (response == null) {
      return;
    }
    if (response.file != null) {
      controller.image = File(response.file!.path);
      controller.update();
    }
  }

  _onCameraClick(BuildContext context, SignUpController controller) {
    final action = CupertinoActionSheet(
      message: Text(
        'Add profile picture'.tr,
        style: TextStyle(fontSize: 15.0),
      ),
      actions: <Widget>[
        CupertinoActionSheetAction(
          isDefaultAction: false,
          onPressed: () async {
            Get.back();
            XFile? image = await imagePicker.pickImage(source: ImageSource.gallery);
            if (image != null) {
              controller.image = File(image.path);
              controller.update();
            }
          },
          child: Text('Choose from gallery'.tr),
        ),
        CupertinoActionSheetAction(
          isDestructiveAction: false,
          onPressed: () async {
            Get.back();
            XFile? image = await imagePicker.pickImage(source: ImageSource.camera);
            if (image != null) {
              controller.image = File(image.path);
              controller.update();
            }
          },
          child: Text('Take a picture'.tr),
        ),
        CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () async {
            Get.back();

            controller.image = null;
            controller.update();
          },
          child: Text('Remove picture'.tr),
        )
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text('Cancel'.tr),
        onPressed: () {
          Get.back();
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (context) => action);
  }

  Widget formUI(BuildContext context, SignUpController controller, themeChange) {
    return Column(
      children: <Widget>[
        Align(
            alignment: Directionality.of(context) == TextDirection.ltr ? Alignment.topLeft : Alignment.topRight,
            child: Text(
              'Create new account'.tr,
              style: TextStyle(color: AppColors.colorPrimary, fontWeight: FontWeight.bold, fontSize: 25.0),
            )),
        Padding(
          padding: const EdgeInsets.only(left: 8.0, top: 10, right: 8, bottom: 8),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: <Widget>[
              CircleAvatar(
                radius: 65,
                backgroundColor: Colors.grey.shade400,
                child: ClipOval(
                  child: SizedBox(
                    width: 170,
                    height: 170,
                    child: controller.image == null
                        ? Image.asset(
                            'assets/images/placeholder.png',
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            controller.image!,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
              ),
              Positioned(
                left: 80,
                right: 0,
                child: FloatingActionButton(
                  heroTag: 'userImage',
                  backgroundColor: AppColors.colorPrimary,
                  mini: true,
                  onPressed: () => _onCameraClick(context, controller),
                  child: Icon(
                    CupertinoIcons.camera,
                    color: themeChange.getTheme() ? Colors.black : Colors.white,
                  ),
                ),
              )
            ],
          ),
        ),
        SizedBox(
          height: 10,
        ),
        TextFormField(
          cursorColor: AppColors.colorPrimary,
          textAlignVertical: TextAlignVertical.center,
          validator: validateName,
          onSaved: (String? val) {
            controller.firstName.value = val.toString();
          },
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            fillColor: Colors.white,
            hintText: 'First Name'.tr,
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0), borderSide: BorderSide(color: AppColors.colorPrimary, width: 2.0)),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
              borderRadius: BorderRadius.circular(25.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
              borderRadius: BorderRadius.circular(25.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(25.0),
            ),
          ),
        ),
        SizedBox(
          height: 10,
        ),
        TextFormField(
          validator: validateName,
          textAlignVertical: TextAlignVertical.center,
          cursorColor: AppColors.colorPrimary,
          onSaved: (String? val) {
            controller.lastName.value = val.toString();
          },
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            fillColor: Colors.white,
            hintText: 'Last Name'.tr,
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0), borderSide: BorderSide(color: AppColors.colorPrimary, width: 2.0)),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
              borderRadius: BorderRadius.circular(25.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
              borderRadius: BorderRadius.circular(25.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(25.0),
            ),
          ),
        ),
        SizedBox(
          height: 10,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), shape: BoxShape.rectangle, border: Border.all(color: Colors.grey.shade200, width: 1.0)),
          child: InternationalPhoneNumberInput(
            onInputChanged: (value) {
              controller.mobile.value = "${value.phoneNumber}";
            },
            ignoreBlank: true,
            autoValidateMode: AutovalidateMode.onUserInteraction,
            inputDecoration: InputDecoration(
              contentPadding: EdgeInsets.zero,
              hintText: 'Phone Number'.tr,
              border: const OutlineInputBorder(
                borderSide: BorderSide.none,
              ),
              isDense: true,
              errorBorder: const OutlineInputBorder(
                borderSide: BorderSide.none,
              ),
            ),
            inputBorder: const OutlineInputBorder(
              borderSide: BorderSide.none,
            ),
            initialValue: PhoneNumber(isoCode: 'ET'),
            selectorConfig: const SelectorConfig(selectorType: PhoneInputSelectorType.DIALOG),
          ),
        ),
        SizedBox(
          height: 10,
        ),
        TextFormField(
          keyboardType: TextInputType.emailAddress,
          textAlignVertical: TextAlignVertical.center,
          textInputAction: TextInputAction.next,
          cursorColor: AppColors.colorPrimary,
          validator: validateEmail,
          onSaved: (String? val) {
            controller.email.value = val.toString();
          },
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            fillColor: Colors.white,
            hintText: 'Email Address'.tr,
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0), borderSide: BorderSide(color: AppColors.colorPrimary, width: 2.0)),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
              borderRadius: BorderRadius.circular(25.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
              borderRadius: BorderRadius.circular(25.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(25.0),
            ),
          ),
        ),
        SizedBox(
          height: 10,
        ),
        TextFormField(
          obscureText: true,
          textAlignVertical: TextAlignVertical.center,
          textInputAction: TextInputAction.next,
          controller: controller.passwordController.value,
          validator: validatePassword,
          onSaved: (String? val) {
            controller.password.value = val.toString();
          },
          style: const TextStyle(fontSize: 18.0),
          cursorColor: AppColors.colorPrimary,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            fillColor: Colors.white,
            hintText: 'Password'.tr,
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0), borderSide: BorderSide(color: AppColors.colorPrimary, width: 2.0)),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
              borderRadius: BorderRadius.circular(25.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
              borderRadius: BorderRadius.circular(25.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(25.0),
            ),
          ),
        ),
        SizedBox(
          height: 10,
        ),
        TextFormField(
          textAlignVertical: TextAlignVertical.center,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => controller.signUpWithEmailAndPassword(context),
          obscureText: true,
          validator: (val) => validateConfirmPassword(controller.passwordController.value.text, val),
          onSaved: (String? val) {
            controller.confirmPassword.value = val.toString();
          },
          style: const TextStyle(fontSize: 18.0),
          cursorColor: AppColors.colorPrimary,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            fillColor: Colors.white,
            hintText: 'Confirm Password'.tr,
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0), borderSide: BorderSide(color: AppColors.colorPrimary, width: 2.0)),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
              borderRadius: BorderRadius.circular(25.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
              borderRadius: BorderRadius.circular(25.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(25.0),
            ),
          ),
        ),
        SizedBox(
          height: 14,
        ),
        InkWell(
          onTap: () {
            controller.signUpWithEmailAndPassword(context);
          },
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), color: AppColors.colorPrimary, border: Border.all(color: AppColors.colorPrimary, width: 1)),
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sign Up',
                    style: TextStyle(color: AppColors.colorWhite, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          height: 15,
        ),
        Text(
          'OR'.tr,
          style: TextStyle(color: AppColors.colorPrimary, fontWeight: FontWeight.bold, fontSize: 25.0),
        ),
        SizedBox(
          height: 15,
        ),
        InkWell(
          onTap: () {
            Get.to(const PhoneNumberInputScreen(), arguments: {
              "login": false,
            });
          },
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), color: Colors.white, border: Border.all(color: AppColors.colorPrimary, width: 1)),
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.call,
                    color: AppColors.colorPrimary,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    'Sign up with phone number',
                    style: TextStyle(color: AppColors.colorPrimary, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1),
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}
