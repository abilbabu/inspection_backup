import 'package:flutter_test/flutter_test.dart';
import 'package:inspection/utils/bodyshop_referral_helper.dart';

void main() {
  group('BodyShopReferralHelper.submittedMessage', () {
    test('signature + NO -> customer PDF only', () {
      final m = BodyShopReferralHelper.submittedMessage(
          'Done.', BodyShopReferralDecision.no,
          customerSigned: true);
      expect(m, contains('Basic Inspection PDF is being sent to the customer'));
      expect(m, isNot(contains('Body Shop')));
    });

    test('no signature + NO -> customer link only', () {
      final m = BodyShopReferralHelper.submittedMessage(
          'Done.', BodyShopReferralDecision.no,
          customerSigned: false);
      expect(m, contains('signature link is being sent to the customer'));
      expect(m, isNot(contains('Body Shop')));
    });

    test('no signature + YES -> link to customer, PDF to body shop contact', () {
      final m = BodyShopReferralHelper.submittedMessage(
          'Done.', BodyShopReferralDecision.yes('Ali'),
          customerSigned: false);
      expect(m, contains('signature link is being sent to the customer'));
      expect(m, contains('PDF is being sent to Ali'));
    });

    test('not asked (non SA/Admin) -> customer message only', () {
      final m = BodyShopReferralHelper.submittedMessage(
          'Done.', BodyShopReferralDecision.notAsked,
          customerSigned: true);
      expect(m, startsWith('Done. '));
      expect(m, isNot(contains('Body Shop')));
    });

    test('never claims delivery', () {
      for (final signed in [true, false]) {
        final m = BodyShopReferralHelper.submittedMessage(
            'Done.', BodyShopReferralDecision.yes(null),
            customerSigned: signed);
        expect(m.toLowerCase(), isNot(contains('delivered')));
        expect(m, contains('the primary Body Shop contact'));
      }
    });
  });
}
