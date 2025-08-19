## 🧹 delete-nm.py – Recursive Node Modules Folder Cleaner
### 📄 Description

`delete-nm.py` is a simple Python script that recursively scans and deletes all node_modules directories starting from the directory in which the script is run. It provides visual feedback in the terminal with optional color-coded messages.

This is particularly useful for freeing up disk space or cleaning up JavaScript/Node.js projects before archiving or transferring them.

### 🚀 Features

- ✅ Recursively searches all subdirectories
- 🗑️ Deletes all node_modules folders found
- 🖥️ Visual terminal output with status messages
- 🌈 Colored output for better readability (optional)
- 🐍 Pure Python — no external dependencies required (colorama is optional)

### 📦 Requirements
- Python 3.6+
- Optional: `colorama` for cross-platform colored terminal output

### Install colorama (optional but recommended for Windows):
```python
pip install colorama
```

## 🧪 Usage

Place the script in the directory where you want to start the cleanup.

Run the script from the terminal:
```python
python delete-nm.py
```

### Watch the output as the script lists and deletes each node_modules folder it finds.

📁 Example Output
🔍 Scanning for node_modules folders...

Deleting: /Users/john/project1/node_modules
✓ Deleted: /Users/john/project1/node_modules
Deleting: /Users/john/project2/frontend/node_modules
✓ Deleted: /Users/john/project2/frontend/node_modules

Done!
✔ Folders deleted: 2
✗ Errors: 0

## ⚠️ Notes

**This operation is destructive. All contents of node_modules folders will be permanently deleted.**

### The script skips nested node_modules folders that are inside already-deleted directories.

### Errors (e.g., permission denied) will be caught and displayed, but the script will continue running.

## 🧼 Why Delete node_modules?
- `node_modules` folders can become extremely large due to dependencies in Node.js projects. They're often regenerated via npm install or yarn install, so removing them is safe and helps:
- Free up disk space
- Reduce clutter in backups or version control
- Reset broken or corrupted installations

## 📜 License
- [MIT Licence](https://github.com/HarshYadav152/resources/blob/main/LICENCE)
### This script is open-source and free to use, modify, or distribute.
