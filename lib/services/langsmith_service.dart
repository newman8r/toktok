import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:math' as math;

class LangSmithService {
  static final String _apiKey = dotenv.env['LANGCHAIN_API_KEY'] ?? '';
  static final String _endpoint = dotenv.env['LANGCHAIN_ENDPOINT'] ?? 'https://api.smith.langchain.com';
  static final String _project = dotenv.env['LANGCHAIN_PROJECT'] ?? 'toktok-gen-calls';
  static final bool _tracingEnabled = dotenv.env['LANGCHAIN_TRACING_V2']?.toLowerCase() == 'true';
  static String? _sessionId;

  // Initialize service and create project if needed
  Future<void> initialize() async {
    if (!_tracingEnabled) return;

    try {
      final headers = {
        'x-api-key': _apiKey,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // First try to create the project
      final createResponse = await http.post(
        Uri.parse('$_endpoint/projects'),
        headers: headers,
        body: jsonEncode({
          'name': _project,
          'description': 'TokTok app generative AI traces',
        }),
      );

      // 201 = Created, 409 = Already exists, both are fine
      if (createResponse.statusCode == 201) {
        print('✅ Created LangSmith project: $_project');
      } else if (createResponse.statusCode == 409) {
        print('ℹ️ LangSmith project already exists: $_project');
      } else {
        print('⚠️ Unexpected response creating project: ${createResponse.statusCode} - ${createResponse.body}');
      }

      // Create a new session
      final sessionResponse = await http.post(
        Uri.parse('$_endpoint/sessions'),
        headers: headers,
        body: jsonEncode({
          'name': 'TokTok Flutter Session',
          'project_name': _project,
          'description': 'Generative AI session for TokTok app',
        }),
      );

      if (sessionResponse.statusCode == 201) {
        final sessionData = jsonDecode(sessionResponse.body);
        _sessionId = sessionData['id'];
        print('✅ Created LangSmith session: $_sessionId');
      } else {
        print('⚠️ Failed to create session: ${sessionResponse.statusCode} - ${sessionResponse.body}');
      }
    } catch (e) {
      print('⚠️ Error initializing LangSmith service: $e');
    }
  }

  // Start a new run/trace
  Future<String> startRun({
    required String name,
    required String runType,
    Map<String, dynamic>? inputs,
  }) async {
    if (!_tracingEnabled) {
      print('⚠️ LangSmith tracing is disabled. Set LANGCHAIN_TRACING_V2=true to enable.');
      return '';
    }

    try {
      final headers = {
        'x-api-key': _apiKey,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Generate IDs
      final runId = _generateUuid();
      final startTime = DateTime.now().toIso8601String();
      
      // Format the timestamp for dotted_order (YYYYMMDDTHHmmssfffZ)
      final formattedTime = startTime
          .replaceAll(RegExp(r'[-:]'), '')  // Remove dashes and colons
          .replaceAll(RegExp(r'\.'), '')    // Remove all periods
          .split('+')[0]                    // Remove timezone offset
          .split('Z')[0];                   // Remove Z if present
      
      // Ensure exactly 6 digits for microseconds by padding with zeros
      final microsStr = startTime.split('.')[1].split('Z')[0].padRight(6, '0').substring(0, 6);
      final finalTime = '${formattedTime}$microsStr';
      
      final dottedOrder = '${finalTime}Z$runId';

      final body = {
        'id': runId,  // Add explicit run ID
        'name': name,
        'run_type': runType,
        'session_id': _sessionId,
        'project_name': _project,
        'trace_id': runId,  // Use same ID for trace_id
        'dotted_order': dottedOrder,
        'inputs': inputs ?? {},
        'start_time': startTime,
        'execution_order': 1,
        'serialized': {
          'name': name,
          'project_name': _project,
        },
        'extra': {
          'runtime': 'flutter',
          'project_name': _project,
          'session_name': 'TokTok Flutter Session',
        },
        'tags': ['flutter', _project],
      };

      print('🔐 LangSmith API Key: ${_apiKey.substring(0, 10)}... (${_apiKey.length} chars)');
      print('🌐 LangSmith Endpoint: $_endpoint');
      print('📦 Project: $_project');
      print('🎫 Session ID: $_sessionId');
      print('🔍 Trace ID: $runId');
      print('📤 Request Headers: $headers');
      print('📤 Request Body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse('$_endpoint/runs'),
        headers: headers,
        body: jsonEncode(body),
      );

      print('📥 Response Status Code: ${response.statusCode}');
      print('📥 Response Headers: ${response.headers}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 202) {
        // Use the trace ID as the run ID since we generated it
        print('✅ Using trace ID as run ID: $runId');
        return runId;
      } else {
        print('❌ Failed to start LangSmith run: ${response.body}');
        return '';
      }
    } catch (e) {
      print('❌ Error starting LangSmith run: $e');
      return '';
    }
  }

  // Helper method to generate a UUID v4
  String _generateUuid() {
    final random = math.Random();
    final List<int> bytes = List<int>.generate(16, (i) {
      if (i == 6) {
        return (random.nextInt(16) & 0x0F) | 0x40; // Version 4
      } else if (i == 8) {
        return (random.nextInt(16) & 0x3F) | 0x80; // Variant 1
      }
      return random.nextInt(256);
    });

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  // Update a run with its completion status and outputs
  Future<void> updateRun({
    required String runId,
    required bool isError,
    Map<String, dynamic>? outputs,
    String? errorMessage,
  }) async {
    if (!_tracingEnabled || runId.isEmpty) return;

    try {
      final headers = {
        'x-api-key': _apiKey,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final body = {
        'end_time': DateTime.now().toIso8601String(),
        'error': isError ? errorMessage : null,
        'outputs': outputs,
        'status': isError ? 'error' : 'completed',
        'project_name': _project,
      };

      print('📤 Update Request Headers: $headers');
      print('📤 Update Request Body: ${jsonEncode(body)}');

      final response = await http.patch(
        Uri.parse('$_endpoint/runs/$runId'),
        headers: headers,
        body: jsonEncode(body),
      );

      print('📥 Update Response Status Code: ${response.statusCode}');
      print('📥 Update Response Headers: ${response.headers}');
      print('📥 Update Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 202) {
        print('✅ Successfully updated run: $runId');
      } else {
        print('❌ Failed to update LangSmith run: ${response.body}');
      }
    } catch (e) {
      print('❌ Error updating LangSmith run: $e');
    }
  }

  // Helper method to wrap an async operation with LangSmith tracing
  Future<T> traceAsync<T>({
    required String name,
    required String runType,
    required Future<T> Function() operation,
    Map<String, dynamic>? inputs,
  }) async {
    final runId = await startRun(
      name: name,
      runType: runType,
      inputs: inputs,
    );

    try {
      final result = await operation();
      
      if (runId.isNotEmpty) {
        await updateRun(
          runId: runId,
          isError: false,
          outputs: {
            'output': result,
            'project': _project,
          },
        );
      }

      return result;
    } catch (e) {
      if (runId.isNotEmpty) {
        await updateRun(
          runId: runId,
          isError: true,
          errorMessage: e.toString(),
        );
      }
      rethrow;
    }
  }
} 