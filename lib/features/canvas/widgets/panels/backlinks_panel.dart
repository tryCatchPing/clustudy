import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/routing/app_routes.dart';
import '../../../../shared/services/sketch_persist_service.dart';
import '../../../notes/data/derived_note_providers.dart';
import '../../../notes/models/note_model.dart';
import '../../providers/link_providers.dart';
import '../../providers/note_editor_provider.dart';

/// Backlinks panel showing both Outgoing (current page) and Backlinks (to this note).
class BacklinksPanel extends ConsumerWidget {
  const BacklinksPanel({super.key, required this.noteId});

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

    return SafeArea(
      child: Drawer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  // Outgoing section (this page)
                  const ListTile(
                    title: Text(
                      'Outgoing (this page)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Icon(Icons.north_east, size: 18),
                  ),
                  if (currentPageId == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text('No current page.'),
                    )
                  else
                    _OutgoingList(noteId: noteId, pageId: currentPageId),
                  const Divider(),
                  // Backlinks section (to this note)
                  const ListTile(
                    title: Text(
                      'Backlinks (to this note)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Icon(Icons.south_west, size: 18),
                  ),
                  _BacklinksList(noteId: noteId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          const Icon(Icons.link, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Links',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}

class _OutgoingList extends ConsumerWidget {
  const _OutgoingList({required this.noteId, required this.pageId});
  final String noteId;
  final String pageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outgoingAsync = ref.watch(linksByPageProvider(pageId));
    final notesAsync = ref.watch(notesProvider);

    return outgoingAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text('Error: $e'),
      ),
      data: (links) {
        if (links.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Outgoing links not found.'),
          );
        }
        final notes = notesAsync.value ?? const <NoteModel>[];
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (ctx, i) {
            final link = links[i];
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
            return ListTile(
              dense: true,
              leading: const Icon(Icons.north_east, size: 18),
              title: Text(targetTitle),
              subtitle: const Text('To note'),
              onTap: () {
                // Close drawer then navigate
                Navigator.of(context).maybePop();
                // Persist current page of the current note before navigating
                // so the ongoing page's edits are saved.
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
          },
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemCount: links.length,
        );
      },
    );
  }
}

class _BacklinksList extends ConsumerWidget {
  const _BacklinksList({required this.noteId});
  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backlinksAsync = ref.watch(backlinksToNoteProvider(noteId));
    final notesAsync = ref.watch(notesProvider);

    return backlinksAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text('Error: $e'),
      ),
      data: (links) {
        if (links.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Backlinks not found.'),
          );
        }
        final notes = notesAsync.value ?? const <NoteModel>[];
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (ctx, i) {
            final link = links[i];
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
            return ListTile(
              dense: true,
              leading: const Icon(Icons.south_west, size: 18),
              title: Text('${sourceNote.title} · p.$pageNumber'),
              subtitle: const Text('From note'),
              onTap: () async {
                // Close drawer
                Navigator.of(context).maybePop();
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
          },
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemCount: links.length,
        );
      },
    );
  }

  int _safePageNumber(NoteModel note, String pageId) {
    final idx = note.pages.indexWhere((p) => p.pageId == pageId);
    return idx >= 0 ? note.pages[idx].pageNumber : 1;
  }
}
