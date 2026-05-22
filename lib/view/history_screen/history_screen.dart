import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inspection/view/global_widgets/customAppBar.dart';
import 'package:flutter/services.dart';

class HistoryScreenList extends StatefulWidget {
  const HistoryScreenList({super.key});

  @override
  State<HistoryScreenList> createState() => HistoryScreenListState();
}

class HistoryScreenListState extends State<HistoryScreenList> {
  bool noHistory = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {});
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        statusBarColor: Colors.white,
        systemNavigationBarColor: Colors.white,
      ),
      child: WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          appBar: CustomAppBar(title: 'History List', onBackPress: null),
          body: Column(
            children: <Widget>[
              Expanded(
                child: noHistory
                    ? ListView.builder(
                        scrollDirection: Axis.vertical,
                        padding: const EdgeInsets.only(top: 16, bottom: 16),
                        itemCount: 1,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              context.go('/historydetailspage');
                            },
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.all(12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          blurRadius: 12,
                                          color: Colors.blue.withOpacity(.9),
                                          spreadRadius: 0,
                                          blurStyle: BlurStyle.outer,
                                          offset: const Offset(0, 0),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.all(8.0),
                                    padding: const EdgeInsets.all(4.0),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.white,
                                          blurRadius: 0.1,
                                          spreadRadius: 0,
                                        ),
                                      ],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.withOpacity(0.19),
                                      ),
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        Expanded(
                                          flex: 2,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            margin: const EdgeInsets.only(
                                              right: 16,
                                            ),
                                            child: Image.asset(
                                              "assets/image/benz.png",
                                              height: 120,
                                              width: 80,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 4,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: const <Widget>[
                                              Text(
                                                "Job Card No: JC-2025-10-467",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                "Date: 13-Nov-2025",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                "Time: 11:25 AM",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: noHistoryCard(),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// -----------------------------
  /// NO QUOTATION CARD (Empty State)
  /// -----------------------------
  Widget noHistoryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            color: Colors.blue.withOpacity(.3),
            blurStyle: BlurStyle.outer,
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.receipt_long, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            "No History List",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            "There are no history available at the moment.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
