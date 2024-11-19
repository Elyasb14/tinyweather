import os
from tabulate import tabulate
from pathlib import Path
import re

def count_lines(file_path):
    """Return the number of non-comment, non-empty lines in a file."""
    try:
        with open(file_path, 'r') as file:
            lines = file.readlines()
            
        # Remove empty lines and whitespace-only lines
        lines = [line.strip() for line in lines]
        lines = [line for line in lines if line]
        
        # Handle different comment styles based on file extension
        extension = file_path.suffix.lower()
        if extension in ['.c', '.h', '.zig']:
            # Remove // style comments
            lines = [line for line in lines if not line.lstrip().startswith('//')]
            
            # Handle /* ... */ style comments for C files
            if extension in ['.c', '.h']:
                in_multiline_comment = False
                filtered_lines = []
                for line in lines:
                    if '/*' in line and '*/' in line:
                        # Handle single-line /* ... */ comment
                        line = re.sub(r'/\*.*?\*/', '', line)
                        if line.strip():
                            filtered_lines.append(line)
                        continue
                        
                    if '/*' in line:
                        in_multiline_comment = True
                        line = line[:line.index('/*')].strip()
                        if line:
                            filtered_lines.append(line)
                        continue
                        
                    if '*/' in line:
                        in_multiline_comment = False
                        line = line[line.index('*/') + 2:].strip()
                        if line:
                            filtered_lines.append(line)
                        continue
                        
                    if not in_multiline_comment and line.strip():
                        filtered_lines.append(line)
                lines = filtered_lines
                
            
        return len(lines)
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
        return 0

def count_tokens(file_path):
    """Return the number of tokens (words) in non-comment lines."""
    try:
        count = 0
        with open(file_path, 'r') as file:
            lines = file.readlines()
            
        # Remove comments using the same logic as count_lines
        extension = file_path.suffix.lower()
        if extension in ['.c', '.h', '.zig']:
            lines = [line for line in lines if not line.lstrip().startswith('//')]
            
        for line in lines:
            # Remove inline comments
            if '//' in line:
                line = line[:line.index('//')]
            elif '#' in line:
                line = line[:line.index('#')]
            count += len(line.split())
        return count
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
        return 0

def walk_directory(directory):
    """Yield file paths and subdirectories."""
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith((".zig", ".c", ".h")):
                yield os.path.join(root, file)
        for dir in dirs:
            yield os.path.join(root, dir)

def print_file_line_counts(directory):
    """Print line count and token count of each file in the directory and subdirectories."""
    directory_path = Path(directory)
    file_line_counts = []
    total_lines = 0
    dir_line_counts = {}
    
    for path in walk_directory(directory):
        path = Path(path)
        if path.is_file():
            lines = count_lines(path)
            tokens = count_tokens(path)
            file_line_counts.append((
                str(path.relative_to(directory_path)),
                lines,
                round(tokens / lines, 2) if lines > 0 else 0
            ))
            total_lines += lines
            dir_path = str(path.parent.relative_to(directory_path))
            dir_line_counts[dir_path] = dir_line_counts.get(dir_path, 0) + lines
    
    print(tabulate(file_line_counts, headers=["Name", "Lines", "Tokens/Line"], tablefmt="grid"))
    
    print("\nDirectory Line Counts:")
    for dir, lines in sorted(dir_line_counts.items()):
        print(f"{dir}: {lines}")
    
    print(f"\nTotal line count: {total_lines}")

if __name__ == "__main__":
    directory = "src"
    print_file_line_counts(directory)
