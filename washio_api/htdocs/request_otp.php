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
$code_from = 'login_otp'; // Ensure this matches usage in verify_otp.php

$conn->begin_transaction();

try {
    // Deactivate old OTPs for this number and purpose
    // Uses the separate country_code and mobile_number (local part) columns from web_codes
    $stmt_deactivate = $conn->prepare("UPDATE web_codes SET isActive = 0 WHERE country_code = ? AND mobile_number = ? AND code_from = ?");
    if (!$stmt_deactivate) {
        throw new Exception("Deactivation statement preparation failed: " . $conn->error);
    }
    $stmt_deactivate->bind_param("sss", $country_code_from_post, $local_phone_from_post, $code_from);
    if (!$stmt_deactivate->execute()) {
        throw new Exception("Failed to deactivate old OTPs: " . $stmt_deactivate->error);
    }
    $stmt_deactivate->close();

    // Insert the new OTP using separate country_code and mobile_number (local part) columns
    $stmt_insert = $conn->prepare("INSERT INTO web_codes (country_code, mobile_number, codes, isActive, rDateTime, code_from) VALUES (?, ?, ?, 1, NOW(), ?)");
    if (!$stmt_insert) {
        throw new Exception("Insertion statement preparation failed: " . $conn->error);
    }
    $otp_str = strval($otp);
    $stmt_insert->bind_param("ssss", $country_code_from_post, $local_phone_from_post, $otp_str, $code_from); 
    
    if ($stmt_insert->execute()) {
        $conn->commit();
        // In a real app, you would also trigger an SMS to $country_code_from_post . $local_phone_from_post with $otp here
        echo json_encode(['status' => 'success', 'message' => 'OTP generated successfully. OTP: ' . $otp]); // For testing, returning OTP
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