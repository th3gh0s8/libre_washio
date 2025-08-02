<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

include('db.php');

// Get POST data
$email = $_POST['email'] ?? '';
$password = $_POST['password'] ?? '';

/*
if (empty($email) || empty($password)) {
    echo json_encode([
        "status" => "error",
        "message" => "Email and password are required"
    ]);
    exit;
}
*/
// Prepare SQL
//$sql = "SELECT id, name, password, role, is_active FROM users WHERE email = ?";
$sql = "SELECT * FROM users WHERE phone = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $email);
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
        "message" => "Email not registered"
    ]);
}
*/

if ($row = $result->fetch_assoc()) {
    echo json_encode(["status" => "success", "user_id" => $row['id']]);
} else {
    echo json_encode(["status" => "error", "message" => "Email not registered"]);
}

$stmt->close();
$conn->close();
?>
