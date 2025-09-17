<?php
ob_start();
error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);

if (!headers_sent()) {
    header("Content-Type: application/json");
}

require __DIR__ . '/db.php';

if (!isset($conn) || $conn->connect_error) {
    if (ob_get_level() > 0) ob_end_clean();
    echo json_encode(['status' => 'error', 'message' => 'Database connection failed.']);
    exit;
}

$user_id = isset($_POST['user_id']) ? (int)$_POST['user_id'] : 0;
$name = isset($_POST['name']) ? trim($_POST['name']) : null;
$email = isset($_POST['email']) ? trim($_POST['email']) : null;
$address = isset($_POST['address']) ? trim($_POST['address']) : null;

if ($user_id <= 0 || empty($name) || empty($email)) {
    if (ob_get_level() > 0) ob_end_clean();
    echo json_encode(['status' => 'error', 'message' => 'User ID, name, and email are required.']);
    exit;
}

$name_parts = explode(' ', $name, 2);
$first_name = $name_parts[0];
$last_name = isset($name_parts[1]) ? $name_parts[1] : '';

$conn->begin_transaction();

try {
    $sql = "UPDATE users SET first_name = ?, last_name = ?, email = ?, address = ?, updated_at = NOW() WHERE id = ?";
    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        throw new Exception("Statement preparation failed: " . $conn->error);
    }
    $stmt->bind_param("ssssi", $first_name, $last_name, $email, $address, $user_id);
    
    if (!$stmt->execute()) {
        throw new Exception("Failed to update user: " . $stmt->error);
    }
    $stmt->close();

    $conn->commit();

    $stmt_get = $conn->prepare("SELECT id, first_name, last_name, email, phone, country_code, address, role, is_active, profile_image, wallet_balance, created_at, updated_at FROM users WHERE id = ?");
    if (!$stmt_get) {
        throw new Exception("Failed to prepare statement to fetch updated user.");
    }
    $stmt_get->bind_param("i", $user_id);
    $stmt_get->execute();
    // <<< FIXED THE BUG HERE >>>
    $result = $stmt_get->get_result();
    $user_data = $result->fetch_assoc();
    $stmt_get->close();

    if (!$user_data) {
        throw new Exception("Failed to retrieve updated user data.");
    }

    $user_data['name'] = trim($user_data['first_name'] . ' ' . $user_data['last_name']);

    if (ob_get_level() > 0) ob_end_clean();
    echo json_encode([
        'status' => 'success',
        'message' => 'Profile updated successfully.',
        'user_data' => $user_data
    ]);
    exit;

} catch (Exception $e) {
    $conn->rollback();
    error_log("update_user_details.php: Transaction Error: " . $e->getMessage());
    if (ob_get_level() > 0) ob_end_clean();
    echo json_encode(['status' => 'error', 'message' => 'Update failed: ' . $e->getMessage()]);
    exit;
} finally {
    if ($conn) {
        $conn->close();
    }
}
?>
