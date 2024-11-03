import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:space_gpt/model/chat_messgae_model.dart';
import 'package:space_gpt/repos/chat_repo.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final List<ChatMessageModel> messages = [];
  bool generating = false;

  ChatBloc() : super(ChatSuccessState(messages: const [])) {
    on<ChatgenerateNewTextMessageEvent>(chatgenerateNewTextMessageEvent);

  }

  FutureOr<void> chatgenerateNewTextMessageEvent(
    ChatgenerateNewTextMessageEvent event, Emitter<ChatState> emit) async {
      // Add user message
      messages.add(ChatMessageModel(
        role: "user", 
        parts: [ChatPartModel(text: event.inputMessage)]
      ));
      emit(ChatSuccessState(messages: messages));

      generating = true;
      // Get and add model response
      final response = await ChatRepository.chatTextgenerationRepo(messages);
      if (response != null) {
        messages.add(response);
        emit(ChatSuccessState(messages: messages));
      }

      generating = false;
  }
}
