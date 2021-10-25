git filter-branch --index-filter 'git rm --cached --ignore-unmatch file_to_remove' --prune-empty -- --all
