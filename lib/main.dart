import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const ScanPage(),
    );
  }
}

/* =========================
   BLUETOOTH SCAN PAGE
   ========================= */
class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  List<ScanResult> devices = [];

  @override
  void initState() {
    super.initState();
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) {
      setState(() => devices = results);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sök ljusenhet')),
      body: ListView(
        children: devices.map((r) {
          return ListTile(
            title: Text(
              r.device.platformName.isNotEmpty
                  ? r.device.platformName
                  : 'Okänd enhet',
            ),
            subtitle: Text(r.device.remoteId.toString()),
            onTap: () async {
              await r.device.connect();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ControlPage(device: r.device),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

/* =========================
   CONTROL PAGE
   ========================= */
class ControlPage extends StatefulWidget {
  final BluetoothDevice device;
  const ControlPage({super.key, required this.device});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  BluetoothCharacteristic? writeChar;

  double brightness = 100;
  Color sliderColor = Colors.orange;
  Color buttonColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    discoverServices();
  }

  Future<void> discoverServices() async {
    final services = await widget.device.discoverServices();
    for (var s in services) {
      for (var c in s.characteristics) {
        if (c.properties.write) {
          writeChar = c;
        }
      }
    }
  }

  void sendValue(int value) {
    writeChar?.write([value]);
  }

  void pickColor(Color current, Function(Color) onPick) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Välj färg'),
        content: ColorPicker(
          pickerColor: current,
          onColorChanged: onPick,
          enableAlpha: false,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Klar'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ljusstyrning')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Ljusstyrka: ${brightness.toInt()}%',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: sliderColor,
                thumbColor: sliderColor,
              ),
              child: Slider(
                min: 0,
                max: 255,
                value: brightness,
                onChanged: (v) {
                  setState(() => brightness = v);
                  sendValue(v.toInt());
                },
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.color_lens),
              label: const Text('Ändra reglagefärg'),
              onPressed: () =>
                  pickColor(sliderColor, (c) => setState(() => sliderColor = c)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 16),
              ),
              onPressed: () => sendValue(0),
              child: const Text('SLÄCK'),
            ),
            TextButton.icon(
              icon: const Icon(Icons.color_lens),
              label: const Text('Ändra knappfärg'),
              onPressed: () =>
                  pickColor(buttonColor, (c) => setState(() => buttonColor = c)),
            ),
          ],
        ),
      ),
    );
  }
}