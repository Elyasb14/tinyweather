import subprocess

if __name__ == "__main__":

    print("\x1b[32mBeginning the bootstrapping of tinyweather-node\x1b[0m")
    subprocess.run(["zig", "build"])
    print("\x1b[32mBuilt tinyweather-node, executable in ./zig-out/bin/tinyweather-node\x1b[0m")
