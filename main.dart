import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(RobotArmApp());
}

class RobotArmApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Robot Arm Control Panel',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: RobotArmPanel(),
    );
  }
}

class RobotArmPanel extends StatefulWidget {
  @override
  _RobotArmPanelState createState() => _RobotArmPanelState();
}

class _RobotArmPanelState extends State<RobotArmPanel> {
  int servo1 = 90;
  int servo2 = 90;
  int servo3 = 90;
  int servo4 = 90;

  List<Map<String, dynamic>> poses = [];

  final String baseUrl = 'http://192.168.0.169/robot_arm_controlPanel';

  @override
  void initState() {
    super.initState();
    loadPoses();
  }

  Future<void> loadPoses() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/pose_api.php'));
      if (response.statusCode == 200) {
        setState(() {
          poses = List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      }
    } catch (e) {}
  }

  Future<void> savePose() async {
    final body = {
      'servo1': '$servo1',
      'servo2': '$servo2',
      'servo3': '$servo3',
      'servo4': '$servo4',
    };
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/pose_api.php'),
        body: body,
      );
      final result = json.decode(response.body);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pose saved successfully!')),
        );
        loadPoses();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Save failed. Check connection.')),
      );
    }
  }

  Future<void> runPose() async {
    final body = {
      'servo1': '$servo1',
      'servo2': '$servo2',
      'servo3': '$servo3',
      'servo4': '$servo4',
    };
    try {
      await http.post(
        Uri.parse('$baseUrl/set_run.php'),
        body: body,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Command sent to robot!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Run failed. Is server online?')),
      );
    }
  }

  Future<void> deletePose(dynamic id) async {
    final int poseId = int.tryParse(id.toString()) ?? -1;
    if (poseId == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid pose ID')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Pose?'),
        content: const Text('Are you sure you want to delete this pose?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await http.get(Uri.parse('$baseUrl/delete_pose.php?id=$poseId'));
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          setState(() {
            poses.removeWhere((pose) => pose['id'] == poseId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pose deleted.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: ${jsonResponse['error']}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delete failed.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Robot Arm Control Panel'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Motor Controls',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildSlider('Motor 1', servo1, (v) => setState(() => servo1 = v)),
                    _buildSlider('Motor 2', servo2, (v) => setState(() => servo2 = v)),
                    _buildSlider('Motor 3', servo3, (v) => setState(() => servo3 = v)),
                    _buildSlider('Motor 4', servo4, (v) => setState(() => servo4 = v)),
                    const SizedBox(height: 20),
                    Center(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                servo1 = servo2 = servo3 = servo4 = 90;
                              });
                            },
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Reset'),
                          ),
                          ElevatedButton.icon(
                            onPressed: savePose,
                            icon: const Icon(Icons.save, size: 18),
                            label: const Text('Save'),
                          ),
                          ElevatedButton.icon(
                            onPressed: runPose,
                            icon: const Icon(Icons.play_arrow, size: 18),
                            label: const Text('Run'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Saved Poses',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (poses.isEmpty)
                      const Text('No poses saved yet.')
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: poses.length,
                        itemBuilder: (ctx, index) {
                          final pose = poses[index];
                          return ListTile(
                            title: Text('S1:${pose['servo1']}°  S2:${pose['servo2']}°  S3:${pose['servo3']}°  S4:${pose['servo4']}°'),
                            trailing: Wrap(
                              spacing: 8,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_circle_right_rounded, color: Colors.lightGreen),
                                  tooltip: 'Load this pose',
                                  onPressed: () {
                                    setState(() {
                                      servo1 = int.tryParse(pose['servo1'].toString()) ?? 90;
                                      servo2 = int.tryParse(pose['servo2'].toString()) ?? 90;
                                      servo3 = int.tryParse(pose['servo3'].toString()) ?? 90;
                                      servo4 = int.tryParse(pose['servo4'].toString()) ?? 90;
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Delete this pose',
                                  onPressed: () => deletePose(pose['id']),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(String label, int value, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value.toDouble(),
                min: 0,
                max: 180,
                divisions: 180,
                label: '$value°',
                onChanged: (v) => onChanged(v.round()),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$value°',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
