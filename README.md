# 🎋 Branch Storage Action

> Store files on an orphan branch of a repo dedicated for static storage

## ⭐ Features

- Save files on a separate branch
- Specify a custom commit message on save
- Customize `storage-branch` name

## 🚀 Quickstart

```yaml
      # Generate an asset in your job. E.G: Download a badge image from shields.io
      - name: Download a badge file
        run: wget https://img.shields.io/badge/license-MIT-red
      
      # Store this asset in 'gh-storage' branch.
      - name: Save file in a new orphan storage branch
        uses: StirlingLabs/BranchStorageAction@main
        with:
          src: license-MIT-blue
          dst: legal/LICENSE
```

Badge generated in this action can then be referenced from your README or anywhere else...

The `src` and `dst` parameters are passed to `cp -r` so they can be a single file or full directory trees.

## Parameters

|Name|Function|
|-|-|
|src|Relative or absolute path to the file that must be saved in storage-branch|
|dst|Path relative to storage branch root where the file (or folder) will be stored. If destination folder doesn't exists it is automatically created.|
|storage-branch|Name of the branch used as storage branch (defaults to 'gh-storage', you can have multiple in differents jobs).|
|prune|If true, deletes as well as adds or updates files, otherwise only adds new files and updates existing ones.|
|comment|Message that will be used to document commit associated with this change.|
|username|Username that will appear in history applying changes to the storage branch.|
|useremail|Email that will appear in history applying changes to the storage branch.|
