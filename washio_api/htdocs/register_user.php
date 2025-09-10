<?php
// Enable full error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: application/json');
require __DIR__ . '/db.php'; 

// CRITICAL: Check database connection
if (!isset($conn) || !$conn instanceof mysqli) {
    error_log("register_user.php: DB connection object is invalid after requiring db.php.");
    echo json_encode([
        'status' => 'error',
        'message' => 'Database connection object ($conn) is invalid. Check db.php script.',
        'conn_variable_type' => isset($conn) ? gettype($conn) : 'not set'
    ]);
    exit;
}
error_log("register_user.php: DB connection appears valid.");

error_log("register_user.php: Accessed. Raw POST data: " . file_get_contents('php://input'));
error_log("register_user.php: Parsed _POST array: " . json_encode($_POST));

// Get POST data for user
$fullNameFromPost = isset($_POST['name']) ? trim($_POST['name']) : null; // This is the full name
$email = isset($_POST['email']) ? trim($_POST['email']) : null;
$phone = isset($_POST['phone']) ? trim($_POST['phone']) : null;
$country_code = isset($_POST['country_code']) ? trim($_POST['country_code']) : null;
$address = isset($_POST['address']) ? trim($_POST['address']) : null;

$vehicle_no = isset($_POST['vehicle_no']) ? trim($_POST['vehicle_no']) : null;
$vehicle_type = isset($_POST['vehicle_type']) ? trim($_POST['vehicle_type']) : null;
$vehicle_model = isset($_POST['vehicle_model']) ? trim($_POST['vehicle_model']) : null;

if (empty($fullNameFromPost) || empty($email) || empty($phone) || empty($country_code)) {
    echo json_encode(['status' => 'error', 'message' => 'Required user fields are missing (name, email, phone, country_code).']);
    exit;
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode(['status' => 'error', 'message' => 'Invalid email format.']);
    exit;
}

// Split the full name into first_name and last_name
$name_parts = explode(' ', $fullNameFromPost, 2);
$first_name = $name_parts[0];
$last_name = isset($name_parts[1]) ? trim($name_parts[1]) : ''; // Ensure last_name is empty string if not present, not null for DB

$has_vehicle_details = false;
if (!empty($vehicle_no) || !empty($vehicle_type) || !empty($vehicle_model)) {
    if (empty($vehicle_no) || empty($vehicle_type) || empty($vehicle_model)) {
        echo json_encode(['status' => 'error', 'message' => 'If providing any vehicle details, all fields (vehicle number, type, model) are required.']);
        exit;
    }
    $has_vehicle_details = true;
}

$conn->begin_transaction();

