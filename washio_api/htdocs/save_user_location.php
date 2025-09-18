<?php
header('Content-Type: application/json');
require_once 'db.php'; // Ensure you have your database connection logic here

// Use a try-catch block for robust error handling
try {
    // Decode the incoming JSON payload
    $data = json_decode(file_get_contents('php://input'), true);

    if (json_last_error() !== JSON_ERROR_NONE) {
        throw new Exception('Invalid JSON received.');
    }

    // Extract and validate required fields
    $userId = $data['user_id'] ?? null;
    $addressType = $data['address_type'] ?? null;
    $mapAddress = $data['map_address'] ?? null;
    $latitude = $data['latitude'] ?? null;
    $longitude = $data['longitude'] ?? null;

    if (!$userId || !$addressType || !$mapAddress || $latitude === null || $longitude === null) {
        throw new Exception('Missing required fields: user_id, address_type, map_address, latitude, and longitude are required.');
    }
    
    // Optional fields
    $addressLine1 = $data['address_line1'] ?? '';
    $addressLine2 = $data['address_line2'] ?? '';

    if (!$conn) {
        throw new Exception('Database connection failed.');
    }

    $existingId = null;
    // For 'Home' and 'Work', we implement an UPSERT logic to avoid duplicates for these specific types.
    if ($addressType == 'Home' || $addressType == 'Work') {
        $stmt_check = $conn->prepare("SELECT id FROM user_locations WHERE userTb = ? AND Address_Type = ?");
        if ($stmt_check === false) throw new Exception('Prepare failed (check): ' . $conn->error);
        
        $stmt_check->bind_param("is", $userId, $addressType);
        $stmt_check->execute();
        $result = $stmt_check->get_result();
        if ($row = $result->fetch_assoc()) {
            $existingId = $row['id'];
        }
        $stmt_check->close();
    }

    if ($existingId) {
        // --- UPDATE existing location ---
        $stmt_update = $conn->prepare(
            "UPDATE user_locations SET Address_Line1 = ?, Address_Line2 = ?, longitude = ?, latitude = ?, Map_Address = ? WHERE id = ?"
        );
        if ($stmt_update === false) throw new Exception('Prepare failed (update): ' . $conn->error);
        
        $stmt_update->bind_param("ssddsi", $addressLine1, $addressLine2, $longitude, $latitude, $mapAddress, $existingId);
        if ($stmt_update->execute()) {
            echo json_encode(['status' => 'success', 'message' => "$addressType address updated successfully."]);
        } else {
            throw new Exception('Execute failed (update): ' . $stmt_update->error);
        }
        $stmt_update->close();
    } else {
        // --- INSERT new location ---
        $stmt_insert = $conn->prepare(
            "INSERT INTO user_locations (userTb, Address_Type, Address_Line1, Address_Line2, longitude, latitude, Map_Address) VALUES (?, ?, ?, ?, ?, ?, ?)"
        );
        if ($stmt_insert === false) throw new Exception('Prepare failed (insert): ' . $conn->error);
        
        $stmt_insert->bind_param("isssdds", $userId, $addressType, $addressLine1, $addressLine2, $longitude, $latitude, $mapAddress);
        if ($stmt_insert->execute()) {
            echo json_encode(['status' => 'success', 'message' => 'New address saved successfully.']);
        } else {
            throw new Exception('Execute failed (insert): ' . $stmt_insert->error);
        }
        $stmt_insert->close();
    }

    $conn->close();

} catch (Exception $e) {
    http_response_code(500); // Internal Server Error
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage(),
        'file' => basename($e->getFile()), // Show only filename for security
        'line' => $e->getLine()
    ]);
}
?>