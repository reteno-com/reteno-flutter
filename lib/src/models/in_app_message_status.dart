sealed class InAppMessageStatus {}

class InAppShouldBeDisplayed extends InAppMessageStatus {}

class InAppIsDisplayed extends InAppMessageStatus {}

class InAppShouldBeClosed extends InAppMessageStatus {
  InAppShouldBeClosed({required this.action});

  final InAppMessageAction action;
}

class InAppIsClosed extends InAppMessageStatus {
  InAppIsClosed({required this.action});

  final InAppMessageAction action;
}

class InAppReceivedError extends InAppMessageStatus {
  InAppReceivedError({required this.errorMessage});

  final String errorMessage;
}

class InAppMessageAction {
  InAppMessageAction({
    required this.isCloseButtonClicked,
    required this.isButtonClicked,
    required this.isOpenUrlClicked,
  });

  final bool isCloseButtonClicked;
  final bool isButtonClicked;
  final bool isOpenUrlClicked;
}
