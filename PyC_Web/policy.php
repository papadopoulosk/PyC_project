<?php
/*
 * Description of Policy class. The class is used to create new XML
 * documents and then stored on the server
 */
class policy {
    
    private $xml=null;
    private $name=null;
    private $classification=null;

    public function __construct($name = null,$content=null,$clearance_level=null){
	// error catching if not passed in
	if($name==NULL && $content==null){
		$this->xml = null;
                $this->name = null;
	}
        else if ($name != null && $content==null) {
            
            $this->xml = new SimpleXMLElement('policies/'.$name.'.xml', NULL, TRUE);
            $this->name = $name;
        }
        else if ($name!= null && $content!=null && $clearance_level!=null)
        { 
            $this->xml = simplexml_load_string($content);
            $this->name = $name;
            $this->classification = $clearance_level;
        }
     }

    private function errorMsg($msg=''){
            echo "<p>{$msg}</p>";
    }

    public  function view()
    {
       echo htmlentities($this->xml->asXML());
    }
    public function edit($labelz)
     {
         ?>
         <form method="post" action="manager.php">
             <table id="policyEditor">
                 <tr><th>Choose a Employee role:</th><td><select name='role'><?php foreach ($labelz as $value) {
             echo "<option value='".$value['id']."'>".$value['name']."</option>";
         } ?></select></td></tr>
                 <hr>
                 <tr><th>Give a name to the document</th><td><input type="text" name="name" required></td></tr>
                 <tr><th>Is Kill-pill active:</th><td><input type="radio" name="kill" value="0" selected>No<input type="radio" name="kill" value="1"> Yes </td></tr>
                 <tr><th>Frequency that GPS locator is activated:</th><td><input type="number" name="freq"></td></tr>
                 <tr><th colspan="2">Coordinates of points that define the "Safe-zone":</th></tr>
                 <tr><td>x1:<input id="x1" name="point1lng" value="(Point 1 x)" readonly="readonly"></td>
                     <td>y1:<input id="y1" name="point1lat" value="(Point 1 y)" readonly="readonly"></td></tr>
                 <tr><td>x2:<input id="x2" name="point2lng" value="(Point 2 x)" readonly="readonly"></td>
                     <td>y2:<input id="y2" name="point2lat" value="(Point 2 y)" readonly="readonly"></td></tr>
                 <tr><td>x3:<input id="x3" name="point3lng" value="(Point 3 x)" readonly="readonly"></td>
                     <td>y3:<input id="y3" name="point3lat" value="(Point 3 y)" readonly="readonly"></td></tr>
                 <tr><td>x4:<input id="x4" name="point4lng" value="(Point 4 x)" readonly="readonly"></td>
                     <td>y4:<input id="y4" name="point4lat" value="(Point 4 y)" readonly="readonly"></td></tr>
                 <tr><td><input type="hidden" id="SWlat" name="SWlat" value=""></td><td><input type="hidden" id="SWlng" name="SWlng" value="" ></td></tr>
                 <tr><td><input type="hidden" id="NElat" name="NElat" value=""></td><td><input type="hidden" id="NElng" name="NElng" value="" ></td></tr>
                 <tr><th>Frequency of updating the log file:</th><td><input type="number" name="logfreq"></td></tr>
                 <tr><th>Frequency of uploading and backing up data:</th><td><input type="number" name="uploadfreq"></td></tr>
                 <tr><td colspan="2">
                 <input type="hidden" name="newpolicy">     
                <input type="submit" value="Generate Policy">
                     </td></tr>
                 
            </table>
        </form>
         <?php
     }
     public function save()
     {
        $this->xml->asXML("policies/".$this->name.".xml");
     }

    public function getPolicyName(){
        return $this->name;
    }
    public function getPolicyClassification(){
        return $this->classification;
    }

}
?>
