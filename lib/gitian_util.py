import sys
import os
from optparse import SUPPRESS_HELP

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

