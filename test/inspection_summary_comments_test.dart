import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Inspection Summary Technician Comments Mapping Logic', () {
    String resolveTechnicianComment({
      required int flag,
      required bool hasReinspection,
      required String technicianComment,
      required String previousTechnicianComment,
    }) {
      return flag == 2
          ? (hasReinspection && technicianComment.trim().isNotEmpty
              ? technicianComment
              : "No comments")
          : (previousTechnicianComment.trim().isNotEmpty
              ? previousTechnicianComment
              : (technicianComment.trim().isNotEmpty
                  ? technicianComment
                  : "No comments"));
    }

    test('Re-Inspection Summary (flag == 2) displays re-inspection comments when present', () {
      final comment = resolveTechnicianComment(
        flag: 2,
        hasReinspection: true,
        technicianComment: 'Replaced brake pads and tested rotor',
        previousTechnicianComment: 'Brake pads worn out below 2mm',
      );

      expect(comment, equals('Replaced brake pads and tested rotor'));
    });

    test('Re-Inspection Summary (flag == 2) displays empty state and does NOT fall back to original comments', () {
      final comment = resolveTechnicianComment(
        flag: 2,
        hasReinspection: true,
        technicianComment: '',
        previousTechnicianComment: 'Brake pads worn out below 2mm',
      );

      expect(comment, equals('No comments'));
    });

    test('Re-Inspection Summary (flag == 2) with whitespace-only comment displays empty state', () {
      final comment = resolveTechnicianComment(
        flag: 2,
        hasReinspection: true,
        technicianComment: '   ',
        previousTechnicianComment: 'Brake pads worn out below 2mm',
      );

      expect(comment, equals('No comments'));
    });

    test('Re-Inspection Summary (flag == 2) with hasReinspection == false displays empty state', () {
      final comment = resolveTechnicianComment(
        flag: 2,
        hasReinspection: false,
        technicianComment: 'Brake pads worn out below 2mm',
        previousTechnicianComment: 'Brake pads worn out below 2mm',
      );

      expect(comment, equals('No comments'));
    });

    test('Normal Inspection Summary (flag == 1) preserves original inspection comments when re-inspection exists', () {
      final comment = resolveTechnicianComment(
        flag: 1,
        hasReinspection: true,
        technicianComment: 'Replaced brake pads and tested rotor',
        previousTechnicianComment: 'Brake pads worn out below 2mm',
      );

      expect(comment, equals('Brake pads worn out below 2mm'));
    });

    test('Normal Inspection Summary (flag == 1) preserves original inspection comments when only initial inspection exists', () {
      final comment = resolveTechnicianComment(
        flag: 1,
        hasReinspection: false,
        technicianComment: 'Brake pads worn out below 2mm',
        previousTechnicianComment: 'Brake pads worn out below 2mm',
      );

      expect(comment, equals('Brake pads worn out below 2mm'));
    });

    test('Normal Inspection Summary (flag == 1) handles empty comments appropriately', () {
      final comment = resolveTechnicianComment(
        flag: 1,
        hasReinspection: false,
        technicianComment: '',
        previousTechnicianComment: '',
      );

      expect(comment, equals('No comments'));
    });
  });
}
