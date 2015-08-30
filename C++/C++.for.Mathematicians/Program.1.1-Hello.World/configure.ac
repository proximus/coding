# Initialize GNU Autoconf (AC)
# ACINIT(package_name, version bug_report_address)
AC_INIT([hello-world], [0.1])

# Initialize GNU Automake (AM)
AM_INIT_AUTOMAKE

# Check for C++ compiler
AC_LANG(C++)

# Set the C++ compiler
AC_PROG_CXX

# Check for doxygen
AC_CHECK_PROGS([DOXYGEN], [doxygen])
if test -z "$DOXYGEN";
   then AC_MSG_WARN([Doxygen not found - continuing without Doxygen support])
fi

AM_CONDITIONAL([HAVE_DOXYGEN],
[test -n "$DOXYGEN"])AM_COND_IF([HAVE_DOXYGEN],
[AC_CONFIG_FILES([docs/Doxyfile])])

# Specify where the Makefiles should be produced.
AC_CONFIG_FILES([Makefile src/Makefile])

# Produce configure script
AC_OUTPUT
