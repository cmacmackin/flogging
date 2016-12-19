# Flogging: Fortran Logging Library
[![GitHub license](https://img.shields.io/badge/license-LGPL_v3-blue.svg)](./LICENSE)
[![GitHub release](https://img.shields.io/github/release/cmacmackin/flogging.svg)](https://github.com/cmacmackin/flogging/releases)
[![Travis](https://img.shields.io/travis/cmacmackin/flogging.svg)](https://travis-ci.org/cmacmackin/flogging)
[![Codecov](https://img.shields.io/codecov/c/github/cmacmackin/flogging.svg)](https://codecov.io/gh/cmacmackin/flogging)

Flogging provides an easy-to-use interface for logging events and
errors in Fortran applications and libraries. Its use and
functionality is similar to that of
[logging](https://docs.python.org/2/library/logging.html) library in
Python. It is meant to be used for providing warnings, error messages,
debug information, or routine output which should be logged. It is not
ideal for all output, such as that used to prompt the user for input.


##Documentation

Flogger provides a module called `logger_mod`, which implements an
object called a `logger`. This contains methods for outputting the
following types of messages:

- **debug:** Information which will only be useful for debugging, such
  as announcing when entering and exiting a procedure
- **trivia:** Information about normal operation which is detailed or
  obscure and thus would not usually be of interest
- **info:** Information about the normal operation of the program
- **warning:** Information produced when something happens which
  results in suboptimal completion of the program
- **error:** Information about something which will result in
  incorrect completion of the program
- **fatal:** Information that an event has occurred which will result
  in immediate termination of the program, without completion

Each type of message is assigned a priority, ranging from 10 (debug)
to 60 (fatal). The priority value for each type of message is
specified in a parameter of the same name. Depending on the priority
of the message, it may be printed to a log file, standard out, and/or
standard error.

While users can instantiate a logger instance and use that, it is
recommended that they use the `master_logger` object provided in the
`logger_mod` module. This way, multiple libraries can make calls to
the same logger and all information will end up in the same log file.

##Usage

Before using the master logger, `logger_init` must be called to set
the logging file and what priority messages will be printed. The
call signature is
```fortran
subroutine logger_init(logfile, stderr_threshold, stdout_threshold, &
	                   logfile_threshold)
```
Arguments are:

- **logfile:** A character string containing the name of the file to
  which output will be written
- **stderr_threshold:** (Optional) An integer which specifies the
  minimum priority a message must have in order to be printed to
  standard error. Defaults to *error*.
- **stdout_threshold:** (Optional) An integer which specifies the
  minimum priority a message must have in order to be printed to
  standard out. Defaults to *info*.
- **logfile_threshold:** (Optional) An integer which specifies the
  minimum priority a message must have in order to be printed to the
  log file. Defaults to *trivia*.

A message is logged by calling the type-bound subroutine with the same
name as the desired message type. These subroutines take the following
arguments:

- **source**: A character string specifying the name of the
  program or procedure in which thee logger is being called.
- **message**: A character string containing the message to be
  printed.

###Example

```fortran
program logging_example
  use logger_mod, only: logger_init, logger => master_logger

  ! Initialise the logger prior to use
  call logger_init()

  ! Write some debugging information
  call logger%debug('logger_example','Starting program logger_example')

  ! Perform some calculation
  ! ...
  call logger%info('logger_example','Found result of calculation')

  ! Perform another calculation
  ! ...
  ! Oh no, an error has occurred
  call logger%error('logger_example','Calculation failed due to error')

  call logger%debug('logger_example','Ending program logger_example')
end program logging_example
```

This produces the following output to the screen.

![Output from the example program above](https://github.com/cmacmackin/flogging/blob/master/sample-output.png)
Note that debug information is not displayed, as its priority falls
below the default threshold for this.

###API

Detailed [API documentation](https://cmacmackin.github.io/flogging) is
available in the Github pages of this repository and can be generated
locally using the [FORD](https://github.com/cmacmackin/ford) tool. 


##Installation

The easiest way to install Flogging is via the
[FLATPack](https://github.com/Fortran-FOSS-Programmers/FLATPack)
repository for the [Spack](https://spack.readthedocs.io/en/latest/)
package manager. It can be installed with the command
```
spack install flogging
```

If compiling manually, you will need to have Stefano Zaghi's
[FACE](https://github.com/szaghi/FACE) library installed. It is
recommended that you compile Flogging using the
[FoBiS.py](https://github.com/szaghi/FoBiS) tool, 
which can be installed from
[PyPI](https://pypi.python.org/pypi/FoBiS.py/). The provided `fobos`
configuration file allows the library to be compiled with the command
```
FoBiS.py build -mode COMPILER-LIBTYPE -dlib FACELOCATION -i FACEMODLOCATION
```
where `COMPILER` is either `gnu` or `intel`, `LIBTYPE` is either
`static` or `shared`, `FACELOCATION` is the path to the directory
containing the compiled FACE library in either static or shared
format, and `FACEMODLOCATION` is the path to the directory containing
the `.mod` file for FACE.

A makefile is provided with this repository, but is not officially
supported. It has been configured for the developer's computer and
will not work elsewhere without modification.


##License

FIAT is licensed under the GNU Lesser General Public License (LGPL) v3.0 or
later. The terms are provided in the file `LICENSE`. The LGPL make reference
to the GNU General Public License (GPL), which is provided in the file `GPL`.
In brief, the LGPL allows this library to be linked to software under any
license (with a few, minor, restrictions). However, should a modified version
of the _library itself_ be released, it must be licensed under the terms of
the LGPL or GPL.
