import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inspection/utils/constant/color_constants.dart';
import 'package:inspection/view/global_widgets/customAppBar.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:inspection/view/global_widgets/customButtonWidget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class QuotationDetailsPage extends StatefulWidget {
  const QuotationDetailsPage({super.key});

  @override
  State<QuotationDetailsPage> createState() => QuotationDetailsPageState();
}

class QuotationDetailsPageState extends State<QuotationDetailsPage> {
  final GlobalKey _shareKey = GlobalKey();
  bool _isCapturing = false;

  Future<void> _shareContent() async {
    try {
      setState(() => _isCapturing = true);
      await Future.delayed(const Duration(milliseconds: 100));
      RenderRepaintBoundary boundary =
          _shareKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      var image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/inspection_share.png');
      await file.writeAsBytes(pngBytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Inspection Summary',
        subject: 'Inspection Details',
      );
    } catch (e, s) {
      debugPrintStack(stackTrace: s);
    } finally {
      setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) => context.go('/quotation'),
      child: Scaffold(
        backgroundColor: ColorConstants.whiteColor,
        appBar: CustomAppBar(
          title: 'Quotation Details',
          onBackPress: () => context.go('/quotation'),
        ),
        body: RepaintBoundary(
          key: _shareKey,
          child: Container(
            color: ColorConstants.whiteColor,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[300],
                            child: const Icon(Icons.directions_car),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "NORMAL SERVICE",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  "Job Card No: JC-2025-10-467",
                                  style: TextStyle(fontSize: 12),
                                ),
                                Text(
                                  "Date: 15-OCT-2025   Time: 12:01PM",
                                  style: TextStyle(fontSize: 12),
                                ),
                                Text(
                                  "Mercedes Benz - E300 - 2015",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: CustomButtonWidget(
                      text: "SHARE",
                      textSize: 15,
                      onPressed: _shareContent,
                    ),
                  ),

                  // Share and Print buttons
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.end,
                  //   children: [
                  //     ElevatedButton(
                  //       onPressed: _shareContent,
                  //       style: ElevatedButton.styleFrom(
                  //         backgroundColor: const Color(0xFF0C5E91),
                  //         padding: const EdgeInsets.symmetric(
                  //           horizontal: 30,
                  //           vertical: 10,
                  //         ),
                  //         shape: RoundedRectangleBorder(
                  //           borderRadius: BorderRadius.circular(6),
                  //         ),
                  //       ),
                  //       child: Text(
                  //         "SHARE",
                  //         style: ApptextstyleConstants.lightText(
                  //           fontSize: 15.sp,
                  //           color: Colors.white,
                  //         ),
                  //       ),
                  //     ),
                  //     SizedBox(width: 4),
                  //     ElevatedButton(
                  //       onPressed: _downloadAsPdf,
                  //       style: ElevatedButton.styleFrom(
                  //         backgroundColor: const Color(0xFF0C5E91),
                  //         padding: const EdgeInsets.symmetric(
                  //           horizontal: 30,
                  //           vertical: 10,
                  //         ),
                  //         shape: RoundedRectangleBorder(
                  //           borderRadius: BorderRadius.circular(6),
                  //         ),
                  //       ),
                  //       child: Text(
                  //         "DOWNLOAD",
                  //         style: ApptextstyleConstants.lightText(
                  //           fontSize: 15.sp,
                  //           color: Colors.white,
                  //         ),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ------------------ TITLE ------------------
                      const Text(
                        "QUOTATION",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ------------------ TABLE HEADER ------------------
                      Container(
                        color: Colors.black12,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: const [
                            Expanded(
                              flex: 3,
                              child: Text(
                                "Description",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                "Qty",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                "Unit Price",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                "VAT",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                "Total",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(),

                      // ------------------ TABLE ROWS ------------------
                      ..._itemRow("Item 1", 3, 5.99, 0.01, 21.38),
                      ..._itemRow("Item 2", 8, 5.09, 0.02, 9.42),
                      ..._itemRow("Item 3", 3, 2.29, 0.03, 7.05),
                      ..._itemRow("Item 4", 8, 5.99, 0.03, 37.96),
                      ..._itemRow("Item 5", 3, 1.59, 0.03, 5.69),
                      ..._itemRow("Item 6", 5, 5.09, 0.04, 15.69),
                      ..._itemRow("Item 7", 4, 1.29, 0.05, 6.14),

                      const SizedBox(height: 20),
                      const Divider(thickness: 1),

                      // ------------------ TOTALS ------------------
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: const [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "Net total 77.48",
                                style: TextStyle(fontSize: 15),
                              ),
                              SizedBox(height: 6),
                              Text(
                                "Vat 5 % 14.91",
                                style: TextStyle(fontSize: 15),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        color: Colors.black12,
                        padding: const EdgeInsets.all(12),
                        child: const Text(
                          "Total 93.39",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),

                      const SizedBox(height: 30),
                      const Divider(),
                      const SizedBox(height: 10),
                    ],
                  ),

                  // Bottom Button
                  Visibility(
                    visible: !_isCapturing,
                    child: SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0066A6), Color(0xFF00BFA6)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            context.go('/quotation');
                          },
                          child: const Text(
                            "CLOSE",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _itemRow(
    String name,
    int qty,
    double price,
    double vat,
    double total,
  ) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(flex: 3, child: Text(name)),
            Expanded(child: Text(qty.toString())),
            Expanded(child: Text(price.toStringAsFixed(2))),
            Expanded(child: Text("${(vat * 100).toStringAsFixed(1)}%")),
            Expanded(child: Text(total.toStringAsFixed(2))),
          ],
        ),
      ),
      const Divider(height: 1),
    ];
  }
}
