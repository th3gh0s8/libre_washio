<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
header("Access-Control-Allow-Methods: POST");

include('db.php');

$data = json_decode(file_get_contents("php://input"), true);

// Basic Input Validation
if (!isset($data['name']) || !isset($data['email']) || !isset($data['phone']) || !isset($data['password']) ||
    empty(trim($data['name'])) || empty(trim($data['email'])) || empty(trim($data['phone'])) || empty(trim($data['password']))) {
    echo json_encode(["success" => false, "message" => "Name, email, phone, and password are required and cannot be empty."]);
    $conn->close();
    exit;
}

$name     = trim($data['name']);
$email    = trim($data['email']);
$phone    = trim($data['phone']);
$password = trim($data['password']); // Raw password, will be hashed by password_hash

// Additional validation (e.g., email format) can be added here
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode(["success" => false, "message" => "Invalid email format."]);
    $conn->close();
    exit;
}

// Check if email or phone already exists (optional, but good practice)
$checkSql = "SELECT id FROM users WHERE email = ? OR phone = ?";
$checkStmt = $conn->prepare($checkSql);
$checkStmt->bind_param("ss", $email, $phone);
$checkStmt->execute();
$checkResult = $checkStmt->get_result();
if ($checkResult->num_rows > 0) {
    echo json_encode(["success" => false, "message" => "Email or phone number already registered."]);
    $checkStmt->close();
    $conn->close();
    exit;
}
$checkStmt->close();

// Hash the password
$hashed_password = password_hash($password, PASSWORD_DEFAULT);

// Prepared Statement for Insertion
$sql = "INSERT INTO users (name, email, phone, password) VALUES (?, ?, ?, ?)";
$stmt = $conn->prepare($sql);

// Bind parameters (s = string)
$stmt->bind_param("ssss", $name, $email, $phone, $hashed_password);

if ($stmt->execute()) {
  echo json_encode(["success" => true, "message" => "User registered successfully"]);
} else {
  // Log detailed error on server, return generic message to client
  // error_log("Signup Error: " . $stmt->error); // Example of server-side logging
  echo json_encode(["success" => false, "message" => "Registration failed. Please try again later."]);
}

$stmt->close();
$conn->close();
?>
