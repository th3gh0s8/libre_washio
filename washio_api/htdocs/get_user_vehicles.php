<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

include('db.php');

// Check if user_id is provided
if (!isset($_GET['user_id']) || empty(trim($_GET['user_id']))) {
    echo json_encode(['status' => 'error', 'message' => 'User ID is required.']);
    exit;
}

$user_id = trim($_GET['user_id']);

// Validate if user_id is a number (basic validation)
if (!filter_var($user_id, FILTER_VALIDATE_INT)) {
    echo json_encode(['status' => 'error', 'message' => 'Invalid User ID format.']);
    exit;
}

$vehicles = [];

// Prepare SQL to fetch vehicles for the given user_id
// Using 'ID' as vehicle_id as per your table structure
$sql = "SELECT ID as vehicle_id, userTB, vehicle_no, vehicle_type, vehicle_model FROM vehicle WHERE userTB = ?";
$stmt = $conn->prepare($sql);

if (!$stmt) {
    echo json_encode(['status' => 'error', 'message' => 'Failed to prepare statement: ' . $conn->error]);
    exit;
}

$stmt->bind_param("i", $user_id);

if ($stmt->execute()) {
    $result = $stmt->get_result();
    while ($row = $result->fetch_assoc()) {
        $vehicles[] = $row;
    }
    
    if (count($vehicles) > 0) {
        echo json_encode(['status' => 'success', 'data' => $vehicles]);
    } else {
        echo json_encode(['status' => 'success', 'message' => 'No vehicles found for this user.', 'data' => []]);
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'Failed to execute statement: ' . $stmt->error]);
}

$stmt->close();
$conn->close();
?>