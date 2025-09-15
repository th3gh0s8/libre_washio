<?php
// Start output buffering and set error reporting
ob_start();
error_reporting(E_ALL);
ini_set('display_errors', 0); 
ini_set('log_errors', 1);

// Set headers for JSON response
if (!headers_sent()) {
    header("Content-Type: application/json");
}

// Include the database connection
require __DIR__ . '/db.php';

// Basic check for DB connection
if (!isset($conn) || $conn->connect_error) {
    if (ob_get_level() > 0) ob_end_clean();
    if (!headers_sent()) header("Content-Type: application/json");
    echo json_encode(['status' => 'error', 'message' => 'Database connection failed.']);
    exit;
}

// --- Main Logic ---

// Get the raw POST data from the request body
$json_data = file_get_contents('php://input');

// Decode the JSON data into a PHP associative array
$data = json_decode($json_data, true);

// Validate the incoming data structure
if (!isset($data['user_id'], $data['station_id'], $data['items'], $data['total_amount'], $data['payment_method']) || !is_array($data['items'])) {
    if (ob_get_level() > 0) ob_end_clean();
    if (!headers_sent()) header("Content-Type: application/json");
    echo json_encode(['status' => 'error', 'message' => 'Invalid data provided. Required: user_id, station_id, items, total_amount, payment_method.']);
    exit;
}

// Assign variables from the decoded data
$user_id = $data['user_id'];
$station_id = $data['station_id'];
$items = $data['items'];
$total_amount = $data['total_amount'];
$payment_method = $data['payment_method'];

// Start a database transaction
$conn->begin_transaction();

try {
    // Step 1: Insert the main order into `oder_tb`
    // Note: service_Tb in `oder_tb` seems redundant if it's a multi-item order. 
    // Here we will insert the ID of the first service as a reference, as the column is NOT NULL.
    // A better schema might allow this to be NULL.
    $first_service_id = $items[0]['id']; // Get ID of the first item for the main order table
    
    $stmt_order = $conn->prepare(
        "INSERT INTO oder_tb (user_Tb, station_Tb, service_Tb, amount, payment_method, status, payment_status) VALUES (?, ?, ?, ?, ?, 'pending', 'unpaid')"
    );
    if (!$stmt_order) {
        throw new Exception("Order statement preparation failed: " . $conn->error);
    }
    $stmt_order->bind_param("iiids", $user_id, $station_id, $first_service_id, $total_amount, $payment_method);
    
    if (!$stmt_order->execute()) {
        throw new Exception("Failed to create order: " . $stmt_order->error);
    }
    
    $order_id = $stmt_order->insert_id;
    $stmt_order->close();

    // Step 2: Insert each item from the cart into `oder_items`
    $stmt_items = $conn->prepare(
        "INSERT INTO oder_items (oderTb, userTb, stationTb, serviceTb, item, price, item_quantity) VALUES (?, ?, ?, ?, ?, ?, ?)"
    );
    if (!$stmt_items) {
        throw new Exception("Order items statement preparation failed: " . $conn->error);
    }

    foreach ($items as $item) {
        $service_id = $item['id'];
        $service_name = $item['service_name'];
        $service_price = $item['service_price'];
        $quantity = $item['quantity'];

        // Bind parameters and execute for each item
        $stmt_items->bind_param("iiiisdi", $order_id, $user_id, $station_id, $service_id, $service_name, $service_price, $quantity);
        if (!$stmt_items->execute()) {
            throw new Exception("Failed to add item to order: " . $stmt_items->error);
        }
    }
    $stmt_items->close();

    // If everything was successful, commit the transaction
    $conn->commit();

    // Clean the output buffer and send success response
    if (ob_get_level() > 0) ob_end_clean();
    if (!headers_sent()) header("Content-Type: application/json");
    echo json_encode(['status' => 'success', 'message' => 'Order created successfully!', 'order_id' => $order_id]);

} catch (Exception $e) {
    // If any step failed, roll back the transaction
    $conn->rollback();
    error_log("create_order.php: Transaction Error: " . $e->getMessage());
    
    // Clean the output buffer and send error response
    if (ob_get_level() > 0) ob_end_clean();
    if (!headers_sent()) header("Content-Type: application/json");
    echo json_encode(['status' => 'error', 'message' => 'Order creation failed: ' . $e->getMessage()]);

} finally {
    // Close the connection if it's still open
    if ($conn && $conn instanceof mysqli) {
        $conn->close();
    }
    // Ensure the script exits cleanly
    exit;
}
?>
