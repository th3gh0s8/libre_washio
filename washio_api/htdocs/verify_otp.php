<?php
ob_start(); // Start output buffering at the very beginning

// Error settings
error_reporting(E_ALL);
ini_set('display_errors', 0); // Errors will be logged, not displayed
ini_set('log_errors', 1);

// Set JSON header if not already set by a premature exit in db.php (e.g. connection failure)
if (!headers_sent()) {
    header('Content-Type: application/json');
}

require __DIR__ . '/db.php'; // db.php will ob_start(), connect, and exit with JSON on connection error.

// If db.php somehow failed to connect AND failed to exit cleanly (should not happen with current db.php)
if (!isset($conn) || !$conn instanceof mysqli) {
    error_log("verify_otp.php: CRITICAL - DB connection object is invalid AFTER db.php include and db.php did not exit as expected.");
    ob_end_clean(); // Clean buffer
    if (!headers_sent()) { header('Content-Type: application/json'); } // Defensive header
    echo json_encode(['status' => 'error','message' => 'PHP: Critical internal server error with DB connection handling.']);
    exit;
}

// error_log("verify_otp.php: DB connection appears valid from verify_otp.php perspective.");
// error_log("verify_otp.php: Accessed. Raw POST data: " . file_get_contents('php://input'));
// error_log("verify_otp.php: Parsed _POST array: " . json_encode($_POST));

$posted_country_code = isset($_POST['country_code']) ? trim($_POST['country_code']) : '';
$posted_local_phone = isset($_POST['local_phone_number']) ? trim($_POST['local_phone_number']) : '';
$otp_entered = isset($_POST['otp']) ? trim($_POST['otp']) : '';
$posted_otp_purpose = isset($_POST['otp_purpose']) ? trim($_POST['otp_purpose']) : '';

if (empty($posted_country_code) || empty($posted_local_phone) || empty($otp_entered) || empty($posted_otp_purpose)) {
    error_log("verify_otp.php: Validation failed. CC: '$posted_country_code', Phone: '$posted_local_phone', OTP: '$otp_entered', Purpose: '$posted_otp_purpose'");
    ob_end_clean(); // Clean buffer
    if (!headers_sent()) { header('Content-Type: application/json'); }
    echo json_encode(['status' => 'error', 'message' => 'Country code, phone number, OTP, and OTP purpose are required.']);
    exit;
}

if ($posted_otp_purpose !== 'login' && $posted_otp_purpose !== 'register') {
    error_log("verify_otp.php: Invalid OTP purpose specified: '$posted_otp_purpose'");
    ob_end_clean(); // Clean buffer
    if (!headers_sent()) { header('Content-Type: application/json'); }
    echo json_encode(['status' => 'error', 'message' => 'Invalid OTP purpose specified by client.']);
    exit;
}
// error_log("verify_otp.php: Inputs valid. CC: $posted_country_code, Phone: $posted_local_phone, OTP: $otp_entered, Purpose: $posted_otp_purpose");

$conn->begin_transaction();

