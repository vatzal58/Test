#!/bin/bash

# Check if required arguments are provided
if [ $# -ne 3 ]; then
    echo "Usage: $0 <repo_list_file> <source_branch> <new_branch>"
    echo "Example: $0 repos.txt main feature-branch"
    exit 1
fi

REPO_LIST=$1
SOURCE_BRANCH=$2
NEW_BRANCH=$3
SUCCESS_COUNT=0
ERROR_COUNT=0
REPORT=""

# Check if repo list file exists
if [ ! -f "$REPO_LIST" ]; then
    echo "Error: File $REPO_LIST not found"
    exit 1
fi

# Function to process each repository
process_repo() {
    local repo_path=$1
    local output=""

    # Store current directory to return later
    local current_dir=$(pwd)
    
    output+="\nProcessing: $repo_path\n"
    
    # Change to repo directory
    if ! cd "$repo_path" 2>/dev/null; then
        output+="Error: Cannot access directory $repo_path\n"
        REPORT+="$output"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        cd "$current_dir"
        return
    }

    # 1. Pull latest changes
    output+="Pulling latest changes...\n"
    if ! git pull origin "$SOURCE_BRANCH" 2>&1; then
        output+="Error: Failed to pull changes\n"
        REPORT+="$output"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        cd "$current_dir"
        return
    fi

    # 2. Checkout source branch
    output+="Checking out $SOURCE_BRANCH...\n"
    if ! git checkout "$SOURCE_BRANCH" 2>&1; then
        output+="Error: Failed to checkout $SOURCE_BRANCH\n"
        REPORT+="$output"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        cd "$current_dir"
        return
    fi

    # 3. Create and push new branch
    output+="Creating new branch $NEW_BRANCH...\n"
    if ! git checkout -b "$NEW_BRANCH" 2>&1; then
        output+="Error: Failed to create new branch $NEW_BRANCH\n"
        REPORT+="$output"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        cd "$current_dir"
        return
    fi

    # Create empty commit
    output+="Creating empty commit...\n"
    if ! git commit --allow-empty -m "Create empty commit for $NEW_BRANCH" 2>&1; then
        output+="Error: Failed to create empty commit\n"
        REPORT+="$output"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        cd "$current_dir"
        return
    fi

    # Push new branch
    output+="Pushing new branch...\n"
    if ! git push origin "$NEW_BRANCH" 2>&1; then
        output+="Error: Failed to push $NEW_BRANCH\n"
        REPORT+="$output"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        cd "$current_dir"
        return
    fi

    output+="Successfully processed $repo_path\n"
    REPORT+="$output"
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    
    # Return to original directory
    cd "$current_dir"
}

# Read repo list file line by line
while IFS= read -r repo_path || [ -n "$repo_path" ]; do
    # Skip empty lines and comments (lines starting with #)
    [ -z "$repo_path" ] && continue
    [[ "$repo_path" =~ ^# ]] && continue
    
    process_repo "$repo_path"
done < "$REPO_LIST"

# Display final report
echo "====================="
echo "Processing Report"
echo "====================="
echo -e "$REPORT"
echo "====================="
echo "Summary:"
echo "Successful operations: $SUCCESS_COUNT"
echo "Failed operations: $ERROR_COUNT"
echo "====================="

exit 0
