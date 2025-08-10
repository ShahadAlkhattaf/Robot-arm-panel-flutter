# Robot Arm Control Panel

This project is a Flutter-based mobile application to control a robot arm with 4 servos. It communicates with a backend server written in PHP that manages servo positions and robot commands via a MySQL database.

---

## Project Structure

### Flutter App

- Provides UI for controlling servos.
- Calls backend APIs to save/load poses and send run commands.

---

### Backend (PHP + MySQL)

- `pose_api.php`: API for saving, retrieving, and deleting saved poses.
- `set_run.php`: Updates the `run` table with current servo positions and sets status to 1.
- `get_run_pose.php`: Returns current servo positions and status.
- `update_status.php`: Resets the `run` table status and servo values to defaults.
- `delete_pose.php`: Deletes a saved pose by ID.

---

## Database Schema

- **pose** table: Stores saved servo positions with columns `id`, `servo1`, `servo2`, `servo3`, `servo4`.
- **run** table: Stores current servo positions and run status for the robot to read.

---

## Arduino sketch

Runs on an ESP32 or compatible board to control the robot arm hardware:

- Connects to WiFi.
- Polls the backend's `get_run_pose.php` text. 
- Moves the servos accordingly.
- Calls `update_status.php` to reset the status and servo values to default (idle).

---

## Screenshot

<img src="screenshot1" width = 400>
<img src="screenshot2" width = 400>
