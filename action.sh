#!/usr/bin/bash
checkout-storage-branch(){
	# get default remote url
	#remote_url=$(git remote get-url origin)

	# if the branch already exists, grab it
	if ! (git fetch -f --update-shallow origin "$storage_branch"); then
		echo "Creating storage branch: $storage_branch"
		# virtually create an orphan branch
		empty_tree=$(git hash-object -w -t tree /dev/null)
		empty_commit=$(git commit-tree "$empty_tree" -m "Created storage branch.")	

		# create the worktree's directory
		mkdir -p "$worktree_path"
		
		# create a worktree for the orphan
		git worktree add -b "$storage_branch" "$worktree_path" "$empty_commit" || exit $?	
	else
		echo "Using storage branch: $storage_branch"
		# use the existing branch
		git worktree add --checkout --track "$worktree_path" "$storage_branch" || exit $?
	fi
	
	# return the worktree path
	echo "$worktree_path"
}

append-storage(){
	echo "Appending content to $storage_branch:$dst" > /dev/stderr

	if [[ "$dst" == "." || "$dst" == "/" ]] ; then
		abs_dst_path="$worktree_path"
	else
		abs_dst_path="$worktree_path/$dst"
	fi

	# create it if it doesn't exist
	if [[ "${dst: -1}" = '/' ]] ; then
		mkdir -p "$abs_dst_path"
	else
		mkdir -p "$(dirname "$abs_dst_path")"
	fi
	
	# copy the new content over
	GLOBIGNORE=".:..:.git" cp -r $src "$abs_dst_path" || exit $?

	# get back to the worktree root
	cd "$worktree_path" || exit $?

	# add, commit and push the new content
	git add . || exit $?

	echo "Pushing $storage_branch..."
	( git commit -m "$comment" && git push origin "HEAD:$storage_branch" ) || echo "No changes in storage branch." > /dev/stderr
	
	# go back to the working directory
	cd - || exit $?
}


prune-storage(){
	echo "Pruning missing and appending new content in $storage_branch:$dst" > /dev/stderr
	
	if [[ "$dst" == "." || "$dst" == "/" ]] ; then
		abs_dst_path=$worktree_path
		# wipe out the existing directory
		GLOBIGNORE=".:..:.git" rm -rf $abs_dst_path/*
	else
		abs_dst_path=$worktree_path/$dst
		# wipe out the existing directory
		rm -rf $abs_dst_path
	fi

	# recreate it
	if [[ "${dst: -1}" = '/' ]] ; then
		mkdir -p "$abs_dst_path"
	else
		mkdir -p "$(dirname "$abs_dst_path")"
	fi
	
	# copy the new content over
	echo copying from $src to $abs_dst_path
	GLOBIGNORE=".:..:.git" cp -r $src "$abs_dst_path" || exit $?

	ls -la $src
	# get back to the worktree root
	cd "$worktree_path" || exit $?

	ls -la
	# add, commit and push the new content
	git add -A . || exit $?

	echo "Pushing $storage_branch..."
	( git commit -m "$comment" && git push origin "HEAD:$storage_branch" ) || echo "No changes in storage branch." > /dev/stderr
	
	# go back to the working directory
	cd - || exit $?
}


main(){
	if [[ -n "$GITHUB_ACTOR" ]]; then
		acceptHead="Accept: application/vnd.github.v3+json"
		apiUrl="https://api.github.com/users/$GITHUB_ACTOR"
		userId=$( curl -H "Authorization: token $GITHUB_TOKEN" -H "$acceptHead" "$apiUrl" | jq '.id' )
		git config --global user.name "$GITHUB_ACTOR"
		if [[ -n "$userId" ]] || [[ "$userId" = "null" ]]; then
			git config --global user.email "$userId+$GITHUB_ACTOR@users.noreply.github.com"
		else
			git config --global user.email "branch.storage@github.action"
		fi
	elif [[ "$CI" == "true" ]]; then
		git config --global user.name "Branch Storage Action"
		git config --global user.email "branch.storage@github.action"
	fi

	# worktree is safe place to store the content
	worktree_path=/tmp/$storage_branch-$(date +%s)

	# Create or checkout the storage branch in a worktree
	checkout-storage-branch
	echo "Local storage path: $worktree_path" > /dev/stderr
	
	if [[ "$prune" != 'true' ]]; then
		append-storage
	else
		prune-storage
	fi

	cd "$worktree_path" || exit $?

	storage_branch="$(git branch --show-current)"

	cd - || exit $?

	echo "Removing local storage branch $storage_branch and worktree: $storage_local_path"

	git worktree remove -f "$worktree_path" || exit $?

	git branch -D "$storage_branch" || exit $?

	rm -rf "$worktree_path" || exit $?
}

# make sure that we are copying .files
shopt -s dotglob
# run main
main
