<?php
@ini_set('display_errors', 0);
@error_reporting(0);

header('Content-Type: application/json');
include 'db.php'; // Your database connection using $host = "localhost";

// CRITICAL: Check database connection immediately after include
if (!isset($conn) || $conn->connect_error) {
    echo json_encode(['status' => 'error', 'message' => 'Database connection failed in verify_otp: ' . (isset($conn) ? $conn->connect_error : 'Unknown error')]);
    exit;
}

$full_phone_number = $_POST['full_phone_number'] ?? null;
$otp_entered = $_POST['otp'] ?? null;
$code_from = 'login_otp'; // Ensure this matches what was used in request_otp.php

if (!$full_phone_number || !$otp_entered) {
    echo json_encode(['status' => 'error', 'message' => 'Phone number and OTP are required.']);
    exit;
}

// Start transaction
$conn->begin_transaction();

try {
    // Check if the OTP is valid, active, and for the correct purpose
    $stmt_check = $conn->prepare("SELECT id, userTb FROM web_codes WHERE mobile_number = ? AND codes = ? AND isActive = 1 AND code_from = ? AND rDateTime >= NOW() - INTERVAL 10 MINUTE");
    if (!$stmt_check) {
        throw new Exception("OTP check statement preparation failed: " . $conn->error);
    }
    // Corrected bind_param to "sss" for 3 string parameters
    $stmt_check->bind_param("sss", $full_phone_number, $otp_entered, $code_from);
    
    if (!$stmt_check->execute()) {
        throw new Exception("Failed to execute OTP check: " . $stmt_check->error);
    }
    
    $result = $stmt_check->get_result();
    $web_code_entry = $result->fetch_assoc();
    $stmt_check->close();

    if ($web_code_entry) {
        $web_code_id = $web_code_entry['id'];
        // $userId_from_web_codes = $web_code_entry['userTb']; // Available if needed

        // Deactivate the OTP
        $stmt_deactivate = $conn->prepare("UPDATE web_codes SET isActive = 0 WHERE id = ?");
        if (!$stmt_deactivate) {
            throw new Exception("OTP deactivation statement preparation failed: " . $conn->error);
        }
        $stmt_deactivate->bind_param("i", $web_code_id); // id is an integer
        if (!$stmt_deactivate->execute()) {
            throw new Exception("Failed to deactivate OTP: " . $stmt_deactivate->error);
        }
        $stmt_deactivate->close();

        // At this point, OTP is verified. Now check if user exists in the 'users' table.
        $user_exists = false;
        $user_data = null;
        
        $stmt_find_user = $conn->prepare("SELECT id, name, email, phone, country_code, profile_image, address, wallet_balance, role, is_active FROM users WHERE CONCAT(country_code, phone) = ?");
        if (!$stmt_find_user) {
            throw new Exception("User find statement preparation failed: " . $conn->error);
        }
        $stmt_find_user->bind_param("s", $full_phone_number); // full_phone_number is a string
        if ($stmt_find_user->execute()) {
            $user_result = $stmt_find_user->get_result();
            if ($user_details = $user_result->fetch_assoc()) {
                $user_exists = true;
                $user_data = $user_details;
            }
        } else {
             // Log error but don't necessarily fail the OTP verification if user check fails
            error_log("Failed to execute user find query: " . $stmt_find_user->error);
        }
        $stmt_find_user->close();
        
        $conn->commit();
        echo json_encode([
            'status' => 'success', 
            'message' => 'OTP verified successfully.',
            'user_exists' => $user_exists,
            'user_data' => $user_data // null if user does not exist
        ]);

    } else {
        // OTP is invalid, inactive, expired, or for a different purpose
        $conn->rollback(); // No changes made to web_codes if OTP wasn't found/valid
        echo json_encode(['status' => 'error', 'message' => 'Invalid or expired OTP. Please try again.']);
    }

} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(['status' => 'error', 'message' => 'Server Error: ' . $e->getMessage()]);
}

$conn->close();
?>