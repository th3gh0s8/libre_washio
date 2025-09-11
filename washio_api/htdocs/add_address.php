<?php
ob_start(); // Start output buffering at the very beginning

// Error reporting - log errors, don't display them
error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);

// Set default content type. db.php might also set it if it exits early.
if (!headers_sent()) {
    header('Content-Type: application/json');
}

include 'db.php'; // Your database connection file

// Strict check for DB connection after include
if (!isset($conn) || !$conn instanceof mysqli || (isset($conn->connect_error) && $conn->connect_error)) {
    error_log("add_address.php: CRITICAL - DB connection object from db.php is invalid or connect_error exists. Conn type: " . (isset($conn) ? gettype($conn) : 'not_set'));
    if (ob_get_level() > 0) ob_end_clean();
    if (!headers_sent()) header('Content-Type: application/json');
    echo json_encode([
        'status' => 'error',
        'message' => 'add_address.php: Critical - Database connection issue.'
    ]);
    exit;
}

// Get the posted data
$user_id = isset($_POST['user_id']) ? $conn->real_escape_string(trim($_POST['user_id'])) : null;
$address_type = isset($_POST['address_type']) ? $conn->real_escape_string(trim($_POST['address_type'])) : null;
$address_line1 = isset($_POST['address_line1']) ? $conn->real_escape_string(trim($_POST['address_line1'])) : null;
$address_line2 = isset($_POST['address_line2']) ? $conn->real_escape_string(trim($_POST['address_line2'])) : null; // Optional
$longitude = isset($_POST['longitude']) ? $conn->real_escape_string(trim($_POST['longitude'])) : null;
$latitude = isset($_POST['latitude']) ? $conn->real_escape_string(trim($_POST['latitude'])) : null;
$map_address = isset($_POST['map_address']) ? $conn->real_escape_string(trim($_POST['map_address'])) : null;

$tableName = 'user_locations';

// Validate required fields
$missing_fields = [];
if (empty($user_id) || !filter_var($user_id, FILTER_VALIDATE_INT)) $missing_fields[] = 'user_id (must be a valid integer)';
if (empty($address_type)) $missing_fields[] = 'address_type';
if (empty($address_line1)) $missing_fields[] = 'address_line1';
if (empty($longitude) || !is_numeric($longitude)) $missing_fields[] = 'longitude (must be numeric)';
if (empty($latitude) || !is_numeric($latitude)) $missing_fields[] = 'latitude (must be numeric)';
if (empty($map_address)) $missing_fields[] = 'map_address';

if (!empty($missing_fields)) {
    $response = [
        'status' => 'error',
        'message' => 'Required fields are missing or invalid.',
        'missing_fields' => $missing_fields
    ];
    error_log("add_address.php: Missing fields - " . implode(", ", $missing_fields));
    if (ob_get_level() > 0) ob_end_clean();
    if (!headers_sent()) header('Content-Type: application/json');
    echo json_encode($response);
    if ($conn instanceof mysqli) $conn->close();
    exit;
}

// Determine SQL and parameters based on address_line2
if (empty($address_line2)) {
    $sql = "INSERT INTO $tableName (userTB, Address_Type, Address_Line1, longitude, latitude, Map_Address, created_at, updated_at) 
            VALUES (?, ?, ?, ?, ?, ?, NOW(), NOW())";
    $param_types = "isddss"; // Corrected: user_id (i), address_type (s), address_line1 (s), longitude (d), latitude (d), map_address (s)
    $params = [&$user_id, &$address_type, &$address_line1, &$longitude, &$latitude, &$map_address];
} else {
    $sql = "INSERT INTO $tableName (userTB, Address_Type, Address_Line1, Address_Line2, longitude, latitude, Map_Address, created_at, updated_at) 
            VALUES (?, ?, ?, ?, ?, ?, ?, NOW(), NOW())";
    $param_types = "isssdss"; // Corrected: user_id (i), address_type (s), address_line1 (s), address_line2 (s), longitude (d), latitude (d), map_address (s)
    $params = [&$user_id, &$address_type, &$address_line1, &$address_line2, &$longitude, &$latitude, &$map_address];
}

$stmt = $conn->prepare($sql);
if (!$stmt) {
    $db_error = $conn->error;
    error_log("add_address.php: Prepare statement failed: " . $db_error);
    $response = ['status' => 'error', 'message' => 'Database error (prepare): ' . $db_error];
    if (ob_get_level() > 0) ob_end_clean();
    if (!headers_sent()) header('Content-Type: application/json');
    echo json_encode($response);
    if ($conn instanceof mysqli) $conn->close();
    exit;
}

// Dynamically bind parameters
// Note: $stmt->bind_param needs references, which $params already provides.
// The spread operator (...) unpacks the $params array into individual arguments.
if (!call_user_func_array([$stmt, 'bind_param'], array_merge([$param_types], $params))) {
    $db_error = $stmt->error; // Or $conn->error if bind_param failure isn't specific to stmt
    error_log("add_address.php: Bind_param failed: " . $db_error);
    $response = ['status' => 'error', 'message' => 'Database error (bind): ' . $db_error];
    if (ob_get_level() > 0) ob_end_clean();
    if (!headers_sent()) header('Content-Type: application/json');
    echo json_encode($response);
    $stmt->close();
    if ($conn instanceof mysqli) $conn->close();
    exit;
}

if ($stmt->execute()) {
    $response = [
        'status' => 'success',
        'message' => 'Address added successfully.',
        'address_id' => $conn->insert_id
    ];
    if (ob_get_level() > 0) ob_end_clean();
    if (!headers_sent()) header('Content-Type: application/json');
    echo json_encode($response);
} else {
    $db_error = $stmt->error;
    error_log("add_address.php: Execute statement failed: " . $db_error);
    $response = ['status' => 'error', 'message' => 'Database error (execute): ' . $db_error];
    if (ob_get_level() > 0) ob_end_clean();
    if (!headers_sent()) header('Content-Type: application/json');
    echo json_encode($response);
}

$stmt->close();
if ($conn instanceof mysqli) $conn->close();
exit;
?>