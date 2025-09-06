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

$phone = $_POST['phone'] ?? null;
$country_code = $_POST['country_code'] ?? null;

if (!$phone || !$country_code) {
    echo json_encode(['status' => 'error', 'message' => 'Phone number and country code are required.']);
    exit;
}

$full_phone_number = $country_code . $phone;
$otp = rand(100000, 999999);
$code_from = 'login_otp';

// Start transaction
$conn->begin_transaction();

try {
    // Deactivate old OTPs for this number and purpose
    $stmt_deactivate = $conn->prepare("UPDATE web_codes SET isActive = 0 WHERE mobile_number = ? AND code_from = ?");
    if (!$stmt_deactivate) {
        throw new Exception("Deactivation statement preparation failed: " . $conn->error);
    }
    $stmt_deactivate->bind_param("ss", $full_phone_number, $code_from);
    if (!$stmt_deactivate->execute()) {
        throw new Exception("Failed to deactivate old OTPs: " . $stmt_deactivate->error);
    }
    $stmt_deactivate->close();

    // Insert the new OTP
    $stmt_insert = $conn->prepare("INSERT INTO web_codes (mobile_number, codes, isActive, rDateTime, code_from) VALUES (?, ?, 1, NOW(), ?)");
    if (!$stmt_insert) {
        throw new Exception("Insertion statement preparation failed: " . $conn->error);
    }
    $otp_str = strval($otp);
    $stmt_insert->bind_param("sss", $full_phone_number, $otp_str, $code_from); 
    
    if ($stmt_insert->execute()) {
        $conn->commit();
        // In a real app, you would also trigger an SMS to $full_phone_number with $otp here
        echo json_encode(['status' => 'success', 'message' => 'OTP generated successfully. OTP: ' . $otp]); // For testing, returning OTP
    } else {
        throw new Exception("Failed to store OTP: " . $stmt_insert->error);
    }
    $stmt_insert->close();

} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(['status' => 'error', 'message' => 'Server Error: ' . $e->getMessage()]);
}

$conn->close();
?>