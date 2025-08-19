import os
import shutil
import sys
from pathlib import Path

# Optional: Add colors for terminal output
try:
    from colorama import init, Fore, Style
    init(autoreset=True)
except ImportError:
    class DummyColor:
        def __getattr__(self, name):
            return ''
    Fore = Style = DummyColor()

deleted_count = 0
error_count = 0

def delete_node_modules(start_path: Path):
    global deleted_count, error_count
    for root, dirs, files in os.walk(start_path, topdown=True):
        if 'node_modules' in dirs:
            nm_path = Path(root) / 'node_modules'
            try:
                print(f"{Fore.YELLOW}Deleting: {nm_path}")
                shutil.rmtree(nm_path)
                print(f"{Fore.GREEN}✓ Deleted: {nm_path}")
                deleted_count += 1
            except Exception as e:
                print(f"{Fore.RED}✗ Failed to delete: {nm_path} → {e}")
                error_count += 1
            # Prevent re-visiting this directory
            dirs.remove('node_modules')

if __name__ == "__main__":
    print(f"{Fore.CYAN}🔍 Scanning for node_modules folders...\n")
    base_path = Path.cwd()
    delete_node_modules(base_path)
    print(f"\n{Fore.CYAN}Done!")
    print(f"{Fore.GREEN}✔ Folders deleted: {deleted_count}")
    print(f"{Fore.RED}✗ Errors: {error_count}")
