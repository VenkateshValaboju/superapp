import 'package:sharehandsprovider/constant/constants.dart';
import 'package:sharehandsprovider/constant/show_toast_dialog.dart';
import 'package:sharehandsprovider/controller/login_controller.dart';
import 'package:sharehandsprovider/themes/app_colors.dart';
import 'package:sharehandsprovider/ui/phoneAuth/phone_number_input_screen.dart';
import 'package:sharehandsprovider/utils/dark_theme_provider.dart';
import 'package:sharehandsprovider/widgets/common_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<LoginController>(
        init: LoginController(),
        builder: (controller) {
          return Scaffold(
            appBar: CommonUI.customAppBar(context, isBack: true, backgroundColor: themeChange.getTheme() ? AppColors.assetColorGrey1000 : AppColors.assetColorLightGrey400),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Form(
                key: controller.key.value,
                autovalidateMode: controller.validate,
                child: ListView(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 32.0, right: 16.0, left: 16.0),
                      child: Text(
                        'Log In'.tr,
                        style: TextStyle(color: AppColors.colorPrimary, fontSize: 25.0, fontWeight: FontWeight.bold),
                      ),
                    ),

                    SizedBox(
                      height: 30,
                    ),
                    TextFormField(
                        textAlignVertical: TextAlignVertical.center,
                        textInputAction: TextInputAction.next,
                        validator: validateEmail,
                        controller: controller.emailController.value,
                        style: const TextStyle(fontSize: 18.0),
                        keyboardType: TextInputType.emailAddress,
                        cursorColor: AppColors.colorPrimary,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.only(left: 16, right: 16),
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
                        )),

                    SizedBox(
                      height: 10,
                    ),
                    TextFormField(
                        textAlignVertical: TextAlignVertical.center,
                        controller: controller.passwordController.value,
                        obscureText: true,
                        validator: validatePassword,
                        onFieldSubmitted: (password) => controller.login(context),
                        textInputAction: TextInputAction.done,
                        style: const TextStyle(fontSize: 18.0),
                        cursorColor: AppColors.colorPrimary,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.only(left: 16, right: 16),
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
                        )),

                    /// forgot password text, navigates user to ResetPasswordScreen
                    /// and this is only visible when logging with email and password
                    Padding(
                      padding: const EdgeInsets.only(top: 16, right: 24),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            showResetPwdAlertDialog(context, controller);
                          },
                          child: Text(
                            'Forgot password?'.tr,
                            style: const TextStyle(color: Colors.lightBlue, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 40,
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.colorPrimary,
                        padding: const EdgeInsets.only(top: 10, bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          side: BorderSide(
                            color: AppColors.colorPrimary,
                          ),
                        ),
                      ),
                      child: Text(
                        'Log In'.tr,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: themeChange.getTheme() ? Colors.black : Colors.white,
                        ),
                      ),
                      onPressed: () => controller.login(context),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 45),
                      child: Center(
                        child: Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OR'.tr,
                                style: TextStyle(color: themeChange.getTheme() ? Colors.white : Colors.black),
                              ),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                      ),
                    ),

                    /// switch between login with phone number and email login states
                    InkWell(
                      onTap: () {
                        Get.to(const PhoneNumberInputScreen(), arguments: {
                          "login": true,
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), color: Colors.white, border: Border.all(color: AppColors.colorPrimary, width: 1)),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.call, color: AppColors.colorPrimary),
                              const SizedBox(
                                width: 10,
                              ),
                              Text(
                                'Login with phone number'.tr,
                                style: TextStyle(color: AppColors.colorPrimary, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        });
  }

  showResetPwdAlertDialog(BuildContext context, controller) {
    Get.defaultDialog(
        title: 'Reset Password',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: controller.emailController.value,
                keyboardType: TextInputType.text,
                maxLines: 1,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.only(left: 16, right: 16),
                  hintText: 'Email'.tr,
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
                    borderSide: BorderSide(color: Colors.grey.shade500),
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                )),
            const SizedBox(
              height: 30.0,
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.colorPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  textStyle: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
              onPressed: () async {
                if (controller.emailController.value.text.toString().isNotEmpty) {
                  ShowToastDialog.showLoader('Sending Email...'.tr);
                  await auth.FirebaseAuth.instance.sendPasswordResetEmail(email: controller.emailController.value.text.toString());
                  ShowToastDialog.closeLoader();
                  Get.back();

                  ShowToastDialog.showToast('Please check your email.'.tr);
                }
              },
              child: Text(
                'Send Link'.tr,
                style: const TextStyle(color: Colors.white, fontSize: 16.0),
              ),
            )
          ],
        ),
        radius: 10.0);
  }
}
