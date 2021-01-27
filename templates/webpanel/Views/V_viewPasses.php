<div style="overflow-x:auto;">
<table id="passes" style="background: white !important;">
  <tr>
    <th><?php echo $lang['satellite']; ?></th>
    <th><?php echo $lang['pass_start']; ?></th>
    <th><?php echo $lang['pass_end']; ?></th>
    <th><?php echo $lang['max_elev']; ?></th>
  </tr>
  <?php
    foreach ($passes as $pass) {
      if ($pass['is_active'] == false) {
        echo "<tr class='inactive' style='background: lightcoral;'>";
      } else {
        echo "<tr>";
      }
//      echo "<td>". $pass['sat_name'] ."</td>";
        $satnameurl=$pass['sat_name'];


        switch ($satnameurl){
	 case "NOAA15":
		$satnameurl=rawurlencode("NOAA 15");
		break;
         case "NOAA18":
                $satnameurl=rawurlencode("NOAA 18");
                break;
	 case "NOAA19":
                $satnameurl=rawurlencode("NOAA 19");
                break;
         case "METEOR-M2":
                $satnameurl=rawurlencode("METEOR-M 2");
                break;
	 }


      echo "<td><a href='https://satvis.space/?elements=Point,Label,Orbit%20track,Sensor%20cone&layers=OfflineHighres&gs=50.8515,-0.1446&tags=Weather&sat=". $satnameurl ."' target='satvis'><div style='height:100%;width:100%'>". $pass['sat_name'] ."</div></a></td>";
      echo "<td>". date('H:i:s', $pass['pass_start']) ."</td>";
      echo "<td>". date('H:i:s', $pass['pass_end']) ."</td>";
      echo "<td>". $pass['max_elev'] ."</td>";
      echo "</tr>";
    }
  ?>
</table>
</div>
