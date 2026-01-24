// lib/features/test/util/state_machine.dart

/// Simple finite‑state‑machine validation helper.
///
/// Usage:
///   validateTransition(current, allowedPrevious, target);
/// Throws [InvalidTransitionException] if the transition is illegal.

class InvalidTransitionException implements Exception {
  final String message;
  InvalidTransitionException(this.message);

  @override
  String toString() => "InvalidTransitionException: $message";
}

/// Validates that a transition from [current] to [target] is allowed.
///
/// * [allowedPrevious] – list of states from which the transition is permitted.
/// * Throws [InvalidTransitionException] if not allowed.
void validateTransition<T>(
  T current,
  List<T> allowedPrevious,
  T target,
) {
  if (!allowedPrevious.contains(current)) {
    throw InvalidTransitionException(
        "Cannot transition from $current to $target");
  }
}
