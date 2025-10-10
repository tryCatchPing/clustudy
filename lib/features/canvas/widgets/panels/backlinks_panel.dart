import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/routing/app_routes.dart';
import '../../../../shared/services/sketch_persist_service.dart';
import '../../../notes/data/derived_note_providers.dart';
import '../../../notes/models/note_model.dart';
import '../../../notes/widgets/note_links_sheet.dart';
import '../../models/link_model.dart';
import '../../providers/link_providers.dart';
import '../../providers/note_editor_provider.dart';

/// Backlinks panel showing both Outgoing (current page) and Backlinks (to this note).
///
/// This is a wrapper that converts data to NoteLinkItem and uses the design system UI.
Future<void> showBacklinksPanel(
  BuildContext context,
  String noteId,
) async {
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.25),
    barrierLabel: 'links',
    pageBuilder: (_, __, ___) {
      return _BacklinksPanelWrapper(noteId: noteId);
    },
    transitionDuration: const Duration(milliseconds: 220),
    transitionBuilder: (_, anim, __, child) {
      final offset = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
      return SlideTransition(position: offset, child: child);
    },
  );
}

/// Internal wrapper widget that watches data and converts to NoteLinkItem
class _BacklinksPanelWrapper extends ConsumerWidget {
  const _BacklinksPanelWrapper({required this.noteId});

  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteAsync = ref.watch(noteProvider(noteId));
    final note = noteAsync.value;
    final currentIndex = ref.watch(currentPageIndexProvider(noteId));

    // Derive current pageId (if available)
    final String? currentPageId =
        (note != null &&
            note.pages.isNotEmpty &&
            currentIndex < note.pages.length)
        ? note.pages[currentIndex].pageId
        : null;

    if (currentPageId == null) {
      // Show empty state
      return const NoteLinksSideSheet(
        outgoing: [],
        backlinks: [],
      );
    }

    // Watch link data
    final outgoingAsync = ref.watch(linksByPageProvider(currentPageId));
    final backlinksAsync = ref.watch(backlinksToNoteProvider(noteId));

    // Convert to NoteLinkItem
    final outgoing = _buildOutgoingItems(
      outgoingAsync,
      ref,
      noteId,
      context,
    );
    final backlinks = _buildBacklinkItems(
      backlinksAsync,
      ref,
      noteId,
      context,
    );

    // Use design system UI
    return NoteLinksSideSheet(
      outgoing: outgoing,
      backlinks: backlinks,
    );
  }

  /// Build outgoing link items from AsyncValue
  List<NoteLinkItem> _buildOutgoingItems(
    AsyncValue<List<LinkModel>> outgoingAsync,
    WidgetRef ref,
    String noteId,
    BuildContext context,
  ) {
    return outgoingAsync.when(
      loading: () => [],
      error: (_, __) => [],
      data: (links) {
        if (links.isEmpty) return [];

        final notesAsync = ref.watch(notesProvider);
        final notes = notesAsync.value ?? const <NoteModel>[];

        return links.map((link) {
          final targetTitle = notes
              .firstWhere(
                (n) => n.noteId == link.targetNoteId,
                orElse: () => NoteModel(
                  noteId: link.targetNoteId,
                  title: link.targetNoteId,
                  pages: const [],
                  sourceType: NoteSourceType.blank,
                ),
              )
              .title;

          return NoteLinkItem(
            title: targetTitle,
            subtitle: 'To note',
            onTap: () {
              // Persist current page of the current note before navigating
              SketchPersistService.saveCurrentPage(ref, noteId);
              // Store per-route resume index for this editor instance
              final idx = ref.read(currentPageIndexProvider(noteId));
              final routeId = ref.read(noteRouteIdProvider(noteId));
              if (routeId != null) {
                ref
                    .read(resumePageIndexMapProvider(noteId).notifier)
                    .save(routeId, idx);
              }
              // Update last known index as well
              ref
                  .read(lastKnownPageIndexProvider(noteId).notifier)
                  .setValue(idx);
              context.pushNamed(
                AppRoutes.noteEditName,
                pathParameters: {'noteId': link.targetNoteId},
              );
            },
          );
        }).toList();
      },
    );
  }

  /// Build backlink items from AsyncValue
  List<NoteLinkItem> _buildBacklinkItems(
    AsyncValue<List<LinkModel>> backlinksAsync,
    WidgetRef ref,
    String noteId,
    BuildContext context,
  ) {
    return backlinksAsync.when(
      loading: () => [],
      error: (_, __) => [],
      data: (links) {
        if (links.isEmpty) return [];

        final notesAsync = ref.watch(notesProvider);
        final notes = notesAsync.value ?? const <NoteModel>[];

        return links.map((link) {
          final sourceNote = notes.firstWhere(
            (n) => n.noteId == link.sourceNoteId,
            orElse: () => NoteModel(
              noteId: link.sourceNoteId,
              title: link.sourceNoteId,
              pages: const [],
              sourceType: NoteSourceType.blank,
            ),
          );
          final pageNumber = _safePageNumber(sourceNote, link.sourcePageId);

          return NoteLinkItem(
            title: '${sourceNote.title} · p.$pageNumber',
            subtitle: 'From note',
            onTap: () async {
              // Persist current page of the current note before navigating
              SketchPersistService.saveCurrentPage(ref, noteId);
              // Store per-route resume index for this editor instance
              final idx = ref.read(currentPageIndexProvider(noteId));
              final routeId = ref.read(noteRouteIdProvider(noteId));
              if (routeId != null) {
                ref
                    .read(resumePageIndexMapProvider(noteId).notifier)
                    .save(routeId, idx);
              }
              // Update last known index as well
              ref
                  .read(lastKnownPageIndexProvider(noteId).notifier)
                  .setValue(idx);
              // Navigate to source note
              context.pushNamed(
                AppRoutes.noteEditName,
                pathParameters: {'noteId': link.sourceNoteId},
              );
              // After navigation, set page index in next frame
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!context.mounted) return;
                // Find page index for sourcePageId
                final note = ref.read(noteProvider(link.sourceNoteId)).value;
                if (note == null) return;
                final idx = note.pages.indexWhere(
                  (p) => p.pageId == link.sourcePageId,
                );
                if (idx >= 0) {
                  ref
                      .read(
                        currentPageIndexProvider(link.sourceNoteId).notifier,
                      )
                      .setPage(idx);
                }
              });
            },
          );
        }).toList();
      },
    );
  }

  int _safePageNumber(NoteModel note, String pageId) {
    final idx = note.pages.indexWhere((p) => p.pageId == pageId);
    return idx >= 0 ? note.pages[idx].pageNumber : 1;
  }
}
