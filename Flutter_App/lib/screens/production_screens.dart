import '../widgets/shimmer_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/checkout_bloc.dart';
import '../blocs/kyc_bloc.dart';
import '../blocs/resource_bloc.dart';
import '../blocs/session_bloc.dart';
import '../firebase/chatcart_services.dart';
import '../models/backend_models.dart';
import '../models/chat_models.dart';
import '../services/backend_api_service.dart';
import '../services/device_service.dart';
import '../widgets/resource_view.dart';

final _prodSvc = ChatCartServices.instance;

class CheckoutArgs {
  final String productId;
  const CheckoutArgs(this.productId);
}

typedef ReportDraft = ({String category, String reason});
typedef SupportDraft = ({String subject, String message, String category});

class ReportActions {
  static const categories = <String, String>{
    'spam': 'Spam or scam',
    'harassment': 'Harassment or bullying',
    'hate': 'Hate speech',
    'sexual_content': 'Sexual or inappropriate content',
    'threats': 'Threats or violence',
    'impersonation': 'Impersonation',
    'other': 'Other',
  };
  static Future<void> reportUser(BuildContext context,
          {required String uid, required String name}) =>
      _sheet(context,
          title: 'Report $name',
          submit: (draft) => _prodSvc.backend.reportUser(
              reportedUid: uid,
              category: draft.category,
              reason: draft.reason));
  static Future<void> reportMessage(BuildContext context,
          {required String conversationId, required String messageId}) =>
      _sheet(context,
          title: 'Report message',
          submit: (draft) => _prodSvc.backend.reportMessage(
              conversationId: conversationId,
              messageId: messageId,
              category: draft.category,
              reason: draft.reason));
  static Future<void> _sheet(BuildContext context,
      {required String title,
      required Future<void> Function(ReportDraft) submit}) async {
    final sent = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _ReportSheet(title: title, submit: submit));
    if (sent == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted. Thank you.')));
    }
  }
}

class _ReportSheet extends StatefulWidget {
  final String title;
  final Future<void> Function(ReportDraft) submit;
  const _ReportSheet({required this.title, required this.submit});
  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final reason = TextEditingController();
  final category = SelectionBloc<String>('spam');
  late final submission = ActionBloc<ReportDraft, void>(widget.submit);
  @override
  void dispose() {
    reason.dispose();
    category.close();
    submission.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<ActionBloc<ReportDraft, void>, ResourceState<void>>(
        bloc: submission,
        listener: (context, state) {
          if (state.succeeded) Navigator.pop(context, true);
          if (state.hasError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(_friendly(state.error!))));
          }
        },
        builder: (context, state) => Padding(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, MediaQuery.viewInsetsOf(context).bottom + 24),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text(
                      'Reports are reviewed by ChatCart moderation staff.'),
                  const SizedBox(height: 18),
                  BlocBuilder<SelectionBloc<String>, String>(
                      bloc: category,
                      builder: (context, value) =>
                          DropdownButtonFormField<String>(
                              initialValue: value,
                              decoration:
                                  const InputDecoration(labelText: 'Reason'),
                              items: ReportActions.categories.entries
                                  .map((e) => DropdownMenuItem(
                                      value: e.key, child: Text(e.value)))
                                  .toList(),
                              onChanged: state.isLoading
                                  ? null
                                  : (v) {
                                      if (v != null) {
                                        category.add(SelectionChanged(v));
                                      }
                                    })),
                  const SizedBox(height: 12),
                  TextField(
                      controller: reason,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                          labelText: 'Additional details (optional)')),
                  const SizedBox(height: 18),
                  ElevatedButton(
                      onPressed: state.isLoading
                          ? null
                          : () => submission.add(ActionRequested((
                                category: category.state,
                                reason: reason.text.trim()
                              ))),
                      child: state.isLoading
                          ? const _Busy()
                          : const Text('Submit report')),
                ])),
      );
}

class SellerKycScreen extends StatefulWidget {
  const SellerKycScreen({super.key});
  @override
  State<SellerKycScreen> createState() => _SellerKycScreenState();
}

