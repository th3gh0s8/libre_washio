<?php
@ini_set('display_errors', 0);
@error_reporting(0);

header('Content-Type: application/json');
include 'db.php'; // Your database connection

if (!isset($conn) || $conn->connect_error) {
    echo json_encode(['status' => 'error', 'message' => 'Database connection failed: ' . (isset($conn) ? $conn->connect_error : 'Unknown error')]);
    exit;
}

$local_phone_from_post = $_POST['phone'] ?? null;
$country_code_from_post = $_POST['country_code'] ?? null;

if (!$local_phone_from_post || !$country_code_from_post) {
    echo json_encode(['status' => 'error', 'message' => 'Phone number and country code are required.']);
    exit;
}

$otp = rand(100000, 999999);
$user_id_for_otp = null; // Initialize user_id for OTP record
$code_from = 'register';   // Default to 'register', will be updated if user exists

$conn->begin_transaction();

try {
    // 1. Find User ID from users table (if user exists)
    $stmt_find_user = $conn->prepare("SELECT id FROM users WHERE country_code = ? AND phone = ?");
    if (!$stmt_find_user) {
        throw new Exception("User find statement preparation failed: " . $conn->error);
    }
    $stmt_find_user->bind_param("ss", $country_code_from_post, $local_phone_from_post);
    if ($stmt_find_user->execute()) {
        $result_user = $stmt_find_user->get_result();
        if ($user_row = $result_user->fetch_assoc()) {
            $user_id_for_otp = $user_row['id'];
            $code_from = 'login'; // User exists, so this OTP is for login
        }
    } else {
        error_log("Failed to execute user find query during OTP request: " . $stmt_find_user->error);
        // Continue with $code_from = 'register' by default if query fails or user not found
    }
    $stmt_find_user->close();

    // 2. Deactivate old OTPs for this number and the determined purpose
    $stmt_deactivate = $conn->prepare("UPDATE web_codes SET isActive = 0 WHERE country_code = ? AND mobile_number = ? AND code_from = ?");
    if (!$stmt_deactivate) {
        throw new Exception("Deactivation statement preparation failed: " . $conn->error);
    }
    $stmt_deactivate->bind_param("sss", $country_code_from_post, $local_phone_from_post, $code_from);
    if (!$stmt_deactivate->execute()) {
        throw new Exception("Failed to deactivate old OTPs: " . $stmt_deactivate->error);
    }
    $stmt_deactivate->close();

    // 3. Insert the new OTP, including userTb and the determined code_from
    $stmt_insert = $conn->prepare("INSERT INTO web_codes (country_code, mobile_number, codes, userTb, isActive, rDateTime, code_from) VALUES (?, ?, ?, ?, 1, NOW(), ?)");
    if (!$stmt_insert) {
        throw new Exception("Insertion statement preparation failed: " . $conn->error);
    }
    $otp_str = strval($otp);
    $stmt_insert->bind_param("sssis", $country_code_from_post, $local_phone_from_post, $otp_str, $user_id_for_otp, $code_from); 
    
    if ($stmt_insert->execute()) {
        $conn->commit();
        // Return code_from in the response so the client knows what type of OTP was generated.
        echo json_encode(['status' => 'success', 'message' => 'OTP generated successfully.', 'otp_purpose' => $code_from, 'otp' => $otp]); // For testing
    } else {
        throw new Exception("Failed to store OTP: " . $stmt_insert->error);
    }
    $stmt_insert->close();

} catch (Exception $e) {
    $conn->rollback();
    error_log("Request OTP Error: " . $e->getMessage() . " for CC: $country_code_from_post, Phone: $local_phone_from_post");
    echo json_encode(['status' => 'error', 'message' => 'Could not process OTP request. Please try again later.']);
}

$conn->close();
?>