import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('taskSheet');
  runApp(const MApp());
}

class MApp extends StatelessWidget {
  const MApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Box sheet = Hive.box('taskSheet');
  final TextEditingController mController = TextEditingController();

  bool showInput = false;
  bool showtask = false;

  final List<String> repeat = ['daily', 'weekly', 'monthly'];

  bool datebutton = false;
  bool date_time_button = false;
  bool repeatbutton = false;

  DateTime? selectdate;
  DateTime? date_time;
  String? repeat_date;

  @override
  void dispose() {
    mController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) myFunction();
    });
  }

  void myFunction() {
    int sizeOfSheet = sheet.length;
    List<dynamic> itemsToUpdate = [];

    for (int i = 0; i < sizeOfSheet; i++) {
      var findRepeat = sheet.getAt(i);
      if (findRepeat == null || findRepeat.length < 5) continue;

      String? repeatType = findRepeat[3] as String?;
      DateTime? endDate = findRepeat[1] as DateTime?;
      DateTime? notifyTime = findRepeat[2] as DateTime?;
      if (endDate == null) continue;

      DateTime now = DateTime.now();
      int days = now.difference(endDate).inDays;
      bool didRepeatRun = false;

      if (repeatType != null && days >= 1) {
        if (repeatType == "daily") {
          for (int j = 1; j <= days; j++) {
            sheet.add([
              findRepeat[0],
              endDate.add(Duration(days: j)),
              notifyTime?.add(Duration(days: j)),
              j == days ? repeatType : null,
              false,
            ]);
          }
          didRepeatRun = true;
        } else if (repeatType == "weekly") {
          int weeks = (days / 7).floor();
          for (int j = 1; j <= weeks; j++) {
            sheet.add([
              findRepeat[0],
              endDate.add(Duration(days: 7 * j)),
              notifyTime?.add(Duration(days: 7 * j)),
              j == weeks ? repeatType : null,
              false,
            ]);
          }
          didRepeatRun = true;
        } else if (repeatType == "monthly") {
          int months = (now.year - endDate.year) * 12 + (now.month - endDate.month);
          for (int j = 1; j <= months; j++) {
            DateTime newDate = DateTime(
              endDate.year,
              endDate.month + j,
              endDate.day,
            );
            DateTime? newNotifyTime = notifyTime != null ? DateTime(
              notifyTime.year,
              notifyTime.month + j,
              notifyTime.day,
              notifyTime.hour,
              notifyTime.minute,
            ) : null;
            sheet.add([
              findRepeat[0],
              newDate,
              newNotifyTime,
              j == months ? repeatType : null,
              false,
            ]);
          }
          didRepeatRun = true;
        }
      }

      if (didRepeatRun) {
        findRepeat[3] = null;
        itemsToUpdate.add({'index': i, 'value': findRepeat});
      }
    }

    for (var item in itemsToUpdate) {
      sheet.putAt(item['index'], item['value']);
    }

    if (itemsToUpdate.isNotEmpty && mounted) setState(() {});
  }

  Future<void> _pickadate(int type, {bool showDate = true, DateTime? olddate, TimeOfDay? oldtime}) async {
    DateTime? pickedDate;

    if (showDate) {
      pickedDate = await showDatePicker(
        context: context,
        initialDate: olddate ?? selectdate ?? DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2100),
      );
      if (!mounted) return;

      if (type == 1 && pickedDate != null) {
        setState(() {
          selectdate = pickedDate;
          datebutton = true;
        });
        return;
      }
    }

    if (type == 2) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: oldtime ?? (date_time != null
            ? TimeOfDay.fromDateTime(date_time!)
            : TimeOfDay.now()),
      );
      if (!mounted) return;

      if (pickedTime != null) {
        setState(() {
          final now = pickedDate ?? date_time ?? DateTime.now();
          date_time = DateTime(
            now.year,
            now.month,
            now.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          date_time_button = true;
        });
      }
    }
  }

  void _pickaRepeatdate() {
    String? tempRepeat;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select a repeat'),
          content: SizedBox(
            width: double.maxFinite,
            height: 200,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: repeat.map((r) {
                  return ListTile(
                    title: Text(r),
                    tileColor: tempRepeat == r ? Colors.blue.withOpacity(0.2) : null,
                    onTap: () {
                      tempRepeat = r;
                      Navigator.of(context).pop();
                      setState(() {
                        repeat_date = r;
                        repeatbutton = true;
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _clearRepeat() {
    setState(() {
      repeat_date = null;
      repeatbutton = false;
    });
  }

  void _resetInputState() {
    selectdate = null;
    date_time = null;
    repeat_date = null;
    datebutton = false;
    date_time_button = false;
    repeatbutton = false;
  }

  @override
  Widget build(BuildContext context) {
    final falseItems = sheet.toMap().entries
        .where((e) => e.value.length > 4 && e.value[4] == false)
        .toList();

    final trueItems = sheet.toMap().entries
        .where((e) => e.value.length > 4 && e.value[4] == true)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C7EFF),
        title: const Text(
          'My ToDo',
          style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(50),
              child: showInput
                  ? Column(
                children: [
                  TextField(
                    controller: mController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Write Task',
                      border: const OutlineInputBorder(),
                      suffixIcon: ElevatedButton(
                        onPressed: () {
                          String textofTask = mController.text;
                          if (textofTask.isEmpty) return;
                          sheet.add([
                            textofTask,
                            selectdate,
                            date_time,
                            repeat_date,
                            false,
                          ]);
                          mController.clear();
                          setState(() {
                            _resetInputState();
                          });
                        },
                        child: const Text("Add"),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildIconButton(
                        icon: Icons.date_range,
                        isActive: datebutton,
                        onPressed: () => _pickadate(1),
                        onClear: () => setState(() {
                          selectdate = null;
                          datebutton = false;
                        }),
                      ),
                      _buildIconButton(
                        icon: Icons.notifications,
                        isActive: date_time_button,
                        onPressed: () => _pickadate(2, showDate: true),
                        onClear: () => setState(() {
                          date_time = null;
                          date_time_button = false;
                        }),
                      ),
                      _buildIconButton(
                        icon: Icons.repeat,
                        isActive: repeatbutton,
                        onPressed: _pickaRepeatdate,
                        onClear: _clearRepeat,
                      ),
                    ],
                  ),
                ],
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.add,
                      size: 48,
                      color: Color(0xFF575757),
                    ),
                    onPressed: () => setState(() => showInput = true),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Add Task',
                    style: TextStyle(
                      fontSize: 48,
                      color: Color(0xFF575757),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  ...falseItems.map((entry) => _buildTaskTile(entry, false)),
                  ListTile(
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Completed',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: Icon(
                            showtask
                                ? Icons.arrow_drop_down
                                : Icons.arrow_right,
                          ),
                          onPressed: () => setState(() => showtask = !showtask),
                        ),
                      ],
                    ),
                  ),
                  if (showtask)
                    ...trueItems.map((entry) => _buildTaskTile(entry, true)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
    required VoidCallback onClear,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isActive ? Colors.blue : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              icon,
              color: isActive ? Colors.white : Colors.blue,
            ),
            onPressed: onPressed,
          ),
        ),
        if (isActive)
          Positioned(
            top: -6,
            right: -6,
            child: InkWell(
              onTap: onClear,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTaskTile(MapEntry<dynamic, dynamic> entry, bool isCompleted) {
    final key = entry.key;
    final item = entry.value;
    if (item.length < 5) return const SizedBox.shrink();

    final String title = item[0]?.toString() ?? 'Untitled';
    final DateTime? taskDate = item[1] as DateTime?;
    final DateTime? notifyTime = item[2] as DateTime?;
    final String? repeatType = item[3] as String?;

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
      ),
      child: ListTile(
        leading: IconButton(
          icon: Icon(
            isCompleted ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            color: Colors.blue,
          ),
          onPressed: () {
            final updated = List.from(item);
            updated[4] = !isCompleted;
            sheet.put(key, updated);
            setState(() {});
          },
        ),
        title: Text(title),
        subtitle: taskDate != null
            ? Text('${taskDate.day}/${taskDate.month}${repeatType != null ? ' ($repeatType)' : ''}')
            : null,
        onLongPress: () => _showTaskMenu(context, entry, taskDate, notifyTime),
      ),
    );
  }

  void _showTaskMenu(BuildContext tileContext, MapEntry<dynamic, dynamic> entry, DateTime? oldDate, DateTime? oldTime) async {
    final RenderBox box = tileContext.findRenderObject() as RenderBox;
    final Offset position = box.localToGlobal(Offset.zero);
    final Size size = box.size;

    final result = await showMenu<int>(
      context: context,
      position: RelativeRect.fromLTRB(
          position.dx,
          position.dy,
          position.dx + size.width,
          position.dy + size.height),
      items: const [
        PopupMenuItem(value: 1, child: Text('Edit')),
        PopupMenuItem(value: 2, child: Text('Delete')),
      ],
    );

    if (!mounted) return;

    if (result == 1) {
      _showEditDialog(entry, oldDate, oldTime);
    } else if (result == 2) {
      await sheet.delete(entry.key);
      if (mounted) setState(() {});
    }
  }

  void _showEditDialog(MapEntry<dynamic, dynamic> entry, DateTime? oldDate, DateTime? oldTime) {
    final item = entry.value;
    final textController = TextEditingController(text: item[0]?.toString());

    DateTime? tempSelectDate = oldDate;
    DateTime? tempDateTime = oldTime;
    String? tempRepeatDate = item[3] as String?;

    bool tempDateButton = oldDate != null;
    bool tempDateTimeButton = oldTime != null;
    bool tempRepeatButton = tempRepeatDate != null;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Task'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Task name',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDialogIconButton(
                      icon: Icons.date_range,
                      isActive: tempDateButton,
                      onPressed: () async {
                        await _pickadate(1, olddate: oldDate);
                        if (selectdate != null) {
                          setDialogState(() {
                            tempSelectDate = selectdate;
                            tempDateButton = true;
                          });
                        }
                      },
                      onClear: () {
                        setDialogState(() {
                          tempSelectDate = null;
                          tempDateButton = false;
                        });
                      },
                    ),
                    _buildDialogIconButton(
                      icon: Icons.notifications,
                      isActive: tempDateTimeButton,
                      onPressed: () async {
                        await _pickadate(2, showDate: false, oldtime: oldTime != null ? TimeOfDay.fromDateTime(oldTime) : null);
                        if (date_time != null) {
                          setDialogState(() {
                            tempDateTime = date_time;
                            tempDateTimeButton = true;
                          });
                        }
                      },
                      onClear: () {
                        setDialogState(() {
                          tempDateTime = null;
                          tempDateTimeButton = false;
                        });
                      },
                    ),
                    _buildDialogIconButton(
                      icon: Icons.repeat,
                      isActive: tempRepeatButton,
                      onPressed: () {
                        _pickaRepeatdate();
                        if (repeat_date != null) {
                          setDialogState(() {
                            tempRepeatDate = repeat_date;
                            tempRepeatButton = true;
                          });
                        }
                      },
                      onClear: () {
                        setDialogState(() {
                          tempRepeatDate = null;
                          tempRepeatButton = false;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  String newText = textController.text;
                  if (newText.isEmpty) return;

                  final updated = List.from(item);
                  updated[0] = newText;

                  if (tempSelectDate != null) updated[1] = tempSelectDate;
                  if (tempDateTime != null) updated[2] = tempDateTime;
                  updated[3] = tempRepeatDate;

                  sheet.put(entry.key, updated);
                  textController.dispose();
                  _resetInputState();
                  Navigator.pop(dialogContext);
                  setState(() {});
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    ).then((_) => textController.dispose());
  }

  Widget _buildDialogIconButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
    required VoidCallback onClear,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isActive ? Colors.blue : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              icon,
              color: isActive ? Colors.white : Colors.blue,
            ),
            onPressed: onPressed,
          ),
        ),
        if (isActive)
          Positioned(
            top: -6,
            right: -6,
            child: InkWell(
              onTap: onClear,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}