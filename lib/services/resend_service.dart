import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ResendService {
  static const String _apiEndpoint = 'https://api.resend.com/emails';
  
  Future<bool> sendGemShareEmail({
    required String toEmail,
    required String gemUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_apiEndpoint),
        headers: {
          'Authorization': 'Bearer ${dotenv.env['RESEND_API_KEY']}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': 'TokTok <share@breeze.help>',
          'to': [toEmail],
          'subject': 'Your video is ready to view',
          'html': '''
            <div style="
              font-family: Arial, sans-serif;
              max-width: 600px;
              margin: 0 auto;
              padding: 20px;
              background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
              color: #ffffff;
              border-radius: 15px;
              box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            ">
              <h1 style="
                color: #4a90e2;
                text-align: center;
                font-size: 24px;
                margin-bottom: 20px;
              ">Your breeze.help video is ready</h1>
              
              <p style="
                text-align: center;
                font-size: 16px;
                line-height: 1.6;
                margin-bottom: 30px;
              ">
                Someone has shared a video with you via breeze.help.
                Click below to view it!
              </p>
              
              <div style="text-align: center;">
                <a href="$gemUrl" style="
                  display: inline-block;
                  background: linear-gradient(135deg, #4a90e2 0%, #357abd 100%);
                  color: white;
                  text-decoration: none;
                  padding: 12px 24px;
                  border-radius: 25px;
                  font-weight: bold;
                  margin: 20px 0;
                  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
                ">View Video</a>
              </div>
              
              <p style="
                text-align: center;
                font-size: 14px;
                color: #888888;
                margin-top: 30px;
              ">
                Shared via breeze.help
              </p>
            </div>
          ''',
        }),
      );
      
      if (response.statusCode == 200) {
        return true;
      } else {
        print('❌ Resend API error: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending email: $e');
      return false;
    }
  }
} 