import os
import sys

def check_input_params(args):
    if (len(args) != 3):
        return False
    return True

def check_package(pkg_name):
    # check if folder exists
    if not os.path.isdir(pkg_name):
        return False
    if not os.path.isfile(os.path.join(pkg_name, "__init__.py")):
        return False
    # check if a setup.py file is present
    if not os.path.isfile("setup.py"):
        return False
    return True

def main():
    args = sys.argv
    if not check_input_params(args):
        print("Invalid call. The correct format is: python3 upload2myPrivatePypi.py <pkg_name> <pypi-repo-index>")
        return
    
    pkg_name = sys.argv[1]
    if not check_package(pkg_name):
        print("Package not present. A folder with the package name containing an __init__.py as well as a setup.py file outside of it need to be present.")
        return

    repository_index = sys.argv[2]            
    os.system('python3 setup.py sdist upload -r %s' % repository_index)


if __name__ == "__main__":
    main()


