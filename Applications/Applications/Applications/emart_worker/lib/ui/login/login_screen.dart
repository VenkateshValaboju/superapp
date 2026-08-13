import 'package:sharehands_worker/constant/constants.dart';
import 'package:sharehands_worker/constant/show_toast_dialog.dart';
import 'package:sharehands_worker/controller/login_controller.dart';
import 'package:sharehands_worker/themes/app_colors.dart';
import 'package:sharehands_worker/utils/dark_theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<LoginController>(
        init: LoginController(),
        builder: (controller) {
          return Scaffold(
            body: Form(
              key: controller.key.value,
              autovalidateMode: controller.validate,
              child: ListView(
                children: <Widget>[
                  Padding(
                    padding:  const EdgeInsets.only(top: 32.0, right: 16.0, left: 16.0),
                    child: Text(
                      'Log In'.tr,
                      style:  TextStyle(color: AppColors.colorPrimary, fontSize: 25.0, fontWeight: FontWeight.bold),
                    ),
                  ),

                  Padding(
                    padding:  const EdgeInsets.only(top: 32.0, right: 24.0, left: 24.0),
                    child: TextFormField(
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
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0), borderSide:  BorderSide(color: AppColors.colorPrimary, width: 2.0)),
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
                  ),

                  /// password text field, visible when logging with email and
                  /// password
                  Padding(
                    padding: const EdgeInsets.only(top: 15.0, right: 24.0, left: 24.0),
                    child: TextFormField(
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
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0), borderSide:  BorderSide(color: AppColors.colorPrimary, width: 2.0)),
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
                  ),

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

                  Padding(
                    padding: const EdgeInsets.only(right: 40.0, left: 40.0, top: 40),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: double.infinity),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.colorPrimary,
                          padding: const EdgeInsets.only(top: 12, bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0),
                            side:  BorderSide(
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
                    ),
                  ),
                ],
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
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: double.infinity),
              child: Padding(
                padding: const EdgeInsets.only(top: 16.0, right: 16.0, left: 16.0),
                child: TextField(
                    controller: controller.emailController.value,
                    keyboardType: TextInputType.text,
                    maxLines: 1,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.only(left: 16, right: 16),
                      hintText: 'Email'.tr,
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0), borderSide:  BorderSide(color: AppColors.colorPrimary, width: 2.0)),
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
              ),
            ),
            const SizedBox(
              height: 30.0,
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.colorPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  textStyle: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
              onPressed: () async {
                if (controller.emailController.value.text.toString().isNotEmpty) {
                  showProgress(context, 'Sending Email...'.tr, false);
                  await auth.FirebaseAuth.instance.sendPasswordResetEmail(email: controller.emailController.value.text.toString());
                  hideProgress();
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
