<?php

header('Content-Type: application/json');
require_once 'db.php';

// Basic validation
if (empty($_POST['vehicle_id']) || empty($_POST['user_id']) || empty($_POST['vehicle_no']) || empty($_POST['vehicle_type']) || empty($_POST['vehicle_model'])) {
    echo json_encode(['status' => 'error', 'message' => 'Missing required fields.']);
    exit;
}

$vehicleId = $_POST['vehicle_id'];
$userId = $_POST['user_id'];
$vehicleNo = $_POST['vehicle_no'];
$vehicleType = $_POST['vehicle_type'];
$vehicleModel = $_POST['vehicle_model'];

try {
    if (!$conn) {
        throw new Exception('Database connection failed.');
    }

    // Corrected to use id in the where clause
    $stmt = $conn->prepare("UPDATE vehicles SET vehicle_no = ?, vehicle_type = ?, vehicle_model = ? WHERE id = ? AND user_id = ?");
    if ($stmt === false) {
        throw new Exception('Prepare failed: ' . $conn->error);
    }

    $stmt->bind_param("sssii", $vehicleNo, $vehicleType, $vehicleModel, $vehicleId, $userId);

    if ($stmt->execute()) {
        if ($stmt->affected_rows > 0) {
            echo json_encode(['status' => 'success', 'message' => 'Vehicle updated successfully.']);
        } else {
            echo json_encode(['status' => 'error', 'message' => 'No vehicle found with the given ID and user ID, or no data changed.']);
        }
    } else {
        throw new Exception('Execute failed: ' . $stmt->error);
    }

    $stmt->close();
    $conn->close();

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
