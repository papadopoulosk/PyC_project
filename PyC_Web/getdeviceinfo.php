<?php

include ('classes/database.php');
include ('classes/device.php');
include ('classes/label.php');
include ('classes/user.php');
include ('includes/connect.php');

$db = new database(DB_SERVER, DB_USER, DB_PASS, DB_DATABASE); 
$db->connect(); 

//$_POST['deviceID']= "00000000-0000-1000-8000-000C29B58891";
if (isset($_POST["deviceID"])){
    $temp1 = $db->query_first("SELECT devices.owner FROM devices WHERE devices.deviceid='".$_POST["deviceID"]."'");
    $temp2 = $db->query_first("SELECT user.username,user.classification FROM user WHERE user.id='".$temp1['owner']."'");
    $temp3 = $db->query_first("SELECT labels.name FROM labels WHERE labels.id='".$temp2['classification']."'");
    echo $temp3['name']."/".$temp2['username'];
}
?>
