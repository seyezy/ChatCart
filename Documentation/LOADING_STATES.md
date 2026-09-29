# Shimmer loading states

Flutter uses `ShimmerLoader` in `lib/widgets/shimmer_loader.dart` for Bloc query
loading states. Skeleton layouts cover chat lists, conversations, marketplace
grids, product details, profiles, checkout/verification forms, orders, support
tickets, announcements and devices. Use `inline: true` inside an existing
scroll view. The widget supports light/dark themes, announces “Loading content”
to screen readers, stops its animation offscreen, and respects reduced motion.
Animation controllers handle presentation only; Blocs still own loading state.
Action buttons retain compact progress indicators while submitting commands.

The Laravel admin shares `admin/loading.blade.php` and the two
`public/assets/admin-loading.*` assets. Same-window navigation and form
submissions show a page skeleton. The dashboard's Refresh button temporarily
replaces its figures with shimmer while requesting JSON from the existing,
authenticated `/admin` route. Failed requests restore the previous figures and
show a retry message. No artificial delay is added, and server-rendered figures
remain available without JavaScript. Reduced-motion preferences disable CSS
animation; browser back navigation resets pending loading UI.

Verification: Flutter layout/reduced-motion tests are in
`Flutter_App/test/shimmer_loader_test.dart`. Local admin integration and
JavaScript lifecycle checks are `.local/check-admin-shimmer.ps1` and
`.local/check-admin-loading.cjs`; the integration check reads existing local
demo credentials without printing them.
