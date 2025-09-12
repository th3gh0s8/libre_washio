<?php
// Start output buffering
ob_start();

error_reporting(E_ALL);
ini_set('display_errors', 0); // Log errors, don't display
ini_set('log_errors', 1);

header("Content-Type: application/json");
require __DIR__ . '/db.php'; // Database connection

if (!isset($conn) || !$conn instanceof mysqli || (isset($conn->connect_error) && $conn->connect_error)) {
    error_log("get_stations.php: CRITICAL - DB connection object from db.php is invalid or connect_error exists and db.php did not exit.");
    if (ob_get_level() > 0) ob_end_clean(); // Clean buffer before echoing
    echo json_encode(['status' => 'error', 'message' => 'Server error: Could not connect to database.']);
    exit;
}

$stations = [];
$sql = "SELECT id, name, address, longitude, latitude FROM stations ORDER BY name ASC";
$result = $conn->query($sql);

if ($result) {
    if ($result->num_rows > 0) {
        while($row = $result->fetch_assoc()) {
            // Ensure correct data types for JSON, especially for decimals
            $row['id'] = (int)$row['id'];
            $row['longitude'] = !is_null($row['longitude']) ? (float)$row['longitude'] : null;
            $row['latitude'] = !is_null($row['latitude']) ? (float)$row['latitude'] : null;
            $stations[] = $row;
        }
        if (ob_get_level() > 0) ob_end_clean();
        echo json_encode(['status' => 'success', 'data' => $stations]);
    } else {
        if (ob_get_level() > 0) ob_end_clean();
        echo json_encode(['status' => 'success', 'data' => [], 'message' => 'No stations found.']);
    }
    $result->free();
} else {
    error_log("get_stations.php: SQL Error - " . $conn->error);
    if (ob_get_level() > 0) ob_end_clean();
    echo json_encode(['status' => 'error', 'message' => 'Error fetching stations: ' . $conn->error]);
}

$conn->close();
// Fallback exit if not already exited
if (ob_get_level() > 0) {
    ob_end_flush(); // Send buffered content if any (should have been cleared)
}
exit;
?>