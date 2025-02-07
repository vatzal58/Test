#!/bin/bash

# Function to modify the Jenkinsfile
modify_jenkinsfile() {
    local repo_path=$1
    local new_image_tag_prefix=$2
    local jenkinsfile_path="$repo_path/Jenkinsfile"

    if [[ ! -f "$jenkinsfile_path" ]]; then
        echo "Jenkinsfile not found in $repo_path. Skipping..."
        return
    fi

    echo "Modifying Jenkinsfile in $repo_path..."
    sed -i "s/openshiftImageTagPrefix = .*/openshiftImageTagPrefix = \"$new_image_tag_prefix\"/" "$jenkinsfile_path"
}

# Function to process a repository
process_repo() {
    local repo_path=$1
    local base_branch=$2
    local new_branch=$3
    local new_image_tag_prefix=$4
    local commit_message=$5

    echo "Processing repository: $repo_path"

    # Navigate to the repository
    cd "$repo_path" || { echo "Repository $repo_path not found. Skipping..."; return; }

    # Pull the latest changes
    echo "Pulling latest changes..."
    git pull || { echo "Failed to pull changes. Skipping..."; return; }

    # Create and checkout the new branch
    echo "Creating and checking out branch $new_branch from $base_branch..."
    git checkout "$base_branch" || { echo "Failed to checkout base branch. Skipping..."; return; }
    git pull || { echo "Failed to pull changes. Skipping..."; return; }
    git checkout -b "$new_branch" || { echo "Failed to create new branch. Skipping..."; return; }

    # Modify the Jenkinsfile
    modify_jenkinsfile "$repo_path" "$new_image_tag_prefix"

    # Stage, commit, and push the changes
    echo "Staging, committing, and pushing changes..."
    git add Jenkinsfile || { echo "Failed to stage changes. Skipping..."; return; }
    git commit -m "$commit_message" || { echo "Failed to commit changes. Skipping..."; return; }
    git push origin HEAD || { echo "Failed to push changes. Skipping..."; return; }

    echo "Repository $repo_path processed successfully."
    cd - > /dev/null || return
}

# Main script
echo "Enter the repository names separated by spaces:"
read -r -a repo_names

echo "Enter the base branch to create the new branch from:"
read -r base_branch

echo "Enter the name of the new branch:"
read -r new_branch

echo "Enter the new openshiftImageTagPrefix value:"
read -r new_image_tag_prefix

echo "Enter the commit message:"
read -r commit_message

# Base directory containing all the repositories
base_dir=$(pwd)

# Process each repository
for repo_name in "${repo_names[@]}"; do
    repo_path="$base_dir/$repo_name"
    process_repo "$repo_path" "$base_branch" "$new_branch" "$new_image_tag_prefix" "$commit_message"
done

echo "Script execution completed."
