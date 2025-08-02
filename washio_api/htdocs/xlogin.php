<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

include('db.php');

$email = $_POST['email'];


$sql = "SELECT * FROM users WHERE phone = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $email);
$stmt->execute();

$result = $stmt->get_result();
if ($row = $result->fetch_assoc()) {
    echo json_encode(["status" => "success", "user_id" => $row['id']]);
} else {
    echo json_encode(["status" => "error", "message" => "Email not registered"]);
}

$stmt->close();
$conn->close();
?>
