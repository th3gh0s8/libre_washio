<?php
// Attempt to start output buffering here as well, to catch any stray output early
if (ob_get_level() == 0) { // Check if buffering is not already active
    ob_start();
}

header("Access-Control-Allow-Origin: *");
// Content-Type will be set before echo, or by db.php if it exits early

include('db.php'); // db.php now also uses ob_start() and exits with JSON on DB connection error

// Aggressive check for $conn after db.php include
if (!isset($conn) || !$conn instanceof mysqli || (isset($conn->connect_error) && $conn->connect_error)) {
    // db.php should have already outputted a JSON error and exited if $conn->connect_error was true.
    // If we reach here, it implies a more complex issue, or $conn is not even a mysqli object.
    error_log("get_user_vehicles.php: CRITICAL - DB connection object from db.php is invalid or connect_error exists and db.php did not exit. Conn type: " . (isset($conn) ? gettype($conn) : 'not_set') . ", Connect Error: " . (isset($conn->connect_error) ? $conn->connect_error : 'N/A'));
    
    if (ob_get_level() > 0) {
        ob_end_clean(); // Clean any buffer to ensure our JSON is the only output
    }
    if (!headers_sent()) {
        header("Content-Type: application/json");
    }
    echo json_encode([
        'status' => 'error',
        'message' => 'get_user_vehicles.php: Critical - DB connection from db.php is invalid or indicated failure.',
        'conn_object_valid' => (isset($conn) && $conn instanceof mysqli),
        'conn_connect_error_val' => (isset($conn->connect_error) ? $conn->connect_error : 'Not applicable or conn not mysqli object')
    ]);
    exit;
}

// If we passed the above, $conn should be a valid, connected mysqli object.
// Set Content-Type if db.php didn't already (e.g., if db.php had an error but didn't exit with JSON itself)
if (!headers_sent()) {
    header("Content-Type: application/json");
}

// Check if user_id is provided
if (!isset($_GET['user_id']) || empty(trim($_GET['user_id']))) {
    if (ob_get_level() > 0) ob_end_clean();
    if (!headers_sent()) header("Content-Type: application/json");
    echo json_encode(['status' => 'error', 'message' => 'User ID is required.']);
    exit;
}

$user_id = trim($_GET['user_id']);

// Validate if user_id is a number (basic validation)
if (!filter_var($user_id, FILTER_VALIDATE_INT)) {
    if (ob_get_level() > 0) ob_end_clean();
    if (!headers_sent()) header("Content-Type: application/json");
    echo json_encode(['status' => 'error', 'message' => 'Invalid User ID format.']);
    exit;
}

$vehicles_data = []; // Renamed variable to avoid confusion with table name
$sql = "SELECT ID as vehicle_id, userTB, vehicle_no, vehicle_type, vehicle_model FROM vehicles WHERE userTB = ?"; // Changed 'vehicle' to 'vehicles'
$stmt = $conn->prepare($sql);

if (!$stmt) {
    error_log("get_user_vehicles.php: Failed to prepare statement: " . $conn->error); // Log the actual DB error
    if (ob_get_level() > 0) ob_end_clean();
    if (!headers_sent()) header("Content-Type: application/json");
    echo json_encode(['status' => 'error', 'message' => 'Failed to prepare SQL statement. Check server logs.', 'db_prepare_error' => $conn->error]);
    exit;
}

$stmt->bind_param("i", $user_id);

if ($stmt->execute()) {
    $result = $stmt->get_result();
    while ($row = $result->fetch_assoc()) {
        $vehicles_data[] = $row; // Use renamed variable
    }
    
    if (ob_get_level() > 0) ob_end_clean();
    if (!headers_sent()) header("Content-Type: application/json");
    if (count($vehicles_data) > 0) { // Use renamed variable
        echo json_encode(['status' => 'success', 'data' => $vehicles_data]); // Use renamed variable
    } else {
        echo json_encode(['status' => 'success', 'message' => 'No vehicles found for this user.', 'data' => []]);
    }
} else {
    error_log("get_user_vehicles.php: Failed to execute statement: " . $stmt->error); // Log the actual DB error
    if (ob_get_level() > 0) ob_end_clean();
    if (!headers_sent()) header("Content-Type: application/json");
    echo json_encode(['status' => 'error', 'message' => 'Failed to execute SQL statement. Check server logs.', 'db_execute_error' => $stmt->error]);
}

$stmt->close();
$conn->close();

// Final clean up of buffer if script somehow reaches here without prior echo/exit
if (ob_get_level() > 0) {
    ob_end_flush(); 
}
?>