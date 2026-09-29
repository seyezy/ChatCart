import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/resource_bloc.dart';

/// Key the query by its inputs, not by a newly-created stream on each build.
class ResourceView<T> extends StatelessWidget {
  final Object sourceKey;
  final Stream<T> Function() source;
  final Widget Function(BuildContext, ResourceState<T>) builder;
  const ResourceView(
      {super.key,
      required this.sourceKey,
      required this.source,
      required this.builder});

  @override
  Widget build(BuildContext context) => BlocProvider<ResourceBloc<T>>(
        key: ValueKey(sourceKey),
        create: (_) => ResourceBloc<T>(source)..add(const ResourceRequested()),
        child: BlocBuilder<ResourceBloc<T>, ResourceState<T>>(builder: builder),
      );
}
