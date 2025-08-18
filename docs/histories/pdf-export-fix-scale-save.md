# PDF Export Implementation: Canvas Scaling and Save/Share Functionality

## Project Context
This document records the implementation of improved PDF export functionality for a Flutter handwriting note-taking app, focusing on proper canvas aspect ratio preservation and distinct save/share operations.

## Problem Statement

The original PDF export system had two critical issues:

1. **Canvas Ratio Problem**: All exported PDFs were forced into A4 format regardless of the original canvas dimensions
   - Blank pages (2000x2000px) were exported as A4 instead of square format
   - PDF backgrounds with different aspect ratios were stretched/compressed to fit A4

2. **Save/Share Logic Problem**: Both "Save" and "Share" buttons executed identical functionality
   - Both opened share dialogs instead of providing distinct behaviors
   - No option for user-selected permanent storage location

## Technical Architecture

### Core Components

1. **PdfExportService** (`lib/shared/services/pdf_export_service.dart`)
   - Orchestrates PDF generation and export operations
   - Provides separate methods for save and share workflows

2. **PageImageComposer** (`lib/shared/services/page_image_composer.dart`)
   - Handles canvas image composition with dynamic sizing
   - Manages background/sketch layer compositing

3. **PdfExportModal** (`lib/features/notes/widgets/pdf_export_modal.dart`)
   - User interface for export configuration
   - Implements save/share selection logic

### Data Flow

```
User Selection → PdfExportModal → PdfExportService → PageImageComposer
     ↓               ↓                    ↓              ↓
Export Type → Export Options → PDF Generation → Canvas Compositing
     ↓               ↓                    ↓              ↓
Save/Share → Function Selection → Dynamic Sizing → Final PDF
```

## Implementation Solutions

### 1. Canvas Ratio Preservation

**Problem**: Fixed A4 page format regardless of canvas dimensions

**Solution**: Dynamic PDF page sizing based on actual canvas dimensions

#### Key Changes in `PdfExportService`:

```dart
// Before: Fixed A4 format
static pw.Page createPdfPage(Uint8List pageImageBytes, {int? pageNumber}) {
  return pw.Page(
    pageFormat: PdfPageFormat.a4,  // Always A4
    // ...
  );
}

// After: Dynamic page format
static pw.Page createPdfPage(
  Uint8List pageImageBytes, {
  double? pageWidth,
  double? pageHeight,
  int? pageNumber,
}) {
  final pageFormat = (pageWidth != null && pageHeight != null)
      ? PdfPageFormat(pageWidth, pageHeight)
      : PdfPageFormat.a4;  // Fallback to A4
  
  return pw.Page(
    pageFormat: pageFormat,
    // ...
  );
}
```

#### Canvas Size Calculation:

```dart
// Convert canvas pixels to PDF points (1 pixel = 0.75 points)
for (int i = 0; i < pageImages.length; i++) {
  final originalPage = pagesToExport[i];
  
  final pageWidthPoints = originalPage.drawingAreaWidth * 0.75;
  final pageHeightPoints = originalPage.drawingAreaHeight * 0.75;
  
  pdf.addPage(createPdfPage(
    pageImage,
    pageWidth: pageWidthPoints,
    pageHeight: pageHeightPoints,
    pageNumber: originalPage.pageNumber,
  ));
}
```

#### Dynamic Canvas Sizing in `PageImageComposer`:

```dart
// Before: Hardcoded A4 dimensions
static const double _pageWidth = 2480.0;   // A4 width
static const double _pageHeight = 3508.0;  // A4 height

// After: Dynamic page dimensions
final pageWidth = page.drawingAreaWidth;   // Actual canvas width
final pageHeight = page.drawingAreaHeight; // Actual canvas height

final finalWidth = (pageWidth * pixelRatio / _defaultPixelRatio).toInt();
final finalHeight = (pageHeight * pixelRatio / _defaultPixelRatio).toInt();
```

### 2. Save/Share Functionality Separation

**Problem**: Identical behavior for both save and share operations

**Solution**: Distinct workflows with proper function routing

#### Export Type Definition:

```dart
enum PdfExportType {
  save('저장', '선택한 위치에 PDF 파일 저장'),
  share('공유', 'PDF 파일을 다른 앱으로 공유');
}
```

#### Function Routing Logic:

```dart
// In _startExport() method
final result = _selectedExportType == PdfExportType.save
    ? await PdfExportService.exportAndSave(
        widget.note,
        widget.pageNotifiers,
        options: options,
      )
    : await PdfExportService.exportAndShare(
        widget.note,
        widget.pageNotifiers,
        options: options,
      );
```

#### Save Workflow (`exportAndSave`):

```dart
static Future<PdfExportResult> exportAndSave(
  NoteModel note,
  Map<String, ScribbleNotifier> pageNotifiers, {
  PdfExportOptions? options,
}) async {
  // 1. Generate PDF
  final pdfBytes = await exportNoteToPdf(/* ... */);
  
  // 2. User selects storage location
  final defaultFileName = '${_cleanFileName(note.title)}.pdf';
  final savedPath = await savePdfToUserLocation(pdfBytes, defaultFileName);
  
  // 3. Return result with permanent file path
  return PdfExportResult(
    success: savedPath != null,
    filePath: savedPath,
    // ...
  );
}
```

#### Share Workflow (`exportAndShare`):

