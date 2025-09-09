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
$code_from = 'login_otp'; // Ensure this matches what was used in request_otp.php

if (!$posted_country_code || !$posted_local_phone || !$otp_entered) {
    echo json_encode(['status' => 'error', 'message' => 'Country code, phone number, and OTP are required.']);
    exit;
}

// Removed: $full_phone_for_otp_lookup = $posted_country_code . $posted_local_phone;

$conn->begin_transaction();

try {
    // Check if the OTP is valid, active, and for the correct purpose
    // Queries web_codes using separate country_code and mobile_number (local part)
    $stmt_check = $conn->prepare("SELECT id, userTb FROM web_codes WHERE country_code = ? AND mobile_number = ? AND codes = ? AND isActive = 1 AND code_from = ? AND rDateTime >= NOW() - INTERVAL 10 MINUTE");
    if (!$stmt_check) {
        throw new Exception("OTP check statement preparation failed: " . $conn->error);
    }
    // Bind parameters: country_code, local_phone, otp_entered, code_from
    $stmt_check->bind_param("ssss", $posted_country_code, $posted_local_phone, $otp_entered, $code_from);
    
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

        // At this point, OTP is verified. Now check if user exists in the 'users' table.
        $user_exists = false;
        $user_data = null;
        
        $stmt_find_user = $conn->prepare("SELECT id, name, email, phone, country_code, profile_image, address, wallet_balance, role, is_active FROM users WHERE country_code = ? AND phone = ?");
        if (!$stmt_find_user) {
            throw new Exception("User find statement preparation failed: " . $conn->error);
        }
        // Uses $posted_country_code and $posted_local_phone which align with users table structure
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
        
        $conn->commit();
        echo json_encode([
            'status' => 'success', 
            'message' => 'OTP verified successfully.',
            'user_exists' => $user_exists,
            'user_data' => $user_data 
        ]);

    } else {
        $conn->rollback();
        echo json_encode(['status' => 'error', 'message' => 'Invalid or expired OTP. Please try again.']);
    }

} catch (Exception $e) {
    $conn->rollback();
    error_log("Verify OTP Error: " . $e->getMessage() . " for CC: $posted_country_code, Phone: $posted_local_phone, OTP: $otp_entered");
    echo json_encode(['status' => 'error', 'message' => 'Server Error during OTP verification. Please try again later.']);
}

$conn->close();
?>