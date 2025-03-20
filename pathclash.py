import os

def pathclash():
    paths = str.split(os.environ['PATH'], os.pathsep)
    unique_paths = set(paths)
    executables_to_paths = {}
    for path in unique_paths:
        print("examining path: ", path)
        if not os.path.isdir(path):
            print("Warning: path", path, "is not a directory")
            continue
        for file in os.listdir(path):
            if os.access(os.path.join(path, file), os.X_OK):
                if file in executables_to_paths:
                    executables_to_paths[file].append(path)
                else:
                    executables_to_paths[file] = [path]

    print("Looking for dupes")
    for executable, present_paths in executables_to_paths.items():
        if len(present_paths) > 1:
            print(executable, "is duplicated:")
            for path in present_paths:
                print("    * in", path)

if __name__ == '__main__':
    pathclash()
