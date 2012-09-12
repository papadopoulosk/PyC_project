<?php 
    require('includes/header.php');
    require 'classes/sdk.class.php';
    require('classes/policy.php');
    require('classes/user.php');
    
    
    //require('classes/device.php');
  if (isset($_POST['delusr'])){
      $db->query("DELETE FROM devices WHERE owner=".$_POST['delusr']."");
      $db->query("DELETE FROM user WHERE id=".$_POST['delusr']."");
      //$usrname2del = $db->query_first("SELECT user.username FROM user WHERE user.id='".$_POST['delusr']."'");
      
       //AWS delete user folder
         $s3 = new AmazonS3();
        
        $bucket = 'pycthesis';
        $exists = $s3->if_bucket_exists($bucket);
        if ($exists){
            $userfolder = "/^documents\/users\/".$_POST['delusr']."/";
            $response = $s3->delete_object($bucket, $userfolder);
        }
      exit;
  }
$folder = 'demo/';
   if (isset($_POST['newpolicy'])){
        $content = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>";
        $content.= "<policy created=\"".date("F j, Y, g:i a")."\" ";
        $content.= "role=\"".$_POST['role']."\" >";
        
        
        if (isset($_POST['SWlat']) && isset($_POST['SWlng']) && isset($_POST['NElat']) && 
                isset($_POST['NElng']) && $_POST['SWlat']!='' && $_POST['SWlng']!=''
                    && $_POST['NElat']!='' && $_POST['NElng']!='' && isset($_POST['freq']) && $_POST['freq']>0  ){
            $content.="<geolocation ";
            $content.="SWlat='".$_POST['SWlat']."' ";
            $content.="SWlng='".$_POST['SWlng']."' ";
            $content.="NElat='".$_POST['NElat']."' ";
            $content.="NElng='".$_POST['NElng']."' ";
            $content.="freq='".$_POST['freq']."'";
            $content.=">";
            $content.="</geolocation>";
        }
        if ( isset($_POST['kill']) && $_POST['kill']==1)
            $content.= "<killpill status='{$_POST['kill']}'/>";
        if (isset($_POST['logfreq']) && $_POST['logfreq']>0 ) {
            $content.="<logfreq value='".$_POST['logfreq']."' />";
        }
        if (isset($_POST['uploadfreq']) && $_POST['uploadfreq']>0 ) {
            $content.="<uploadfreq value='".$_POST['uploadfreq']."' />";
        } 
        if ( isset($_POST['timestart']) && $_POST['timestart']!="" && isset($_POST['timeend']) && $_POST['timeend']!="" ) {
            $content.="<timeframe start=\"".$_POST['timestart']."\" end=\"".$_POST['timeend']."\" />";
        }
        $content.= "</policy>";
        $newpolicy = new policy($_POST['name'],$content, $_POST['role']);
        
        //$newpolicy->save();
        //delete old policy
        $tempoldfile = $db->query_first("SELECT policy FROM labels WHERE id=".$_POST['role'].";");
        $oldfile = "policies/{$tempoldfile['policy']}";
        if (file_exists($oldfile)) {
            unlink($oldfile);
        } 
        //Delete policy from AWS
        $s3 = new AmazonS3();
        $bucket = 'pycthesis';
        if($s3->if_bucket_exists($bucket)){
            // Delete a specific version
            $response = $s3->delete_object($bucket, $oldfile);
        }
        
        
        $newpolicy->save();
        $db->fetch_assoc("UPDATE labels SET policy='".$newpolicy->getPolicyName().".xml' WHERE id=".$_POST['role'].";"); 
        $labels     = $db->fetch_assoc("SELECT * FROM labels;");
    }
?>
                <script>
		  $(function() {
			$('.time').timepicker({
                            timeFormat:"H:i"
                        });
		  });
		</script>
<section class="maincontent" id="first">
    <header><h2 class="font2"><img class="managerImg" src="images2/asset.png" alt="assets">Asset Management</h2></header>
    <p  id="fileBrowser" ><a href="https://console.aws.amazon.com/s3/home?#" target="_blank">Amazon S3</a><a href="http://konpapadopoulos.kiwedevelopment.eu/thesis/ajaxplorer/" target="_blank">Local file Browser</a></p>
    <table><tr><td>
    <form method="post" action="users.php"><input type="submit" name="newuser" value="Add new user"><input type="hidden" name="newuser"></form>
    </td></tr></table>
