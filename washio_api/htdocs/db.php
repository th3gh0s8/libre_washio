<?php
// Enable full error reporting for debugging (helpful during setup)
error_reporting(E_ALL);
ini_set('display_errors', 1);

$servername = "localhost";    // MySQL server hostname (usually "localhost" or "127.0.0.1")
$username = "root";           // Your MySQL username
$password = "Pasindu@12236";    // Your MySQL password
$dbname = "washio";           // <<< CORRECTED DATABASE NAME
$port = 3307;                 // Your MySQL port

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname, $port);

// Check connection
if ($conn->connect_error) {
    // Log detailed error to the PHP error log
    error_log("Database Connection failed: " . $conn->connect_error . " (Details: Server=$servername, User=$username, DB=$dbname, Port=$port)");
    
    // Send a generic error response to the client
    header('Content-Type: application/json');
    echo json_encode([
        'status' => 'error',
        'message' => 'Could not connect to the database. Please check server logs for more details.',
    ]);
    exit; // Stop script execution if connection fails
}

// Set character set to utf8mb4 for better Unicode support
if (!$conn->set_charset("utf8mb4")) {
    error_log("Error loading character set utf8mb4: " . $conn->error);
}

// Optional: Log successful connections for debugging (remove in production):
// error_log("db.php: Successfully connected to database. (Server=$servername, User=$username, DB=$dbname, Port=$port)");

// The $conn variable is now ready to be used by any PHP script that includes this db.php file.
?>