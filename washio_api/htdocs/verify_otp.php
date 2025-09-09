<?php
@ini_set('display_errors', 0);
@error_reporting(0);

header('Content-Type: application/json');
include 'db.php'; // Your database connection

if (!isset($conn) || $conn->connect_error) {
    echo json_encode(['status' => 'error', 'message' => 'Database connection failed in verify_otp: ' . (isset($conn) ? $conn->connect_error : 'Unknown error')]);
    exit;
}

$posted_country_code = $_POST['country_code'] ?? null;
$posted_local_phone = $_POST['local_phone_number'] ?? null;
$otp_entered = $_POST['otp'] ?? null;
$posted_otp_purpose = $_POST['otp_purpose'] ?? null; // Expect 'login' or 'register' from client

if (!$posted_country_code || !$posted_local_phone || !$otp_entered || !$posted_otp_purpose) {
    echo json_encode(['status' => 'error', 'message' => 'Country code, phone number, OTP, and OTP purpose are required.']);
    exit;
}

// Validate otp_purpose to be one of the expected values
if ($posted_otp_purpose !== 'login' && $posted_otp_purpose !== 'register') {
    echo json_encode(['status' => 'error', 'message' => 'Invalid OTP purpose specified.']);
    exit;
}

$conn->begin_transaction();

try {
    // Check if the OTP is valid, active, and for the correct purpose
    $stmt_check = $conn->prepare("SELECT id, userTb FROM web_codes WHERE country_code = ? AND mobile_number = ? AND codes = ? AND isActive = 1 AND code_from = ? AND rDateTime >= NOW() - INTERVAL 10 MINUTE");
    if (!$stmt_check) {
        throw new Exception("OTP check statement preparation failed: " . $conn->error);
    }
    // Bind parameters: country_code, local_phone, otp_entered, posted_otp_purpose
    $stmt_check->bind_param("ssss", $posted_country_code, $posted_local_phone, $otp_entered, $posted_otp_purpose);
    
    if (!$stmt_check->execute()) {
        throw new Exception("Failed to execute OTP check: " . $stmt_check->error);
    }
    
    $result = $stmt_check->get_result();
    $web_code_entry = $result->fetch_assoc();
    $stmt_check->close();

    if ($web_code_entry) {
        $web_code_id = $web_code_entry['id'];

        // Deactivate the OTP
        $stmt_deactivate = $conn->prepare("UPDATE web_codes SET isActive = 0 WHERE id = ?");
        if (!$stmt_deactivate) {
            throw new Exception("OTP deactivation statement preparation failed: " . $conn->error);
        }
        $stmt_deactivate->bind_param("i", $web_code_id);
        if (!$stmt_deactivate->execute()) {
            throw new Exception("Failed to deactivate OTP: " . $stmt_deactivate->error);
        }
        $stmt_deactivate->close();

        $user_exists = false;
        $user_data = null;
        
        // If the OTP was for login, userTb should exist (unless an edge case). 
        // If for registration, userTb might be null if OTP generated before user record created.
        // The user check below is crucial for both flows.
        $stmt_find_user = $conn->prepare("SELECT id, name, email, phone, country_code, profile_image, address, wallet_balance, role, is_active FROM users WHERE country_code = ? AND phone = ?");
        if (!$stmt_find_user) {
            throw new Exception("User find statement preparation failed: " . $conn->error);
        }
        $stmt_find_user->bind_param("ss", $posted_country_code, $posted_local_phone);
        
        if ($stmt_find_user->execute()) {
            $user_result = $stmt_find_user->get_result();
            if ($user_details = $user_result->fetch_assoc()) {
                $user_exists = true;
                $user_data = $user_details;
            }
        } else {
            error_log("Failed to execute user find query: " . $stmt_find_user->error);
        }
        $stmt_find_user->close();
        
        // If the purpose was 'register' and user doesn't exist yet, this is where you'd typically guide them to the registration form.
        // If purpose was 'login' and user doesn't exist, that's an anomaly.
        // The current response structure handles returning user_exists and user_data.

        $conn->commit();
        echo json_encode([
            'status' => 'success', 
            'message' => 'OTP verified successfully.',
            'user_exists' => $user_exists,
            'user_data' => $user_data,
            'otp_purpose_verified' => $posted_otp_purpose // Good to confirm back what was verified
        ]);

    } else {
        $conn->rollback();
        echo json_encode(['status' => 'error', 'message' => 'Invalid or expired OTP. Please check the OTP and try again.']);
    }

} catch (Exception $e) {
    $conn->rollback();
    error_log("Verify OTP Error: " . $e->getMessage() . " for CC: $posted_country_code, Phone: $posted_local_phone, OTP: $otp_entered, Purpose: $posted_otp_purpose");
    echo json_encode(['status' => 'error', 'message' => 'Server Error during OTP verification. Please try again later.']);
}

$conn->close();
?>