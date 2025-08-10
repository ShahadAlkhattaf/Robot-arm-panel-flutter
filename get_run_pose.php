<?php

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header('Content-Type: text/plain'); 

$conn = mysqli_connect("localhost", "root", "", "robotservostatus");
if (!$conn) {
    // If connection fails, return default values in required format
    echo "0,s190,s290,s390,s490,s590,s690";
    exit;
}

$result = mysqli_query($conn, "SELECT * FROM run LIMIT 1");
$pose = mysqli_fetch_assoc($result);

if ($pose) {
    // Prepare values
    $status = (int)$pose['status'];
    $servo1 = (int)$pose['servo1'];
    $servo2 = (int)$pose['servo2'];
    $servo3 = (int)$pose['servo3'];
    $servo4 = (int)$pose['servo4'];

    // Format string: status,s1xx,s2xx,s3xx,s4xx,s590,s690
    echo "{$status},s1{$servo1},s2{$servo2},s3{$servo3},s4{$servo4}";
} else {
    // If no row found, return default values
    echo "0,s190,s290,s390,s490,s590,s690";
}

mysqli_close($conn);
