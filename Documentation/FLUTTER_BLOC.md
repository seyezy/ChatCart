# Flutter state management

ChatCart uses event-based Bloc (`flutter_bloc`) for application and UI state.
The development, staging, and production entry points all bootstrap the same
providers in `Flutter_App/lib/app.dart`; flavor selection remains in the entry
points and `AppConfig`.

## Ownership

| Bloc | Responsibility | Lifetime |
| --- | --- | --- |
| `SessionBloc` | Firebase user, theme, sign-out, lifecycle-triggered presence/device registration | App |
| `PhoneAuthBloc` | Phone validation, code request, OTP verification and errors | App; shared by phone and OTP routes |
| `ChatActionsBloc` | Open a direct conversation, optionally send a product enquiry | App |
| `ConversationBloc` | Messages, read receipts, send/upload status and typing commands | Conversation route |
| `CheckoutBloc` | Quantity, payment, validation and order submission | Checkout route |
| `KycBloc` | Verification status, document selection, uploads and submission | Verification route |
| `ResourceBloc<T>` | Query loading/data/errors and refresh | Query widget or route |
| `ActionBloc<Input, Output>` | Report, support-ticket and device-revocation commands | Form or route |
| `SelectionBloc<T>` | Onboarding page, marketplace category and form selections | Widget or form |

Widgets dispatch events and render with `BlocBuilder`/`BlocConsumer`.
Navigation, dialogs and snackbars run in listeners. Stateful widgets retain
only lifecycle-owned objects such as text controllers, focus nodes and Blocs;
they do not call `setState` to manage application state.

Repositories and Firebase services remain the data layer. Their streams are
consumed by Blocs. Service subscriptions for Firebase connectivity and token
refresh remain infrastructure concerns.

## Queries and commands

Use `ResourceView<T>` with a `sourceKey` containing the query's inputs, including
the user ID for account-specific data. Rebuilding its parent does not restart
the request. Changing the key replaces and closes the old Bloc. Refresh cancels
the previous subscription, preventing stale responses from overwriting new data.

Commands use `droppable()` to reject duplicate submissions while work is in
flight. Closing a Bloc suppresses late UI emissions; it does not undo a request
already received by Firebase or Laravel. Checkout also retains its successful
order and rejects repeat submissions for that route.

Session user changes are emitted independently of optional presence/device
work. An unavailable Realtime Database therefore does not delay the UI's login
or logout state. Optional service work is serialized and bounded by timeouts.

When adding features, keep asynchronous mutations in a feature Bloc or an
`ActionBloc`, give subscriptions a clear owner, and close locally owned Blocs
in `dispose`. Use immutable events and state. Do not introduce Provider,
Riverpod, GetX, `setState`, `StreamBuilder`, or `FutureBuilder` as an additional
application state-management approach. `provider` may appear transitively in
the dependency lockfile because `flutter_bloc` uses it internally.

## Verification

Run from `Flutter_App` with the project's Flutter SDK:

```powershell
flutter test
flutter analyze
flutter build apk --debug --flavor development -t lib/main_development.dart --target-platform android-x64
```

Tests cover request cancellation, stale futures, duplicate commands, errors and
retry, phone/OTP validation, checkout snapshots, widget subscription lifetime,
and session responsiveness when optional services stall. These tests use fake
callbacks and do not create cloud accounts or orders.
