<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
header('Content-Type: application/json');

require __DIR__ . '/db.php'; // Use robust include

// Check db connection
if (!isset($conn) || !$conn instanceof mysqli) {
    error_log("update_user_details.php: DB connection object is invalid. Check db.php.");
    echo json_encode(['status' => 'error', 'message' => 'Internal server error: Database connection invalid.']);
    exit;
}
error_log("update_user_details.php: DB connection appears valid.");

// Log POST data
error_log("update_user_details.php: Accessed. Raw POST data: " . file_get_contents('php://input'));
error_log("update_user_details.php: Parsed _POST array: " . json_encode($_POST));

// Get POST data
$user_id = isset($_POST['user_id']) ? filter_var(trim($_POST['user_id']), FILTER_VALIDATE_INT) : null;
$fullNameFromPost = isset($_POST['name']) ? trim($_POST['name']) : null;
$email = isset($_POST['email']) ? trim($_POST['email']) : null;
$address = isset($_POST['address']) ? trim($_POST['address']) : null;

// Basic validation
if (empty($user_id) || empty($fullNameFromPost) || empty($email)) {
    error_log("update_user_details.php: Validation failed. Missing user_id, name, or email.");
    echo json_encode(['status' => 'error', 'message' => 'User ID, name, and email are required.']);
    exit;
}
if ($user_id === false || $user_id <= 0) {
    error_log("update_user_details.php: Invalid User ID format or value: " . $_POST['user_id']);
    echo json_encode(['status' => 'error', 'message' => 'Invalid User ID format.']);
    exit;
}
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    error_log("update_user_details.php: Invalid email format: " . $email);
    echo json_encode(['status' => 'error', 'message' => 'Invalid email format.']);
    exit;
}

// Split the full name into first_name and last_name
$name_parts = explode(' ', $fullNameFromPost, 2);
$first_name = $name_parts[0];
$last_name = isset($name_parts[1]) ? trim($name_parts[1]) : '';

$conn->begin_transaction();

try {
    // Check if the new email is already used by ANOTHER user
    $stmt_check_email = $conn->prepare("SELECT id FROM users WHERE email = ? AND id != ?");
    if (!$stmt_check_email) throw new Exception("Email check statement preparation failed: " . $conn->error);
    $stmt_check_email->bind_param("si", $email, $user_id);
    $stmt_check_email->execute();
    $result_check_email = $stmt_check_email->get_result();
    if ($result_check_email->num_rows > 0) {
        $stmt_check_email->close();
        $conn->rollback();
        error_log("update_user_details.php: Email '$email' already in use by another account for user_id '$user_id'.");
        echo json_encode(['status' => 'error', 'message' => 'This email address is already in use by another account.']);
        exit;
    }
    $stmt_check_email->close();

    // MODIFIED UPDATE: Use first_name and last_name
    $sql_update_user = "UPDATE users SET first_name = ?, last_name = ?, email = ?, address = ?, updated_at = NOW() WHERE id = ?";
    $stmt_update_user = $conn->prepare($sql_update_user);
    if (!$stmt_update_user) throw new Exception("User update statement preparation failed: " . $conn->error);

    $address_to_save = (empty($address) || is_null($address)) ? NULL : $address;
    // Parameters: first_name, last_name, email, address, user_id
    $stmt_update_user->bind_param("ssssi", $first_name, $last_name, $email, $address_to_save, $user_id);
    
    if ($stmt_update_user->execute()) {
        if ($stmt_update_user->affected_rows > 0) {
            $conn->commit();
            error_log("update_user_details.php: User details updated successfully for user_id: " . $user_id);
            
            // Fetch and return the updated user data, ensuring 'name' is constructed
            // MODIFIED SELECT: Fetch first_name, last_name
            $stmt_get_updated_user = $conn->prepare("SELECT id, first_name, last_name, email, phone, country_code, profile_image, address, wallet_balance, role, is_active FROM users WHERE id = ?");
            if (!$stmt_get_updated_user) throw new Exception("Get updated user data statement prep failed: " . $conn->error);
            $stmt_get_updated_user->bind_param("i", $user_id);
            $stmt_get_updated_user->execute();
            $updated_user_data_row = $stmt_get_updated_user->get_result()->fetch_assoc();
            $stmt_get_updated_user->close();

            if ($updated_user_data_row) {
                $constructed_full_name = trim(($updated_user_data_row['first_name'] ?? '') . ' ' . ($updated_user_data_row['last_name'] ?? ''));
                $updated_user_data_row['name'] = $constructed_full_name ?: null;
                // Optionally unset first_name, last_name from response
            }

            echo json_encode([
                'status' => 'success',
                'message' => 'User details updated successfully.',
                'user_data' => $updated_user_data_row
            ]);
        } else {
            $conn->rollback(); 
            error_log("update_user_details.php: No changes detected or user not found for user_id: " . $user_id);
            echo json_encode(['status' => 'info', 'message' => 'No changes detected or user not found.']);
        }
    } else {
        throw new Exception("Failed to update user details: " . $stmt_update_user->error);
    }
    $stmt_update_user->close();

} catch (Exception $e) {
    if ($conn->server_status & MYSQLI_TRANS_ACTIVE) {
        $conn->rollback();
    }
    error_log("update_user_details.php: Server Error for user_id '$user_id': " . $e->getMessage() . " SQL Error: " . $conn->error);
    echo json_encode(['status' => 'error', 'message' => 'Server Error: ' . $e->getMessage()]);
}

if ($conn) {
    $conn->close();
}
?>