<table id="assets">
    <?php 
foreach ($labels as $value) {
    echo "<tr><th colspan='2'>".$value['name'].": </th><td class='width20'>";
            //echo "<input id=\"".$value['policy']."\" type=\"button\" value=\"View ".$value['policy']."\">";
            echo "<a href=\"policies/".$value['policy']."\" target=\"_blank\">{$value['policy']}</a>";
            
    echo "</td></tr>";
    foreach ($users as $usr) {
        if ($usr['classification']==$value['id'])
        {
            echo "<tr id=\"rowID".$usr['id']."\"><td>".$usr['fname']." ".$usr['lname'].":</td>";
            echo "<td>";
            foreach ($devices as $dev) {
                if ($dev['owner']==$usr['id']) 
                    echo $dev['deviceid'];  
                }
            echo "</td><td><form class='inline' method='post' action='users.php'>";
            echo "<input type='hidden' name='userid' value='".$usr['id']."'><input type=\"submit\" value=\"Edit\"></form>";
            echo "<form id='delUsr".$usr['id']."' class='inline' method=\"post\" action=\"users.php\">";
            echo "<input class=\"delusr\" type=\"submit\" name=\"delete\" value=\"Delete\">";
            echo "<input type=\"hidden\" name=\"deleteuser\" value=\"".$usr['id']."\"/></form></td>";
            echo "</tr>";
            echo "<script> jQuery(function ($) {
                    $('form#delUsr".$usr['id']." input.delusr').click(function (e) {
                            e.preventDefault();

                            // example of calling the confirm function
                            // you must use a callback function to perform the \"yes\" action
                            confirm(\"Delete user ".$usr['fname']." ".$usr['lname']."?\", function () {
                                    $.ajax({ 
                                            type: \"POST\",
                                            data: \"delusr=\" + ".$usr['id'].",
                                            url: \"manager.php\",
                                            success: function(msg){
                                                    $(\"#rowID".$usr['id']."\").hide(\"slow\");
                                            }
                                    });
                            });
                    });
            }); </script>";        
            
        }
        
    }
}
?>  
   
</table>
    <p><a id="privatekey" href="#">Generate new Private/Public Key pair</a></p>
</section>
 <!-- modal content -->
		<div id='confirm'>
			<div class='header'><span>Confirm</span></div>
			<div class='message'></div>
			<div class='buttons'>
				<div class='no simplemodal-close'>No</div><div class='yes'>Yes</div>
			</div>
		</div>
		<!-- preload the images -->
		<div style='display:none'>
			<img src='img/confirm/header.gif' alt='' />
			<img src='img/confirm/button.gif' alt='' />
		</div>
<section class="maincontent" id="second">
    <header><h2  class="font2"><img class="managerImg" src="images2/vault.png" alt="vault">Policy Manager</h2></header>
    <article>
        <p>The policy manager allows the easy creation of an XML 
                document that can be retrieved by the mobile application.</p>
        <?php
        $xml = new policy(null);
        //$xml->view();
        $xml->edit($labels);
        
        if (isset($newpolicy)){
            echo "<hr />";
            //echo htmlentities($content);
            echo "<p><a href='policies/".$newpolicy->getPolicyName().".xml' target=\"_blank\">Click to view the new document.</a></p>";
        }
       ?>
    </article>
</section>
<p>Please adjust the area:</p>
 <div id="map_canvas"></div>
 <!-- Simple modal Javascript library -->
<script type="text/javascript" src="javascript/jquery.simplemodal.1.4.2.min.js"></script>
<script type="text/javascript" src="javascript/mymodalfunctions.js"></script>
<script>
$("a#privatekey").click(function(e){
                       e.preventDefault();
                            confirm("Realy create new private/public key pair? Old pair will be useless.", function () {
                                $.ajax({
                                    url: "createprivatekey.php",
                                    success:function(data){
                                        
                                    }
                                })
                            });
                  });

</script>
<?php require('includes/footer.php'); ?>