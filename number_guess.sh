#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t -c"
# TRUNCATE=$($PSQL "TRUNCATE users CASCADE;")

RANDOM_NUMBER=$(($RANDOM % 1000 + 1))

echo -e "\nEnter your username:"
read USERNAME

# Check user data in database
USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME'";)
# If not found
if [[ -z $USER_ID ]]
then
  # Add to database
  INSERT_PLAYER_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME');")
  # Read from database
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME'";)
fi

GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE user_id = $USER_ID;")
GAMES_PLAYED=$(echo $GAMES_PLAYED | sed 's/ *//')

# If games played
if [[ $GAMES_PLAYED -eq 0 ]]
then
  # Greet user as first timer
  echo -e "\nWelcome, $USERNAME! It looks like this is your first time here."
else
  # Else, greet and announce # of games and best game
  BEST_GAME_ID=$($PSQL "SELECT best_game_id FROM users WHERE user_id = $USER_ID;")
  BEST_GAME_ID=$(echo $BEST_GAME_ID | sed 's/ *//')
  if [[ $BEST_GAME_ID ]]
  then
    LOWEST_GUESSES=$($PSQL "SELECT MIN(guesses) FROM games WHERE user_id = $USER_ID;")
    LOWEST_GUESSES=$(echo $LOWEST_GUESSES | sed 's/ *//')
  fi
  echo -e "\nWelcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $LOWEST_GUESSES guesses."
fi

# Play game
echo -e "\nGuess the secret number between 1 and 1000:"
read PLAYER_GUESS
NUM_GUESSES=1

# Start game while loop
# DEBUG: echo -e "answer = $RANDOM_NUMBER, guess = $PLAYER_GUESS"
while [[ $PLAYER_GUESS != $RANDOM_NUMBER ]]
do  
  if ! [[ $PLAYER_GUESS =~ [0-9]+ ]]
  then
    echo -e "\nThat is not an integer, guess again:"
  elif [[ $PLAYER_GUESS -gt $RANDOM_NUMBER ]]
  then
    echo -e "\nIt's lower than that, guess again:"
  else
    echo -e "\nIt's higher than that, guess again:"
  fi
  NUM_GUESSES=$(($NUM_GUESSES + 1))
  read PLAYER_GUESS
done

# Find best game guesses
LOWEST_GUESSES=$($PSQL "SELECT MIN(guesses) FROM games WHERE user_id = $USER_ID;")

# Add game to games database
UPDATE_RESULT=$($PSQL "INSERT INTO games(user_id, guesses) VALUES($USER_ID, $NUM_GUESSES);")


BEST_GAME_ID=$($PSQL "SELECT best_game_id FROM users WHERE user_id = $USER_ID;")

# If this game is better or first game
if [ -z $BEST_GAME_ID ] || [ $NUM_GUESSES -lt $LOWEST_GUESSES ]
then
  # Get this games ID
  THIS_GAME_ID=$($PSQL "SELECT MAX(game_id) FROM games;")
  
  # Update users with this game id
  UPDATE_BEST_GAME_RESULT=$($PSQL "UPDATE users SET best_game_id = $THIS_GAME_ID WHERE user_id = $USER_ID;")
fi

# Increment games played
GAMES_PLAYED_RESULT=$($PSQL "UPDATE users SET games_played = $(($GAMES_PLAYED + 1)) WHERE user_id = $USER_ID;")

# Exited while loop, game was won
echo -e "\nYou guessed it in $NUM_GUESSES tries. The secret number was $RANDOM_NUMBER. Nice job!"