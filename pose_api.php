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

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $servo1 = (int)$_POST['servo1'];
    $servo2 = (int)$_POST['servo2'];
    $servo3 = (int)$_POST['servo3'];
    $servo4 = (int)$_POST['servo4'];

    $stmt = mysqli_prepare($conn, "INSERT INTO pose (servo1, servo2, servo3, servo4) VALUES (?, ?, ?, ?)");
    if ($stmt) {
        mysqli_stmt_bind_param($stmt, "iiii", $servo1, $servo2, $servo3, $servo4);
        if (mysqli_stmt_execute($stmt)) {
            echo json_encode(['success' => true]);
        } else {
            echo json_encode(['success' => false, 'error' => 'Insert failed']);
        }
        mysqli_stmt_close($stmt);
    }
} else {
    // GET: Return all poses
    $result = mysqli_query($conn, "SELECT * FROM pose ORDER BY id DESC");
    $poses = [];
    while ($row = mysqli_fetch_assoc($result)) {
        $poses[] = $row;
    }
    echo json_encode($poses);
}

mysqli_close($conn);
?>