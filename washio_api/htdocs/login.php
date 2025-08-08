<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

include('db.php');

// Get POST data
$phone = $_POST['phone'] ?? ''; // Changed 'email' to 'phone'

/*
// Password would be handled by OTP verification script or a different login flow
$password = $_POST['password'] ?? ''; 

if (empty($phone) || empty($password)) { // Changed $email to $phone
    echo json_encode([
        "status" => "error",
        "message" => "Phone number and password are required" // Adjusted message
    ]);
    exit;
}
*/

if (empty($phone)) {
    echo json_encode([
        "status" => "error",
        "message" => "Phone number is required"
    ]);
    exit;
}

// Prepare SQL
//$sql = "SELECT id, name, password, role, is_active FROM users WHERE email = ?";
$sql = "SELECT * FROM users WHERE phone = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $phone); // Changed $email to $phone
$stmt->execute();

$result = $stmt->get_result();

/*
if ($row = $result->fetch_assoc()) {
    // 🔐 If you're using hashed passwords in DB:
    // if (password_verify($password, $row['password'])) {

    // 🔓 If you're using plain text passwords (not secure, but for testing):

    if ($password === $row['password']) {
        echo json_encode([
            "status" => "success",
            "user_id" => $row['id'],
            "name" => $row['name'],
            "role" => $row['role'],
            "is_active" => $row['is_active']
        ]);
    } else {
        echo json_encode([
            "status" => "error",
            "message" => "Invalid password"
        ]);
    }
} else {
    echo json_encode([
        "status" => "error",
        "message" => "Phone number not registered" // Changed message
    ]);
}
*/

// This simplified block aligns with the welcome_screen.dart flow:
// check if phone exists, then Flutter navigates to VerificationScreen.
// Actual login (e.g. OTP check) would happen in a subsequent step/script.
if ($row = $result->fetch_assoc()) {
    // In a real scenario, you might also generate and send an OTP here
    // or include it in the response for the app to use/verify.
    echo json_encode(["status" => "success", "user_id" => $row['id'], "message" => "User found, proceed to verification."]);
} else {
    echo json_encode(["status" => "error", "message" => "Phone number not registered"]); // Changed message
}

$stmt->close();
$conn->close();
?>