try {
    $stmt_check_user = $conn->prepare("SELECT id FROM users WHERE phone = ? AND country_code = ?");
    if (!$stmt_check_user) throw new Exception("User check statement preparation failed: " . $conn->error);
    $stmt_check_user->bind_param("ss", $phone, $country_code);
    $stmt_check_user->execute();
    $result_check_user = $stmt_check_user->get_result();
    if ($result_check_user->num_rows > 0) {
        $stmt_check_user->close();
        $conn->rollback(); 
        echo json_encode(['status' => 'error', 'message' => 'User with this phone number already exists.']);
        exit;
    }
    $stmt_check_user->close();

    $stmt_check_email = $conn->prepare("SELECT id FROM users WHERE email = ?");
    if (!$stmt_check_email) throw new Exception("Email check statement preparation failed: " . $conn->error);
    $stmt_check_email->bind_param("s", $email);
    $stmt_check_email->execute();
    $result_check_email = $stmt_check_email->get_result();
    if ($result_check_email->num_rows > 0) {
        $stmt_check_email->close();
        $conn->rollback();
        echo json_encode(['status' => 'error', 'message' => 'This email address is already registered.']);
        exit;
    }
    $stmt_check_email->close();

    $default_role = 'customer'; // Matching your 'DESCRIBE users' output for role
    $default_wallet_balance = 0.00;
    $default_is_active = 1; 
    $address_to_save = (empty($address) || is_null($address)) ? NULL : $address;

    // MODIFIED INSERT: Use first_name and last_name
    $sql_insert_user = "INSERT INTO users (first_name, last_name, email, phone, country_code, address, wallet_balance, role, is_active, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())";
    $stmt_insert_user = $conn->prepare($sql_insert_user);
    if (!$stmt_insert_user) throw new Exception("User insertion statement preparation failed: " . $conn->error);
    // Parameters: first_name, last_name, email, phone, country_code, address, wallet_balance, role, is_active
    $stmt_insert_user->bind_param("ssssssdss", $first_name, $last_name, $email, $phone, $country_code, $address_to_save, $default_wallet_balance, $default_role, $default_is_active);
    
    if ($stmt_insert_user->execute()) {
        $new_user_id = $stmt_insert_user->insert_id;
        error_log("register_user.php: User inserted successfully. New User ID: " . $new_user_id);
        $stmt_insert_user->close();

        if ($has_vehicle_details) {
            error_log("register_user.php: Attempting to insert vehicle details for User ID: " . $new_user_id);
            // Assuming 'vehicle' table has userTB linking to users.id
            $sql_insert_vehicle = "INSERT INTO vehicle (userTB, vehicle_no, vehicle_type, vehicle_model) VALUES (?, ?, ?, ?)";
            $stmt_insert_vehicle = $conn->prepare($sql_insert_vehicle);
            if (!$stmt_insert_vehicle) throw new Exception("Vehicle insertion statement preparation failed: " . $conn->error);
            $stmt_insert_vehicle->bind_param("isss", $new_user_id, $vehicle_no, $vehicle_type, $vehicle_model);
            if (!$stmt_insert_vehicle->execute()) throw new Exception("Failed to insert vehicle details: " . $stmt_insert_vehicle->error);
            error_log("register_user.php: Vehicle details inserted for User ID: " . $new_user_id);
            $stmt_insert_vehicle->close();
        }
        
        // MODIFIED SELECT: Fetch first_name, last_name to construct combined name
        // Ensure all other columns match your 'DESCRIBE users' for consistency
        $stmt_get_new_user = $conn->prepare("SELECT id, first_name, last_name, email, phone, country_code, profile_image, address, wallet_balance, role, is_active FROM users WHERE id = ?");
        if (!$stmt_get_new_user) throw new Exception("Failed to prepare statement to fetch new user data: " . $conn->error);
        $stmt_get_new_user->bind_param("i", $new_user_id);
        if (!$stmt_get_new_user->execute()) throw new Exception("Failed to execute statement to fetch new user data: " . $stmt_get_new_user->error);
        
        $new_user_data_result = $stmt_get_new_user->get_result();
        $new_user_data_row = $new_user_data_result->fetch_assoc();
        $stmt_get_new_user->close();

        if ($new_user_data_row) {
            // Construct the 'name' field for the response
            $constructed_full_name = trim(($new_user_data_row['first_name'] ?? '') . ' ' . ($new_user_data_row['last_name'] ?? ''));
            $new_user_data_row['name'] = $constructed_full_name ?: null;
             // Optionally unset first_name and last_name if client only expects 'name'
            // unset($new_user_data_row['first_name']);
            // unset($new_user_data_row['last_name']);
        }

        $conn->commit();
        echo json_encode([
            'status' => 'success',
            'message' => 'User registered successfully' . ($has_vehicle_details ? ' with vehicle details.' : '.'),
            'user_data' => $new_user_data_row // This now includes the 'name' field
        ]);
    } else {
        throw new Exception("Failed to register user: " . $stmt_insert_user->error);
    }

} catch (Exception $e) {
    if ($conn->server_status & MYSQLI_TRANS_ACTIVE) {
        $conn->rollback();
    }
    error_log("register_user.php: Server Error: " . $e->getMessage() . " Raw POST: " . json_encode($_POST));
    echo json_encode(['status' => 'error', 'message' => 'Server Error: ' . $e->getMessage()]);
}

if ($conn) {
    $conn->close();
}
?>