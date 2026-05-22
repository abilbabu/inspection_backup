import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inspection/utils/constant/appTextStyle_constants.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:inspection/utils/dummyDB/Dummydb.dart';
import 'package:inspection/view/global_widgets/customAppBar.dart';
import 'package:inspection/view/global_widgets/customButtonWidget.dart';

class FullScreenImage extends StatelessWidget {
  final String imageUrl;
  final String label;

  const FullScreenImage({
    super.key,
    required this.imageUrl,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCarDiagram = label == "Inspection Diagram";
    final firstGroup = DummyDB.damageList.take(3).toList();
    final secondGroup = DummyDB.damageList.skip(3).toList();
    String toTitleCase(String text) {
      if (text.isEmpty) return text;

      return text
          .split(' ')
          .map(
            (word) => word.isEmpty
                ? word
                : word[0].toUpperCase() + word.substring(1).toLowerCase(),
          )
          .join(' ');
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: "Vehicle Image",
          onBackPress: () => context.pop(),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              Text(
                toTitleCase(label),
                style: ApptextstyleConstants.mediumText(
                  fontSize: 16,
                  color: ColorConstants.blackColor,
                ),
              ),

              const SizedBox(height: 20),

              /// 🖼 Full Screen Area
              Expanded(
                child: isCarDiagram
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 5,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: ColorConstants.whiteColor,
                            // border: Border.all(
                            //   // color: ColorConstants.syanColor,
                            //   width: 2.5,
                            // ),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                flex: 8,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: ColorConstants.whiteColor,
                                  ),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.contain,
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    },
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.broken_image,
                                              size: 60,
                                            ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.center,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: ColorConstants.activecolor,
                                    ),
                                  ),

                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Legend",
                                        style: ApptextstyleConstants.mediumText(
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 6),

                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: List.generate(firstGroup.length, (
                                          index,
                                        ) {
                                          final item = firstGroup[index];
                                          return Text(
                                            "${item["emoji"]} ${item["label"]}",
                                            style:
                                                ApptextstyleConstants.lightText(
                                                  color: item["color"],
                                                  fontSize: 12,
                                                ),
                                          );
                                        }),
                                      ),

                                      const SizedBox(height: 4),

                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: List.generate(
                                          secondGroup.length,
                                          (index) {
                                            final item = secondGroup[index];
                                            return Text(
                                              "${item["emoji"]} ${item["label"]}",
                                              style:
                                                  ApptextstyleConstants.lightText(
                                                    color: item["color"],
                                                    fontSize: 12,
                                                  ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                            ],
                          ),
                        ),
                      )
                    /// 🔹 NORMAL FULLSCREEN IMAGE (NO LEGEND)
                    : Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 5,
                        ),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            // border: Border.all(
                            //   // color: ColorConstants.syanColor,
                            //   width: 2.5,
                            // ),
                          ),
                          child:
                              //  FutureBuilder<ImageInfo>(
                              //   future: _getNetworkImageSize(imageUrl),
                              //   builder: (context, snapshot) {
                              //     if (!snapshot.hasData) {
                              //       return const Center(
                              //         child: CircularProgressIndicator(),
                              //       );
                              //     }
                              //     final imageInfo = snapshot.data!;
                              //     final isLandscape =
                              //         imageInfo.image.width > imageInfo.image.height;
                              //     return ClipRect(
                              //       child: FittedBox(
                              //         fit: BoxFit.cover,
                              //         child: Transform.rotate(
                              //           angle: isLandscape ? 1.5708 : 0,
                              //           child: Image.network(
                              //             imageUrl,
                              //             loadingBuilder: (context, child, progress) {
                              //               if (progress == null) return child;
                              //               return const Center(
                              //                 child: CircularProgressIndicator(),
                              //               );
                              //             },
                              //             errorBuilder:
                              //                 (context, error, stackTrace) =>
                              //                     const Icon(
                              //                       Icons.broken_image,
                              //                       size: 60,
                              //                     ),
                              //           ),
                              //         ),
                              //       ),
                              //     );
                              //   },
                              // ),
                              Image.network(
                                imageUrl,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image, size: 60),
                              ),
                        ),
                      ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: CustomButtonWidget(
                  text: "Close",
                  textSize: 16,
                  textColor: ColorConstants.whiteColor,
                  onPressed: () => context.pop(),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// Future<ImageInfo> _getNetworkImageSize(String url) async {
//   final completer = Completer<ImageInfo>();
//   final image = NetworkImage(url);

//   image
//       .resolve(const ImageConfiguration())
//       .addListener(
//         ImageStreamListener((ImageInfo info, bool _) {
//           completer.complete(info);
//         }),
//       );

//   return completer.future;
// }
