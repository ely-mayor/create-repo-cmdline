#!/bin/bash

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

# Create the GitHub repository and redirect the curl response to /dev/null to hide it
if curl -f -X POST \
  -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/user/repos -d "{\"name\": \"$REPO_NAME\", \"private\": $REPO_PRIVATE}" >/dev/null 2>&1; then
  echo "Repository '$REPO_NAME' created successfully on GitHub."
else
  echo "Failed to create repository on GitHub."
fi

