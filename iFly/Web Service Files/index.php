<?php

/*
    index.php - the main page for processing http requests from
      the iFly application. This page handles user registration, user login,
      requests for flights and requests for points
*/

// Retrieve post variables
$firstName = $_POST['firstName'];
$lastName = $_POST['lastName'];
$email = $_POST['userName'];
$password = $_POST['userPassword'];
$mode = $_POST['mode'];
$flightNumber = $_POST['flightNumber'];

// Open mySQL Connection
$conn = $conn = new mysqli("us-cdbr-iron-east-03.cleardb.net", "b87bda83679db8", "82e7e35e", "heroku_9af174b243d2ecf");

// When register mode is selected
if ($mode == "register") {
  // Check to see if account already exists (aka email is in database)
  $message = $conn->query("SELECT * FROM users WHERE email = '$email'");
  // if account exists return error
  if ($message->num_rows > 0) {
    echo "Account already exists";
    return;
  }
  // Email not found in database
  else {
    // Query to insert new user into database
    $conn->query("INSERT INTO users (firstName, lastName, email, password) VALUES ('$firstName', '$lastName', '$email', '$password')");
    echo "Account Created";
  }
}
// When login mode is selected
else if ($mode == "login") {
  // Check if a user with matching username and password exist
  $message = $conn->query("SELECT * FROM users WHERE email = '$email' AND password = '$password'");
  // If not, credentials are wrong or account doesn't exist
  if ($message->num_rows < 1) {
    $loginAttempt->success = 0;
    $loginAttempt->message = "Username or password is incorrect";
    $loginAttempt->firstName = "NULL";
    $loginAttempt->lastName = "NULL";
    $loginAttempt->userId = "NULL";
    $loginAttempt->email = "NULL";
    $loginJSON = json_encode($loginAttempt);
    echo $loginJSON;
  }
  // Display welcome message if user is succesfully logged in
  else {
    $response = "";
    if($row = $message->fetch_assoc()) {
        $loginAttempt->success = 1;
        $loginAttempt->message = "Thank you for logging in, ".$row['firstName']." ".$row['lastName']."!";
        $loginAttempt->firstName = $row['firstName'];
        $loginAttempt->lastName = $row['lastName'];
        $loginAttempt->userId = $row['id'];
        $loginAttempt->email = $row['email'];
    }
    $loginJSON = json_encode($loginAttempt);
    echo $loginJSON;
  }
}

// Retrieve flights from the server
else if ($mode == "getFlights") {
  $message = $conn->query("SELECT * FROM flights");
  $count = 0;
  while ($row = $message->fetch_assoc()) {
      // populate array with returned flight information
      $flights[] = $row;
   }
   // Encode and return JSON file with flight info
   $flightJSON = json_encode($flights);
   echo $flightJSON;
 }

 // Retrieve and return flight points with the selected flight id
 else if ($mode == "getPoints") {
   // Retrieve all points which correspond to the selected flight
   $message = $conn->query("SELECT * FROM points WHERE flight = '$flightNumber'");
   while ($row = $message->fetch_assoc()) {
       $points[] = $row;
    }
    // Encode and return json data with points
    $pointJSON = json_encode($points);
    echo $pointJSON;

 }

$conn->close();

?>
