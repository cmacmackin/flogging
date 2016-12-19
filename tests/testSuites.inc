#ifdef NEVERDEFINEDEVEREVEREVER
! Need this to trick FoBiS.py into realizing that the driver program
! depends on all of the test modules
use logging_tests
#endif
ADD_TEST_SUITE(logging_tests_suite)
