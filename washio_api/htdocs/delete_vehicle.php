<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

include('db.php');

// Get POST data
$vehicle_id = isset($_POST['vehicle_id']) ? trim($_POST['vehicle_id']) : null;
$user_id = isset($_POST['user_id']) ? trim($_POST['user_id']) : null; 

// Validate input
if (empty($vehicle_id) || !filter_var($vehicle_id, FILTER_VALIDATE_INT)) {
    echo json_encode(['status' => 'error', 'message' => 'Valid Vehicle ID is required.']);
    exit;
}
if (empty($user_id) || !filter_var($user_id, FILTER_VALIDATE_INT)) {
    echo json_encode(['status' => 'error', 'message' => 'Valid User ID is required for security verification.']);
    exit;
}

// Security Check: Verify the vehicle belongs to the user before deleting
$stmt_check_owner = $conn->prepare("SELECT id FROM vehicles WHERE id = ? AND user_id = ?");
if (!$stmt_check_owner) {
    echo json_encode(['status' => 'error', 'message' => 'Prepare statement failed (check owner): ' . $conn->error]);
    exit;
}
$stmt_check_owner->bind_param("ii", $vehicle_id, $user_id);
$stmt_check_owner->execute();
$result_check_owner = $stmt_check_owner->get_result();
if ($result_check_owner->num_rows == 0) {
    $stmt_check_owner->close();
    echo json_encode(['status' => 'error', 'message' => 'Vehicle not found or you do not have permission to delete this vehicle.']);
    exit;
}
$stmt_check_owner->close();

// Prepare SQL to delete vehicle
$sql = "DELETE FROM vehicles WHERE id = ? AND user_id = ?"; // Double check user_id for safety
$stmt = $conn->prepare($sql);

if (!$stmt) {
    echo json_encode(['status' => 'error', 'message' => 'Prepare statement failed (delete vehicle): ' . $conn->error]);
    exit;
}

$stmt->bind_param("ii", $vehicle_id, $user_id);

if ($stmt->execute()) {
    if ($stmt->affected_rows > 0) {
        echo json_encode(['status' => 'success', 'message' => 'Vehicle deleted successfully.']);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'Failed to delete vehicle or vehicle not found.']);
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'Failed to execute delete statement: ' . $stmt->error]);
}

$stmt->close();
$conn->close();
?>