import 'package:flutter/material.dart';
import 'package:team_workspace/core/constants/app_strings.dart';
import 'package:team_workspace/core/utils/debouncer.dart';

/// Debounced search field for filtering dashboard tasks by title.
class TaskSearchField extends StatefulWidget {
  const TaskSearchField({
    super.key,
    required this.onChanged,
    this.initialQuery = '',
  });

  final ValueChanged<String> onChanged;
  final String initialQuery;

  @override
  State<TaskSearchField> createState() => _TaskSearchFieldState();
}

class _TaskSearchFieldState extends State<TaskSearchField> {
  late final TextEditingController _controller;
  final Debouncer _debouncer = Debouncer();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {});
    _debouncer.run(() => widget.onChanged(value));
  }

  void _clear() {
    _controller.clear();
    setState(() {});
    _debouncer.cancel();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Semantics(
      label: strings.searchTasksSemantics,
      textField: true,
      child: TextField(
        key: const ValueKey('dashboard-search-field'),
        controller: _controller,
        onChanged: _onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: strings.searchTasksHint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  key: const ValueKey('dashboard-search-clear'),
                  tooltip: strings.clearSearch,
                  onPressed: _clear,
                  icon: const Icon(Icons.clear),
                ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
