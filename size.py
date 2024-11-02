import os
from tabulate import tabulate

def count_lines(file_path):
    """Return the number of lines in a file."""
    try:
        with open(file_path, 'r') as file:
            return sum(1 for line in file)
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
        return 0

def print_file_line_counts(directory):
    """Print line count of each file in the directory."""
    file_line_counts = [(filename, count_lines(os.path.join(directory, filename))) 
                        for filename in os.listdir(directory) if os.path.isfile(os.path.join(directory, filename))]
    
    print(tabulate(file_line_counts, headers=["File", "Lines"], tablefmt="grid"))

if __name__ == "__main__":
    directory = "src"
    print_file_line_counts(directory)
