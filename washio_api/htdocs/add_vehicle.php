<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

include('db.php');

// Log incoming POST data for debugging
// error_log("add_vehicle.php: Accessed. Raw POST data: " . file_get_contents('php://input'));
// error_log("add_vehicle.php: Parsed _POST array: " . json_encode($_POST));

// Get POST data
$user_id = isset($_POST['user_id']) ? trim($_POST['user_id']) : null;
$vehicle_no = isset($_POST['vehicle_no']) ? trim($_POST['vehicle_no']) : null;
$vehicle_type = isset($_POST['vehicle_type']) ? trim($_POST['vehicle_type']) : null;
$vehicle_model = isset($_POST['vehicle_model']) ? trim($_POST['vehicle_model']) : null;

// Validate input
if (empty($user_id) || !filter_var($user_id, FILTER_VALIDATE_INT)) {
    echo json_encode(['status' => 'error', 'message' => 'Valid User ID is required.']);
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

// Optional: Check if this vehicle number already exists for this user
$stmt_check = $conn->prepare("SELECT ID FROM vehicle WHERE userTB = ? AND vehicle_no = ?");
if (!$stmt_check) {
    echo json_encode(['status' => 'error', 'message' => 'Prepare statement failed (check vehicle): ' . $conn->error]);
    exit;
}
$stmt_check->bind_param("is", $user_id, $vehicle_no);
$stmt_check->execute();
$result_check = $stmt_check->get_result();
if ($result_check->num_rows > 0) {
    $stmt_check->close();
    echo json_encode(['status' => 'error', 'message' => 'This vehicle number is already registered for this user.']);
    exit;
}
$stmt_check->close();

// Prepare SQL to insert new vehicle
$sql = "INSERT INTO vehicle (userTB, vehicle_no, vehicle_type, vehicle_model) VALUES (?, ?, ?, ?)";
$stmt = $conn->prepare($sql);

if (!$stmt) {
    echo json_encode(['status' => 'error', 'message' => 'Prepare statement failed (insert vehicle): ' . $conn->error]);
    exit;
}

$stmt->bind_param("isss", $user_id, $vehicle_no, $vehicle_type, $vehicle_model);

if ($stmt->execute()) {
    $new_vehicle_id = $stmt->insert_id;
    echo json_encode([
        'status' => 'success', 
        'message' => 'Vehicle added successfully.',
        'vehicle_id' => $new_vehicle_id // Send back the ID of the newly added vehicle
    ]);
} else {
    echo json_encode(['status' => 'error', 'message' => 'Failed to add vehicle: ' . $stmt->error]);
}

$stmt->close();
$conn->close();
?>