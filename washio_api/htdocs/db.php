<?php
ob_start(); // Start output buffering at the very beginning

// Enable full error reporting (to be logged)
error_reporting(E_ALL);
// IMPORTANT: Turn off displaying errors directly in the output for API stability
ini_set('display_errors', 0);
// Ensure PHP logs errors
ini_set('log_errors', 1); 

$servername = "localhost";
$username = "root";
$password = "Pasindu@12236"; // Please double-check this password
$dbname = "washio";
$port = 3307; // Please double-check this port with your XAMPP MySQL (often 3306)

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname, $port);

// Check connection
if ($conn->connect_error) {
    error_log("Database Connection failed in db.php: " . $conn->connect_error . " (Details: Server=$servername, User=$username, DB=$dbname, Port=$port)");
    
    ob_end_clean(); // Clean any previous buffer
    if (!headers_sent()) {
        header('Content-Type: application/json');
    }
    echo json_encode([
        'status' => 'error',
        'message' => 'PHP: Database connection failed. Check server logs.',
        'db_error_message' => $conn->connect_error // Provide specific DB error for easier client-side debugging if needed
    ]);
    exit; // Stop script execution if connection fails
}

if (!$conn->set_charset("utf8mb4")) {
    error_log("Error loading character set utf8mb4 in db.php: " . $conn->error);
    // Not exiting here, as the connection might still be usable
}

// error_log("db.php: Successfully connected to database."); // Keep for debugging if needed, but commented for production
// Do not ob_end_clean() here if connection is successful, the including script manages its own output.
?>