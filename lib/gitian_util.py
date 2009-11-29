import sys
import yaml
import os
import shutil
import fnmatch
from optparse import SUPPRESS_HELP

def prepare_build_package(control, ptr):
    if not os.access("build", os.F_OK):
        res = os.system("git clone --no-checkout '%s' build" % (ptr['url']))
        if res != 0:
            print >> sys.stderr, "git clone failed"
            sys.exit(1)

        res = os.system("cd build && git reset --hard '%s'" % (ptr['commit']))
        if res != 0:
            print >> sys.stderr, "git reset failed"
            sys.exit(1)

    res = os.system("cd build && git clean -d -f -x")
    if res != 0:
        print >> sys.stderr, "git clean failed"
        sys.exit(1)

def open_package(name):
    repos = repository_root()

    package_dir = os.path.join(repos, "packages", name)

    control_f = open(os.path.join(package_dir, "control"))

    if control_f is None:
        print >> sys.stderr, "could not open control file"
        sys.exit(1)

    control = yaml.load(control_f)
    control_f.close()

    name = control['name']
    ptr_f = open(os.path.join(package_dir, name + '.vcptr'))

    if ptr_f is None:
        print >> sys.stderr, "could not open version control pointer file"
        sys.exit(1)

    ptr = yaml.load(ptr_f)
    ptr_f.close()

    return (package_dir, control, ptr)

    
def repository_root():
    dir = os.getcwd()
    parent = os.path.dirname(dir)
    while (parent != dir):
        if os.access(os.path.join(dir, "gitian-repos"), os.F_OK):
            return dir

        dir = parent
        parent = os.path.dirname(dir)

    print >> sys.stderr, "must be run within the gitian repository"
    exit(1)

def shell_complete(option, opt, value, parser):
    for option in parser.option_list:
        for flag in str(option).split('/'):
            if option.help != SUPPRESS_HELP:
                print "(-)%s[%s]"%(flag, option.help)
    exit(0)

def optparser_extend(parser):
    parser.add_option ("", "--shell-complete", action="callback",
                       callback=shell_complete,
                       help=SUPPRESS_HELP
                      )

def find_command(command):
    command = "gitian-" + command
    progdir = os.path.dirname(sys.argv[0])
    found_dir = None
    for dir in [os.path.join(progdir, "../lib"), "/usr/lib/gitian"]:
        if os.access(os.path.join(dir, command), os.F_OK):
            found_dir = dir
            break
    if found_dir is None:
        print>>sys.stderr, "installation problem - could not find subcommand %s"%(command)
        exit(1)
    return os.path.join(found_dir, command)

def build_gem(package_dir, control, ptr, destination):
    name = control['name']

    os.chdir(package_dir)

    prepare_build_package(control, ptr)

    packager_options = control.get('packager_options', {}) or {}

    rake_cmd = packager_options.get('rake_cmd', 'rake -rlocal_rubygems gem')
    packages = control.get('packages')

    if packages:
        for package in packages:
            print "Building package %s" % (package)
            # default to package name
            dir = control['directories'].get(package, package)
            res = os.system("cd build/%s && %s" % (dir, rake_cmd))
            if res != 0:
                print >> sys.stderr, "build in build/%s failed" % (dir)
                sys.exit(1)
    else:
        print "Building gem %s" % (name)
        res = os.system("cd build && %s" % (rake_cmd))
        if res != 0:
            print >> sys.stderr, "build failed"
            sys.exit(1)

def copy_gems_to_dist(destination):
    for dirpath, dirs, files in os.walk('build'):
        for file in fnmatch.filter(files, '*.gem'):
            if not os.access(destination, os.F_OK):
                os.makedirs(destination)
            shutil.copy(os.path.join(dirpath, file), destination)

