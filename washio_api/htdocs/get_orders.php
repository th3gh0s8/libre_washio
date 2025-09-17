<?php
require_once 'db_connect.php';

header('Content-Type: application/json');

if (isset($_GET['user_id'])) {
    $userId = $_GET['user_id'];

    // Validate that userId is a non-empty integer
    if (!filter_var($userId, FILTER_VALIDATE_INT) || $userId <= 0) {
        echo json_encode(['status' => 'error', 'message' => 'Invalid User ID.']);
        exit;
    }

    $stmt = $conn->prepare("SELECT o.id, s.name as service_name, st.name as station_name, o.order_date, o.price FROM orders o JOIN services s ON o.service_id = s.id JOIN stations st ON o.station_id = st.id WHERE o.user_id = ? ORDER BY o.order_date DESC");
    if ($stmt === false) {
        echo json_encode(['status' => 'error', 'message' => 'Database statement preparation failed: ' . $conn->error]);
        exit;
    }
    
    $stmt->bind_param("i", $userId);
    
    if (!$stmt->execute()) {
        echo json_encode(['status' => 'error', 'message' => 'Database query execution failed: ' . $stmt->error]);
        $stmt->close();
        exit;
    }
    
    $result = $stmt->get_result();

    $orders = array();
    while ($row = $result->fetch_assoc()) {
        $orders[] = $row;
    }

    echo json_encode(['status' => 'success', 'data' => $orders]);

    $stmt->close();
} else {
    echo json_encode(['status' => 'error', 'message' => 'User ID is required.']);
}

$conn->close();
?>
