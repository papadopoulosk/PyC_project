<?php

include ('classes/database.php');
include ('classes/device.php');
include ('classes/label.php');
include ('classes/user.php');
include ('includes/connect.php');

$db = new database(DB_SERVER, DB_USER, DB_PASS, DB_DATABASE);
$db->connect();

if (isset($_POST["deviceID"])) {

    $temp1 = $db->query_first("SELECT devices.owner FROM devices WHERE devices.deviceid='" . $_POST["deviceID"] . "'");
    if ($temp1) {


        $temp2 = $db->query_first("SELECT user.username FROM user WHERE user.id='" . $temp1['owner'] . "'");


        if ($_FILES["file"]["error"] > 0) {
            echo "Error: " . $_FILES["file"]["error"] . "<br />";
        } else {
            echo "File name: " . $_FILES["file"]["name"] . ". ";
            move_uploaded_file($_FILES["file"]["tmp_name"], "documents/users/" . $temp2['username'] . "/" . $_FILES["file"]["name"]);
            echo "Successfully stored in: " . "documents/users/" . $temp2['username'] . "/" . $_FILES["file"]["name"];
        }
    } else {
        echo "No device id found";
    }
} else {
    echo "No device id sent";
}
?>