```dart
static Future<PdfExportResult> exportAndShare(
  NoteModel note,
  Map<String, ScribbleNotifier> pageNotifiers, {
  PdfExportOptions? options,
}) async {
  // 1. Generate PDF
  final pdfBytes = await exportNoteToPdf(/* ... */);
  
  // 2. Save to temporary location
  final fileName = _generateFileName(note.title, exportOptions.quality);
  final filePath = await savePdfToTemporary(pdfBytes, fileName);
  
  // 3. Share via system dialog
  if (exportOptions.autoShare) {
    await sharePdf(filePath, shareText: exportOptions.shareText);
    
    // 4. Clean up temporary file
    try {
      final tempFile = File(filePath);
      if (tempFile.existsSync()) {
        await tempFile.delete();
      }
    } catch (e) {
      // Non-critical cleanup failure
    }
  }
  
  // 5. Return result (no permanent file path for share)
  return PdfExportResult(
    success: true,
    filePath: null,  // Temporary file deleted
    // ...
  );
}
```

## Canvas Dimension Management

### Page Models Integration

The solution leverages existing `NotePageModel` properties for dynamic sizing:

```dart
// In NotePageModel
double get drawingAreaWidth {
  if (hasPdfBackground && backgroundWidth != null) {
    return backgroundWidth!;  // Use PDF's actual width
  }
  return NoteEditorConstants.canvasWidth;  // Use default (2000px)
}

double get drawingAreaHeight {
  if (hasPdfBackground && backgroundHeight != null) {
    return backgroundHeight!;  // Use PDF's actual height
  }
  return NoteEditorConstants.canvasHeight;  // Use default (2000px)
}
```

### Canvas Size Examples

1. **Blank Page**: 2000×2000px → 1500×1500pt PDF (square format)
2. **A4 PDF Background**: 595×842px → 446×632pt PDF (A4 format)
3. **Letter PDF Background**: 612×792px → 459×594pt PDF (Letter format)

## User Experience Flow

### Save Operation:
1. User selects "Save" option
2. User configures export settings (quality, pages)
3. User clicks "Export" button
4. System generates PDF with proper canvas ratios
5. File picker opens for location selection
6. PDF saved to user-selected permanent location
7. Success message: "PDF 저장 완료!"

### Share Operation:
1. User selects "Share" option
2. User configures export settings
3. User clicks "Export" button
4. System generates PDF with proper canvas ratios
5. PDF saved to temporary location
6. System share dialog opens
7. After sharing, temporary file deleted automatically
8. Success message: "PDF 공유 완료!"

## File Structure Changes

### Modified Files:

1. **`/lib/shared/services/pdf_export_service.dart`**
   - Added dynamic page format support
   - Implemented separate save/share workflows
   - Added user location selection with file picker
   - Added temporary file cleanup for share operations

2. **`/lib/shared/services/page_image_composer.dart`**
   - Removed hardcoded A4 dimensions
   - Implemented dynamic canvas sizing based on page properties
   - Updated image composition to use actual canvas dimensions

3. **`/lib/features/notes/widgets/pdf_export_modal.dart`**
   - Added export type selection UI (save vs share)
   - Implemented proper function routing based on user selection
   - Updated success messages to differentiate between operations

### Dependencies Added:

```yaml
dependencies:
  file_picker: ^8.0.6  # For user location selection
  share_plus: ^10.0.0  # For system share functionality
```

## Performance Considerations

### Memory Management:
- Temporary files automatically deleted after share operations
- Dynamic sizing reduces unnecessary memory allocation
- Image composition optimized for actual canvas dimensions

### Storage Efficiency:
- Canvas ratio preservation prevents unnecessary padding/stretching
- Quality-based pixel ratios maintain optimal file sizes
- User-controlled storage location prevents internal storage bloat

## Testing Scenarios

### Canvas Ratio Tests:
1. **Blank Page Export**: Verify 2000×2000px → square PDF format
2. **PDF Background Export**: Verify original aspect ratio preservation
3. **Mixed Pages**: Verify different page sizes in single PDF

### Save/Share Tests:
1. **Save Operation**: Verify file picker opens and saves to selected location
2. **Share Operation**: Verify system share dialog opens
3. **Temporary Cleanup**: Verify temp files deleted after sharing
4. **Cancel Handling**: Verify proper behavior when user cancels

## Error Handling

### File Operations:
- File picker cancellation handling (returns null)
- Write permission error handling
- Temporary file cleanup failure (non-critical)

### Canvas Processing:
- Invalid canvas dimensions fallback to defaults
- Background image load failure handling
- Memory allocation error recovery

## Future Enhancements

### Potential Improvements:
1. **Custom Canvas Sizes**: Allow users to specify export dimensions
2. **Batch Processing**: Multiple notes export with consistent sizing
3. **Format Options**: Support for additional export formats (JPEG, PNG)
4. **Cloud Integration**: Direct save to cloud storage services

### Architecture Extensions:
1. **Export Plugins**: Modular export destination handlers
2. **Template System**: Predefined canvas size templates
3. **Compression Options**: Advanced PDF optimization settings

## Conclusion

This implementation successfully resolves both the canvas scaling and save/share functionality issues by:

1. **Dynamic PDF Sizing**: Canvas dimensions properly preserved in exported PDFs
2. **Distinct Workflows**: Clear separation between permanent storage and temporary sharing
3. **User Control**: File picker integration for storage location selection
4. **Resource Management**: Automatic cleanup of temporary files

The solution maintains backward compatibility while providing enhanced user experience and technical flexibility for future improvements.