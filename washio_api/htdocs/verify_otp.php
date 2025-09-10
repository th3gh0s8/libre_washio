<?php
// Cache buster: <?php echo time(); ?>
// Enable full error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: application/json');

require __DIR__ . '/db.php';

if (!isset($conn) || !$conn instanceof mysqli) {
    error_log("verify_otp.php: DB connection object is invalid. Check db.php.");
    echo json_encode(['status' => 'error','message' => 'Database connection object invalid.','conn_variable_type' => isset($conn) ? gettype($conn) : 'not set']);
    exit;
}
error_log("verify_otp.php: DB connection appears valid.");

error_log("verify_otp.php: Accessed. Raw POST data: " . file_get_contents('php://input'));
error_log("verify_otp.php: Parsed _POST array: " . json_encode($_POST));

$posted_country_code = isset($_POST['country_code']) ? trim($_POST['country_code']) : '';
$posted_local_phone = isset($_POST['local_phone_number']) ? trim($_POST['local_phone_number']) : '';
$otp_entered = isset($_POST['otp']) ? trim($_POST['otp']) : '';
$posted_otp_purpose = isset($_POST['otp_purpose']) ? trim($_POST['otp_purpose']) : ''; // e.g., 'login' or 'register'

if (empty($posted_country_code) || empty($posted_local_phone) || empty($otp_entered) || empty($posted_otp_purpose)) {
    error_log("verify_otp.php: Validation failed. CC: '$posted_country_code', Phone: '$posted_local_phone', OTP: '$otp_entered', Purpose: '$posted_otp_purpose'");
    echo json_encode(['status' => 'error', 'message' => 'Country code, phone number, OTP, and OTP purpose are required and cannot be empty.']);
    exit;
}

if ($posted_otp_purpose !== 'login' && $posted_otp_purpose !== 'register') {
    error_log("verify_otp.php: Invalid OTP purpose specified: '$posted_otp_purpose'");
    echo json_encode(['status' => 'error', 'message' => 'Invalid OTP purpose specified by client.']);
    exit;
}
error_log("verify_otp.php: Inputs valid. CC: $posted_country_code, Phone: $posted_local_phone, OTP: $otp_entered, Purpose: $posted_otp_purpose");

$conn->begin_transaction();

try {
    error_log("verify_otp.php: Checking OTP. CC: $posted_country_code, Phone: $posted_local_phone, OTP: $otp_entered, Purpose: $posted_otp_purpose");
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
        error_log("verify_otp.php: OTP matched. web_codes.ID: $web_code_id");

        $stmt_deactivate = $conn->prepare("UPDATE web_codes SET is_active = 0 WHERE ID = ?");
        if (!$stmt_deactivate) {
            throw new Exception("OTP deactivation statement preparation failed: " . $conn->error);
        }
        $stmt_deactivate->bind_param("i", $web_code_id);
        if (!$stmt_deactivate->execute()) {
            throw new Exception("Failed to deactivate OTP: " . $stmt_deactivate->error);
        }
        $stmt_deactivate->close();
        error_log("verify_otp.php: OTP deactivated. web_codes.ID: $web_code_id");

        $user_exists = false;
        $user_data = null;
        
        error_log("verify_otp.php: Checking for user. CC: $posted_country_code, Phone: $posted_local_phone");
        // MODIFIED SQL: Select first_name and last_name instead of name
        // Also ensure other columns match your DESCRIBE users output for consistency
        $stmt_find_user = $conn->prepare(
            "SELECT id, first_name, last_name, email, phone, country_code, profile_image, address, wallet_balance, role, is_active FROM users WHERE country_code = ? AND phone = ?"
        );
        if (!$stmt_find_user) {
            throw new Exception("User find statement preparation failed: " . $conn->error);
        }
        $stmt_find_user->bind_param("ss", $posted_country_code, $posted_local_phone);
        
        if ($stmt_find_user->execute()) {
            $user_result = $stmt_find_user->get_result();
            if ($user_details_row = $user_result->fetch_assoc()) {
                $user_exists = true;
                $user_data = $user_details_row; // Contains first_name, last_name

                // Construct the 'name' field for the response
                $fullName = trim(($user_data['first_name'] ?? '') . ' ' . ($user_data['last_name'] ?? ''));
                $user_data['name'] = $fullName ?: null; // Assign combined name, or null if both were empty/null
                // Remove original first_name and last_name from the response if you only want 'name'
                // unset($user_data['first_name']);
                // unset($user_data['last_name']);
                // For now, let's keep them and also provide 'name'

                error_log("verify_otp.php: User found. UserID: " . $user_data['id'] . ". Full name: " . $user_data['name']);
            } else {
                error_log("verify_otp.php: User not found with this phone number.");
            }
        } else {
            error_log("verify_otp.php: Failed to execute user find query: " . $stmt_find_user->error);
        }
        $stmt_find_user->close();
        
        $conn->commit();
        error_log("verify_otp.php: Verification successful.");
        echo json_encode([
            'status' => 'success', 
            'message' => 'OTP verified successfully.',
            'user_exists' => $user_exists,
            'user_data' => $user_data, // This will now include the 'name' field
            'otp_purpose_verified' => $posted_otp_purpose
        ]);

    } else {
        $conn->rollback();
        error_log("verify_otp.php: OTP verification failed - Invalid, expired, or incorrect purpose. CC: $posted_country_code, Phone: $posted_local_phone, OTP: $otp_entered, Purpose: $posted_otp_purpose");
        echo json_encode(['status' => 'error', 'message' => 'Invalid or expired OTP, or OTP purpose mismatch. Please check and try again.']);
    }

} catch (Exception $e) {
    if ($conn->server_status & MYSQLI_TRANS_ACTIVE) { 
        $conn->rollback();
    }
    error_log("Verify OTP Error: " . $e->getMessage() . " for inputs: CC: $posted_country_code, Phone: $posted_local_phone, OTP: $otp_entered, Purpose: $posted_otp_purpose. SQL Error: " . $conn->error);
    echo json_encode(['status' => 'error', 'message' => 'Server Error during OTP verification. ' . $e->getMessage()]);
}

if ($conn) {
    $conn->close();
}
?>