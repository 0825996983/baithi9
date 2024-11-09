import 'dart:convert';
import 'dart:io';

const String filePath = 'Student.json';

class StudentManagement {
  Future<Map<String, dynamic>> _readStudentsData() async {
    final file = File(filePath);
    try {
      if (await file.exists()) {
        String contents = await file.readAsString();
        return jsonDecode(contents);
      } else {
        return {'students': []}; // Return empty structure if file doesn't exist
      }
    } catch (e) {
      print("✘ Error reading file: $e");
      rethrow; // Rethrow exception to propagate the error
    }
  }

  Future<void> _writeStudentsData(Map<String, dynamic> data) async {
    final file = File(filePath);
    try {
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      print("✘ Error writing to file: $e");
    }
  }

  Future<void> displayAllStudents() async {
    try {
      Map<String, dynamic> data = await _readStudentsData();
      List<dynamic> students = data['students'];

      if (students.isEmpty) {
        print("\n✘ No students found.");
        return;
      }

      print("\n📚 List of Students:");
      print("=" * 50);
      for (var student in students) {
        print('ID: ${student['id']}, Name: ${student['name']}');
        print("Subjects and Scores:");
        print("-" * 30);
        for (var subject in student['subjects']) {
          print('  ${subject['name']}: ${subject['scores'].join(", ")}');
        }
        print("-" * 30);
      }
      print("=" * 50);
    } catch (e) {
      print("✘ Error displaying students: $e");
    }
  }

  Future<void> addStudent() async {
    try {
      Map<String, dynamic> data = await _readStudentsData();
      List<dynamic> students = data['students'];

      // Nhập thông tin sinh viên
      String? studentId = await _getInput("Enter student ID: ", required: true);
      String? name = await _getInput("Enter student name: ", required: true);

      List<Map<String, dynamic>> subjects = [];
      while (true) {
        String? subjectName = await _getInput(
            "Enter subject name (Enter 'stop' to save the student: ");
        if (subjectName?.toLowerCase() == 'stop') break;

        String? scoresInput = await _getInput(
            "Enter scores separated by commas: ",
            required: true);

        // Xử lý điểm số
        List<int> scores = [];
        if (scoresInput != null && scoresInput.isNotEmpty) {
          try {
            scores =
                scoresInput.split(',').map((e) => int.parse(e.trim())).toList();
          } catch (e) {
            print("✘ Invalid scores input. Please enter numbers only.");
            continue;
          }
        }

        subjects.add({"name": subjectName, "scores": scores});
      }

      // Thêm sinh viên vào danh sách
      students.add({"id": studentId, "name": name, "subjects": subjects});

      // Lưu dữ liệu vào file ngay sau khi thêm sinh viên
      await _writeStudentsData(data);

      print("\n✔ Student added successfully!");
    } catch (e) {
      print("✘ Error adding student: $e");
    }
  }

  Future<void> editStudent() async {
    try {
      Map<String, dynamic> data = await _readStudentsData();
      List<dynamic> students = data['students'];

      // Tìm kiếm sinh viên theo ID
      String? studentId = await _getInput(
          "Enter the ID of the student you want to edit: ",
          required: true);
      var student =
          students.firstWhere((s) => s['id'] == studentId, orElse: () => null);

      if (student == null) {
        print("✘ Student not found!");
        return;
      }

      // Chỉnh sửa tên sinh viên
      String? newName =
          await _getInput("Enter new name (or press Enter to skip): ");
      if (newName != null && newName.isNotEmpty) {
        student['name'] = newName;
      }

      // Hiển thị các môn học của sinh viên
      print("\nCurrent subjects and scores:");
      print("-" * 30);
      for (int i = 0; i < student['subjects'].length; i++) {
        var subject = student['subjects'][i];
        print(
            "${i + 1}. ${subject['name']} - Scores: ${subject['scores'].join(", ")}");
      }
      print("-" * 30);

      // Xử lý thêm, sửa, xóa môn học
      String? action = await _getInput(
          "\nEnter 'add' to add a subject, 'edit' to edit a subject, or 'delete' to remove a subject: ");
      if (action == 'add') {
        _addSubject(student);
      } else if (action == 'edit') {
        _editSubject(student);
      } else if (action == 'delete') {
        _deleteSubject(student);
      }

      await _writeStudentsData(data);
      print("\n✔ Student information updated successfully!");
    } catch (e) {
      print("✘ Error editing student: $e");
    }
  }

