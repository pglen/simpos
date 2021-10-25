for del in `cat deleted.txt`
do
    git filter-branch --index-filter "git rm --cached --ignore-unmatch $del" --prune-empty -- --all
    # The following seems to be necessary every time
    # because otherwise git won't overwrite refs/original
    git reset --hard
    git for-each-ref --format="%(refname)" refs/original/ | xargs -n 1 git update-ref -d
    git reflog expire --expire=now --all
    git gc --aggressive --prune=now
done;
