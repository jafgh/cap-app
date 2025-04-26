const String charset = '0123456789abcdefghijklmnopqrstuvwxyz';
final Map<String, int> char2idx = {
  for (var i = 0; i < charset.length; i++) charset[i]: i
};
final Map<int, String> idx2char = {
  for (var i = 0; i < charset.length; i++) i: charset[i]
};
const int numClasses = charset.length;
const int numPos = 5;

const String onnxModelAssetName = 'assets/models/holako_bag.onnx';

// API Endpoints
const String baseApiUrl = "https://api.ecsc.gov.sy:8443";
const String loginUrl = "$baseApiUrl/secure/auth/login";
const String processListUrl = "$baseApiUrl/dbm/db/execute";
// ... add other URLs
const String processListUrl = "$baseApiUrl/get/captcha";
const String processListUrl = "$baseApiUrl/rs/reserve";
