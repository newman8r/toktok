# Cloudinary Signature Generation Guide 🔐

## Core Rules for Signature Generation

### Parameters to Include/Exclude 🎯

When generating signatures for Cloudinary requests, ALWAYS exclude these parameters:
- `file`
- `cloud_name`
- `resource_type`
- `api_key`

Everything else that's part of your request should be included in the signature.

### Signature Generation Process 📝

1. Create a string with parameters:
   - Include all parameters EXCEPT the excluded ones listed above
   - Add the `timestamp` parameter
   - Sort all parameters alphabetically
   - Join with format: `key=value&key2=value2`
2. Append your API secret to the end of the string
3. Generate SHA-1 hash of the final string

## Working Examples from Our Codebase 💡

### 1. Basic Video Upload (Simple)
```dart
// CORRECT
final paramsToSign = {
  'public_id': pid,
  'timestamp': timestamp.toString(),
};

// INCORRECT - Don't include file
final paramsToSign = {
  'file': videoUrl,  // ❌ Wrong!
  'public_id': pid,
  'timestamp': timestamp.toString(),
};
```

### 2. Video with Transformations (Complex)
```dart
// CORRECT
final paramsToSign = {
  'eager': eagerTransformation,
  'public_id': newPublicId,
  'timestamp': timestamp.toString(),
  'type': 'upload',
};

// INCORRECT - Don't include resource_type
final paramsToSign = {
  'eager': eagerTransformation,
  'public_id': newPublicId,
  'resource_type': 'video',  // ❌ Wrong!
  'timestamp': timestamp.toString(),
  'type': 'upload',
};
```

## Common Pitfalls and Solutions 🚫

### 1. Request vs. Signature Parameters
- **Request Fields**: Include ALL parameters (`file`, `resource_type`, etc.)
- **Signature Generation**: Only include allowed parameters

Example:
```dart
// Signature parameters (LIMITED)
final paramsToSign = {
  'public_id': publicId,
  'timestamp': timestamp.toString(),
  'type': 'upload',
};

// Request fields (COMPLETE)
request.fields.addAll({
  'api_key': _apiKey,
  'file': videoUrl,
  'public_id': publicId,
  'resource_type': 'video',
  'signature': signature,
  'timestamp': timestamp.toString(),
  'type': 'upload',
});
```

### 2. Eager Transformations
When using eager transformations:
- Include the entire transformation string in the signature
- Keep the transformation string exactly the same in both signature and request

```dart
final eagerTransformation = 'c_crop,w_100,h_100';
final paramsToSign = {
  'eager': eagerTransformation,
  'public_id': publicId,
  'timestamp': timestamp.toString(),
};
```

## Why This Is Tricky for LLMs 🤖

1. **Context Sensitivity**
   - Parameters vary between different types of requests
   - Some parameters are request-specific but shouldn't be in signatures
   - Rules about what to include/exclude aren't always obvious from code patterns

2. **Pattern Recognition Limitations**
   - Working examples might include both signature and request code
   - Hard to differentiate between signature parameters and request parameters
   - Similar-looking code can have different requirements

3. **Documentation vs. Implementation**
   - Documentation rules might not be immediately apparent in code
   - Implementation details can vary while still following the same rules
   - Edge cases might not be covered in standard documentation

## Best Practices Checklist ✅

Before implementing any Cloudinary request:

1. **Signature Generation**
   - [ ] Remove excluded parameters (`file`, `cloud_name`, `resource_type`, `api_key`)
   - [ ] Sort parameters alphabetically
   - [ ] Include timestamp
   - [ ] Append API secret at the end

2. **Request Building**
   - [ ] Include ALL necessary parameters in the request
   - [ ] Add resource_type when needed
   - [ ] Include API key
   - [ ] Add file parameter last

3. **Validation**
   - [ ] Double-check signature parameters
   - [ ] Verify transformation strings match in both signature and request
   - [ ] Ensure timestamp is in correct format (Unix timestamp)

## Debugging Tips 🔍

If you get a signature error:

1. Print the string being signed (mask the API secret!)
2. Compare parameters with a working example
3. Check parameter ordering (must be alphabetical)
4. Verify no excluded parameters are in the signature

Example debug code:
```dart
print('Parameters to sign:');
paramsToSign.forEach((key, value) => print('  $key: $value'));
print('String to sign (before secret): ${stringToSign}');
```

## Reference Implementation 📚

See our `_generateSignature` method in `CloudinaryService`:
```dart
String _generateSignature(Map<String, String> params) {
  final sortedParams = params.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));

  final stringToSign = sortedParams
      .map((e) => '${e.key}=${e.value}')
      .join('&') + _apiSecret;

  return crypto.sha1.convert(utf8.encode(stringToSign)).toString();
}
```

Remember: When in doubt, refer to this guide and the working examples in our codebase! 🌟 