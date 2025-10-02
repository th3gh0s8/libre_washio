<?php
// Start output buffering at the very beginning
ob_start();

error_reporting(E_ALL);
ini_set('display_errors', 0); // Log errors, don't display them
ini_set('log_errors', 1);

if (!headers_sent()) {
    header("Content-Type: application/json");
}

require __DIR__ . '/db.php'; // db.php handles its own output buffering and JSON exit on DB connection error

// Check if $conn is valid after db.php include (it should have exited if connection failed)
if (!isset($conn) || !$conn instanceof mysqli || (isset($conn->connect_error) && $conn->connect_error)) {
    error_log("register_user.php: CRITICAL - DB connection object from db.php is invalid or connect_error exists and db.php did not exit.");
    if (ob_get_level() > 0) ob_end_clean();
    if (!headers_sent()) header("Content-Type: application/json");
    echo json_encode(['status' => 'error', 'message' => 'register_user.php: Critical - DB connection issue from db.php.']);
    exit;
}

// Get POST data
$name = isset($_POST['name']) ? trim($_POST['name']) : null;
$email = isset($_POST['email']) ? trim($_POST['email']) : null;
$phone = isset($_POST['phone']) ? trim($_POST['phone']) : null;
$country_code = isset($_POST['country_code']) ? trim($_POST['country_code']) : null;
$address = isset($_POST['address']) ? trim($_POST['address']) : null; // Optional

// Optional vehicle details
$vehicle_no = isset($_POST['vehicle_no']) ? trim($_POST['vehicle_no']) : null;
$vehicle_type = isset($_POST['vehicle_type']) ? trim($_POST['vehicle_type']) : null;
$vehicle_model = isset($_POST['vehicle_model']) ? trim($_POST['vehicle_model']) : null;

// Basic validation
if (empty($name) || empty($email) || empty($phone) || empty($country_code)) {
    if (ob_get_level() > 0) ob_end_clean();
    if (!headers_sent()) header("Content-Type: application/json");
    echo json_encode(['status' => 'error', 'message' => 'Name, email, phone, and country code are required.']);
    exit;
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    if (ob_get_level() > 0) ob_end_clean();
    if (!headers_sent()) header("Content-Type: application/json");
    echo json_encode(['status' => 'error', 'message' => 'Invalid email format.']);
    exit;
}

// Split name into first_name and last_name (simple split by first space)
$name_parts = explode(' ', $name, 2);
$first_name = $name_parts[0];
$last_name = isset($name_parts[1]) ? $name_parts[1] : ''; // Handle cases where there is no last name

// Check if user already exists (by phone and country_code)
$stmt_check_user = $conn->prepare("SELECT id FROM users WHERE phone = ? AND country_code = ?");
if (!$stmt_check_user) {
    error_log("register_user.php: User check statement preparation failed: " . $conn->error);
    if (ob_get_level() > 0) ob_end_clean();
    if (!headers_sent()) header("Content-Type: application/json");
    echo json_encode(['status' => 'error', 'message' => 'Server error during user check preparation. Please try again.']);
    exit;
}
$stmt_check_user->bind_param("ss", $phone, $country_code);
$stmt_check_user->execute();
$result_check_user = $stmt_check_user->get_result();
if ($result_check_user->num_rows > 0) {
    $stmt_check_user->close();
    if (ob_get_level() > 0) ob_end_clean();
    if (!headers_sent()) header("Content-Type: application/json");
    echo json_encode(['status' => 'error', 'message' => 'This phone number is already registered.']);
    exit;
}
$stmt_check_user->close();

$conn->begin_transaction();

try {
    // Insert into users table, explicitly setting created_at and updated_at
    $sql_user = "INSERT INTO users (first_name, last_name, email, phone, country_code, address, role, is_active, profile_image, wallet_balance, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, 'customer', 1, NULL, 0.00, NOW(), NOW())";
    $stmt_user = $conn->prepare($sql_user);
    if (!$stmt_user) {
        throw new Exception("User statement preparation failed: " . $conn->error);
    }
    // Bind parameters for the user details (created_at and updated_at are set by NOW() in SQL)
    $stmt_user->bind_param("ssssss", $first_name, $last_name, $email, $phone, $country_code, $address);
    if (!$stmt_user->execute()) {
        throw new Exception("Failed to register user: " . $stmt_user->error);
    }
    $user_id = $stmt_user->insert_id;
    $stmt_user->close();

    // If vehicle details are provided, add them
    if (!empty($vehicle_no) && !empty($vehicle_type) && !empty($vehicle_model)) {
        // Corrected userTb to user_id
        $sql_vehicle = "INSERT INTO vehicles (user_id, vehicle_no, vehicle_type, vehicle_model) VALUES (?, ?, ?, ?)";
        $stmt_vehicle = $conn->prepare($sql_vehicle);
        if (!$stmt_vehicle) {
            throw new Exception("Vehicle statement preparation failed: " . $conn->error);
        }
        $stmt_vehicle->bind_param("isss", $user_id, $vehicle_no, $vehicle_type, $vehicle_model);
        if (!$stmt_vehicle->execute()) {
            throw new Exception("Failed to add vehicle details: " . $stmt_vehicle->error);
        }
        $stmt_vehicle->close();
    }

    $conn->commit();

    // Fetch the newly created user data, including created_at and updated_at
    $stmt_get_user = $conn->prepare("SELECT id, first_name, last_name, email, phone, country_code, address, role, is_active, profile_image, wallet_balance, created_at, updated_at FROM users WHERE id = ?");
    if (!$stmt_get_user) {
        throw new Exception("Failed to prepare statement to fetch new user: " . $conn->error);
    }
    $stmt_get_user->bind_param("i", $user_id);
    $stmt_get_user->execute();
    $result_get_user = $stmt_get_user->get_result();
    $user_data = $result_get_user->fetch_assoc();
    $stmt_get_user->close();

    if (!$user_data) {
         throw new Exception("Failed to retrieve newly registered user data.");
    }
    
    // Construct the 'name' field for the response from first_name and last_name
    $user_data['name'] = trim($user_data['first_name'] . ' ' . $user_data['last_name']);

    if (ob_get_level() > 0) ob_end_clean();
    if (!headers_sent()) header("Content-Type: application/json");
    echo json_encode([
        'status' => 'success',
        'message' => 'User registered successfully.',
        'user_data' => $user_data
    ]);
    exit;

} catch (Exception $e) {
    $conn->rollback();
    error_log("register_user.php: Transaction Error: " . $e->getMessage());
    if (ob_get_level() > 0) ob_end_clean();
    if (!headers_sent()) header("Content-Type: application/json");
    echo json_encode(['status' => 'error', 'message' => 'Registration failed: ' . $e->getMessage()]);
    exit;
}

// Fallback exit, should have been exited earlier.
if ($conn && $conn instanceof mysqli) {
    $conn->close();
}
if (ob_get_level() > 0) ob_end_clean();
if (!headers_sent()) header("Content-Type: application/json");
echo json_encode(['status' => 'error', 'message' => 'PHP: Reached end of script unexpectedly in register_user.php.']);
exit;
?>