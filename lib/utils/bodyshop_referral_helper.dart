import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:inspection/apiServices/api_services.dart';
import 'package:inspection/controller/authentication_%20controller.dart';
import 'package:inspection/utils/custom_toast.dart';
import 'package:inspection/view/inspection_screen/widgets/confirm_submission_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Result of the Body Shop referral question asked before a Basic / Quick inspection submit.
class BodyShopReferralDecision {
  /// false = stop, do not submit (dialog dismissed, or YES without a usable primary contact).
  final bool proceed;

  /// Value to send to the backend as `bodyShopReferral`; null when the question was not asked
  /// (user is not a Service Advisor / Admin), so the existing request is unchanged.
  final bool? referral;

  /// Primary contact name when referral is true (for the success message).
  final String? contactName;

  const BodyShopReferralDecision._(this.proceed, this.referral, this.contactName);

  static const notAsked = BodyShopReferralDecision._(true, null, null);
  static const stop = BodyShopReferralDecision._(false, null, null);
  static const no = BodyShopReferralDecision._(true, false, null);
  static BodyShopReferralDecision yes(String? name) =>
      BodyShopReferralDecision._(true, true, name);
}

class BodyShopReferralHelper {
  static const String noPrimaryMessage =
      "No primary Body Shop contact is configured. Please configure a primary contact in General Settings before proceeding with the referral.";

  /// Asks Service Advisors / Admins whether the vehicle goes to the Body Shop.
  /// On YES it verifies that an active primary contact is configured; if not, it shows a warning
  /// and returns [BodyShopReferralDecision.stop] so the user stays on the screen with all
  /// inspection data intact.
  static Future<BodyShopReferralDecision> ask(BuildContext context) async {
    final auth = context.read<AuthenticationController>();
    if (!auth.isDepartmentLoaded) {
      await auth.loadUserDepartment();
    }
    if (!(auth.isAdmin || auth.isServiceAdvisor)) {
      return BodyShopReferralDecision.notAsked;
    }
    if (!context.mounted) return BodyShopReferralDecision.stop;

    final answer = await ConfirmSubmissionDialog.showBodyShopReferral(context);
    if (answer == null) return BodyShopReferralDecision.stop; // dismissed
    if (answer == false) return BodyShopReferralDecision.no;

    final status = await _fetchPrimaryContactStatus();
    if (!context.mounted) return BodyShopReferralDecision.stop;
    if (status == null) {
      CustomToast.showError(context,
          "Could not verify the Body Shop contact. Please check your connection and try again.");
      return BodyShopReferralDecision.stop;
    }
    if (status['configured'] != true) {
      CustomToast.showWarning(
          context, (status['message'] as String?) ?? noPrimaryMessage);
      return BodyShopReferralDecision.stop;
    }
    return BodyShopReferralDecision.yes(status['contactName'] as String?);
  }

  /// How long the combined success message stays visible (it survives navigation).
  static const Duration submittedToastDuration = Duration(seconds: 4);

  /// Message to show after a successful submit. WhatsApp messages are sent by the backend in the
  /// background after the inspection is saved, so this says "being sent", never "delivered".
  ///
  /// [customerSigned]: a customer signature was captured on this screen. The backend re-checks the
  /// saved signature and decides PDF vs. link; this only picks the wording.
  static String submittedMessage(
    String completedText,
    BodyShopReferralDecision d, {
    required bool customerSigned,
  }) {
    final parts = <String>[
      completedText,
      customerSigned
          ? "The Basic Inspection PDF is being sent to the customer on WhatsApp."
          : "A signature link is being sent to the customer on WhatsApp.",
    ];
    if (d.referral == true) {
      final who = (d.contactName == null || d.contactName!.isEmpty)
          ? "the primary Body Shop contact"
          : d.contactName!;
      parts.add("Body Shop referral recorded; the PDF is being sent to $who.");
    }
    return parts.join(" ");
  }

  static Future<Map<String, dynamic>?> _fetchPrimaryContactStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken');
      final response = await http.get(
        Uri.parse(ApiServices.bodyShopPrimaryContactStatus),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body);
      if (body is Map && body['data'] is Map) {
        return Map<String, dynamic>.from(body['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