class _SellerKycScreenState extends State<SellerKycScreen> {
  final legalName = TextEditingController(),
      businessName = TextEditingController();
  final country = TextEditingController(text: 'Nigeria'),
      documentNumber = TextEditingController();
  late final bloc = KycBloc(_prodSvc)..add(KycRequested());
  @override
  void dispose() {
    legalName.dispose();
    businessName.dispose();
    country.dispose();
    documentNumber.dispose();
    bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<KycBloc, KycState>(
        bloc: bloc,
        listener: (context, state) {
          final message =
              state.submitted ? 'KYC submitted for admin review.' : state.error;
          if (message != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(message)));
          }
        },
        builder: (context, state) => Scaffold(
            appBar: AppBar(title: const Text('Seller Verification')),
            body: state.loading
                ? const ShimmerLoader(layout: SkeletonLayout.form)
                : ListView(padding: const EdgeInsets.all(16), children: [
                    if (state.error != null)
                      _ProdError(
                          message: state.error!,
                          retry: () => bloc.add(KycRequested())),
                    if (state.status != null) _StatusCard(state.status!),
                    const Text('Identity details',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    const Text(
                        'Submit accurate details. ChatCart administrators will review the documents before seller verification is granted.'),
                    const SizedBox(height: 20),
                    TextField(
                        controller: legalName,
                        decoration:
                            const InputDecoration(labelText: 'Legal name *')),
                    const SizedBox(height: 12),
                    TextField(
                        controller: businessName,
                        decoration:
                            const InputDecoration(labelText: 'Business name')),
                    const SizedBox(height: 12),
                    TextField(
                        controller: country,
                        decoration:
                            const InputDecoration(labelText: 'Country *')),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                        initialValue: state.documentType,
                        decoration:
                            const InputDecoration(labelText: 'Document type'),
                        items: [
                          'National ID',
                          'Passport',
                          'Driver License',
                          'Business Registration'
                        ]
                            .map((e) =>
                                DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: state.submitting
                            ? null
                            : (v) {
                                if (v != null) {
                                  bloc.add(KycDocumentTypeChanged(v));
                                }
                              }),
                    const SizedBox(height: 12),
                    TextField(
                        controller: documentNumber,
                        decoration: const InputDecoration(
                            labelText: 'Document number *')),
                    const SizedBox(height: 18),
                    _UploadTile(
                        title: 'Identity document',
                        subtitle:
                            state.document?.name ?? 'Upload a clear image',
                        icon: Icons.badge_outlined,
                        onTap: () => bloc.add(KycImagePicked(false))),
                    const SizedBox(height: 10),
                    _UploadTile(
                        title: 'Verification selfie',
                        subtitle: state.selfie?.name ?? 'Take a live selfie',
                        icon: Icons.face_retouching_natural,
                        onTap: () => bloc.add(KycImagePicked(true))),
                    const SizedBox(height: 24),
                    ElevatedButton(
                        onPressed: state.submitting
                            ? null
                            : () => bloc.add(KycSubmitted(
                                legalName: legalName.text,
                                businessName: businessName.text,
                                country: country.text,
                                documentNumber: documentNumber.text)),
                        child: state.submitting
                            ? const _Busy()
                            : const Text('Submit for verification')),
                  ])),
      );
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final address = TextEditingController(), city = TextEditingController();
  final region = TextEditingController(), phone = TextEditingController();
  late final bloc = CheckoutBloc((id, qty, address, payment) => _prodSvc.backend
      .createOrder(
          productId: id,
          quantity: qty,
          deliveryAddress: address,
          paymentMethod: payment));
  @override
  void dispose() {
    address.dispose();
    city.dispose();
    region.dispose();
    phone.dispose();
    bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as CheckoutArgs?;
    if (args == null) {
      return const Scaffold(body: Center(child: Text('No product selected.')));
    }
    return BlocConsumer<CheckoutBloc, CheckoutState>(
      bloc: bloc,
      listener: (context, state) async {
        if (state.error != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.error!)));
        }
        final order = state.order;
        if (order == null) return;
        await showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
                    icon: const Icon(Icons.check_circle,
                        color: Colors.green, size: 48),
                    title: const Text('Order placed'),
                    content: Text(
                        'Order ${order.orderNo} has been created.\nTotal: ${order.formattedTotal}'),
                    actions: [
                      FilledButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Continue'))
                    ]));
        if (context.mounted) Navigator.pushReplacementNamed(context, '/orders');
      },
      builder: (context, state) => ResourceView<MarketplaceProduct?>(
          sourceKey: args.productId,
          source: () => _prodSvc.marketplace.watchProduct(args.productId),
          builder: (context, product) {
            final p = product.data;
            return Scaffold(
                appBar: AppBar(title: const Text('Checkout')),
                body: product.isLoading
                    ? const ShimmerLoader(layout: SkeletonLayout.form)
                    : product.hasError
                        ? _ProdError(
                            message: _friendly(product.error!),
                            retry: () => context
                                .read<ResourceBloc<MarketplaceProduct?>>()
                                .refresh())
                        : p == null
                            ? const Center(
                                child: Text(
                                    'This product is no longer available.'))
                            : ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                    ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: SizedBox(
                                            width: 58,
                                            height: 58,
                                            child: p.imageUrls.isEmpty
                                                ? const Icon(
                                                    Icons.shopping_bag_outlined)
                                                : ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    child: Image.network(
                                                        p.imageUrls.first,
                                                        fit: BoxFit.cover))),
                                        title: Text(p.title,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700)),
                                        subtitle: Text(p.formattedPrice)),
                                    const Divider(height: 32),
                                    const Text('Quantity',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700)),
                                    Row(children: [
                                      IconButton(
                                          onPressed: !state.busy &&
                                                  state.quantity > 1
                                              ? () => bloc.add(QuantityChanged(
                                                  state.quantity - 1))
                                              : null,
                                          icon: const Icon(
                                              Icons.remove_circle_outline)),
                                      Text('${state.quantity}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w800)),
                                      IconButton(
                                          onPressed: !state.busy &&
                                                  state.quantity < 99
                                              ? () => bloc.add(QuantityChanged(
                                                  state.quantity + 1))
                                              : null,
                                          icon: const Icon(
                                              Icons.add_circle_outline))
                                    ]),
                                    const SizedBox(height: 12),
                                    const Text('Delivery address',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 10),
                                    TextField(
                                        controller: address,
                                        decoration: const InputDecoration(
                                            labelText: 'Street address')),
                                    const SizedBox(height: 10),
                                    TextField(
                                        controller: city,
                                        decoration: const InputDecoration(
                                            labelText: 'City')),
                                    const SizedBox(height: 10),
                                    TextField(
                                        controller: region,
                                        decoration: const InputDecoration(
                                            labelText: 'State')),
                                    const SizedBox(height: 10),
                                    TextField(
                                        controller: phone,
                                        keyboardType: TextInputType.phone,
                                        decoration: const InputDecoration(
                                            labelText: 'Delivery phone')),
                                    const SizedBox(height: 18),
                                    const Text('Payment',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700)),
                                    RadioGroup<String>(
                                        groupValue: state.payment,
                                        onChanged: (v) {
                                          if (v != null) {
                                            bloc.add(PaymentChanged(v));
                                          }
                                        },
                                        child: Column(children: [
                                          RadioListTile<String>(
                                              value: 'bank_transfer',
                                              enabled: !state.busy,
                                              title:
                                                  const Text('Bank transfer'),
                                              subtitle: const Text(
                                                  'Payment remains unpaid until confirmed by the backend/payment workflow.')),
                                          RadioListTile<String>(
                                              value: 'pay_on_delivery',
                                              enabled: !state.busy,
                                              title:
                                                  const Text('Pay on delivery'))
                                        ])),
                                    const SizedBox(height: 12),
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Order total',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700)),
                                          Text(
                                              _money(p.price * state.quantity,
                                                  p.currency),
                                              style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w900))
                                        ]),
                                    const SizedBox(height: 18),
                                    ElevatedButton(
                                        onPressed: state.busy ||
                                                state.order != null
                                            ? null
                                            : () =>
                                                bloc.add(OrderSubmitted(p.id, {
                                                  'line1': address.text.trim(),
                                                  'city': city.text.trim(),
                                                  'state': region.text.trim(),
                                                  'phone': phone.text.trim(),
                                                  'country': 'Nigeria'
                                                })),
                                        child: state.busy
                                            ? const _Busy()
                                            : const Text('Place order')),
                                  ]));
          }),
    );
  }
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: ResourceView<List<ChatCartOrder>>(
          sourceKey: context.watch<SessionBloc>().state.user?.uid ?? '',
          source: () => Stream.fromFuture(_prodSvc.backend.myOrders()),
          builder: (context, state) {
            final bloc = context.read<ResourceBloc<List<ChatCartOrder>>>();
            if (state.isLoading) {
              return const ShimmerLoader();
            }
            if (state.hasError) {
              return _ProdError(
                  message: _friendly(state.error!), retry: bloc.refresh);
            }
            final rows = state.data ?? [];
            return RefreshIndicator(
                onRefresh: bloc.refresh,
                child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: rows.isEmpty ? 1 : rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      if (rows.isEmpty) {
                        return const Center(child: Text('No orders yet.'));
                      }
                      final o = rows[i];
                      return Card(
                          child: ListTile(
                              title: Text(o.orderNo,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800)),
                              subtitle: Text(
                                  '${o.orderStatus.replaceAll('_', ' ')} • ${o.paymentStatus.replaceAll('_', ' ')}\n${o.paymentMethod.replaceAll('_', ' ')}'),
                              isThreeLine: true,
                              trailing: Text(o.formattedTotal,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800))));
                    }));
          }));
}

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final subject = TextEditingController(), message = TextEditingController();
  final category = SelectionBloc<String>('general');
  late final tickets = ResourceBloc<List<SupportTicketSummary>>(
      () => Stream.fromFuture(_prodSvc.backend.myTickets()))
    ..add(const ResourceRequested());
  late final submission =
      ActionBloc<SupportDraft, SupportTicketSummary>((draft) {
    if (draft.subject.trim().isEmpty || draft.message.trim().isEmpty) {
      throw StateError('Enter a subject and message.');
    }
    return _prodSvc.backend.createSupportTicket(
        subject: draft.subject.trim(),
        message: draft.message.trim(),
        category: draft.category);
  });
  @override
  void dispose() {
    subject.dispose();
    message.dispose();
    category.close();
    tickets.close();
    submission.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<
          ActionBloc<SupportDraft, SupportTicketSummary>,
          ResourceState<SupportTicketSummary>>(
      bloc: submission,
      listener: (context, state) {
        if (state.hasError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(_friendly(state.error!))));
        }
        if (state.succeeded) {
          subject.clear();
          message.clear();
          tickets.add(const ResourceRequested());
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Ticket ${state.data!.ticketNo} created.')));
        }
      },
      builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Help & Support')),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            const Text('Create a support ticket',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            TextField(
                controller: subject,
                decoration: const InputDecoration(labelText: 'Subject')),
            const SizedBox(height: 10),
            BlocBuilder<SelectionBloc<String>, String>(
                bloc: category,
                builder: (_, value) => DropdownButtonFormField<String>(
                    initialValue: value,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: [
                      'general',
                      'account',
                      'chat',
                      'marketplace',
                      'order',
                      'payment',
                      'safety'
                    ]
                        .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e[0].toUpperCase() + e.substring(1))))
                        .toList(),
                    onChanged: state.isLoading
                        ? null
                        : (v) {
                            if (v != null) category.add(SelectionChanged(v));
                          })),
            const SizedBox(height: 10),
            TextField(
                controller: message,
                minLines: 4,
                maxLines: 7,
                decoration:
                    const InputDecoration(labelText: 'How can we help?')),
            const SizedBox(height: 14),
            ElevatedButton(
                onPressed: state.isLoading
                    ? null
                    : () => submission.add(ActionRequested((
                          subject: subject.text,
                          message: message.text,
                          category: category.state
                        ))),
                child: state.isLoading
                    ? const _Busy()
                    : const Text('Submit ticket')),
            const SizedBox(height: 28),
            const Text('Your tickets',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            BlocBuilder<ResourceBloc<List<SupportTicketSummary>>,
                    ResourceState<List<SupportTicketSummary>>>(
                bloc: tickets,
                builder: (context, state) {
                  if (state.isLoading) {
                    return const ShimmerLoader(inline: true);
                  }
                  if (state.hasError) {
                    return _ProdError(
                        message: _friendly(state.error!),
                        retry: tickets.refresh);
                  }
                  final rows = state.data ?? [];
                  if (rows.isEmpty) {
                    return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text('No support tickets yet.'));
                  }
                  return Column(
                      children: rows
                          .map((t) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.support_agent),
                              title: Text(t.subject),
                              subtitle: Text(
                                  '${t.ticketNo} • ${t.status.replaceAll('_', ' ')}'),
                              trailing: Text(t.priority)))
                          .toList());
                }),
          ])));
}

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: ResourceView<List<ChatCartAnnouncement>>(
          sourceKey: context.watch<SessionBloc>().state.user?.uid ?? '',
          source: () => Stream.fromFuture(_prodSvc.backend.announcements()),
          builder: (context, state) {
            if (state.isLoading) {
              return const ShimmerLoader();
            }
            if (state.hasError) {
              return _ProdError(
                  message: _friendly(state.error!),
                  retry: () => context
                      .read<ResourceBloc<List<ChatCartAnnouncement>>>()
                      .refresh());
            }
            final rows = state.data ?? [];
            if (rows.isEmpty) {
              return const Center(child: Text('No announcements right now.'));
            }
            return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final a = rows[i];
                  return Card(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.title,
                                    style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 8),
                                Text(a.body,
                                    style: const TextStyle(height: 1.45)),
                                const SizedBox(height: 10),
                                Text(a.placement.toUpperCase(),
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary)),
                              ])));
                });
          }));
}

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionBloc>().state.user;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Sign in required.')));
    }
    return BlocProvider(
      create: (_) => ActionBloc<String, void>(_prodSvc.devices.revoke),
      child: ResourceView<List<ChatCartDevice>>(
          sourceKey: user.uid,
          source: () => _prodSvc.devices.watchDevices(user.uid),
          builder: (context, state) =>
              BlocConsumer<ActionBloc<String, void>, ResourceState<void>>(
                listener: (context, action) {
                  if (action.hasError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_friendly(action.error!))));
                  }
                  if (action.succeeded) {
                    context
                        .read<ResourceBloc<List<ChatCartDevice>>>()
                        .add(const ResourceRequested());
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Device revoked.')));
                  }
                },
                builder: (context, action) => Scaffold(
                    appBar: AppBar(title: const Text('Devices & Sessions')),
                    body: state.isLoading
                        ? const ShimmerLoader()
                        : state.hasError
                            ? _ProdError(
                                message: _friendly(state.error!),
                                retry: () => context
                                    .read<ResourceBloc<List<ChatCartDevice>>>()
                                    .refresh())
                            : ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                    const Text('Registered devices',
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 6),
                                    const Text(
                                        'Revoking a device removes its ChatCart push registration. An administrator can also revoke devices from the admin portal.'),
                                    const SizedBox(height: 16),
                                    ...(state.data ?? []).map((d) => Card(
                                        child: ListTile(
                                            leading:
                                                Icon(_deviceIcon(d.platform)),
                                            title: Text(
                                                '${d.platform}${d.current ? ' • This device' : ''}',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w700)),
                                            subtitle: Text(d.revoked
                                                ? 'Revoked'
                                                : 'Active'),
                                            trailing: d.revoked
                                                ? const Icon(Icons.block)
                                                : TextButton(
                                                    onPressed: action.isLoading
                                                        ? null
                                                        : () =>
                                                            _revoke(context, d),
                                                    child: const Text(
                                                        'Revoke'))))),
                                  ])),
              )),
    );
  }

  Future<void> _revoke(BuildContext context, ChatCartDevice device) async {
    final ok = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
                    title: const Text('Revoke device?'),
                    content: Text(device.current
                        ? 'Push notifications will stop on this device.'
                        : 'This device will no longer receive ChatCart push notifications.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('Revoke'))
                    ])) ??
        false;
    if (ok && context.mounted) {
      context.read<ActionBloc<String, void>>().add(ActionRequested(device.id));
    }
  }
}

