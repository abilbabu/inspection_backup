import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inspection/controller/authentication_%20controller.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:provider/provider.dart';

class BottomnavbarScreen extends StatefulWidget {
  final Widget child;

  const BottomnavbarScreen({super.key, required this.child});

  @override
  State<BottomnavbarScreen> createState() => _BottomnavbarScreenState();
}

class _BottomnavbarScreenState extends State<BottomnavbarScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthenticationController>(
      builder: (context, controller, _) {
        if (!controller.isDepartmentLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final int userDepartment = controller.userDepartment;

        final bool isJobCardDepartment =
            userDepartment == 2 || userDepartment == 4;

        final List<String> routes = isJobCardDepartment
            ? ['/home', '/history', '/settings']
            : ['/home', '/quotation', '/history', '/settings'];

        /// NAV ITEMS
        final List<BottomNavigationBarItem> navItems = isJobCardDepartment
            ? [
                _buildNavItem(Icons.home_filled, 0, controller.currentIndex),

                _buildNavItem(Icons.history, 1, controller.currentIndex),

                _buildNavItem(Icons.settings, 2, controller.currentIndex),
              ]
            : [
                _buildNavItem(Icons.home_filled, 0, controller.currentIndex),

                _buildNavItem(
                  Icons.request_quote_rounded,
                  1,
                  controller.currentIndex,
                ),

                _buildNavItem(Icons.history, 2, controller.currentIndex),

                _buildNavItem(Icons.settings, 3, controller.currentIndex),
              ];

        return Scaffold(
          extendBody: true,
          body: widget.child,
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(color: Colors.transparent),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              currentIndex: controller.currentIndex,
              selectedItemColor: null,
              unselectedItemColor: ColorConstants.greyColor,
              enableFeedback: false,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              onTap: (index) {
                controller.setIndex(index);
                context.go(routes[index]);
              },
              items: navItems,
            ),
          ),
        );
      },
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData icon,
    int index,
    int currentIndex,
  ) {
    final isSelected = index == currentIndex;

    const gradient = LinearGradient(
      colors: [Color(0xFF0066A6), Color(0xFF00BFA6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: isSelected
            ? ShaderMask(
                shaderCallback: (bounds) => gradient.createShader(bounds),
                child: Icon(icon, size: 35, color: Colors.white),
              )
            : Icon(icon, size: 28, color: ColorConstants.greyColor),
      ),
      label: '',
    );
  }
}
