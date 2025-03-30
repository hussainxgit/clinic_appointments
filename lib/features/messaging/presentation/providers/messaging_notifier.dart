import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/sms_record.dart';
import '../../services/kwt_sms_service.dart';

class MessagingState {
  final List<SmsRecord> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;

  MessagingState({
    required this.messages,
    this.isLoading = false,
    this.isSending = false,
    this.error,
  });

  MessagingState copyWith({
    List<SmsRecord>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
  }) {
    return MessagingState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error,
    );
  }
}

class MessagingNotifier extends StateNotifier<MessagingState> {
  final KwtSmsService _smsService;

  MessagingNotifier(this._smsService) : super(MessagingState(messages: []));

  Future<void> loadMessages({String? recipient}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _smsService.getMessageHistory(recipient: recipient);

    if (result.isSuccess) {
      state = state.copyWith(messages: result.data, isLoading: false);
    } else {
      state = state.copyWith(error: result.error, isLoading: false);
    }
  }

  Future<bool> sendMessage({
    required String phoneNumber,
    required String message,
    String? sender,
    int? languageCode,
  }) async {
    state = state.copyWith(isSending: true, error: null);

    final result = await _smsService.sendSms(
      phoneNumber: phoneNumber,
      message: message,
      sender: sender,
      languageCode: languageCode,
    );

    state = state.copyWith(isSending: false);

    if (result.isSuccess) {
      // Reload messages to show the sent message
      await loadMessages();
      return true;
    } else {
      state = state.copyWith(error: result.error);
      return false;
    }
  }
}

final messagingProvider =
    StateNotifierProvider<MessagingNotifier, MessagingState>((ref) {
      final smsService = ref.watch(kwtSmsServiceProvider);
      return MessagingNotifier(smsService);
    });
