<?php
@ini_set('display_errors', 0);
@error_reporting(0);

header('Content-Type: application/json');
include 'db.php'; // Your database connection

// CRITICAL: Check database connection
if (!isset($conn) || $conn->connect_error) {
    echo json_encode(['status' => 'error', 'message' => 'Database connection failed: ' . (isset($conn) ? $conn->connect_error : 'Unknown error')]);
    exit;
}

// Get POST data
$user_id = $_POST['user_id'] ?? null;
$name = $_POST['name'] ?? null;
$email = $_POST['email'] ?? null;
$address = $_POST['address'] ?? null; // Optional, can be empty string if submitted

// Basic validation
if (empty($user_id) || empty($name) || empty($email)) {
    echo json_encode(['status' => 'error', 'message' => 'User ID, name, and email are required.']);
    exit;
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode(['status' => 'error', 'message' => 'Invalid email format.']);
    exit;
}

// Start transaction
$conn->begin_transaction();

try {
    // Check if the new email is already used by ANOTHER user
    $stmt_check_email = $conn->prepare("SELECT id FROM users WHERE email = ? AND id != ?");
    if (!$stmt_check_email) {
        throw new Exception("Email check statement preparation failed: " . $conn->error);
    }
    $stmt_check_email->bind_param("si", $email, $user_id);
    $stmt_check_email->execute();
    $result_check_email = $stmt_check_email->get_result();
    if ($result_check_email->num_rows > 0) {
        $stmt_check_email->close();
        $conn->rollback();
        echo json_encode(['status' => 'error', 'message' => 'This email address is already in use by another account.']);
        exit;
    }
    $stmt_check_email->close();

    // Prepare update statement
    // We are not allowing phone/country_code changes here for simplicity (they often require re-verification)
    $sql_update_user = "UPDATE users SET name = ?, email = ?, address = ?, updated_at = NOW() WHERE id = ?";
    $stmt_update_user = $conn->prepare($sql_update_user);
    if (!$stmt_update_user) {
        throw new Exception("User update statement preparation failed: " . $conn->error);
    }

    // Bind parameters: s (name), s (email), s (address), i (user_id)
    // Ensure address is passed correctly, even if it's an empty string or null from the form
    $address_to_save = (empty($address) || is_null($address)) ? NULL : $address;
    $stmt_update_user->bind_param("sssi", $name, $email, $address_to_save, $user_id);
    
    if ($stmt_update_user->execute()) {
        if ($stmt_update_user->affected_rows > 0) {
            $conn->commit();
            // Optionally, fetch and return the updated user data
            $stmt_get_updated_user = $conn->prepare("SELECT id, name, email, phone, country_code, profile_image, address, wallet_balance, role, is_active FROM users WHERE id = ?");
            $stmt_get_updated_user->bind_param("i", $user_id);
            $stmt_get_updated_user->execute();
            $updated_user_data = $stmt_get_updated_user->get_result()->fetch_assoc();
            $stmt_get_updated_user->close();

            echo json_encode([
                'status' => 'success',
                'message' => 'User details updated successfully.',
                'user_data' => $updated_user_data
            ]);
        } else {
            // No rows affected could mean the user_id was not found, or data was the same
            $conn->rollback(); // Or commit if no change is not an error
            echo json_encode(['status' => 'info', 'message' => 'No changes detected or user not found.']);
        }
    } else {
        throw new Exception("Failed to update user details: " . $stmt_update_user->error);
    }
    $stmt_update_user->close();

} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(['status' => 'error', 'message' => 'Server Error: ' . $e->getMessage()]);
}

$conn->close();
?>