<?php
$host = "localhost"; // Changed from "mysql" to "localhost"
$user = "root";
$pass = "";
$db   = "washio";

$conn = new mysqli($host, $user, $pass, $db);

// The calling script should check $conn->connect_error
// and handle JSON error reporting itself.
?>