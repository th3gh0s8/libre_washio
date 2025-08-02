<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
header("Access-Control-Allow-Methods: POST");

include('db.php');

$data = json_decode(file_get_contents("php://input"), true);

$name     = $conn->real_escape_string($data['name']);
$email    = $conn->real_escape_string($data['email']);
$phone    = $conn->real_escape_string($data['phone']);
$password = password_hash($data['password'], PASSWORD_DEFAULT);

$sql = "INSERT INTO users (name, email, phone, password) VALUES ('$name', '$email', '$phone', '$password')";

if ($conn->query($sql)) {
  echo json_encode(["success" => true, "message" => "User registered successfully"]);
} else {
  echo json_encode(["success" => false, "message" => "Error: " . $conn->error]);
}

$conn->close();
?>
