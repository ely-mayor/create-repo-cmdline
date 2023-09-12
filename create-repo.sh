#!/bin/bash

# Prompt for the repository name
echo "Enter repository name:"
read REPO_NAME

# Read the GitHub token from the configuration file
CONFIG_FILE=".github_config"

if [ -f "$CONFIG_FILE" ]; then
  source "$CONFIG_FILE"
fi

# Check if the token is set, and if not, prompt for it
if [ -z "$GITHUB_TOKEN" ]; then
  echo "GitHub token is not set. Please enter your GitHub token:"
  read GITHUB_TOKEN
  # Save the token to the configuration file
  echo "GITHUB_TOKEN=$GITHUB_TOKEN" > "$CONFIG_FILE"
fi

# Create the GitHub repository
curl -f -X POST \
  -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/user/repos -d "{\"name\": \"$REPO_NAME\", \"private\": true}"

# Check if the repository creation was successful
if [ $? -eq 0 ]; then
  echo "Repository '$REPO_NAME' created successfully on GitHub."
else
  echo "Failed to create repository on GitHub."
fi

