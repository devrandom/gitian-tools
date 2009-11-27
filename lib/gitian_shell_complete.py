from optparse import SUPPRESS_HELP

def shell_complete(option, opt, value, parser):
    for option in parser.option_list:
        for flag in str(option).split('/'):
            if option.help != SUPPRESS_HELP:
                print "(-)%s[%s]"%(flag, option.help)
    exit(0)

def apply(parser):
    parser.add_option ("", "--shell-complete", action="callback",
                       callback=shell_complete,
                       help=SUPPRESS_HELP
                      )
