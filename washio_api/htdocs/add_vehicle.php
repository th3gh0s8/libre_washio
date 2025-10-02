<?php

header('Content-Type: application/json');
require_once 'db.php';

// Basic validation
if (empty($_POST['user_id']) || empty($_POST['vehicle_no']) || empty($_POST['vehicle_type']) || empty($_POST['vehicle_model'])) {
    echo json_encode(['status' => 'error', 'message' => 'Missing required fields.']);
    exit;
}

$userId = $_POST['user_id'];
$vehicleNo = $_POST['vehicle_no'];
$vehicleType = $_POST['vehicle_type'];
$vehicleModel = $_POST['vehicle_model'];

try {
    if (!$conn) {
        throw new Exception('Database connection failed.');
    }

    // Corrected userTb to user_id
    $stmt = $conn->prepare("INSERT INTO vehicles (user_id, vehicle_no, vehicle_type, vehicle_model) VALUES (?, ?, ?, ?)");
    if ($stmt === false) {
        throw new Exception('Prepare failed: ' . $conn->error);
    }

    $stmt->bind_param("isss", $userId, $vehicleNo, $vehicleType, $vehicleModel);

    if ($stmt->execute()) {
        echo json_encode(['status' => 'success', 'message' => 'Vehicle added successfully.']);
    } else {
        throw new Exception('Execute failed: ' . $stmt->error);
    }

    $stmt->close();
    $conn->close();

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
