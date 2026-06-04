// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:inspection/view/global_widgets/customAppBar.dart';
// import 'package:inspection/view/global_widgets/customButtonWidget.dart';
// import 'package:share_plus/share_plus.dart';

// class HistoryDetailsPage extends StatefulWidget {
//   const HistoryDetailsPage({super.key});

//   @override
//   State<HistoryDetailsPage> createState() => HistoryDetailsPageState();
// }

// class HistoryDetailsPageState extends State<HistoryDetailsPage> {
//   final GlobalKey _pdfKey = GlobalKey();

//   Future<void> _shareContent() async {
//     await Share.share(
//       'Check this quotation summary!',
//       subject: 'Quotation Details',
//     );
//   }

//   // Future<void> _downloadAsPdf() async {
//   //   try {
//   //     // Capture widget as image
//   //     RenderRepaintBoundary boundary =
//   //         _pdfKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
//   //     var image = await boundary.toImage(pixelRatio: 3.0);
//   //     ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
//   //     Uint8List imageBytes = byteData!.buffer.asUint8List();
//   //     final pdf = pw.Document();
//   //     final pdfImage = pw.MemoryImage(imageBytes);
//   //     pdf.addPage(
//   //       pw.Page(
//   //         pageFormat: PdfPageFormat.a4,
//   //         build: (pw.Context context) => pw.Center(child: pw.Image(pdfImage)),
//   //       ),
//   //     );
//   //     final dir = await getTemporaryDirectory();
//   //     final file = File(
//   //       '${dir.path}/quotation_${DateTime.now().millisecondsSinceEpoch}.pdf',
//   //     );
//   //     await file.writeAsBytes(await pdf.save());
//   //     await Share.shareXFiles([XFile(file.path)], text: "Quotation PDF");
//   //     ScaffoldMessenger.of(
//   //       context,
//   //     ).showSnackBar(SnackBar(content: Text('PDF downloaded: ${file.path}')));
//   //   } catch (e) {
//   //     debugPrint("PDF Generation Failed: $e");
//   //   }
//   // }

