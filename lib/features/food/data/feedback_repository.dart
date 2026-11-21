import 'dart:async';
import 'package:college_canteen/features/food/models/feedback.dart';

abstract interface class FeedbackRepository {
  Future<void> submit(Feedback feedback);
  Stream<List<Feedback>> watchFeedback();
  Feedback? forOrder(String orderId);
}

class InMemoryFeedbackRepository implements FeedbackRepository {
  final List<Feedback> _feedbacks = [];
  final StreamController<List<Feedback>> _controller =
      StreamController<List<Feedback>>.broadcast();

  InMemoryFeedbackRepository({List<Feedback>? initialFeedback}) {
    if (initialFeedback != null) {
      _feedbacks.addAll(initialFeedback);
    }
  }

  @override
  Future<void> submit(Feedback feedback) async {
    if (feedback.rating < 1 || feedback.rating > 5) {
      throw ArgumentError.value(
        feedback.rating,
        'rating',
        'Rating must be between 1 and 5',
      );
    }
    if (_feedbacks.any((f) => f.orderId == feedback.orderId)) {
      throw StateError(
        'Feedback has already been submitted for order "${feedback.orderId}"',
      );
    }

    _feedbacks.add(feedback);
    if (!_controller.isClosed) {
      _controller.add(List.unmodifiable(_feedbacks));
    }
  }

  @override
  Stream<List<Feedback>> watchFeedback() async* {
    yield List.unmodifiable(_feedbacks);
    yield* _controller.stream;
  }

  @override
  Feedback? forOrder(String orderId) {
    final index = _feedbacks.indexWhere((f) => f.orderId == orderId);
    return index >= 0 ? _feedbacks[index] : null;
  }

  void dispose() {
    _controller.close();
  }
}
