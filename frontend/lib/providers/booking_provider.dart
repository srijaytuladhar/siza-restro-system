import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_model.dart';
import 'api_providers.dart';

class BookingState {
  final BookingModel? activeBooking;
  final String userId;
  final bool isLoading;
  final String? errorMessage;

  BookingState({
    this.activeBooking,
    required this.userId,
    this.isLoading = false,
    this.errorMessage,
  });

  BookingState copyWith({
    BookingModel? activeBooking,
    bool clearActiveBooking = false,
    String? userId,
    bool? isLoading,
    String? errorMessage,
  }) {
    return BookingState(
      activeBooking: clearActiveBooking ? null : (activeBooking ?? this.activeBooking),
      userId: userId ?? this.userId,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class BookingNotifier extends StateNotifier<BookingState> {
  final Ref _ref;

  BookingNotifier(this._ref)
      : super(BookingState(userId: _generateGuestId())) {
    // Optionally recover booking if needed
  }

  static String _generateGuestId() {
    final rand = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'guest_${timestamp}_${rand.nextInt(10000)}';
  }

  Future<void> scanAndBookTable(String qrCodeToken) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final apiService = _ref.read(apiServiceProvider);
      final booking = await apiService.scanAndBook(qrCodeToken, state.userId);
      state = state.copyWith(activeBooking: booking, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> closeActiveBooking() async {
    final active = state.activeBooking;
    if (active == null) return;
    
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final apiService = _ref.read(apiServiceProvider);
      await apiService.closeBooking(active.id);
      state = state.copyWith(clearActiveBooking: true, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void reset() {
    state = BookingState(userId: _generateGuestId());
  }
}

final bookingProvider = StateNotifierProvider<BookingNotifier, BookingState>((ref) {
  return BookingNotifier(ref);
});
