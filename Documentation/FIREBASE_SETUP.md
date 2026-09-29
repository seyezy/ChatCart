# Firebase Setup per Flavor

Create three Firebase projects or three isolated Firebase app configurations. Separate Firebase projects are recommended for clean development/staging/production isolation.

For each environment enable:
- Firebase Authentication (Phone; optionally email/social providers)
- Cloud Firestore for realtime chat
- Realtime Database for presence and typing
- Firebase Storage for chat/KYC media
- Firebase Cloud Messaging

Copy public Firebase client values into the matching Flutter `.env` file. Place the matching Firebase service-account JSON on the Laravel server and reference its absolute path in the server `.env`.

Suggested FCM topics:
- `chatcart-development`
- `chatcart-staging`
- `chatcart-production`

Deploy the supplied Firebase rules from `Flutter_App/` after checking the selected Firebase project.
