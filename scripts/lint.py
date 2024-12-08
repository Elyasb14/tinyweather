import os
import sys
import subprocess

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Error: Please provide a command-line argument.")
        sys.exit(1)
    
    first_arg = sys.argv[1]
    valgrind_command = f"valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes --track-fds=yes {first_arg}"
    
    try:
        result = subprocess.run(valgrind_command, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        print("STDOUT:")
        print(result.stdout)
        print("\nSTDERR:")
        print(result.stderr)
    except subprocess.CalledProcessError as e:
        print(f"Command failed with return code {e.returncode}")
        print("\nSTDOUT:")
        print(e.stdout)
        print("\nSTDERR:")
        print(e.stderr)
