#!/bin/bash

# Number Guessing Game with PostgreSQL persistence
# Uses a database `number_guess` and a `users` table with columns:
# username (varchar), games_played (int), best_game (int)

# psql command wrapper
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo "Enter your username:"
read USERNAME

# Enforce max length 22 characters
while [ ${#USERNAME} -gt 22 ]
do
	echo "Your username is too long, please try again:"
	read USERNAME
done

# Check if user exists
USER_INFO=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$USERNAME';")

if [[ -z $USER_INFO ]]
then
	echo "Welcome, $USERNAME! It looks like this is your first time here."
	# create user record
	$PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$USERNAME', 0, NULL);" >/dev/null
	GAMES_PLAYED=0
	BEST_GAME=""
else
	IFS='|' read GAMES_PLAYED BEST_GAME <<< "$USER_INFO"
	echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Start the game
SECRET=$(( RANDOM % 1000 + 1 ))
echo "Guess the secret number between 1 and 1000:"
GUESS=""
ATTEMPTS=0

while true
do
	read GUESS

	# Validate integer
	if [[ ! $GUESS =~ ^[0-9]+$ ]]
	then
		echo "That is not an integer, guess again:"
		continue
	fi

	((ATTEMPTS++))

	if (( GUESS > SECRET ))
	then
		echo "It's lower than that, guess again:"
	elif (( GUESS < SECRET ))
	then
		echo "It's higher than that, guess again:"
	else
		echo "You guessed it in $ATTEMPTS tries. The secret number was $SECRET. Nice job!"

		# Update games_played
		$PSQL "UPDATE users SET games_played = games_played + 1 WHERE username='$USERNAME';" >/dev/null

		# Update best_game if NULL or current attempts is better
		CURRENT_BEST=$($PSQL "SELECT best_game FROM users WHERE username='$USERNAME';")
		if [[ -z $CURRENT_BEST ]]
		then
			$PSQL "UPDATE users SET best_game = $ATTEMPTS WHERE username='$USERNAME';" >/dev/null
		else
			if (( ATTEMPTS < CURRENT_BEST ))
			then
				$PSQL "UPDATE users SET best_game = $ATTEMPTS WHERE username='$USERNAME';" >/dev/null
			fi
		fi

		break
	fi
done