//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//       canPop: false,
//       onPopInvoked: (didPop) => context.go('/history'),
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         appBar: CustomAppBar(
//           title: 'History Details',
//           onBackPress: () => context.go('/history'),
//         ),
//         body: RepaintBoundary(
//           key: _pdfKey,
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(12.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 Card(
//                   elevation: 2,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(12),
//                     child: Row(
//                       children: [
//                         Container(
//                           width: 50,
//                           height: 50,
//                           color: Colors.grey[300],
//                           child: const Icon(Icons.directions_car),
//                         ),
//                         SizedBox(width: 12),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 "NORMAL SERVICE",
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 14,
//                                 ),
//                               ),
//                               Text(
//                                 "Job Card No: JC-2025-10-467",
//                                 style: TextStyle(fontSize: 12),
//                               ),
//                               Text(
//                                 "Date: 15-OCT-2025   Time: 12:01PM",
//                                 style: TextStyle(fontSize: 12),
//                               ),
//                               Text(
//                                 "Mercedes Benz - E300 - 2015",
//                                 style: TextStyle(fontSize: 12),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),

//                 const SizedBox(height: 12),
//                 Align(
//                   alignment: Alignment.centerRight,
//                   child: CustomButtonWidget(
//                     text: "SHARE",
//                     textSize: 15,
//                     onPressed: _shareContent,
//                   ),
//                 ),

//                 // Share and Print buttons
//                 // Row(
//                 //   mainAxisAlignment: MainAxisAlignment.end,
//                 //   children: [
//                 //     ElevatedButton(
//                 //       onPressed: _shareContent,
//                 //       style: ElevatedButton.styleFrom(
//                 //         backgroundColor: const Color(0xFF0C5E91),
//                 //         padding: const EdgeInsets.symmetric(
//                 //           horizontal: 30,
//                 //           vertical: 10,
//                 //         ),
//                 //         shape: RoundedRectangleBorder(
//                 //           borderRadius: BorderRadius.circular(6),
//                 //         ),
//                 //       ),
//                 //       child: Text(
//                 //         "SHARE",
//                 //         style: ApptextstyleConstants.lightText(
//                 //           fontSize: 15.sp,
//                 //           color: Colors.white,
//                 //         ),
//                 //       ),
//                 //     ),
//                 //     SizedBox(width: 4),
//                 //     ElevatedButton(
//                 //       onPressed: _downloadAsPdf,
//                 //       style: ElevatedButton.styleFrom(
//                 //         backgroundColor: const Color(0xFF0C5E91),
//                 //         padding: const EdgeInsets.symmetric(
//                 //           horizontal: 30,
//                 //           vertical: 10,
//                 //         ),
//                 //         shape: RoundedRectangleBorder(
//                 //           borderRadius: BorderRadius.circular(6),
//                 //         ),
//                 //       ),
//                 //       child: Text(
//                 //         "DOWNLOAD",
//                 //         style: ApptextstyleConstants.lightText(
//                 //           fontSize: 15.sp,
//                 //           color: Colors.white,
//                 //         ),
//                 //       ),
//                 //     ),
//                 //   ],
//                 // ),
//                 const SizedBox(height: 20),

//                 const Text(
//                   "Quotation History",
//                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                 ),
//                 const SizedBox(height: 8),

//                 // Quotation Table
//                 Table(
//                   border: TableBorder.all(color: Colors.black, width: 1),
//                   columnWidths: const {
//                     0: FixedColumnWidth(40),
//                     1: FlexColumnWidth(2),
//                     2: FixedColumnWidth(40),
//                     3: FixedColumnWidth(70),
//                     4: FixedColumnWidth(70),
//                   },
//                   children: const [
//                     TableRow(
//                       decoration: BoxDecoration(color: Color(0xFFE6E6E6)),
//                       children: [
//                         Padding(
//                           padding: EdgeInsets.all(6.0),
//                           child: Text(
//                             "Si No.",
//                             style: TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                         ),
//                         Padding(
//                           padding: EdgeInsets.all(6.0),
//                           child: Text(
//                             "Description",
//                             style: TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                         ),
//                         Padding(
//                           padding: EdgeInsets.all(6.0),
//                           child: Text(
//                             "Qty",
//                             style: TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                         ),
//                         Padding(
//                           padding: EdgeInsets.all(6.0),
//                           child: Text(
//                             "Unit Price",
//                             style: TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                         ),
//                         Padding(
//                           padding: EdgeInsets.all(6.0),
//                           child: Text(
//                             "Net Price",
//                             style: TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                         ),
//                       ],
//                     ),
//                     TableRow(
//                       children: [
//                         Padding(
//                           padding: EdgeInsets.all(6.0),
//                           child: Text("1."),
//                         ),
//                         Padding(
//                           padding: EdgeInsets.all(6.0),
//                           child: Text("Recharging battery"),
//                         ),
//                         Padding(padding: EdgeInsets.all(6.0), child: Text("1")),
//                         Padding(
//                           padding: EdgeInsets.all(6.0),
//                           child: Text("400"),
//                         ),
//                         Padding(
//                           padding: EdgeInsets.all(6.0),
//                           child: Text("400"),
//                         ),
//                       ],
//                     ),
//                     TableRow(
//                       children: [
//                         Padding(
//                           padding: EdgeInsets.all(6.0),
//                           child: Text("2."),
//                         ),
//                         Padding(
//                           padding: EdgeInsets.all(6.0),
//                           child: Text("Horn"),
//                         ),
//                         Padding(padding: EdgeInsets.all(6.0), child: Text("1")),
//                         Padding(
//                           padding: EdgeInsets.all(6.0),
//                           child: Text("1880"),
//                         ),
//                         Padding(
//                           padding: EdgeInsets.all(6.0),
//                           child: Text("1880"),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 20),

//                 // Totals box
//                 Align(
//                   alignment: Alignment.centerRight,
//                   child: Container(
//                     width: 180,
//                     padding: const EdgeInsets.all(8.0),
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.black, width: 1),
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     child: const Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text("Sub Total : 2280.00"),
//                         Text("VAT (5%) : 114.00"),
//                         Text("Discount : 0.00"),
//                         Divider(),
//                         Text(
//                           "Total : 2394.00",
//                           style: TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),

//                 const SizedBox(height: 25),

//                 // Bottom Button
//                 SizedBox(
//                   width: double.infinity,
//                   child: Container(
//                     decoration: BoxDecoration(
//                       gradient: const LinearGradient(
//                         colors: [Color(0xFF0066A6), Color(0xFF00BFA6)],
//                       ),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         elevation: 0,
//                         backgroundColor: Colors.transparent,
//                         shadowColor: Colors.transparent,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                       ),
//                       onPressed: () {
//                         context.go('/quotation');
//                       },
//                       child: const Text(
//                         "CLOSE",
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
