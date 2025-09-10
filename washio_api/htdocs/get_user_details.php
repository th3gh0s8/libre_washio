<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
header('Content-Type: application/json');

require __DIR__ . '/db.php'; // Use robust include

// Check db connection from db.php
if (!isset($conn) || !$conn instanceof mysqli) {
    error_log("get_user_details.php: DB connection object is invalid. Check db.php.");
    echo json_encode(['status' => 'error', 'message' => 'Internal server error: Database connection invalid.']);
    exit;
}

$userId = null;
if (isset($_GET['userId'])) {
    $userId = filter_var($_GET['userId'], FILTER_VALIDATE_INT);
    if ($userId === false || $userId <= 0) {
        error_log("get_user_details.php: Invalid User ID format or value: " . $_GET['userId']);
        echo json_encode(['status' => 'error', 'message' => 'Invalid User ID format.']);
        exit;
    }
} else {
    error_log("get_user_details.php: User ID not provided.");
    echo json_encode(['status' => 'error', 'message' => 'User ID is required.']);
    exit;
}

error_log("get_user_details.php: Attempting to fetch details for User ID: " . $userId);

// MODIFIED SQL: Select first_name, last_name, and other relevant fields.
// Ensure these fields match your 'DESCRIBE users;' output.
$sql = "SELECT id, first_name, last_name, email, phone, country_code, profile_image, address, wallet_balance, role, is_active, created_at FROM users WHERE id = ?";
$stmt = $conn->prepare($sql);

if (!$stmt) {
    error_log("get_user_details.php: Statement preparation failed: " . $conn->error . " | SQL: " . $sql);
    echo json_encode(['status' => 'error', 'message' => 'Internal server error: Could not prepare statement.']);
    exit;
}

$stmt->bind_param("i", $userId);

if ($stmt->execute()) {
    $result = $stmt->get_result();
    if ($user = $result->fetch_assoc()) {
        // Construct the 'name' field from first_name and last_name
        $fullName = trim(($user['first_name'] ?? '') . ' ' . ($user['last_name'] ?? ''));
        $user['name'] = $fullName ?: null; // Assign combined name, or null if both were empty/null

        // Optionally remove first_name and last_name if you only want the combined 'name' field
        // unset($user['first_name']);
        // unset($user['last_name']);
        
        error_log("get_user_details.php: User found for ID: $userId. Name: " . $user['name']);
        echo json_encode(['status' => 'success', 'data' => $user]);
    } else {
        error_log("get_user_details.php: User not found for ID: " . $userId);
        echo json_encode(['status' => 'error', 'message' => 'User not found.']);
    }
} else {
    error_log("get_user_details.php: Query execution failed for User ID $userId: " . $stmt->error);
    echo json_encode(['status' => 'error', 'message' => 'Internal server error: Could not execute query.']);
}

$stmt->close();
// $conn->close(); // Connection is usually closed at the end of db.php or if shared globally

?>