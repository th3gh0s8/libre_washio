<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

include('db.php');

// Log incoming POST data for debugging
// error_log("update_vehicle.php: Accessed. Raw POST data: " . file_get_contents('php://input'));
// error_log("update_vehicle.php: Parsed _POST array: " . json_encode($_POST));

// Get POST data
$vehicle_id = isset($_POST['vehicle_id']) ? trim($_POST['vehicle_id']) : null;
$user_id = isset($_POST['user_id']) ? trim($_POST['user_id']) : null; // For security check
$vehicle_no = isset($_POST['vehicle_no']) ? trim($_POST['vehicle_no']) : null;
$vehicle_type = isset($_POST['vehicle_type']) ? trim($_POST['vehicle_type']) : null;
$vehicle_model = isset($_POST['vehicle_model']) ? trim($_POST['vehicle_model']) : null;

// Validate input
if (empty($vehicle_id) || !filter_var($vehicle_id, FILTER_VALIDATE_INT)) {
    echo json_encode(['status' => 'error', 'message' => 'Valid Vehicle ID is required.']);
    exit;
}
if (empty($user_id) || !filter_var($user_id, FILTER_VALIDATE_INT)) {
    echo json_encode(['status' => 'error', 'message' => 'Valid User ID is required for security verification.']);
    exit;
}
if (empty($vehicle_no)) {
    echo json_encode(['status' => 'error', 'message' => 'Vehicle number is required.']);
    exit;
}
if (empty($vehicle_type)) {
    echo json_encode(['status' => 'error', 'message' => 'Vehicle type is required.']);
    exit;
}
if (empty($vehicle_model)) {
    echo json_encode(['status' => 'error', 'message' => 'Vehicle model is required.']);
    exit;
}

// Security Check: Verify the vehicle belongs to the user before updating
$stmt_check_owner = $conn->prepare("SELECT ID FROM vehicle WHERE ID = ? AND userTB = ?");
if (!$stmt_check_owner) {
    echo json_encode(['status' => 'error', 'message' => 'Prepare statement failed (check owner): ' . $conn->error]);
    exit;
}
$stmt_check_owner->bind_param("ii", $vehicle_id, $user_id);
$stmt_check_owner->execute();
$result_check_owner = $stmt_check_owner->get_result();
if ($result_check_owner->num_rows == 0) {
    $stmt_check_owner->close();
    echo json_encode(['status' => 'error', 'message' => 'Vehicle not found or you do not have permission to update this vehicle.']);
    exit;
}
$stmt_check_owner->close();

// Optional: Check if the new vehicle number conflicts with another vehicle of THE SAME USER (excluding the current vehicle being updated)
$stmt_check_conflict = $conn->prepare("SELECT ID FROM vehicle WHERE userTB = ? AND vehicle_no = ? AND ID != ?");
if (!$stmt_check_conflict) {
    echo json_encode(['status' => 'error', 'message' => 'Prepare statement failed (check conflict): ' . $conn->error]);
    exit;
}
$stmt_check_conflict->bind_param("isi", $user_id, $vehicle_no, $vehicle_id);
$stmt_check_conflict->execute();
$result_check_conflict = $stmt_check_conflict->get_result();
if ($result_check_conflict->num_rows > 0) {
    $stmt_check_conflict->close();
    echo json_encode(['status' => 'error', 'message' => 'This vehicle number is already registered for another of your vehicles.']);
    exit;
}
$stmt_check_conflict->close();


// Prepare SQL to update vehicle
$sql = "UPDATE vehicle SET vehicle_no = ?, vehicle_type = ?, vehicle_model = ? WHERE ID = ? AND userTB = ?"; // Double check userTB for safety
$stmt = $conn->prepare($sql);

if (!$stmt) {
    echo json_encode(['status' => 'error', 'message' => 'Prepare statement failed (update vehicle): ' . $conn->error]);
    exit;
}

$stmt->bind_param("sssii", $vehicle_no, $vehicle_type, $vehicle_model, $vehicle_id, $user_id);

if ($stmt->execute()) {
    if ($stmt->affected_rows > 0) {
        echo json_encode(['status' => 'success', 'message' => 'Vehicle updated successfully.']);
    } else {
        // This can happen if the data submitted is identical to the existing data,
        // or if the vehicle_id or user_id didn't match (though owner check should catch this).
        echo json_encode(['status' => 'success', 'message' => 'No changes made to the vehicle. Data might be identical.']);
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'Failed to update vehicle: ' . $stmt->error]);
}

$stmt->close();
$conn->close();
?>