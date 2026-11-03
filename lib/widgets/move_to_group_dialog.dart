import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'mode_button.dart';
import 'tv_dialog_option.dart';
import 'tv_text_field_gate.dart';

/// What [showMoveToGroupDialog] picked: the viewer's own group to move the
/// channel into, or null = back to its provider group.
class MoveToGroupChoice {
  const MoveToGroupChoice(this.title);
  final String? title;
}

/// Hold OK on a live channel → "Move to group…" (owner, 2026-10-21): the
/// viewer's own groups, "New group…" (asks for a name), and — once moved —
/// "Back to <provider group>". Null = cancelled.
Future<MoveToGroupChoice?> showMoveToGroupDialog(
  BuildContext context, {
  required String channelName,
  required List<String> userGroups,
  required String currentGroup,
  required String providerGroup,
}) async {
  final moved = currentGroup != providerGroup;
  final choice = await showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(tr('Move {name} to', {'name': channelName}),
          maxLines: 2, overflow: TextOverflow.ellipsis),
      children: [
        for (final g in userGroups)
          TvDialogOption(
            autofocus: true,
            onPressed: () => Navigator.of(context).pop('g:$g'),
            child: Row(children: [
              Expanded(child: Text(g)),
              if (g == currentGroup)
                Icon(Icons.check,
                    size: 18, color: Theme.of(context).colorScheme.primary),
            ]),
          ),
        TvDialogOption(
          onPressed: () => Navigator.of(context).pop('new'),
          child: Row(children: [
            const Icon(Icons.add, size: 18),
            const SizedBox(width: 8),
            Text(tr('New group…')),
          ]),
        ),
        if (moved)
          TvDialogOption(
            onPressed: () => Navigator.of(context).pop('back'),
            child: Text(tr('Back to {group}', {'group': providerGroup})),
          ),
        TvDialogOption(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr('Cancel')),
        ),
      ],
    ),
  );
  if (choice == null || !context.mounted) return null;
  if (choice == 'back') return const MoveToGroupChoice(null);
  if (choice.startsWith('g:')) return MoveToGroupChoice(choice.substring(2));
  final name = await askGroupName(context);
  return name == null ? null : MoveToGroupChoice(name);
}

/// The new group's name; null = cancelled or left empty. Also used by the
/// group hold menu's "New group…".
Future<String?> askGroupName(BuildContext context) async {
  final controller = TextEditingController();
  final entered = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(tr('New group')),
      content: FocusNodeOwner(
        builder: (context, node) => TvTextFieldGate(
          focusNode: node,
          builder: (context, readOnly) => TextField(
            controller: controller,
            focusNode: node,
            readOnly: readOnly,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: tr('Group name')),
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
        ),
      ),
      // ModeButton: the plain dialog buttons' focus look is too faint on
      // a TV (same as Playlist Manager's dialogs).
      actions: [
        ModeButton(
          label: tr('Cancel'),
          selected: false,
          onTap: () => Navigator.of(context).pop(),
        ),
        ModeButton(
          label: tr('Create'),
          selected: false,
          onTap: () => Navigator.of(context).pop(controller.text),
        ),
      ],
    ),
  );
  controller.dispose();
  final name = entered?.trim();
  return name == null || name.isEmpty ? null : name;
}

/// Hold OK on a channel > Rename… (playlist editor quick edit). Returns the
/// new display name, '' to go back to the provider's name, or null.
Future<String?> askChannelName(BuildContext context, String current) async {
  final controller = TextEditingController(text: current);
  final entered = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(tr('Rename channel')),
      content: FocusNodeOwner(
        builder: (context, node) => TvTextFieldGate(
          focusNode: node,
          builder: (context, readOnly) => TextField(
            controller: controller,
            focusNode: node,
            readOnly: readOnly,
            autofocus: true,
            decoration: InputDecoration(labelText: tr('Channel name')),
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
        ),
      ),
      actions: [
        ModeButton(
          label: tr('Cancel'),
          selected: false,
          onTap: () => Navigator.of(context).pop(),
        ),
        ModeButton(
          label: tr('Save'),
          selected: false,
          onTap: () => Navigator.of(context).pop(controller.text),
        ),
      ],
    ),
  );
  controller.dispose();
  return entered?.trim();
}
