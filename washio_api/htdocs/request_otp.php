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
error_log("request_otp.php: DB connection object from db.php appears to be a valid mysqli object.");

$local_phone_from_post = isset($_POST['phone']) ? trim($_POST['phone']) : null;
$country_code_from_post = isset($_POST['country_code']) ? trim($_POST['country_code']) : null;

if (empty($local_phone_from_post) || empty($country_code_from_post)) {
    error_log("request_otp.php: Validation failed. country_code: '" . ($country_code_from_post ?? 'NULL') . "', phone: '" . ($local_phone_from_post ?? 'NULL') . "'");
    echo json_encode(['status' => 'error', 'message' => 'Phone number and country code are required and cannot be empty.']);
    exit;
}
error_log("request_otp.php: Received country_code: " . $country_code_from_post . ", phone: " . $local_phone_from_post);

$otp = rand(100000, 999999);
$user_id_for_otp = null; 
$otp_request_purpose = 'register'; // Default purpose

$conn->begin_transaction();

try {
    error_log("request_otp.php: Checking for existing user with CC: $country_code_from_post, Phone: $local_phone_from_post");
    $stmt_find_user = $conn->prepare("SELECT id FROM users WHERE country_code = ? AND phone = ?");
    if (!$stmt_find_user) {
        throw new Exception("User find statement preparation failed: " . $conn->error);
    }
    $stmt_find_user->bind_param("ss", $country_code_from_post, $local_phone_from_post);
    
    if ($stmt_find_user->execute()) {
        $result_user = $stmt_find_user->get_result();
        if ($user_row = $result_user->fetch_assoc()) {
            $user_id_for_otp = $user_row['id'];
            $otp_request_purpose = 'login';
            error_log("request_otp.php: User found. ID: " . $user_id_for_otp . ". OTP Purpose set to: " . $otp_request_purpose);
        } else {
            error_log("request_otp.php: User not found. OTP Purpose remains: " . $otp_request_purpose);
        }
    } else {
        error_log("request_otp.php: User find query execution failed: " . $stmt_find_user->error);
        // Decide if this is a fatal error or if we can proceed with registration OTP
    }
    $stmt_find_user->close();

    error_log("request_otp.php: Deactivating old OTPs for CC: $country_code_from_post, Phone: $local_phone_from_post, Purpose: $otp_request_purpose");
    $stmt_deactivate = $conn->prepare("UPDATE web_codes SET is_active = 0 WHERE country_code = ? AND mobile_number = ? AND requested_at = ?");
    if (!$stmt_deactivate) {
        throw new Exception("Deactivation statement preparation failed: " . $conn->error);
    }
    $stmt_deactivate->bind_param("sss", $country_code_from_post, $local_phone_from_post, $otp_request_purpose);
    if (!$stmt_deactivate->execute()) {
        error_log("request_otp.php: Deactivating old OTPs failed: " . $stmt_deactivate->error . ". Continuing...");
        // This might not be a fatal error, an OTP can still be sent.
    }
    $stmt_deactivate->close();

    $otp_str = strval($otp);
    error_log("request_otp.php: Inserting new OTP: $otp_str for CC: $country_code_from_post, Phone: $local_phone_from_post, UserID for OTP (userTb): " . ($user_id_for_otp ?? 'NULL') . ", Purpose (requested_at): $otp_request_purpose");
    
    // Ensure the table name `web_codes` and column names match your DB schema exactly.
    $stmt_insert = $conn->prepare("INSERT INTO web_codes (country_code, mobile_number, otp_code, userTb, is_active, requested_dateTime, requested_at) VALUES (?, ?, ?, ?, 1, NOW(), ?)");
    if (!$stmt_insert) {
        throw new Exception("Insertion statement preparation failed: " . $conn->error);
    }
    // Note: Parameter types 'sssis' - $user_id_for_otp is an integer (i) or null.
    $stmt_insert->bind_param("sssis", $country_code_from_post, $local_phone_from_post, $otp_str, $user_id_for_otp, $otp_request_purpose);
    
    if ($stmt_insert->execute()) {
        $conn->commit();
        error_log("request_otp.php: OTP $otp_str stored successfully.");
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
    // SIMPLIFIED ROLLBACK CHECK
    if ($conn && $conn instanceof mysqli && $conn->thread_id) { // Check if $conn is a valid, active connection
        $conn->rollback();
        error_log("request_otp.php: Transaction rolled back due to exception.");
    } else {
        error_log("request_otp.php: Transaction NOT rolled back. Connection object might be invalid or no active transaction detected simply.");
    }
    // END SIMPLIFIED ROLLBACK CHECK

    error_log("request_otp.php Error: " . $e->getMessage() . " for CC: $country_code_from_post, Phone: $local_phone_from_post. Input POST: " . json_encode($_POST));
    echo json_encode(['status' => 'error', 'message' => 'Could not process OTP request. ' . $e->getMessage()]);
}

if ($conn && $conn instanceof mysqli) { // Ensure $conn is valid before closing
    $conn->close();
}
?>