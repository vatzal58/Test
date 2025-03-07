#!/bin/bash

# Script to clone multiple Bitbucket repositories from a text file

# Check if input file is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <repository_list_file.txt>"
    echo "Example: $0 repos.txt"
    exit 1
fi

INPUT_FILE=$1
BASE_DIR=$(pwd)  # Current directory as base for cloning
BITBUCKET_URL="git@bitbucket.org"  # Default Bitbucket SSH URL
USERNAME=""  # Add your Bitbucket username if using HTTPS
WORKSPACE="" # Add your Bitbucket workspace/org name

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: File '$INPUT_FILE' not found!"
    exit 1
fi

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "Error: Git is not installed. Please install Git first."
    exit 1
fi

# Create a logs directory if it doesn't exist
mkdir -p clone_logs

# Log file with timestamp
LOG_FILE="clone_logs/clone_$(date +%Y%m%d_%H%M%S).log"

echo "Starting repository cloning process..." | tee -a "$LOG_FILE"
echo "Started at: $(date)" | tee -a "$LOG_FILE"
echo "----------------------------------------" | tee -a "$LOG_FILE"

# Counter for successful and failed clones
SUCCESS_COUNT=0
FAIL_COUNT=0

# Read the input file line by line
while IFS= read -r REPO_NAME; do
    # Skip empty lines or lines starting with #
    [[ -z "$REPO_NAME" || "$REPO_NAME" =~ ^# ]] && continue

    # Trim whitespace
    REPO_NAME=$(echo "$REPO_NAME" | xargs)

    echo "Processing: $REPO_NAME" | tee -a "$LOG_FILE"
    
    # Construct the full repository URL
    # Using SSH (recommended):
    FULL_URL="${BITBUCKET_URL}:${WORKSPACE}/${REPO_NAME}.git"
    
    # Alternative using HTTPS (uncomment if preferred):
    # FULL_URL="https://${USERNAME}@bitbucket.org/${WORKSPACE}/${REPO_NAME}.git"

    # Clone the repository
    if git clone "$FULL_URL" "$BASE_DIR/$REPO_NAME" 2>> "$LOG_FILE"; then
        echo "Successfully cloned $REPO_NAME" | tee -a "$LOG_FILE"
        ((SUCCESS_COUNT++))
    else
        echo "Failed to clone $REPO_NAME" | tee -a "$LOG_FILE"
        ((FAIL_COUNT++))
    fi
    
    echo "----------------------------------------" | tee -a "$LOG_FILE"

done < "$INPUT_FILE"

# Print summary
echo "" | tee -a "$LOG_FILE"
echo "Cloning Summary:" | tee -a "$LOG_FILE"
echo "Successful clones: $SUCCESS_COUNT" | tee -a "$LOG_FILE"
echo "Failed clones: $FAIL_COUNT" | tee -a "$LOG_FILE"
echo "Completed at: $(date)" | tee -a "$LOG_FILE"

echo "Process completed. Check $LOG_FILE for details."
