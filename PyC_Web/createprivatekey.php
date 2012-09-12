<?php
include("includes/connect.php");
include("classes/database.php");

$db = new database(DB_SERVER, DB_USER, DB_PASS, DB_DATABASE); 
$db->connect();

$privateKey = openssl_pkey_new(array(
	'private_key_bits' => 1024,
	'private_key_type' => OPENSSL_KEYTYPE_RSA,
));

openssl_pkey_export($privateKey, $privateKeyExport);
if ($db->query("UPDATE encryption SET privateKey='".$privateKeyExport."' WHERE id=1")==1){
    echo "New private key stored successfully in DB";
}
//echo $privateKeyExport;
//echo $db->query("INSERT INTO encryption VALUES ('','".$privateKey."')");
         
?>
