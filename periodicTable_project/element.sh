#!/bin/bash

export PAGER=cat
export PSQLRC=/dev/null

if [[ $# -eq 0 ]]; then
  echo "Please provide an element as an argument."
  exit 0
fi

escaped_input=$(printf "%s" "$1" | sed "s/'/''/g")

query=$(cat <<SQL
SELECT e.atomic_number, e.symbol, e.name, t."type", p.atomic_mass, p.melting_point_celsius, p.boiling_point_celsius
FROM elements AS e
JOIN properties AS p ON e.atomic_number = p.atomic_number
JOIN types AS t ON p.type_id = t.type_id
WHERE e.atomic_number::text = '$escaped_input'
   OR e.symbol = '$escaped_input'
   OR e.name = '$escaped_input';
SQL
)

result=$(psql -U postgres -d periodic_table -X -tA -c "$query")

if [[ -z "$result" ]]; then
  echo "I could not find that element in the database."
  exit 0
fi

IFS='|' read -r atomic_number symbol name element_type atomic_mass melting_point boiling_point <<< "$result"
printf "The element with atomic number %s is %s (%s). It's a %s, with a mass of %s amu. %s has a melting point of %s celsius and a boiling point of %s celsius.\n" "$atomic_number" "$name" "$symbol" "$element_type" "$atomic_mass" "$name" "$melting_point" "$boiling_point"
