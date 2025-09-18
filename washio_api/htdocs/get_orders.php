<?php
header('Content-Type: application/json');

// Set a custom error handler to catch warnings and notices
set_error_handler(function($severity, $message, $file, $line) {
    throw new ErrorException($message, 0, $severity, $file, $line);
});

try {
    require_once 'db.php'; // Throws an exception on connection failure

    if (!isset($_GET['user_id'])) {
        throw new Exception('User ID is required.');
    }

    $userId = $_GET['user_id'];
    if (!filter_var($userId, FILTER_VALIDATE_INT) || $userId <= 0) {
        throw new Exception('Invalid User ID.');
    }

    if (!$conn) {
        throw new Exception('Database connection object not found.');
    }

    // CORRECTED QUERY: This now matches the database schema you provided and includes order status.
    $query = "SELECT 
                o.id AS order_id, 
                st.name AS station_name, 
                o.amount AS total_price, 
                o.order_date_time AS order_date,
                o.status AS order_status
              FROM oder_tb o 
              JOIN stations st ON o.station_Tb = st.id 
              WHERE o.user_Tb = ? 
              ORDER BY o.order_date_time DESC";
    
    $stmt = $conn->prepare($query);
    if ($stmt === false) {
        // Provide the actual SQL error in the exception message
        throw new Exception('Database statement preparation failed: ' . $conn->error);
    }
    
    $stmt->bind_param("i", $userId);
    
    if (!$stmt->execute()) {
        // Provide the actual SQL error in the exception message
        throw new Exception('Database query execution failed: ' . $stmt->error);
    }
    
    $result = $stmt->get_result();
    
    $orders = [];
    while ($row = $result->fetch_assoc()) {
        $orders[] = $row;
    }
    
    $stmt->close();
    $conn->close();

    echo json_encode(['status' => 'success', 'data' => $orders]);

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