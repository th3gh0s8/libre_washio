<?php
header('Content-Type: application/json');
include 'db.php'; // Your database connection

$userId = null;
if (isset($_GET['userId'])) {
    $userId = $_GET['userId'];
} else {
    echo json_encode(['status' => 'error', 'message' => 'User ID is required']);
    exit;
}

if ($conn->connect_error) {
    echo json_encode(['status' => 'error', 'message' => 'Database connection failed: ' . $conn->connect_error]);
    exit;
}

// Use prepared statements to prevent SQL injection
$stmt = $conn->prepare("SELECT id, name, email, phone, country_code, profile_image, address, wallet_balance, role, is_active, created_at FROM users WHERE id = ?");
if (!$stmt) {
    echo json_encode(['status' => 'error', 'message' => 'Statement preparation failed: ' . $conn->error]);
    exit;
}

$stmt->bind_param("i", $userId); // 'i' for integer

if ($stmt->execute()) {
    $result = $stmt->get_result();
    if ($user = $result->fetch_assoc()) {
        echo json_encode(['status' => 'success', 'data' => $user]);
    } else {
        echo json_encode(['status' => 'error', 'message' => 'User not found']);
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'Query execution failed: ' . $stmt->error]);
}

$stmt->close();
$conn->close();
?>