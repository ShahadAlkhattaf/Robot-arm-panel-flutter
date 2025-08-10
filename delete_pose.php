<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: application/json');

$id = $_GET['id'] ?? null;
if (!$id || !is_numeric($id)) {
    echo json_encode(['success' => false, 'error' => 'Invalid ID']);
    exit;
}

$conn = mysqli_connect("localhost", "root", "", "robotservostatus");
if (!$conn) {
    echo json_encode(['success' => false, 'error' => 'DB connection failed']);
    exit;
}

$stmt = $conn->prepare("DELETE FROM pose WHERE id = ?");
$stmt->bind_param("i", $id);
if ($stmt->execute()) {
    echo json_encode(['success' => true]);
} else {
    echo json_encode(['success' => false, 'error' => 'Delete failed']);
}
$stmt->close();
mysqli_close($conn);
?>
