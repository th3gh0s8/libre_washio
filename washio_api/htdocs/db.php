<?php
$host = "mysql";
$user = "root";
$pass = "";
$db   = "washio";

$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
  die("Connection failed: " . $conn->connect_error);
}
?>