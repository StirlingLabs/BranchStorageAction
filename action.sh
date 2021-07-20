
checkout-storage-branch(){
	declare -n worktree_path=$1
	
	# get default remote url
	remote_url=$(git remote get-url origin)

	# clone repo in another directory
	worktree_path=/tmp/$storage_branch-$(date +%s)
	
	# if the branch already exists, grab it
	git fetch -f --update-shallow origin $storage_branch

	if [ $? -ne 0 ]; then
		# virtually create an orphan branch
		empty_tree=$(git hash-object -w -t tree /dev/null)
		empty_commit=$(git commit-tree "$empty_tree" -m "Created storage branch.")	

		# create the worktree's directory
		mkdir -p $worktree_path
		
		# create a worktree for the orphan
		git worktree add -b $storage_branch $worktree_path $empty_commit	
	else
		# use the existing branch
		git worktree add --checkout --track $worktree_path $storage_branch
	fi
	
	# return the worktree path
	echo $worktree_path
}

append-storage(){
	storage_local_path="$1"

	echo "Appending content to $storage_branch:$dst" > /dev/stderr

	abs_dst_path=$storage_local_path/$dst

	# create it if it doesn't exist
	mkdir -p $(dirname $abs_dst_path)
	
	# copy the new content over
	cp -r $src $abs_dst_path

	# get back to the worktree root
	cd $storage_local_path

	# add, commit and push the new content
	git add .
	( git commit -m "$comment" && git push origin HEAD:$storage_branch ) || echo "No changes in storage branch." > /dev/stderr
	
	# go back to the working directory
	cd -
}


overwrite-storage(){
	storage_local_path="$1"

	echo "Overwriting content in $storage_branch:$dst" > /dev/stderr

	abs_dst_path=$storage_local_path/$dst

	# wipe out the existing directory
	rm -rf $abs_dst_path

	# recreate it
	mkdir -p $(dirname $abs_dst_path)
	
	# copy the new content over
	cp -r $src $abs_dst_path

	# get back to the worktree root
	cd $storage_local_path

	ls -la

	# add, commit and push the new content
	git add -A .
	( git commit -m "$comment" && git push origin HEAD:$storage_branch ) || echo "No changes in storage branch." > /dev/stderr
	
	# go back to the working directory
	cd -
}


main(){
	if [[ "$CI" == "true" ]]; then
		git config --global user.email storage@github.action
		git config --global user.name "GitHub storage action"
	fi

	# Create or checkout the storage branch in a worktree
	checkout-storage-branch storage_local_path
	echo "Local storage path: $storage_local_path" > /dev/stderr
	
	if [[ "$prune" != 'true' ]]; then
		append-storage $storage_local_path
	else
		overwrite-storage $storage_local_path
	fi

	cd $storage_local_path

	storage_branch=$(git branch --show-current)

	cd -

	git worktree remove -f $storage_local_path

	git branch -D $storage_branch

	rm -rf $storage_local_path
}

main
