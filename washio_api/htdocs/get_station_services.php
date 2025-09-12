<?php
// Start output buffering
ob_start();

error_reporting(E_ALL);
ini_set('display_errors', 0); // Log errors, don't display
ini_set('log_errors', 1);

header("Content-Type: application/json");
require __DIR__ . '/db.php'; // Database connection

if (!isset($conn) || !$conn instanceof mysqli || (isset($conn->connect_error) && $conn->connect_error)) {
    error_log("get_station_services.php: CRITICAL - DB connection error from db.php");
    if (ob_get_level() > 0) ob_end_clean();
    echo json_encode(['status' => 'error', 'message' => 'Server error: Could not connect to database.']);
    exit;
}

$station_id = isset($_GET['station_id']) ? (int)$_GET['station_id'] : null;

if (empty($station_id)) {
    if (ob_get_level() > 0) ob_end_clean();
    echo json_encode(['status' => 'error', 'message' => 'Station ID is required.']);
    exit;
}

$services = [];
// Assuming your station foreign key in station_services is 'stationTb' as per your schema
$sql = "SELECT id, stationTb, service_name, service_price, estimated_time FROM station_services WHERE stationTb = ? ORDER BY service_name ASC";
$stmt = $conn->prepare($sql);

if (!$stmt) {
    error_log("get_station_services.php: SQL Prepare Error - " . $conn->error);
    if (ob_get_level() > 0) ob_end_clean();
    echo json_encode(['status' => 'error', 'message' => 'Server error: Could not prepare statement. ' . $conn->error]);
    exit;
}

$stmt->bind_param("i", $station_id);

if ($stmt->execute()) {
    $result = $stmt->get_result();
    if ($result->num_rows > 0) {
        while($row = $result->fetch_assoc()) {
            // Ensure correct data types for JSON
            $row['id'] = (int)$row['id'];
            $row['stationTb'] = (int)$row['stationTb']; // This is the station_id
            $row['service_price'] = !is_null($row['service_price']) ? (float)$row['service_price'] : null;
            // estimated_time is DATETIME, it will be a string. Consider formatting if needed.
            $services[] = $row;
        }
        if (ob_get_level() > 0) ob_end_clean();
        echo json_encode(['status' => 'success', 'data' => $services]);
    } else {
        if (ob_get_level() > 0) ob_end_clean();
        echo json_encode(['status' => 'success', 'data' => [], 'message' => 'No services found for this station.']);
    }
    $result->free();
} else {
    error_log("get_station_services.php: SQL Execute Error - " . $stmt->error);
    if (ob_get_level() > 0) ob_end_clean();
    echo json_encode(['status' => 'error', 'message' => 'Error fetching services: ' . $stmt->error]);
}

$stmt->close();
$conn->close();

// Fallback exit
if (ob_get_level() > 0) {
    ob_end_flush();
}
exit;
?>