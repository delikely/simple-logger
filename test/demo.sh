#! /bin/sh
#
# log4sh example: Hello, world
#

# load log4sh (disabling properties file warning) and clear the default
# configuration
LOG4SH_CONFIGURATION='none' . ./log4sh
log4sh_resetConfiguration

# set the global logging level to INFO
logger_setLevel INFO

# add and configure a FileAppender that outputs to STDERR, and activate the
# configuration
logger_addAppender stderr
appender_setType stderr FileAppender
appender_file_setFile stderr STDERR
appender_activateOptions stderr

# say Hello to the world
logger_info 'Hello, world'
