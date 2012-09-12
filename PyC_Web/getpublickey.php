<?php
include("includes/connect.php");
include("classes/database.php");

$db = new database(DB_SERVER, DB_USER, DB_PASS, DB_DATABASE); 
$db->connect();

$priv = $db->query_first("SELECT privateKey FROM encryption WHERE id=1 LIMIT 1");

 // get the public key $keyDetails['key'] from the private key;
//openssl_pkey_export(openssl_pkey_get_private ($priv['privateKey']),$dump);
//echo $dump;

$keyDetails = openssl_pkey_get_details( openssl_pkey_get_private ($priv['privateKey']));
//file_put_contents('publicKey.pem', $keyDetails['key']);
//$pubKey = openssl_pkey_get_public('publicKey.pem');
$pubKey = $keyDetails['key'];

echo $pubKey;
?>
