import os
from tabulate import tabulate
from pathlib import Path

def count_lines(file_path):
    """Return the number of lines in a file."""
    try:
        with open(file_path, 'r') as file:
            return sum(1 for line in file)
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
        return 0

def count_tokens(file_path):
    """Return the number of tokens (words) in a file."""
    try:
        with open(file_path, 'r') as file:
            return sum(len(line.split()) for line in file)
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
        return 0

def walk_directory(directory):
    """Yield file paths and subdirectories."""
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(".zig"):
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
            file_line_counts.append((str(path.relative_to(directory_path)), lines, tokens / lines if lines > 0 else 0))
            total_lines += lines
            dir_path = str(path.parent.relative_to(directory_path))
            if dir_path not in dir_line_counts:
                dir_line_counts[dir_path] = 0
            dir_line_counts[dir_path] += lines
    
    print(tabulate(file_line_counts, headers=["Name", "Lines", "Tokens/Line"], tablefmt="grid"))
    
    print("\nDirectory Line Counts:")
    for dir, lines in dir_line_counts.items():
        print(f"{dir}: {lines}")
    
    print(f"\nTotal line count: {total_lines}")

if __name__ == "__main__":
    directory = "src"
    print_file_line_counts(directory)
