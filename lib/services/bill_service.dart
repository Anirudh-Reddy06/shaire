import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

class BillService {
  final String baseUrl = "https://shaire-bill-extraction-api.onrender.com";
  
  Future<Map<String, dynamic>> extractBillInfo(File imageFile) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/extract_bill'));
      
      // Add the image file to the request
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      ));
      
      // Send the request
      var response = await request.send();
      
      // Get the response
      var responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        return json.decode(responseData);
      } else {
        throw Exception('Failed to extract bill info: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error extracting bill info: $e');
    }
  }
  
  // Health check to verify server is running
  Future<bool> checkServerHealth() async {
    try {
      print('Checking server health at: ${Uri.parse('$baseUrl/health')}');
      final response = await http.get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 10)); // Add timeout
      print('Server health response: ${response.statusCode}, Body: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('Server health check failed with error: $e');
      return false;
    }
  }
}