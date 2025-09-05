import 'dart:ui' show Rect, Offset;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../shared/repositories/link_repository.dart';
import '../data/memory_link_repository.dart';
import '../models/link_model.dart';

part 'link_providers.g.dart';

// Debug verbosity for link providers
const bool _kLinkProvidersVerbose = false;

/// LinkRepository 주입용 Provider. 실제 구현체는 앱 구성 단계에서 override 가능.
@Riverpod(keepAlive: true)
LinkRepository linkRepository(Ref ref) {
  final repo = MemoryLinkRepository();
  ref.onDispose(repo.dispose);
  return repo;
}

/// 특정 페이지의 Outgoing 링크 목록을 스트림으로 제공합니다.
@riverpod
Stream<List<LinkModel>> linksByPage(Ref ref, String pageId) {
  if (_kLinkProvidersVerbose) {
    debugPrint('[linksByPageProvider] page=$pageId');
  }
  final repo = ref.watch(linkRepositoryProvider);
  return repo.watchByPage(pageId);
}

/// 특정 노트로 들어오는 Backlinks 목록을 스트림으로 제공합니다.
@riverpod
Stream<List<LinkModel>> backlinksToNote(Ref ref, String noteId) {
  if (_kLinkProvidersVerbose) {
    debugPrint('[backlinksToNoteProvider] note=$noteId');
  }
  final repo = ref.watch(linkRepositoryProvider);
  return repo.watchBacklinksToNote(noteId);
}

/// 페인트를 위한 Rect 목록으로 변환합니다.
@riverpod
List<Rect> linkRectsByPage(Ref ref, String pageId) {
  final linksAsync = ref.watch(linksByPageProvider(pageId));
  return linksAsync.when(
    data: (links) {
      if (_kLinkProvidersVerbose) {
        debugPrint(
          '[linkRectsByPageProvider] page=$pageId links=${links.length}',
        );
      }
      return links
          .map(
            (l) =>
                Rect.fromLTWH(l.bboxLeft, l.bboxTop, l.bboxWidth, l.bboxHeight),
          )
          .toList(growable: false);
    },
    error: (_, __) => const <Rect>[],
    loading: () => const <Rect>[],
  );
}

/// 주어진 좌표에 해당하는 링크를 찾아 반환합니다(없으면 null).
@riverpod
LinkModel? linkAtPoint(Ref ref, String pageId, Offset localPoint) {
  final linksAsync = ref.watch(linksByPageProvider(pageId));
  return linksAsync.when(
    data: (links) {
      if (_kLinkProvidersVerbose) {
        debugPrint(
          '[linkAtPointProvider] page=$pageId test='
          '${localPoint.dx.toStringAsFixed(1)},'
          '${localPoint.dy.toStringAsFixed(1)} candidates=${links.length}',
        );
      }
      for (final l in links) {
        final r = Rect.fromLTWH(
          l.bboxLeft,
          l.bboxTop,
          l.bboxWidth,
          l.bboxHeight,
        );
        if (r.contains(localPoint)) return l;
      }
      return null;
    },
    error: (_, __) => null,
    loading: () => null,
  );
}
