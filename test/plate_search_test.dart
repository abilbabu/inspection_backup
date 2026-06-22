import 'package:flutter_test/flutter_test.dart';
import 'package:inspection/controller/customerDetails_controller.dart';

void main() {
  test('Plate suggestion sorting priority - numeric query', () {
    final controller = CustomerDetailsController();
    
    // Set dummy data to test
    controller.regNoSuggestions = [
      '23345',
      '24533',
      '334',
      '2334',
    ];

    // Filter by query "33"
    final results = controller.filterPlateSuggestions('33');

    // Expected order:
    // 1. 334 (Starts with 33)
    // 2. 2334 (Ends with 334 / contains 33 at index 1)
    // 3. 23345 (Contains 33 at index 1, but length is larger)
    // 4. 24533 (Contains 33 at index 3 / ends with 33)
    expect(results, [
      '334',
      '2334',
      '23345',
      '24533',
    ]);
  });

  test('Plate suggestion sorting priority - letter queries', () {
    final controller = CustomerDetailsController();

    controller.regNoSuggestions = [
      'DXB A 7852',
      'AUH A 1233',
      'RRR G 334',
      '90673-R7',
      '777-R',
    ];

    // Search 'AU' -> AUH A 1233
    expect(controller.filterPlateSuggestions('AU'), [
      'AUH A 1233',
    ]);

    // Search 'DX' -> DXB A 7852
    expect(controller.filterPlateSuggestions('DX'), [
      'DXB A 7852',
    ]);

    // Search ' G 3' -> RRR G 334
    expect(controller.filterPlateSuggestions(' G 3'), [
      'RRR G 334',
    ]);

    // Search 'R7' -> 90673-R7
    expect(controller.filterPlateSuggestions('R7'), [
      '90673-R7',
    ]);

    // Search '-R' -> 777-R, 90673-R7
    expect(controller.filterPlateSuggestions('-R'), [
      '777-R',
      '90673-R7',
    ]);
  });

  test('Plate suggestion empty results - placeholder output', () {
    final controller = CustomerDetailsController();

    controller.regNoSuggestions = [
      'DXB A 7852',
      'AUH A 1233',
    ];

    // Case 1: matches empty, isSearching is true -> returns ["Loading..."]
    controller.isSearching = true;
    expect(controller.filterPlateSuggestions('RRR'), ['Loading...']);

    // Case 2: matches empty, isSearching is false -> returns ["No Data Found"]
    controller.isSearching = false;
    expect(controller.filterPlateSuggestions('RRR'), ['No Data Found']);
  });

  test('Customer vehicles dropdown filtering and empty text restoration', () {
    final controller = CustomerDetailsController();

    // Mock initial load of existing customer vehicles
    final vehicles = [
      {"vId": 1, "vRegNo": "DXB A 7852"},
      {"vId": 2, "vRegNo": "AUH A 1233"},
    ];
    controller.allCustomerVehicles = List.from(vehicles);
    controller.filteredVehicles = List.from(vehicles);

    // Initial state: shows all
    expect(controller.filteredVehicles.length, 2);

    // Type query "12" -> filters to matching
    controller.vehiclePlateController.text = "12";
    expect(controller.filteredVehicles.length, 1);
    expect(controller.filteredVehicles.first["vRegNo"], "AUH A 1233");

    // Backspace to empty -> restores all
    controller.vehiclePlateController.text = "";
    expect(controller.filteredVehicles.length, 2);
  });

  test('Plate suggestion sorting priority and normalization - Issue 1 & 2', () {
    final controller = CustomerDetailsController();

    controller.regNoSuggestions = [
      'AUH 1 2842',
      'DXB A 2842',
      'AUH 12842',
      '2842-R7',
      '1232842',
      '28421',
      '92842',
    ];

    // Search for "2842" should return all of them containing 2842 in their normalized digits
    final results = controller.filterPlateSuggestions('2842');
    expect(results.contains('AUH 1 2842'), isTrue);
    expect(results.contains('DXB A 2842'), isTrue);
    expect(results.contains('AUH 12842'), isTrue);
    expect(results.contains('2842-R7'), isTrue);
    expect(results.contains('1232842'), isTrue);
    expect(results.contains('28421'), isTrue);
    expect(results.contains('92842'), isTrue);

    // Search ignoring spaces, hyphens, and separators
    // AUH12842 -> should match AUH 1 2842, AUH 12842
    final match1 = controller.filterPlateSuggestions('AUH12842');
    expect(match1.contains('AUH 1 2842'), isTrue);
    expect(match1.contains('AUH 12842'), isTrue);

    // AUH-1-2842 -> should match AUH 1 2842, AUH 12842
    final match2 = controller.filterPlateSuggestions('AUH-1-2842');
    expect(match2.contains('AUH 1 2842'), isTrue);
    expect(match2.contains('AUH 12842'), isTrue);

    // Additional Requirement matches:
    // Search "2842" -> Match AUH 1 2842
    expect(controller.filterPlateSuggestions('2842').contains('AUH 1 2842'), isTrue);
    // Search "12842" -> Match AUH 1 2842
    expect(controller.filterPlateSuggestions('12842').contains('AUH 1 2842'), isTrue);
    // Search "AUH" -> Match AUH 1 2842
    expect(controller.filterPlateSuggestions('AUH').contains('AUH 1 2842'), isTrue);
    // Search "AUH12842" -> Match AUH 1 2842
    expect(controller.filterPlateSuggestions('AUH12842').contains('AUH 1 2842'), isTrue);
  });
}
