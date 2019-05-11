<?php

/*
    uploadFlight.php -
      this handles upload requests and pushes flights
      and their associated points to the database.
*/

$flightJson = file_get_contents('php://input');
$flightArray = json_decode($flightJson, true);

$flightName = $flightArray["name"];
$flightPoints = $flightArray["points"];
$description = $flightArray["description"];
$userId = $flightArray["user"];
$location = $flightArray["location"];
//$location = $flightArray["location"];

$conn = new mysqli("us-cdbr-iron-east-03.cleardb.net", "b87bda83679db8", "82e7e35e", "heroku_9af174b243d2ecf");
$message = $conn->query("SELECT * FROM flights WHERE name = '$flightName'");
if ($message->num_rows > 0) {
  echo "Flight name already taken";
}
else {
  // Insert flight into the list
  $conn->query("INSERT INTO flights (name, user, description, location) VALUES ('$flightName', '$userId', '$description', '$location')");

  // Retrieve generated flight id
  $message = $conn->query("SELECT * FROM flights WHERE name = '$flightName'");
  if($row = $message->fetch_assoc()) {
      $flightId = $row['id'];
    }

  $count = 0;        // Index of points
  $finished = False; // Indicator for end of loop

  // populate array with points
  while (!$finished) {
    if (array_key_exists($count, $flightPoints)) {
      $latitude = $flightPoints[$count]['latitude'];
      $longitude = $flightPoints[$count]['longitude'];
      $altitude = $flightPoints[$count]['altitude'];
      $speedY = $flightPoints[$count]['speedY'];
      $speedX = $flightPoints[$count]['speedX'];
      $heading = $flightPoints[$count]['heading'];

      $conn->query("INSERT INTO points (flight, point, latitude, longitude, altitude, hspeed, vspeed, heading) VALUES ('$flightId', '$count', '$latitude', '$longitude', '$altitude', '$speedX', '$speedY', '$heading')");
      $count += 1;
    }
    else {
      $finished = True;
    }
  }
  echo "Flight successfully uploaded";
}

?>
