import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:inspection/utils/constant/image_constants.dart';
import 'package:inspection/view/global_widgets/customAppBar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isEditing = false;

  Future<Map<String, dynamic>> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      "name": prefs.getString("userName") ?? "",
      "role": prefs.getString("userRole") ?? "",
      "email": prefs.getString("userEmail") ?? "",
      "phone": prefs.getString("userPhone") ?? "",
      "phoneCode": prefs.getString("userPhoneCode") ?? "",
    };
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) => context.go('/settings'),
      child: Scaffold(
        backgroundColor: ColorConstants.whiteColor,
        appBar: CustomAppBar(
          title: "Profile",
          onBackPress: () => context.go('/settings'),
        ),
        body: FutureBuilder(
          future: getSavedUser(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final user = snapshot.data!;

            return SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 150,
                          width: 150,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              ImageConstants.profileLogo,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Text(
                          'Profile Details',
                          style: ApptextstyleConstants.thinText(
                            fontSize: 18,
                            color: ColorConstants.blackColor,
                          ),
                        ),
                        SizedBox(height: 15),
                        Text(
                          "Full Name",
                          style: TextStyle(
                            fontSize: 14,
                            color: ColorConstants.greyColor,
                          ),
                        ),
                        SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.all(14),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black26),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            user["name"],
                            style: ApptextstyleConstants.lightText(
                              fontSize: 14,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "User Role",
                          style: TextStyle(
                            fontSize: 14,
                            color: ColorConstants.greyColor,
                          ),
                        ),
                        SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.all(14),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black26),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            user["role"],
                            style: ApptextstyleConstants.lightText(
                              fontSize: 14,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Mobile Number",
                              style: TextStyle(
                                fontSize: 14,
                                color: ColorConstants.greyColor,
                              ),
                            ),
                            SizedBox(height: 5),

                            Row(
                              children: [
                                /// PHONE CODE (ALWAYS FIXED)
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.black26),
                                  ),
                                  child: Text(
                                    user["phoneCode"],
                                    style: ApptextstyleConstants.lightText(
                                      fontSize: 14,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.black26),
                                    ),
                                    child: Text(
                                      user["phone"],
                                      style: ApptextstyleConstants.lightText(
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Email Address",
                          style: TextStyle(
                            fontSize: 14,
                            color: ColorConstants.greyColor,
                          ),
                        ),
                        SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.all(14),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black26),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            user["email"],
                            style: ApptextstyleConstants.lightText(
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () {
                        context.go('/settings');
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(
                          vertical: 5,
                          horizontal: 0,
                        ),
                        padding: EdgeInsets.only(left: 16),
                        width: 150,
                        height: 50,
                        decoration: BoxDecoration(
                          color: ColorConstants.signoutButton,
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(24.0),
                            bottomRight: Radius.circular(24.0),
                          ),
                          border: Border.all(
                            color: ColorConstants.syanColor,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.close_sharp,
                              color: ColorConstants.whiteColor,
                              size: 24,
                            ),
                            Padding(
                              padding: EdgeInsetsGeometry.symmetric(
                                horizontal: 5,
                              ),
                              child: Text(
                                "Close",
                                style: TextStyle(
                                  color: ColorConstants.whiteColor,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
