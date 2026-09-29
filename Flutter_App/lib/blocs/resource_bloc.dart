import 'dart:async';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Immutable state shared by read-only queries and submitted commands.
class ResourceState<T> {
  final T? data;
  final Object? error;
  final bool isLoading;
  final bool succeeded;
  const ResourceState(
      {this.data, this.error, this.isLoading = false, this.succeeded = false});
  bool get hasError => error != null;
}

class ResourceRequested {
  final Completer<void>? completion;
  const ResourceRequested([this.completion]);
}

/// Owns the subscription. Reload cancels the old source; closing cancels it too.
class ResourceBloc<T> extends Bloc<ResourceRequested, ResourceState<T>> {
  final Stream<T> Function() source;
  ResourceBloc(this.source) : super(ResourceState<T>(isLoading: true)) {
    on<ResourceRequested>((event, emit) async {
      emit(ResourceState<T>(isLoading: true));
      try {
        await emit.forEach<T>(source(), onData: (value) {
          if (event.completion?.isCompleted == false) {
            event.completion!.complete();
          }
          return ResourceState<T>(data: value, succeeded: true);
        }, onError: (error, stack) {
          if (event.completion?.isCompleted == false) {
            event.completion!.complete();
          }
          return ResourceState<T>(error: error);
        });
        if (!emit.isDone && state.isLoading) {
          emit(ResourceState<T>(succeeded: true));
        }
      } catch (error) {
        if (!emit.isDone) emit(ResourceState<T>(error: error));
      } finally {
        if (event.completion?.isCompleted == false) {
          event.completion!.complete();
        }
      }
    }, transformer: restartable());
  }
  Future<void> refresh() {
    if (isClosed) return Future.value();
    final completion = Completer<void>();
    add(ResourceRequested(completion));
    return completion.future;
  }
}

class ActionRequested<I> {
  final I input;
  const ActionRequested(this.input);
}

/// A command has one owner and cannot be submitted twice while in flight.
class ActionBloc<I, O> extends Bloc<ActionRequested<I>, ResourceState<O>> {
  ActionBloc(Future<O> Function(I) execute) : super(ResourceState<O>()) {
    on<ActionRequested<I>>((event, emit) async {
      emit(ResourceState<O>(isLoading: true));
      try {
        final result = await execute(event.input);
        if (!emit.isDone) emit(ResourceState<O>(data: result, succeeded: true));
      } catch (error) {
        if (!emit.isDone) emit(ResourceState<O>(error: error));
      }
    }, transformer: droppable());
  }
}

class SelectionChanged<T> {
  final T value;
  const SelectionChanged(this.value);
}

class SelectionBloc<T> extends Bloc<SelectionChanged<T>, T> {
  SelectionBloc(super.initialState) {
    on<SelectionChanged<T>>((event, emit) => emit(event.value));
  }
}
