<?php
header('Content-Type: application/json');

// Standard error handling
set_error_handler(function($severity, $message, $file, $line) {
    throw new ErrorException($message, 0, $severity, $file, $line);
});

try {
    require_once 'db.php'; // Connects to the database

    // Check for order_id in the request
    if (!isset($_GET['order_id'])) {
        throw new Exception('Order ID is required.');
    }
    $orderId = $_GET['order_id'];
    if (!filter_var($orderId, FILTER_VALIDATE_INT) || $orderId <= 0) {
        throw new Exception('Invalid Order ID.');
    }

    if (!$conn) {
        throw new Exception('Database connection object not found.');
    }

    // Query to get items for the specific order from the 'oder_items' table
    $query = "SELECT item, price, item_quantity FROM oder_items WHERE oderTb = ?";
    
    $stmt = $conn->prepare($query);
    if ($stmt === false) {
        throw new Exception('Database statement preparation failed: ' . $conn->error);
    }
    
    $stmt->bind_param("i", $orderId);
    
    if (!$stmt->execute()) {
        throw new Exception('Database query execution failed: ' . $stmt->error);
    }
    
    $result = $stmt->get_result();
    $items = [];
    while ($row = $result->fetch_assoc()) {
        $items[] = $row;
    }
    
    $stmt->close();
    $conn->close();

    // Return the items as JSON
    echo json_encode(['status' => 'success', 'data' => $items]);

} catch (Exception $e) {
    restore_error_handler();
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => 'A server error occurred: ' . $e->getMessage(),
        'file' => $e->getFile(),
        'line' => $e->getLine()
    ]);
}
?>