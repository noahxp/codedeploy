<?php
echo "v1   <br>";
echo gethostname() . "   <br>";
echo gethostbyname(gethostname()) . "   <br>";
$date = new DateTime('2000-01-01');
echo $date->format('Y-m-d H:i:s') . "  <br>";
echo "\n";
?>
