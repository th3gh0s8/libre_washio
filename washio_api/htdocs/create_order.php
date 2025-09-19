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

    // Begin database transaction
    $conn->begin_transaction();

    try {
        // Step 1: Insert into the main order table (oder_tb)
        $orderStmt = $conn->prepare(
            "INSERT INTO oder_tb (user_Tb, station_Tb, amount, order_date_time, status, payment_method) VALUES (?, ?, ?, NOW(), ?, ?)"
        );
        if ($orderStmt === false) throw new Exception("Prepare failed (order): " . $conn->error);
        
        $orderStmt->bind_param("iidss", $userId, $stationId, $totalAmount, $status, $paymentMethod);
        if (!$orderStmt->execute()) throw new Exception("Execute failed (order): " . $orderStmt->error);
        
        $orderId = $conn->insert_id;
        $orderStmt->close();

        // Step 2: Insert each item from the cart
        $itemStmt = $conn->prepare(
            "INSERT INTO oder_items (oderTb, userTb, stationTb, serviceTb, item, item_quantity, price) VALUES (?, ?, ?, ?, ?, ?, ?)"
        );
        if ($itemStmt === false) throw new Exception("Prepare failed (items): " . $conn->error);

        foreach ($items as $item) {
            $serviceId = $item['id'] ?? null;
            $itemName = $item['service_name'] ?? 'Unknown Item';
            $quantity = $item['quantity'] ?? null;
            $price = $item['service_price'] ?? null;

            if ($serviceId === null || $quantity === null || $price === null) {
                throw new Exception("Invalid item data in cart.");
            }
            
            $itemStmt->bind_param("iiiisid", $orderId, $userId, $stationId, $serviceId, $itemName, $quantity, $price);
            if (!$itemStmt->execute()) throw new Exception("Execute failed for item $serviceId: " . $itemStmt->error);
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

        // If all queries were successful, commit the transaction
        $conn->commit();

        echo json_encode([
            'status' => 'success',
            'message' => 'Order placed successfully!',
            'display_order_id' => $displayOrderId // Send the user-facing count back to the app
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