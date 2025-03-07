#!/bin/bash

# Check if both input file and commit message are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <input_file.txt> <commit_message>"
    exit 1
fi

INPUT_FILE=$1
COMMIT_MESSAGE=$2

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found"
    exit 1
fi

# Arrays to track success and failure
declare -a successful_repos
declare -a failed_repos

# Function to process each repository
process_repo() {
    local repo_path="$1"
    local source_branch="$2"
    local target_branch="$3"
    local release_branch="$4"
    local image_tag_prefix="$5"
    local made_changes=0

    echo "Processing repository: $repo_path"
    
    # Change to repo directory
    cd "$repo_path" || {
        echo "Failed to change to directory: $repo_path"
        failed_repos+=("$repo_path")
        return 1
    }

    # 1. Git pull
    echo "Pulling latest changes..."
    git pull origin "$source_branch" || {
        echo "Failed to pull from $source_branch"
        failed_repos+=("$repo_path")
        return 1
    }

    # 2. Create and checkout target feature branch from source branch
    echo "Creating target branch: $target_branch from $source_branch..."
    git checkout "$source_branch" || {
        echo "Failed to checkout $source_branch"
        failed_repos+=("$repo_path")
        return 1
    }
    git checkout -b "$target_branch" || {
        echo "Failed to create $target_branch"
        failed_repos+=("$repo_path")
        return 1
    }

    # 3. Modify Jenkinsfile if openshiftImageTagPrefix exists
    if [ -f "Jenkinsfile" ]; then
        if grep -q "openshiftImageTagPrefix" "Jenkinsfile"; then
            echo "Modifying Jenkinsfile with new image tag prefix: $image_tag_prefix..."
            sed -i "s/openshiftImageTagPrefix = .*/openshiftImageTagPrefix = \"$image_tag_prefix\"/" Jenkinsfile || {
                echo "Failed to modify Jenkinsfile"
                failed_repos+=("$repo_path")
                return 1
            }
            made_changes=1
        else
            echo "Note: openshiftImageTagPrefix not found in Jenkinsfile, will create empty commit"
        fi
    else
        echo "Warning: Jenkinsfile not found in $repo_path, will create empty commit"
    fi

    # 4. Stage, commit and push the changes (either real or empty)
    echo "Committing changes..."
    if [ $made_changes -eq 1 ]; then
        git add Jenkinsfile || {
            echo "Failed to stage Jenkinsfile"
            failed_repos+=("$repo_path")
            return 1
        }
        git commit -m "$COMMIT_MESSAGE" || {
            echo "Failed to commit changes"
            failed_repos+=("$repo_path")
            return 1
        }
    else
        git commit --allow-empty -m "$COMMIT_MESSAGE" || {
            echo "Failed to create empty commit"
            failed_repos+=("$repo_path")
            return 1
        }
    fi
    
    git push origin "$target_branch" || {
        echo "Failed to push $target_branch"
        failed_repos+=("$repo_path")
        return 1
    }

    # 5. Create release branch from target feature branch
    echo "Creating release branch: $release_branch..."
    git checkout -b "$release_branch" || {
        echo "Failed to create $release_branch"
        failed_repos+=("$repo_path")
        return 1
    }
    git push origin "$release_branch" || {
        echo "Failed to push $release_branch"
        failed_repos+=("$repo_path")
        return 1
    }

    echo "Successfully processed $repo_path"
    successful_repos+=("$repo_path")
    echo "--------------------------------"
}

# Read the input file line by line
while IFS=' ' read -r repo_path source_branch target_branch release_branch image_tag_prefix; do
    # Skip empty lines or lines starting with #
    [[ -z "$repo_path" || "$repo_path" =~ ^# ]] && continue

    # Process the repository
    process_repo "$repo_path" "$source_branch" "$target_branch" "$release_branch" "$image_tag_prefix"
done < "$INPUT_FILE"

# Print summary
echo -e "\n=== Processing Summary ==="
echo "Successful repositories (${#successful_repos[@]}):"
for repo in "${successful_repos[@]}"; do
    echo "  - $repo"
done

echo -e "\nFailed repositories (${#failed_repos[@]}):"
for repo in "${failed_repos[@]}"; do
    echo "  - $repo"
done

if [ ${#failed_repos[@]} -eq 0 ]; then
    echo -e "\nAll repositories processed successfully!"
else
    echo -e "\nSome repositories failed to process. Please check the logs above for details."
fi

find "$(pwd)" -maxdepth 1 -type d ! -path "$(pwd)" -exec realpath {} \; | awk '{print $1 " release/2025.02.14 feature/2025.05.16 release/2025.05.14 2025.05.16"}' > repos.txt && echo "# Format: repo_path source_branch target_branch release_branch openshiftImageTagPrefix" | cat - repos.txt > temp && mv temp repos.txt