try {
    // error_log("verify_otp.php: Checking OTP. CC: $posted_country_code, Phone: $posted_local_phone, OTP: $otp_entered, Purpose: $posted_otp_purpose");
    error_log("verify_otp.php: DETAILED CHECK PARAMS -> CC: [\"$posted_country_code\"], Phone: [\"$posted_local_phone\"], OTP: [\"$otp_entered\"], Purpose: [\"$posted_otp_purpose\"]");

    $stmt_check = $conn->prepare(
        "SELECT ID, userTb FROM web_codes WHERE country_code = ? AND mobile_number = ? AND otp_codes = ? AND requested_at = ? AND is_active = 1 AND requested_dateTime >= NOW() - INTERVAL 10 MINUTE"
    );
    if (!$stmt_check) {
        throw new Exception("OTP check statement preparation failed: " . $conn->error);
    }
    $stmt_check->bind_param("ssss", $posted_country_code, $posted_local_phone, $otp_entered, $posted_otp_purpose);
    
    if (!$stmt_check->execute()) {
        throw new Exception("Failed to execute OTP check: " . $stmt_check->error);
    }
    
    $result = $stmt_check->get_result();
    $web_code_entry = $result->fetch_assoc();
    $stmt_check->close();

    if ($web_code_entry) {
        $web_code_id = $web_code_entry['ID'];
        // error_log("verify_otp.php: OTP matched. web_codes.ID: $web_code_id");

        $stmt_deactivate = $conn->prepare("UPDATE web_codes SET is_active = 0 WHERE ID = ?");
        if (!$stmt_deactivate) throw new Exception("OTP deactivation statement preparation failed: " . $conn->error);
        $stmt_deactivate->bind_param("i", $web_code_id);
        if (!$stmt_deactivate->execute()) throw new Exception("Failed to deactivate OTP: " . $stmt_deactivate->error);
        $stmt_deactivate->close();
        // error_log("verify_otp.php: OTP deactivated. web_codes.ID: $web_code_id");

        $user_exists = false;
        $user_data = null;
        
        $stmt_find_user = $conn->prepare(
            "SELECT id, first_name, last_name, email, phone, country_code, profile_image, address, wallet_balance, role, is_active FROM users WHERE country_code = ? AND phone = ?"
        );
        if (!$stmt_find_user) throw new Exception("User find statement preparation failed: " . $conn->error);
        $stmt_find_user->bind_param("ss", $posted_country_code, $posted_local_phone);
        
        if ($stmt_find_user->execute()) {
            $user_result = $stmt_find_user->get_result();
            if ($user_details_row = $user_result->fetch_assoc()) {
                $user_exists = true;
                $user_data = $user_details_row; 
                $fullName = trim(($user_data['first_name'] ?? '') . ' ' . ($user_data['last_name'] ?? ''));
                $user_data['name'] = $fullName ?: null; 
            }
        } else {
            throw new Exception("Failed to execute user find query: " . $stmt_find_user->error);
        }
        $stmt_find_user->close();
        
        $conn->commit();
        // error_log("verify_otp.php: Verification successful.");
        ob_end_clean(); // Clean buffer
        if (!headers_sent()) { header('Content-Type: application/json'); }
        echo json_encode([
            'status' => 'success', 
            'message' => 'OTP verified successfully.',
            'user_exists' => $user_exists,
            'user_data' => $user_data, 
            'otp_purpose_verified' => $posted_otp_purpose
        ]);
        exit;

    } else {
        $conn->rollback();
        error_log("verify_otp.php: OTP verification failed (no matching active OTP). CC: $posted_country_code, Phone: $posted_local_phone, OTP: $otp_entered, Purpose: $posted_otp_purpose");
        ob_end_clean(); // Clean buffer
        if (!headers_sent()) { header('Content-Type: application/json'); }
        echo json_encode(['status' => 'error', 'message' => 'Invalid or expired OTP, or OTP purpose mismatch. Please check and try again.']);
        exit;
    }

} catch (Exception $e) {
    // SIMPLIFIED ROLLBACK CHECK
    if ($conn && $conn instanceof mysqli && $conn->thread_id) { // Check if $conn is a valid, active connection
        $conn->rollback();
        error_log("verify_otp.php: Transaction rolled back due to exception.");
    } else {
        error_log("verify_otp.php: Transaction NOT rolled back. Connection object might be invalid or no active transaction detected simply.");
    }
    // END SIMPLIFIED ROLLBACK CHECK

    error_log("Verify OTP Exception: " . $e->getMessage() . " for inputs: CC: $posted_country_code, Phone: $posted_local_phone, OTP: $otp_entered, Purpose: $posted_otp_purpose. SQL Error (if any): " . $conn->error);
    ob_end_clean(); // Clean buffer
    if (!headers_sent()) { header('Content-Type: application/json'); }
    echo json_encode(['status' => 'error', 'message' => 'Server Error during OTP verification: ' . $e->getMessage()]);
    exit;
}

// Fallback exit, should have been exited earlier.
if ($conn && $conn instanceof mysqli) {
    $conn->close();
}
ob_end_clean(); // Clean buffer if we somehow reach here
if (!headers_sent()) { header('Content-Type: application/json'); }
echo json_encode(['status' => 'error', 'message' => 'PHP: Reached end of script unexpectedly.']);
exit;
?>