<?php 
    require('includes/header.php');
    require('classes/policy.php');
    require('classes/user.php');
    //require('classes/device.php');
  if (isset($_POST['delusr'])){
      $db->query("DELETE FROM devices WHERE owner=".$_POST['delusr']."");
      $db->query("DELETE FROM user WHERE id=".$_POST['delusr']."");
      return;
  }
    
   if (isset($_POST['newpolicy'])){
        $content = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>";
        $content.= "<policy created=\"".date("F j, Y, g:i a")."\" ";
        $content.= "role=\"".$_POST['role']."\" >";
        
        
        if (isset($_POST['SWlat']) && isset($_POST['SWlng']) && isset($_POST['NElat']) && 
                isset($_POST['NElng']) && $_POST['SWlat']!='' && $_POST['SWlng']!=''
                    && $_POST['NElat']!='' && $_POST['NElng']!='' ){
            $content.="<geolocation ";
            $content.="SWlat='".$_POST['SWlat']."' ";
            $content.="SWlng='".$_POST['SWlng']."' ";
            $content.="NElat='".$_POST['NElat']."' ";
            $content.="NElng='".$_POST['NElng']."' ";
            if (isset($_POST['freq']) && $_POST['freq']>0 ) $content.="freq='".$_POST['freq']."'";
            $content.=">";
            $content.="</geolocation>";
        }
        if ( isset($_POST['kill']))
            $content.= "<killpill status='{$_POST['kill']}'/>";
        if (isset($_POST['logfreq']) && $_POST['logfreq']>0 ) {
            $content.="<logfreq value='".$_POST['logfreq']."' />";
        }
        if (isset($_POST['uploadfreq']) && $_POST['uploadfreq']>0 ) {
            $content.="<uploadfreq value='".$_POST['uploadfreq']."' />";
        } 
        $content.= "</policy>";
        $newpolicy = new policy($_POST['name'],$content, $_POST['role']);
        
        //$newpolicy->save();
        $oldfile = $db->query_first("SELECT policy FROM labels WHERE id=".$_POST['role'].";");
        if (file_exists("policies/{$oldfile['policy']}")) {
            unlink("policies/{$oldfile['policy']}");
        } 
        $newpolicy->save();
        $db->fetch_assoc("UPDATE labels SET policy='".$newpolicy->getPolicyName().".xml' WHERE id=".$_POST['role'].";");    
   }   
?>
<section class="maincontent" id="first">
    <header><h2 class="font2"><img class="managerImg" src="images2/asset.png">Asset Management</h2></header>
    <table><tr><td>
    <form method="post" action="users.php"><input type="submit" name="newuser" value="Add new user"><input type="hidden" name="newuser"></form>
    </td></tr></table>
<table id="assets" border="0">
    <?php 
foreach ($labels as $value) {
    echo "<tr><th colspan='2'>".$value['name'].": </th><td width=20%>";
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
            echo "<input type=\"hidden\" name=\"deleteuser\" value=\"".$usr['id']."\"></form></td>";
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
        echo "</tr>";
    }
}
?>  
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
</table>
</section>
<section class="maincontent" id="second">
    <header><h2  class="font2"><img class="managerImg" src="images2/vault.png">Policy Manager</h2></header>
    <article><im
        <p>The policy manager allows the easy creation of an XML 
                document that can be retrieved by the mobile application.</p>
        <?php
        $xml = new policy(null);
        //$xml->view();
        $xml->edit($labels);
        
        if (isset($newpolicy)){
            echo "<hr>";
                    echo htmlentities($content);
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
<?php require('includes/footer.php'); ?>