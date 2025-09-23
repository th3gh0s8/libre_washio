<?php
header('Content-Type: application/json');
require_once 'db.php';

// Handle GET request to fetch addresses
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    try {
        $userId = $_GET['user_id'] ?? null;

        if (!$userId) {
            throw new Exception('User ID is required for GET request.');
        }

        if (!$conn) {
            throw new Exception('Database connection failed.');
        }

        $stmt = $conn->prepare(
            "SELECT id, Address_Type, Address_Line1, Address_Line2, Map_Address, latitude, longitude FROM user_locations WHERE userTb = ?"
        );
        if ($stmt === false) throw new Exception('Prepare failed: ' . $conn->error);
        
        $stmt->bind_param("i", $userId);
        
        if (!$stmt->execute()) throw new Exception('Execute failed: ' . $stmt->error);

        $result = $stmt->get_result();
        $locations = [];
        while ($row = $result->fetch_assoc()) {
            $locations[] = $row;
        }

        echo json_encode(['status' => 'success', 'data' => $locations]);

        $stmt->close();
        $conn->close();

    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
    }
    exit;
}

// Handle POST request to add/update addresses (existing logic)
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $data = json_decode(file_get_contents('php://input'), true);

        if (json_last_error() !== JSON_ERROR_NONE) {
            throw new Exception('Invalid JSON received.');
        }

        $userId = $data['user_id'] ?? null;
        $addressType = $data['address_type'] ?? null;
        $mapAddress = $data['map_address'] ?? null;
        $latitude = $data['latitude'] ?? null;
        $longitude = $data['longitude'] ?? null;

        if (!$userId || !$addressType || !$mapAddress || $latitude === null || $longitude === null) {
            throw new Exception('Missing required fields: user_id, address_type, map_address, latitude, and longitude are required.');
        }
        
        $addressLine1 = $data['address_line1'] ?? '';
        $addressLine2 = $data['address_line2'] ?? '';

        if (!$conn) {
            throw new Exception('Database connection failed.');
        }

        $existingId = null;
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
            $stmt_update = $conn->prepare(
                "UPDATE user_locations SET Address_Line1 = ?, Address_Line2 = ?, longitude = ?, latitude = ?, Map_Address = ? WHERE id = ?"
            );
            if ($stmt_update === false) throw new Exception('Prepare failed (update): ' . $conn->error);
            
            // --- CHANGE HERE ---
            $stmt_update->bind_param("sssssi", $addressLine1, $addressLine2, $longitude, $latitude, $mapAddress, $existingId);
            if ($stmt_update->execute()) {
                echo json_encode(['status' => 'success', 'message' => "$addressType address updated successfully."]);
            } else {
                throw new Exception('Execute failed (update): ' . $stmt_update->error);
            }
            $stmt_update->close();
        } else {
            $stmt_insert = $conn->prepare(
                "INSERT INTO user_locations (userTb, Address_Type, Address_Line1, Address_Line2, longitude, latitude, Map_Address) VALUES (?, ?, ?, ?, ?, ?, ?)"
            );
            if ($stmt_insert === false) throw new Exception('Prepare failed (insert): ' . $conn->error);
            
            // --- AND CHANGE HERE ---
            $stmt_insert->bind_param("issssss", $userId, $addressType, $addressLine1, $addressLine2, $longitude, $latitude, $mapAddress);
            if ($stmt_insert->execute()) {
                echo json_encode(['status' => 'success', 'message' => 'New address saved successfully.']);
            } else {
                throw new Exception('Execute failed (insert): ' . $stmt_insert->error);
            }
            $stmt_insert->close();
        }

        $conn->close();

    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode([
            'status' => 'error',
            'message' => $e->getMessage(),
            'file' => basename($e->getFile()),
            'line' => $e->getLine()
        ]);
    }
    exit;
}

// If neither GET nor POST, return error
http_response_code(405); // Method Not Allowed
echo json_encode(['status' => 'error', 'message' => 'Invalid request method. Only GET and POST are supported.']);
?>
