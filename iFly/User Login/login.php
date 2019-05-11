<?php

// Retrieve post variables
$firstName = $_POST['firstName'];
$lastName = $_POST['lastName'];
$email = $_POST['userName'];
$password = $_POST['userPassword'];
$mode = $_POST['mode'];

// Open mySQL Connection
$conn = new mysqli("us-cdbr-iron-east-03.cleardb.net", "b87bda83679db8", "82e7e35e", "heroku_9af174b243d2ecf");

// When register mode is selected
if ($mode == "register") {
  // Check to see if account already exists (aka email is in database)
  $message = $conn->query("SELECT * FROM users WHERE email = '$email'");
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
else if ($mode = "login") {
  // Check if a user with matching username and password exist
  $message = $conn->query("SELECT * FROM users WHERE email = '$email' AND password = '$password'");
  // If not, credentials are wrong or account doesn't exist
  if ($message->num_rows < 1) {
    echo "Username or password is incorrect";
    return;
  }
  // Display welcome message if user is succesfully logged in
  else {
    $response = "";
    while($row = $message->fetch_assoc()) {
      $response = "Thank you for logging in, ".$row['firstName']." ".$row['lastName']."!";
    }
    echo $response;
  }
}

$conn->close();
?>
