<?php
@ini_set('display_errors', 0);
@error_reporting(0);

header('Content-Type: application/json');
include 'db.php'; // Your database connection using $host = "localhost";

// CRITICAL: Check database connection immediately after include
if (!isset($conn) || $conn->connect_error) {
    echo json_encode(['status' => 'error', 'message' => 'Database connection failed: ' . (isset($conn) ? $conn->connect_error : 'Unknown error')]);
    exit;
}

// Get POST data
$name = $_POST['name'] ?? null;
$email = $_POST['email'] ?? null;
$phone = $_POST['phone'] ?? null; // Local phone number part
$country_code = $_POST['country_code'] ?? null;
$address = $_POST['address'] ?? null; // Optional

// Basic validation
if (empty($name) || empty($email) || empty($phone) || empty($country_code)) {
    echo json_encode(['status' => 'error', 'message' => 'Required fields are missing (name, email, phone, country_code).']);
    exit;
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode(['status' => 'error', 'message' => 'Invalid email format.']);
    exit;
}

$full_phone_number_for_check = $country_code . $phone;

// Start transaction
$conn->begin_transaction();

try {
    // Safeguard: Check if user with this phone number already exists
    $stmt_check_user = $conn->prepare("SELECT id FROM users WHERE phone = ? AND country_code = ?");
    if (!$stmt_check_user) {
        throw new Exception("User check statement preparation failed: " . $conn->error);
    }
    $stmt_check_user->bind_param("ss", $phone, $country_code);
    $stmt_check_user->execute();
    $result_check_user = $stmt_check_user->get_result();
    if ($result_check_user->num_rows > 0) {
        $stmt_check_user->close();
        $conn->rollback(); // No need to proceed if user already exists by some chance
        echo json_encode(['status' => 'error', 'message' => 'User with this phone number already exists.']);
        exit;
    }
    $stmt_check_user->close();

    // Optional: Check if email is used by another account (different phone number)
    $stmt_check_email = $conn->prepare("SELECT id FROM users WHERE email = ?");
    if (!$stmt_check_email) {
        throw new Exception("Email check statement preparation failed: " . $conn->error);
    }
    $stmt_check_email->bind_param("s", $email);
    $stmt_check_email->execute();
    $result_check_email = $stmt_check_email->get_result();
    if ($result_check_email->num_rows > 0) {
        $stmt_check_email->close();
        $conn->rollback();
        echo json_encode(['status' => 'error', 'message' => 'This email address is already registered with another account.']);
        exit;
    }
    $stmt_check_email->close();

    // Insert new user
    // Columns: id, name, email, phone, country_code, profile_image, address, wallet_balance, role, is_active, created_at, updated_at
    $default_role = 'user';
    $default_wallet_balance = 0.00;
    $default_is_active = 1;
    // profile_image can be NULL or a default path string

    $sql_insert_user = "INSERT INTO users (name, email, phone, country_code, address, wallet_balance, role, is_active, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())";
    $stmt_insert_user = $conn->prepare($sql_insert_user);
    if (!$stmt_insert_user) {
        throw new Exception("User insertion statement preparation failed: " . $conn->error);
    }
    // Types: s (name), s (email), s (phone), s (country_code), s (address), d (wallet_balance), s (role), i (is_active)
    $stmt_insert_user->bind_param("sssssdsi", $name, $email, $phone, $country_code, $address, $default_wallet_balance, $default_role, $default_is_active);
    
    if ($stmt_insert_user->execute()) {
        $new_user_id = $stmt_insert_user->insert_id;
        $conn->commit();
        echo json_encode([
            'status' => 'success',
            'message' => 'User registered successfully.',
            'user_id' => $new_user_id
        ]);
    } else {
        throw new Exception("Failed to register user: " . $stmt_insert_user->error);
    }
    $stmt_insert_user->close();

} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(['status' => 'error', 'message' => 'Server Error: ' . $e->getMessage()]);
}

$conn->close();
?>