  void _addSubject(Map<String, dynamic> student) async {
    String? subjectName = await _getInput("Enter new subject name: ");
    String? scoresInput =
        await _getInput("Enter scores separated by commas: ", required: true);

    // Xử lý điểm số
    List<int> scores = [];
    if (scoresInput != null && scoresInput.isNotEmpty) {
      try {
        scores =
            scoresInput.split(',').map((e) => int.parse(e.trim())).toList();
      } catch (e) {
        print("✘ Invalid scores input. Please enter numbers only.");
        return;
      }
    }

    student['subjects'].add({"name": subjectName, "scores": scores});
  }

  void _editSubject(Map<String, dynamic> student) async {
    String? subjectIndexInput =
        await _getInput("\nEnter the subject number to edit: ", required: true);
    int index = int.tryParse(subjectIndexInput ?? '') ?? -1;

    if (index >= 0 && index < student['subjects'].length) {
      var subject = student['subjects'][index];
      String? newSubjectName =
          await _getInput("Enter new subject name (or press Enter to skip): ");
      if (newSubjectName != null && newSubjectName.isNotEmpty) {
        subject['name'] = newSubjectName;
      }

      String? scoresInput = await _getInput(
          "Enter new scores separated by commas (or press Enter to skip): ");
      if (scoresInput != null && scoresInput.isNotEmpty) {
        subject['scores'] =
            scoresInput.split(',').map((e) => int.parse(e.trim())).toList();
      }
    } else {
      print("✘ Invalid subject number.");
    }
  }

  void _deleteSubject(Map<String, dynamic> student) async {
    String? subjectIndexInput = await _getInput(
        "\nEnter the subject number to delete: ",
        required: true);
    int index = int.tryParse(subjectIndexInput ?? '') ?? -1;

    if (index >= 0 && index < student['subjects'].length) {
      student['subjects'].removeAt(index);
    } else {
      print("✘ Invalid subject number.");
    }
  }

  Future<String?> _getInput(String prompt, {bool required = false}) async {
    stdout.write(prompt);
    String? input = stdin.readLineSync();
    while (required && (input == null || input.isEmpty)) {
      print("✘ Input cannot be empty!");
      stdout.write(prompt);
      input = stdin.readLineSync();
    }
    return input;
  }

  Future<void> searchStudent() async {
    try {
      Map<String, dynamic> data = await _readStudentsData();
      List<dynamic> students = data['students'];

      stdout.write("\nEnter student name or ID to search: ");
      String? keyword = stdin.readLineSync();

      var results = students.where((s) {
        var studentName = s['name'] as String?;
        // Kiểm tra nếu tên sinh viên có giá trị thì mới thực hiện contains
        return s['id'] == keyword ||
            (studentName != null &&
                studentName.toLowerCase().contains(keyword!.toLowerCase()));
      }).toList();

      if (results.isEmpty) {
        print("✘ No student found with the given name or ID.");
        return;
      }

      print("\n🔍 Search Results:");
      print("=" * 50);
      for (var student in results) {
        print('ID: ${student['id']}, Name: ${student['name']}');
        print("Subjects and Scores:");
        print("-" * 30);
        for (var subject in student['subjects']) {
          print('  ${subject['name']}: ${subject['scores'].join(", ")}');
        }
        print("-" * 30);
      }
      print("=" * 50);
    } catch (e) {
      print("✘ Error searching students: $e");
    }
  }

  void showMenu() {
    print("\n📋 Student Management System");
    print("1. View all students");
    print("2. Add a new student");
    print("3. Edit student information");
    print("4. Search student");
    print("5. Exit");
    print("=" * 50);
  }

  Future<void> run() async {
    while (true) {
      showMenu();
      String? choice = await _getInput("Choose an option: ", required: true);

      switch (choice) {
        case '1':
          await displayAllStudents();
          break;
        case '2':
          await addStudent();
          break;
        case '3':
          await editStudent();
          break;
        case '4':
          await searchStudent();
          break;
        case '5':
          print("👋 Goodbye!");
          return;
        default:
          print("✘ Invalid choice! Please try again.");
      }
    }
  }
}

void main() async {
  StudentManagement system = StudentManagement();
  await system.run();
}
