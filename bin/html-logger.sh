
# this file should 'source'd by the script

HTML_BOLD_PL="html-bold.pl"

# trouble will ensue if the HTML_LOG_FILE is not defined by using script
#HTML_LOG_FILE=""

function log_error () {
    if [ -z "$HTML_LOGGER_FILE" ]; then
	eval $COLOR_RED
	echo $*
	eval $COLOR_NORMAL
    else
	echo $* | html-error.pl >> "$HTML_LOGGER_FILE"
    fi
}

function log_important () {
    if [ -z "$HTML_LOGGER_FILE" ]; then
	eval $COLOR_BOLD
	echo $*
	eval $COLOR_NORMAL
    else
	echo $* | html-bold.pl >> "$HTML_LOGGER_FILE"
    fi
}

function log_sectionhead () {
    if [ -z "$HTML_LOGGER_FILE" ]; then
	eval $COLOR_BOLD
	echo $*
	eval $COLOR_NORMAL
    else
	echo $* | html-h1.pl "color=#00FF55;" >> "$HTML_LOGGER_FILE"
    fi
}

function log_warning () {
    if [ -z "$HTML_LOGGER_FILE" ]; then
	eval $COLOR_YELLOW
	echo $*
	eval $COLOR_NORMAL
    else
	echo $* | html-warning.pl >> "$HTML_LOGGER_FILE"
    fi
}



