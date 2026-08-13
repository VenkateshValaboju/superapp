import 'dart:io';

import 'package:sharehandsprovider/constant/constants.dart';
import 'package:sharehandsprovider/controller/otpController.dart';
import 'package:sharehandsprovider/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';

import '../../utils/dark_theme_provider.dart';

class PhoneNumberInputScreen extends StatelessWidget {
  const PhoneNumberInputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<OtpController>(
        init: OtpController(),
        builder: (controller) {
          if (Platform.isAndroid && !controller.login.value) {
            retrieveLostData(controller);
          }
          return Scaffold(
            appBar: AppBar(
              elevation: 0.0,
              backgroundColor: Colors.transparent,
              iconTheme: IconThemeData(color: themeChange.getTheme() ? Colors.white : Colors.black),
            ),
            body: SingleChildScrollView(
              child: Container(
                margin: EdgeInsets.only(left: 16.0, right: 16, bottom: 16),
                child: Form(
                  key: controller.key.value,
                  autovalidateMode: controller.validate,
                  child: Column(
                    children: <Widget>[
                      Align(
                          alignment: Directionality.of(context) == TextDirection.ltr ? Alignment.topLeft : Alignment.topRight,
                          child: Text(
                            controller.login.value ? 'Sign In'.tr : 'Create new account'.tr,
                            style: TextStyle(color: AppColors.colorPrimary, fontWeight: FontWeight.bold, fontSize: 25.0),
                          )),

                      /// user first name text field , this is visible until we verify the
                      /// code in case of sign up with phone number
                      Visibility(
                        visible: !controller.codeSent.value && !controller.login.value,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: double.infinity),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16.0, right: 8.0, left: 8.0),
                            child: TextFormField(
                              cursorColor: AppColors.colorPrimary,
                              textAlignVertical: TextAlignVertical.center,
                              validator: validateName,
                              controller: controller.firstNameController.value,
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
                          ),
                        ),
                      ),

                      /// last name of the user , this is visible until we verify the
                      /// code in case of sign up with phone number
                      Visibility(
                        visible: !controller.codeSent.value && !controller.login.value,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: double.infinity),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16.0, right: 8.0, left: 8.0),
                            child: TextFormField(
                              validator: validateName,
                              textAlignVertical: TextAlignVertical.center,
                              cursorColor: AppColors.colorPrimary,
                              onSaved: (String? val) {
                                controller.lastName.value = val.toString();
                              },
                              controller: controller.lastNameController.value,
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
                          ),
                        ),
                      ),

                      /// user phone number,  this is visible until we verify the code
                      Visibility(
                        visible: !controller.codeSent.value,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16.0, right: 8.0, left: 8.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), shape: BoxShape.rectangle, border: Border.all(color: Colors.grey.shade200)),
                            child: InternationalPhoneNumberInput(
                              onInputChanged: (PhoneNumber number) => controller.phoneNumber.value = number.phoneNumber.toString(),
                              onInputValidated: (bool value) => controller.isPhoneValid.value = value,
                              ignoreBlank: true,
                              autoValidateMode: AutovalidateMode.onUserInteraction,
                              inputDecoration: InputDecoration(
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
                        ),
                      ),

                      /// code validation field, this is visible in case of sign up with
                      /// phone number and the code is sent
                      Visibility(
                        visible: controller.codeSent.value,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 32.0, right: 24.0, left: 24.0),
                          child: PinCodeTextField(
                            length: 6,
                            appContext: context,
                            keyboardType: TextInputType.phone,
                            backgroundColor: Colors.transparent,
                            pinTheme: PinTheme(
                                shape: PinCodeFieldShape.box,
                                borderRadius: BorderRadius.circular(5),
                                fieldHeight: 40,
                                fieldWidth: 40,
                                activeColor: AppColors.colorPrimary,
                                activeFillColor: themeChange.getTheme() ? Colors.grey.shade700 : Colors.grey.shade100,
                                selectedFillColor: Colors.transparent,
                                selectedColor: AppColors.colorPrimary,
                                inactiveColor: Colors.grey.shade600,
                                inactiveFillColor: Colors.transparent),
                            enableActiveFill: true,
                            onCompleted: (v) {
                              controller.submitCode(v, context);
                            },
                            onChanged: (value) {
                              print(value);
                            },
                          ),
                        ),
                      ),

                      /// the main action button of the screen, this is hidden if we
                      /// received the code from firebase
                      /// the action and the title is base on the state,
                      /// * Sign up with email and password: send email and password to
                      /// firebase
                      /// * Sign up with phone number: submits the phone number to
                      /// firebase and await for code verification
                      Visibility(
                        visible: !controller.codeSent.value,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 40.0, left: 40.0, top: 40.0),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: double.infinity),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.colorPrimary,
                                padding: const EdgeInsets.only(top: 12, bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25.0),
                                  side: BorderSide(
                                    color: AppColors.colorPrimary,
                                  ),
                                ),
                              ),
                              onPressed: () => controller.signUp(context),
                              child: Text(
                                'Send code'.tr,
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: themeChange.getTheme() ? Colors.black : Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Text(
                            'OR'.tr,
                            style: TextStyle(color: themeChange.getTheme() ? Colors.white : Colors.black),
                          ),
                        ),
                      ),

                      /// switch between sign up with phone number and email sign up states
                      InkWell(
                        onTap: () {
                          Get.back();
                        },
                        child: Text(
                          controller.login.value ? 'Login with E-mail'.tr : 'Sign up with E-mail'.tr,
                          style: const TextStyle(color: Colors.lightBlue, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }

  /// used on android by the image picker lib, sometimes on android the image
  /// is lost
  Future<void> retrieveLostData(OtpController controller) async {
    final LostDataResponse? response = await controller.imagePicker.retrieveLostData();
    if (response == null) {
      return;
    }
    if (response.file != null) {
      controller.image = File(response.file!.path);
    }
  }
}
