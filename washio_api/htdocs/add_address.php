<?php
header('Content-Type: application/json');
include 'db.php'; // Your database connection file

// Get the posted data
// It's good practice to ensure these are set and sanitize them
$user_id = isset($_POST['user_id']) ? mysqli_real_escape_string($conn, $_POST['user_id']) : null;
$address_type = isset($_POST['address_type']) ? mysqli_real_escape_string($conn, $_POST['address_type']) : null; // e.g., 'Home', 'Work', 'Other'
$address_line1 = isset($_POST['address_line1']) ? mysqli_real_escape_string($conn, $_POST['address_line1']) : null;
$address_line2 = isset($_POST['address_line2']) ? mysqli_real_escape_string($conn, $_POST['address_line2']) : null; // Optional
$longitude = isset($_POST['longitude']) ? mysqli_real_escape_string($conn, $_POST['longitude']) : null;
$latitude = isset($_POST['latitude']) ? mysqli_real_escape_string($conn, $_POST['latitude']) : null;
$map_address = isset($_POST['map_address']) ? mysqli_real_escape_string($conn, $_POST['map_address']) : null; // Full address string from map selection

$response = array();

// Corrected table name
$tableName = 'user_locations'; 

if ($user_id && $address_type && $address_line1 && $longitude && $latitude && $map_address) {
    // Address_line2 can be NULL, so we handle it differently if not provided
    if ($address_line2 === null || $address_line2 === '') {
        $sql = "INSERT INTO $tableName (userTB, Address_Type, Address_Line1, longitude, latitude, Map_Address, created_at, updated_at) 
                VALUES (?, ?, ?, ?, ?, ?, NOW(), NOW())";
        $stmt = mysqli_prepare($conn, $sql);
        mysqli_stmt_bind_param($stmt, 'isssss', $user_id, $address_type, $address_line1, $longitude, $latitude, $map_address);
    } else {
        $sql = "INSERT INTO $tableName (userTB, Address_Type, Address_Line1, Address_Line2, longitude, latitude, Map_Address, created_at, updated_at) 
                VALUES (?, ?, ?, ?, ?, ?, ?, NOW(), NOW())";
        $stmt = mysqli_prepare($conn, $sql);
        mysqli_stmt_bind_param($stmt, 'issssss', $user_id, $address_type, $address_line1, $address_line2, $longitude, $latitude, $map_address);
    }

    if (mysqli_stmt_execute($stmt)) {
        $response['status'] = 'success';
        $response['message'] = 'Address added successfully.';
        $response['address_id'] = mysqli_insert_id($conn); // Get the ID of the newly inserted address
    } else {
        $response['status'] = 'error';
        $response['message'] = 'Failed to add address: ' . mysqli_stmt_error($stmt);
    }
    mysqli_stmt_close($stmt);
} else {
    $response['status'] = 'error';
    $response['message'] = 'Required fields are missing.';
    $missing_fields = [];
    if (!$user_id) $missing_fields[] = 'user_id';
    if (!$address_type) $missing_fields[] = 'address_type';
    if (!$address_line1) $missing_fields[] = 'address_line1';
    if (!$longitude) $missing_fields[] = 'longitude';
    if (!$latitude) $missing_fields[] = 'latitude';
    if (!$map_address) $missing_fields[] = 'map_address';
    $response['missing_fields'] = $missing_fields;
}

mysqli_close($conn);
echo json_encode($response);
?>
