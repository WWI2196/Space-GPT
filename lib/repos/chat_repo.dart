import 'package:dio/dio.dart';
import 'package:space_gpt/model/chat_messgae_model.dart';
import 'package:space_gpt/utils/constants.dart';
import 'dart:developer';

class ChatRepository {
  static Future<ChatMessageModel?> chatTextgenerationRepo(List<ChatMessageModel> previousMessages) async {
    try {
      Dio dio = Dio();
      
      // Configure Dio
      dio.options.headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await dio.post(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=${apiKey}",
        data: {
          "contents": previousMessages.map((e) => e.toMap()).toList(),
          "generationConfig": {
            "temperature": 0.9,
            "topK": 40,
            "topP": 0.95,
            "maxOutputTokens": 8192,
            "responseMimeType": "text/plain"
          }
        },
      );

      if (response.statusCode == 200) {
        final content = response.data['candidates'][0]['content'];
        return ChatMessageModel(
          role: "model",
          parts: [ChatPartModel(text: content['parts'][0]['text'])]
        );
      }
      return null;

    } on DioException catch (e) {
      log('Dio error: ${e.message}');
      if (e.type == DioExceptionType.connectionTimeout) {
        log('Connection timeout');
      }
      return null;
    } catch (e) {
      log('General error: ${e.toString()}');
      return null;
    }
  }
}