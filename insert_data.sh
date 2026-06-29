#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.

# Path to the CSV file containing the match data.
csv_file="/workspace/project/games.csv"

# Escape single quotes so team names can be inserted safely into SQL strings.
escape_sql_literal() {
  local value="$1"
  value=${value//\'/\'\'}
  printf '%s' "$value"
}

# Run a SQL statement through the existing psql command.
run_sql() {
  local sql="$1"
  eval "$PSQL \"$sql\""
}

# Look up the team_id for a team name from the teams table.
get_team_id() {
  local team_name="$1"
  local escaped_team_name
  escaped_team_name=$(escape_sql_literal "$team_name")
  local query="SELECT team_id FROM teams WHERE name = '$escaped_team_name';"
  run_sql "$query"
}

# Insert each unique team name from the CSV into the teams table first.
while IFS= read -r team_name; do
  [[ -z "$team_name" ]] && continue
  escaped_team_name=$(escape_sql_literal "$team_name")
  sql="INSERT INTO teams (name) VALUES ('$escaped_team_name') ON CONFLICT (name) DO NOTHING;"
  run_sql "$sql"
done < <(tail -n +2 "$csv_file" | awk -F',' '{print $3; print $4}' | sed '/^$/d' | sort -u)

# Insert one row into the games table for each match in the CSV.
while IFS=, read -r year round winner opponent winner_goals opponent_goals; do
  [[ -z "$year" && -z "$round" ]] && continue
  winner_id=$(get_team_id "$winner")
  opponent_id=$(get_team_id "$opponent")
  escaped_round=$(escape_sql_literal "$round")
  sql="INSERT INTO games (year, round, winner_id, opponent_id, winner_goals, opponent_goals) VALUES ($year, '$escaped_round', $winner_id, $opponent_id, $winner_goals, $opponent_goals);"
  run_sql "$sql"
done < <(tail -n +2 "$csv_file")