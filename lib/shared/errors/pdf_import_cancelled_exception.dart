/// Thrown when a user cancels the PDF import flow before completion.
class PdfImportCancelledException implements Exception {
  /// Creates a new cancellation exception.
  const PdfImportCancelledException();

  @override
  String toString() => 'PdfImportCancelledException';
}
