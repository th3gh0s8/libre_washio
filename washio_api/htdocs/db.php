<?php
ob_start(); // Start output buffering at the very beginning

// Enable full error reporting (to be logged)
error_reporting(E_ALL);
ini_set('display_errors', 1); // IMPORTANT: Turn off displaying errors directly in the output
ini_set('log_errors', 1); 

$servername = "localhost";
// $username = "root";
// $password = "Pasindu@12236"; // Please double-check this password
// $dbname = "washio";

$username = "pw_washio";
$password = "washio-2025-09-27"; // Please double-check this password
$dbname = "pw_washio_db";
$port = 3306; // Please double-check this port with your XAMPP MySQL (often 3306)

$conn = null; // Initialize $conn
$db_connection_error_message = 'Connection not attempted or failed before error property set.';

$link = mysqli_init();
if (!$link) {
    $db_connection_error_message = 'mysqli_init failed';
    error_log("Database Connection failed in db.php: mysqli_init failed");
    throw new Exception($db_connection_error_message);
} else {
    // Set connection timeout to 5 seconds
    if (!mysqli_options($link, MYSQLI_OPT_CONNECT_TIMEOUT, 5)) {
        // Log if setting option fails, but attempt to connect anyway
        error_log("Database Connection warning in db.php: Failed to set MYSQLI_OPT_CONNECT_TIMEOUT");
    }

    // Attempt to connect
    if (@mysqli_real_connect($link, $servername, $username, $password, $dbname, $port)) {
        $conn = $link;
    } else {
        // @ suppresses PHP warning for connection, we handle it via mysqli_connect_error()
        $db_connection_error_message = mysqli_connect_error(); // Get connection error
        error_log("Database Connection failed in db.php (mysqli_real_connect): " . $db_connection_error_message . " (Details: Server=$servername, User=$username, DB=$dbname, Port=$port)");
        throw new Exception($db_connection_error_message);
    }
}

// If $conn is not null, it means mysqli_real_connect succeeded and $conn is the link resource
if (!$conn->set_charset("utf8mb4")) {
    error_log("Error loading character set utf8mb4 in db.php: " . $conn->error);
}
?>