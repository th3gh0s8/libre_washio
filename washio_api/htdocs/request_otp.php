<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: application/json');
require __DIR__ . '/db.php'; // Ensures db.php is included from the same directory

// CRITICAL CHECK: Verify $conn from db.php after include
if (!isset($conn) || !$conn instanceof mysqli) {
    error_log("request_otp.php: DB connection object (\$conn) is invalid after requiring db.php. Check db.php execution and connection logic. Actual type: " . (isset($conn) ? gettype($conn) : 'not set'));
    echo json_encode([
        'status' => 'error',
        'message' => 'Internal server error: Database connection is not valid. Please check server logs.'
    ]);
    exit;
}

$local_phone_from_post = isset($_POST['phone']) ? trim($_POST['phone']) : null;
$country_code_from_post = isset($_POST['country_code']) ? trim($_POST['country_code']) : null;

if (empty($local_phone_from_post) || empty($country_code_from_post)) {
    error_log("request_otp.php: Validation failed. country_code: '" . ($country_code_from_post ?? 'NULL') . "', phone: '" . ($local_phone_from_post ?? 'NULL') . "'");
    echo json_encode(['status' => 'error', 'message' => 'Phone number and country code are required and cannot be empty.']);
    exit;
}

$otp = rand(100000, 999999);
$user_id_for_otp = null; 
$otp_request_purpose = 'register'; // Default purpose

$conn->begin_transaction();

try {
    $stmt_find_user = $conn->prepare("SELECT id FROM users WHERE country_code = ? AND phone = ?");
    if (!$stmt_find_user) throw new Exception("User find statement preparation failed: " . $conn->error);
    $stmt_find_user->bind_param("ss", $country_code_from_post, $local_phone_from_post);
    
    if ($stmt_find_user->execute()) {
        $result_user = $stmt_find_user->get_result();
        if ($user_row = $result_user->fetch_assoc()) {
            $user_id_for_otp = $user_row['id'];
            $otp_request_purpose = 'login';
        }
    }
    $stmt_find_user->close();

    // Corrected to use `request_type` column
    $stmt_deactivate = $conn->prepare("UPDATE web_codes SET is_active = 0 WHERE country_code = ? AND mobile_number = ? AND request_type = ?");
    if (!$stmt_deactivate) throw new Exception("Deactivation statement preparation failed: " . $conn->error);
    $stmt_deactivate->bind_param("sss", $country_code_from_post, $local_phone_from_post, $otp_request_purpose);
    $stmt_deactivate->execute(); // Execute but don't treat failure as fatal
    $stmt_deactivate->close();

    $otp_str = strval($otp);
    
    // Corrected INSERT statement to match the new schema
    // It uses `request_type` and relies on the DB for `requested_at`
    $stmt_insert = $conn->prepare("INSERT INTO web_codes (country_code, mobile_number, otp_code, user_id, is_active, request_type) VALUES (?, ?, ?, ?, 1, ?)");
    if (!$stmt_insert) throw new Exception("Insertion statement preparation failed: " . $conn->error);
    
    // Corrected bind_param to match the new query (sssis)
    $stmt_insert->bind_param("sssis", $country_code_from_post, $local_phone_from_post, $otp_str, $user_id_for_otp, $otp_request_purpose);
    
    if ($stmt_insert->execute()) {
        $conn->commit();
        echo json_encode([
            'status' => 'success', 
            'message' => 'OTP generated successfully.', 
            'otp_purpose' => $otp_request_purpose, 
            'otp_for_testing' => $otp // For testing purposes, remove in production
        ]);
    } else {
        throw new Exception("Failed to store OTP: " . $stmt_insert->error);
    }
    $stmt_insert->close();

} catch (Exception $e) {
    if ($conn && $conn instanceof mysqli && $conn->thread_id) {
        $conn->rollback();
    }
    error_log("request_otp.php Error: " . $e->getMessage() . " for Input: " . json_encode($_POST));
    echo json_encode(['status' => 'error', 'message' => 'Could not process OTP request. ' . $e->getMessage()]);
}

if ($conn && $conn instanceof mysqli) {
    $conn->close();
}
?>