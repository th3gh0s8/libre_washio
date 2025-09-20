<?php
header('Content-Type: application/json');
require_once 'db.php';

try {
    if (!$conn) {
        throw new Exception("Database connection failed.");
    }

    $data = json_decode(file_get_contents('php://input'), true);

    if (json_last_error() !== JSON_ERROR_NONE) {
        throw new Exception("Invalid JSON received.");
    }

    $userId = $data['user_id'] ?? null;
    $stationId = $data['station_id'] ?? null;
    $items = $data['items'] ?? [];
    $totalAmount = $data['total_amount'] ?? null;
    $paymentMethod = $data['payment_method'] ?? 'cash_on_delivery';
    $status = 'in_progress';

    if (!$userId || !$stationId || empty($items) || $totalAmount === null) {
        throw new Exception("Missing required order data.");
    }

    $firstServiceId = null;
    if (isset($items[0]['id'])) { 
        $firstServiceId = $items[0]['id'];
    } 

    $conn->begin_transaction();

    try {
        $orderStmt = $conn->prepare(
            "INSERT INTO oder_tb (user_Tb, station_Tb, service_Tb, amount, order_date_time, status, payment_method) VALUES (?, ?, ?, ?, NOW(), ?, ?)"
        );
        if ($orderStmt === false) throw new Exception("Prepare failed (order): " . $conn->error);
        
        $orderStmt->bind_param("iiidss", $userId, $stationId, $firstServiceId, $totalAmount, $status, $paymentMethod);
        if (!$orderStmt->execute()) throw new Exception("Execute failed (order): " . $orderStmt->error);
        
        $orderId = $conn->insert_id; // This is the actual_order_id
        $orderStmt->close();

        $itemStmt = $conn->prepare(
            "INSERT INTO oder_items (oderTb, userTb, stationTb, serviceTb, item, item_quantity, price) VALUES (?, ?, ?, ?, ?, ?, ?)"
        );
        if ($itemStmt === false) throw new Exception("Prepare failed (items): " . $conn->error);

        foreach ($items as $item) {
            $serviceIdForItem = $item['id'] ?? null;
            $itemName = $item['service_name'] ?? 'Unknown Item';
            $quantity = $item['quantity'] ?? null;
            $price = $item['service_price'] ?? null;

            if ($serviceIdForItem === null || $quantity === null || $price === null) {
                throw new Exception("Invalid item data in cart.");
            }
            
            $itemStmt->bind_param("iiiisid", $orderId, $userId, $stationId, $serviceIdForItem, $itemName, $quantity, $price);
            if (!$itemStmt->execute()) throw new Exception("Execute failed for item $serviceIdForItem: " . $itemStmt->error);
        }
        $itemStmt->close();

        // Step 3: Get the user-specific order count for the display ID
        $countStmt = $conn->prepare("SELECT COUNT(*) as order_count FROM oder_tb WHERE user_Tb = ?");
        if ($countStmt === false) throw new Exception("Prepare failed (count): " . $conn->error);
        
        $countStmt->bind_param("i", $userId);
        if (!$countStmt->execute()) throw new Exception("Execute failed (count): " . $countStmt->error);
        
        $result = $countStmt->get_result();
        $countRow = $result->fetch_assoc();
        $displayOrderId = $countRow['order_count'];
        $countStmt->close();

        // Step 4: Get station name - CORRECTED TABLE NAME
        $stationName = "Unknown Station"; // Default value
        $stationStmt = $conn->prepare("SELECT name FROM stations WHERE id = ?"); // Changed station_tb to stations
        if ($stationStmt) {
            $stationStmt->bind_param("i", $stationId);
            if ($stationStmt->execute()) {
                $stationResult = $stationStmt->get_result();
                if ($stationRow = $stationResult->fetch_assoc()) {
                    $stationName = $stationRow['name'];
                }
            }
            $stationStmt->close();
        } else { // Handle prepare failure for station name query
            // Optionally log an error here, but continue with default station name
            // error_log("Failed to prepare station name query: " . $conn->error);
        }

        $conn->commit();

        echo json_encode([
            'status' => 'success',
            'message' => 'Order placed successfully!',
            'actual_order_id' => $orderId, 
            'display_order_id' => $displayOrderId,
            'station_name' => $stationName 
        ]);

    } catch (Exception $e) {
        $conn->rollback();
        throw $e;
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
?>