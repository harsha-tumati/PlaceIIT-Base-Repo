import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ============================================================================
// 1. MOCK Setup: We generate a mock client to simulate API responses.
// Need to run: flutter pub run build_runner build
// ============================================================================
@GenerateMocks([http.Client])
import 'flutter_unit_test_example.mocks.dart'; 

// ============================================================================
// 2. YOUR FLUTTER API SERVICE: The actual code your app uses logic 
// ============================================================================
class StudentApiService {
  final http.Client client;
  final String baseUrl = 'http://localhost:5000/api/v1';

  StudentApiService(this.client);

  /// Hits POST /api/v1/student/queue/join
  Future<Map<String, dynamic>> joinCompanyQueue(String companyId, String round, String token) async {
    final response = await client.post(
      Uri.parse('$baseUrl/student/queue/join'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'companyId': companyId, 'round': round}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 403) {
      throw Exception('DriveState Locked: Company is not in current active Drive State.');
    } else {
      throw Exception('Failed to join queue: ${response.body}');
    }
  }

  /// Hits GET /api/v1/student/profile
  Future<Map<String, dynamic>> fetchProfile(String token) async {
    final response = await client.get(
      Uri.parse('$baseUrl/student/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load profile');
    }
  }
}

// ============================================================================
// 3. THE FLUTTER UNIT TESTS (What you execute with 'flutter test')
// ============================================================================
void main() {
  group('Student API Service Unit Tests', () {
    late MockClient mockClient;
    late StudentApiService apiService;
    final String stubToken = "fake_jwt_token";

    setUp(() {
      // Runs before every individual test
      mockClient = MockClient();
      apiService = StudentApiService(mockClient);
    });

    test('joinCompanyQueue returns success data when API returns 200', () async {
      // 1. Setup Mock Response
      when(mockClient.post(
        Uri.parse('http://localhost:5000/api/v1/student/queue/join'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('{"message": "Successfully joined queue", "queuePosition": 3}', 200));

      // 2. Execute Code
      final result = await apiService.joinCompanyQueue("comp_123", "Round 1", stubToken);

      // 3. Assert Expectations
      expect(result['message'], 'Successfully joined queue');
      expect(result['queuePosition'], 3);
    });

    test('joinCompanyQueue throws DriveState error if API returns 403', () async {
      // 1. Setup Mock Response simulating Admin Drive State mismatch
      when(mockClient.post(
        Uri.parse('http://localhost:5000/api/v1/student/queue/join'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('{"message": "This company is not in active slot"}', 403));

      // 2 & 3. Execute and Assert Exception
      expect(
        () => apiService.joinCompanyQueue("comp_123", "Round 1", stubToken),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('DriveState Locked'))),
      );
    });

    test('fetchProfile returns decoded JSON when response is 200', () async {
      // 1. Setup mock
      final profileJson = jsonEncode({
        "name": "Harsha",
        "rollNumber": "190110",
        "contact": "9876543210"
      });
      when(mockClient.get(
        Uri.parse('http://localhost:5000/api/v1/student/profile'),
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(profileJson, 200));

      // 2. Execute code
      final profile = await apiService.fetchProfile(stubToken);

      // 3. Assert
      expect(profile['name'], 'Harsha');
      expect(profile['rollNumber'], '190110');
    });
  });
}
