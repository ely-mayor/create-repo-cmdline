#!/bin/bash

# Check if curl is installed
if ! command -v curl &> /dev/null; then
  echo "curl is not installed. Please install curl before running this script."
  exit 1
fi

get_github_username() {
  local response="$1"
  local login_line=$(echo "$response" | grep '"login":')
  local username=$(echo "$login_line" | cut -d'"' -f4)
  echo "$username"
}

# Function to create or update repository description
update_repo_description() {
  local repo_owner="$1"
  local repo_name="$2"
  local token="$3"
  echo "Enter a description for the repository:"
  read DESCRIPTION

  if [ -z "$DESCRIPTION" ]; then
    echo "Description cannot be empty. No description added."
  else
    # Update the repository's description using the GitHub API
    if curl -X PATCH \
      -H "Authorization: token $token" -H "Accept: application/vnd.github.v3+json" \
      "https://api.github.com/repos/$repo_owner/$repo_name" -d "{\"name\": \"$repo_name\", \"description\": \"$DESCRIPTION\"}" >/dev/null 2>&1; then
      echo "Description updated successfully."
    else
      echo "Failed to update description on GitHub."
    fi
  fi
}

# Prompt for the repository name and ensure it's not empty
while true; do
  echo "Enter repository name:"
  read REPO_NAME
  if [ -z "$REPO_NAME" ]; then
    echo "Repository name cannot be empty. Please try again."
  else
    break
  fi
done

# Prompt for public or private repository with default to lowercase "y" for "yes"
while true; do
  echo "Do you want the repository to be private? (Y/N, default is 'y'):"
  read IS_PRIVATE

  # Convert the user's choice to uppercase for case-insensitive comparison
  IS_PRIVATE=$(echo "$IS_PRIVATE" | tr '[:lower:]' '[:upper:]')

  # Set the default value to lowercase "y" if the input is empty
  if [ -z "$IS_PRIVATE" ]; then
    IS_PRIVATE="Y"
  fi

  # Check if the input is valid
  if [ "$IS_PRIVATE" == "Y" ] || [ "$IS_PRIVATE" == "YES" ] || [ "$IS_PRIVATE" == "N" ] || [ "$IS_PRIVATE" == "NO" ]; then
    if [ "$IS_PRIVATE" == "N" ] || [ "$IS_PRIVATE" == "NO" ]; then
      REPO_PRIVATE=false
    else
      REPO_PRIVATE=true
    fi
    break
  else
    echo "Invalid input. Please enter 'Y' for yes or 'N' for no."
  fi
done

# Read the GitHub token from the configuration file and ensure it's not empty
while true; do
  CONFIG_FILE=".github_config"
  if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
  fi

  if [ -z "$GITHUB_TOKEN" ]; then
    echo "GitHub token is not set. Please enter your GitHub token:"
    read GITHUB_TOKEN

    if [ -z "$GITHUB_TOKEN" ]; then
      echo "GitHub token cannot be empty. Please try again."
    else
      # Save the token to the configuration file
      echo "GITHUB_TOKEN=$GITHUB_TOKEN" > "$CONFIG_FILE"
      break
    fi
  else
    break
  fi
done

# Get the GitHub username programmatically and assign it to GITHUB_USERNAME
API_RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user)
GITHUB_USERNAME=$(get_github_username "$API_RESPONSE")

# Create the GitHub repository and handle errors
if curl -f -X POST \
  -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/user/repos -d "{\"name\": \"$REPO_NAME\", \"private\": $REPO_PRIVATE}" >/dev/null 2>&1; then
  echo "Repository '$REPO_NAME' created successfully on GitHub."

  # Ask the user if they want to add a description or about section
  while true; do
    echo "Do you want to add a description to the repository? (Y/N):"
    read ADD_DESCRIPTION

    ADD_DESCRIPTION=$(echo "$ADD_DESCRIPTION" | tr '[:lower:]' '[:upper:]')

    if [ "$ADD_DESCRIPTION" == "Y" ] || [ "$ADD_DESCRIPTION" == "YES" ]; then
      update_repo_description "$GITHUB_USERNAME" "$REPO_NAME" "$GITHUB_TOKEN"
      break
    elif [ "$ADD_DESCRIPTION" == "N" ] || [ "$ADD_DESCRIPTION" == "NO" ]; then
      echo "No description added."
      break
    else
      echo "Invalid input. Please enter 'Y' for yes or 'N' for no."
    fi
  done

else
  echo "Failed to create repository on GitHub."
fi

