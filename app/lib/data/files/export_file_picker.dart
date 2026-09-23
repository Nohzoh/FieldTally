import 'package:file_selector/file_selector.dart';

/// A file the agent chose, already read (#191).
class PickedFile {
  const PickedFile({required this.name, required this.content});

  /// Shown back so it is obvious which file is about to be imported.
  final String name;

  final String content;
}

/// Asks the system for the export file (#191).
///
/// A file rather than a paste: the export is delivered as a file, and a
/// history spanning years is not something anyone pastes into a text field
/// — which is also why the Agent Stats path stays a paste, since Agent Stats
/// offers no download at all.
///
/// Behind a class of its own so the screen can be tested without a platform
/// channel: nothing here answers in a widget test.
class ExportFilePicker {
  const ExportFilePicker();

  /// Null when the agent backed out of the picker.
  Future<PickedFile?> pick() async {
    // Deliberately no type filter. Android reports a downloaded `.csv` as
    // `text/csv`, `text/comma-separated-values` or `application/octet-stream`
    // depending on which app wrote it, and a filter that guesses wrong greys
    // out the very file the agent came to fetch. Reading it and saying
    // plainly that it is not an export is the better failure.
    final file = await openFile();
    if (file == null) return null;

    return PickedFile(name: file.name, content: await file.readAsString());
  }
}
