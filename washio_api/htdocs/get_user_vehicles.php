<?php

header('Content-Type: application/json');
require_once 'db.php';

$userId = $_GET['user_id'] ?? null;

if (!$userId) {
    echo json_encode(['status' => 'error', 'message' => 'User ID is required.']);
    exit;
}

try {
    if (!$conn) {
        throw new Exception('Database connection failed.');
    }

    // Corrected userTb to user_id
    $stmt = $conn->prepare("SELECT vehicle_id, vehicle_no, vehicle_type, vehicle_model FROM vehicles WHERE user_id = ?");
    if ($stmt === false) {
        throw new Exception('Prepare failed: ' . $conn->error);
    }

    $stmt->bind_param("i", $userId);

    if ($stmt->execute()) {
        $result = $stmt->get_result();
        $vehicles = [];
        while ($row = $result->fetch_assoc()) {
            $vehicles[] = $row;
        }
        echo json_encode(['status' => 'success', 'data' => $vehicles]);
    } else {
        throw new Exception('Execute failed: ' . $stmt->error);
    }

    $stmt->close();
    $conn->close();

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
}
