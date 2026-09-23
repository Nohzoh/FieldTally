import 'package:fieldtally/data/files/export_file_picker.dart';

/// Answers with a file of the test's choosing (#191).
///
/// The real picker opens a system dialog over a platform channel, which no
/// widget test has. Everything the screen does with the file — reading it,
/// planning the import, refusing it — happens on this side of that call.
class FakeExportFilePicker implements ExportFilePicker {
  FakeExportFilePicker({this.file});

  /// Null stands for the agent backing out of the picker.
  PickedFile? file;

  /// How many times the screen asked.
  int calls = 0;

  @override
  Future<PickedFile?> pick() async {
    calls++;
    return file;
  }
}
