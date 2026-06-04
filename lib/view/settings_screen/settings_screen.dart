import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:inspection/controller/authentication_%20controller.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:inspection/utils/constant/image_constants.dart';
import 'package:inspection/view/global_widgets/customAppBar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  Future<Map<String, dynamic>> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      "name": prefs.getString("userName") ?? "",
      "role": prefs.getString("userRole") ?? "",
      "email": prefs.getString("userEmail") ?? "",
    };
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        statusBarColor: ColorConstants.whiteColor,
        systemNavigationBarColor: ColorConstants.whiteColor,
      ),
      child: Scaffold(
        backgroundColor: ColorConstants.whiteColor,
        appBar: CustomAppBar(
          title: 'Settings Page',
           onBackPress: () {
            context.go('/settings');
          },
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          flex: 2,
                          child: ClipRRect(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(10.0),
                              bottomRight: Radius.circular(16.0),
                            ),
                            child: Image.asset(
                              ImageConstants.profileLogo,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        SizedBox(width: 16.0),
                        Expanded(
                          flex: 3,
                          child: FutureBuilder(
                            future: getSavedUser(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return SizedBox(); // or CircularProgressIndicator()
                              }
      
                              final user = snapshot.data!;
      
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    user["name"],
                                    style: ApptextstyleConstants.lightText(
                                      fontSize: 15,
                                      color: ColorConstants.blackColor,
                                    ),
                                  ),
                                  SizedBox(height: 2.0),
                                  RichText(
                                    text: TextSpan(
                                      text: "Role: ",
                                      style: ApptextstyleConstants.thinText(
                                        fontSize: 10,
                                        color: ColorConstants.blackColor,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: user["role"],
                                          style:
                                              ApptextstyleConstants.thinText(
                                                fontSize: 10,
                                                color:
                                                    ColorConstants.blackColor,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 4.0),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () => context.go("/profile"),
                          child: Row(
                            children: [
                              Container(
                                alignment: Alignment.center,
                                margin: EdgeInsets.symmetric(vertical: 8),
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topRight,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      ColorConstants.lightblueColor,
                                      ColorConstants.syanColor,
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  Icons.person,
                                  color: ColorConstants.whiteColor,
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 16),
                              Text(
                                "Profile",
                                style: ApptextstyleConstants.thinText(
                                  color: ColorConstants.blackColor,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              alignment: Alignment.center,
                              margin: EdgeInsets.symmetric(vertical: 8),
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    ColorConstants.lightblueColor,
                                    ColorConstants.syanColor,
                                  ],
                                ),
                              ),
                              child: Icon(
                                Icons.request_quote_rounded,
                                color: ColorConstants.whiteColor,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              "Quotation List",
                              style: ApptextstyleConstants.thinText(
                                color: ColorConstants.blackColor,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              alignment: Alignment.center,
                              margin: EdgeInsets.symmetric(vertical: 8),
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    ColorConstants.lightblueColor,
                                    ColorConstants.syanColor,
                                  ],
                                ),
                              ),
                              child: Icon(
                                Icons.lock,
                                color: ColorConstants.whiteColor,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              "Privacy",
                              style: ApptextstyleConstants.thinText(
                                color: ColorConstants.blackColor,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  splashColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () {
                    Provider.of<AuthenticationController>(
                      context,
                      listen: false,
                    ).logout(context);
                    context.go("/login");
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 16, horizontal: 0),
                    padding: EdgeInsets.only(left: 16),
                    width: 180,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomRight,
                        colors: [
                          ColorConstants.lightblueColor,
                          ColorConstants.syanColor,
                        ],
                      ),
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
                        SizedBox(width: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.logout,
                              color: ColorConstants.whiteColor,
                              size: 24,
                            ),
                            SizedBox(width: 10),
                            Text(
                              "Signout",
                              style: ApptextstyleConstants.lightText(
                                fontSize: 15,
                                color: ColorConstants.whiteColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 10),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
