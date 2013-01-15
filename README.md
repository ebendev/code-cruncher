CodeCruncher
============

An HTML, CSS, and JavaScript minifier I wrote in Perl in 2007.

Warning
-------
This project is here for personal historical purposes only and not intended for use by anyone.

Command Line Options
--------------------
    -ws            # crunch whitespace
    --ws-only      # crunch only whitespace
    --no-warnings  # crunch without asking for user approval
    --append-log   # append to the log file, instead of replacing it
    -root:path     # specify path to index.html or equivalent starting point (only one root may be given)
    -output:path   # specify path to the output root (only one output root may be given)
    -update:path   # specify path (relative to root) to any unconnected, but dependent modules, like tests, that 
                   #   need to have the updated names
    -avoid:name    # specify the name of a function, variable, or ID that should not be crunched
    -log:path      # specify the path to the log file (default is log.html in current working directory)
    -profile:path  # specify the path to a config file which holds the command line options desired (any given 
                   #   command line options will override those found in the profile - not yet implemented
