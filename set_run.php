<?php

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

$conn = mysqli_connect("localhost", "root", "", "robotservostatus");
if (!$conn) {
    echo json_encode(['success' => false, 'error' => 'DB connection failed']);
    exit;
}

// Get servo values from sliders
$servo1 = (int)($_POST['servo1'] ?? 90);
$servo2 = (int)($_POST['servo2'] ?? 90);
$servo3 = (int)($_POST['servo3'] ?? 90);
$servo4 = (int)($_POST['servo4'] ?? 90);


$servo1 = max(0, min(180, $servo1));
$servo2 = max(0, min(180, $servo2));
$servo3 = max(0, min(180, $servo3));
$servo4 = max(0, min(180, $servo4));

// Update run table
$sql = "UPDATE run SET 
    status = 1,
    servo1 = $servo1,
    servo2 = $servo2,
    servo3 = $servo3,
    servo4 = $servo4";

if (mysqli_query($conn, $sql)) {
    echo json_encode(['success' => true]);
} else {
    echo json_encode(['success' => false, 'error' => mysqli_error($conn)]);
}

mysqli_close($conn);
?>