class _Busy extends StatelessWidget {
  const _Busy();
  @override
  Widget build(BuildContext context) => const SizedBox(
      width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2));
}

class _StatusCard extends StatelessWidget {
  final SellerKycStatus s;
  const _StatusCard(this.s);
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(14)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(s.status == 'verified' ? Icons.verified : Icons.hourglass_top,
            color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Current status: ${s.status.replaceAll('_', ' ')}',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          if (s.rejectionReason?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(s.rejectionReason!)
          ]
        ]))
      ]));
}

class _UploadTile extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const _UploadTile(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Theme.of(context).dividerColor)),
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.upload_file));
}

class _ProdError extends StatelessWidget {
  final String message;
  final VoidCallback retry;
  const _ProdError({required this.message, required this.retry});
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            TextButton(onPressed: retry, child: const Text('Try again'))
          ])));
}

String _friendly(Object e) => e is BackendApiException
    ? e.message
    : e.toString().replaceFirst('Exception: ', '');
String _money(num value, String currency) => currency == 'NGN'
    ? '₦${value.toStringAsFixed(0)}'
    : '$currency ${value.toStringAsFixed(2)}';
IconData _deviceIcon(String p) => p == 'android'
    ? Icons.android
    : p == 'iOS' || p == 'ios'
        ? Icons.phone_iphone
        : Icons.devices;
