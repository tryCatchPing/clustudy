import 'package:flutter/material.dart';

class LinkModel {
  final String id;
  final String sourceNoteId;
  final int sourcePageId;
  final String targetNoteId;
  final Rect boundingBox; // Normalized bounding box (0.0 to 1.0)
  final String label;

  LinkModel({
    required this.id,
    required this.sourceNoteId,
    required this.sourcePageId,
    required this.targetNoteId,
    required this.boundingBox,
    required this.label,
  });

  // Factory constructor to create LinkModel from a map (e.g., from LinkService)
  factory LinkModel.fromJson(Map<String, dynamic> json) {
    return LinkModel(
      id: json['id'] as String,
      sourceNoteId: json['sourceNoteId'] as String,
      sourcePageId: json['sourcePageId'] as int,
      targetNoteId: json['targetNoteId'] as String,
      boundingBox: Rect.fromLTWH(
        (json['x0'] as num).toDouble(),
        (json['y0'] as num).toDouble(),
        ((json['x1'] as num) - (json['x0'] as num)).toDouble(),
        ((json['y1'] as num) - (json['y0'] as num)).toDouble(),
      ),
      label: json['label'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceNoteId': sourceNoteId,
      'sourcePageId': sourcePageId,
      'targetNoteId': targetNoteId,
      'x0': boundingBox.left,
      'y0': boundingBox.top,
      'x1': boundingBox.right,
      'y1': boundingBox.bottom,
      'label': label,
    };
  }

  LinkModel copyWith({
    String? id,
    String? sourceNoteId,
    int? sourcePageId,
    String? targetNoteId,
    Rect? boundingBox,
    String? label,
  }) {
    return LinkModel(
      id: id ?? this.id,
      sourceNoteId: sourceNoteId ?? this.sourceNoteId,
      sourcePageId: sourcePageId ?? this.sourcePageId,
      targetNoteId: targetNoteId ?? this.targetNoteId,
      boundingBox: boundingBox ?? this.boundingBox,
      label: label ?? this.label,
    );
  }
}
