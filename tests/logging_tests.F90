!
!  logging_tests.pf
!  This file is part of flogging.
!  
!  Copyright 2016 Chris MacMackin <cmacmackin@gmail.com>
!  
!  This program is free software; you can redistribute it and/or
!  modify it under the terms of the GNU Lesser General Public License
!  as published by the Free Software Foundation; either version 3 of
!  the License, or (at your option) any later version.
!  
!  This program is distributed in the hope that it will be useful, but
!  WITHOUT ANY WARRANTY; without even the implied warranty of
!  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
!  Lesser General Public License for more details.
!  
!  You should have received a copy of the GNU Lesser General Public
!  License along with this program; if not, write to the Free Software
!  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
!  02110-1301, USA.
!

module logging_tests
  use iso_fortran_env, only: r8 => real64, iostat_end
  use pfunit_mod
  use logger_mod
  implicit none

  !@TestCase
  type, extends(testcase), public :: log_test
    type(logger) :: nonmaster_log, threshold_log
    character(len=18) :: nonmaster_file = 'test_nonmaster.log'
    character(len=18) :: threshold_file = 'test_threshold.log'
    character(len=15) :: master_file = 'test_master.log'
    integer :: threshold = info
  contains
    procedure :: setup
    procedure :: teardown
  end type log_test

contains

  subroutine setup(this)
    class(log_test), intent(inout) :: this
    this%nonmaster_log = logger(this%nonmaster_file, 1000, 0, this%threshold)
    this%threshold_log = logger(this%threshold_file, 1000, 1000, this%threshold)
    call logger_init(this%master_file, 1000, 1000, 0)
  end subroutine setup

  subroutine teardown(this)
    class(log_test), intent(inout) :: this
    if (this%nonmaster_log%is_open()) call this%nonmaster_log%destroy()
    if (master_logger%is_open()) call master_logger%destroy()
    call execute_command_line('rm '//this%nonmaster_file)
    call execute_command_line('rm '//this%threshold_file)
    call execute_command_line('rm '//this%master_file)
  end subroutine teardown

  subroutine test_output(filename, msg_type, src, msg)
    character(len=*), intent(in) :: filename, msg_type, src, msg
    character(len=256) :: line
    integer :: u, flag, is, ie
    open(newunit=u,file=filename,action='read',status='old',iostat=flag)
#line 64 "tests/logging_tests.pf"
  call assertEqual(0,flag,message='Error opening log file "'//filename//'"', &
 & location=SourceLocation( &
 & 'logging_tests.pf', &
 & 64) )
  if (anyExceptions()) return
#line 65 "tests/logging_tests.pf"
    read(u,'(256a)',iostat=flag) line
    close(u)
#line 67 "tests/logging_tests.pf"
  call assertEqual(0,flag,message='Error reading log file "'//filename//'"', &
 & location=SourceLocation( &
 & 'logging_tests.pf', &
 & 67) )
  if (anyExceptions()) return
#line 68 "tests/logging_tests.pf"
    is = 24
    ie = 24 + len(src) - 1
#line 70 "tests/logging_tests.pf"
  call assertEqual(src,line(is:ie),message='Incorrect message source printed to file.', &
 & location=SourceLocation( &
 & 'logging_tests.pf', &
 & 70) )
  if (anyExceptions()) return
#line 71 "tests/logging_tests.pf"
    is = ie + 4
    ie = is + len(msg_type) - 1
#line 73 "tests/logging_tests.pf"
  call assertEqual(msg_type,line(is:ie),message='Incorrect message type printed to file.', &
 & location=SourceLocation( &
 & 'logging_tests.pf', &
 & 73) )
  if (anyExceptions()) return
#line 74 "tests/logging_tests.pf"
    is = ie + 3
    ie = is + len(msg)
#line 76 "tests/logging_tests.pf"
  call assertEqual(msg,line(is:ie),message='Incorrect '//msg_type//' message printed to file.', &
 & location=SourceLocation( &
 & 'logging_tests.pf', &
 & 76) )
  if (anyExceptions()) return
#line 77 "tests/logging_tests.pf"
  end subroutine test_output

  subroutine test_threshold(priority, threshold, filename, msg_type, src, msg)
    integer :: priority, threshold
    character(len=*), intent(in) :: filename, msg_type, src, msg
    character(len=256) :: line
    integer :: u, flag, is, ie
    if (priority >= threshold) then
      call test_output(filename, msg_type, src, msg)
    else
      open(newunit=u,file=filename,action='read',status='old',iostat=flag)
#line 88 "tests/logging_tests.pf"
  call assertEqual(0,flag,message='Error opening log file "'//filename//'"', &
 & location=SourceLocation( &
 & 'logging_tests.pf', &
 & 88) )
  if (anyExceptions()) return
#line 89 "tests/logging_tests.pf"
      read(u,'(256a)',iostat=flag) line
#line 90 "tests/logging_tests.pf"
  call assertEqual(iostat_end,flag,message=msg_type//' message printed to log when below threshold priority.', &
 & location=SourceLocation( &
 & 'logging_tests.pf', &
 & 90) )
  if (anyExceptions()) return
#line 91 "tests/logging_tests.pf"
    end if
  end subroutine test_threshold

  !@Test
  subroutine test_debug(this)
    class(log_test), intent(inout) :: this
    character(len=10), parameter :: src = 'test_debug'
    character(len=23), parameter :: msg = 'This is a debug message'
    call master_logger%debug(src, msg)
    call master_logger%destroy()
    call test_output(this%master_file,'debug',src,msg)
    call this%threshold_log%debug(src, msg)
    call this%threshold_log%destroy()
    call test_threshold(debug,this%threshold,this%threshold_file,'debug',src,msg)
  end subroutine test_debug

  !@Test
  subroutine test_trivia(this)
    class(log_test), intent(inout) :: this
    character(len=11), parameter :: src = 'test_trivia'
    character(len=24), parameter :: msg = 'This is a trivia message'
    call master_logger%trivia(src, msg)
    call master_logger%destroy()
    call test_output(this%master_file,'trivia',src,msg)
    call this%threshold_log%trivia(src, msg)
    call this%threshold_log%destroy()
    call test_threshold(trivia,this%threshold,this%threshold_file,'trivia',src,msg)
  end subroutine test_trivia

  !@Test
  subroutine test_info(this)
    class(log_test), intent(inout) :: this
    character(len=10), parameter :: src = 'test_info'
    character(len=23), parameter :: msg = 'This is an info message'
    call master_logger%info(src, msg)
    call master_logger%destroy()
    call test_output(this%master_file,'info',src,msg)
    call this%threshold_log%info(src, msg)
    call this%threshold_log%destroy()
    call test_threshold(info,this%threshold,this%threshold_file,'info',src,msg)
  end subroutine test_info
  
  !@Test
  subroutine test_warning(this)
    class(log_test), intent(inout) :: this
    character(len=12), parameter :: src = 'test_warning'
    character(len=25), parameter :: msg = 'This is a warning message'
    call master_logger%warning(src, msg)
    call master_logger%destroy()
    call test_output(this%master_file,'warning',src,msg)
    call this%threshold_log%warning(src, msg)
    call this%threshold_log%destroy()
    call test_threshold(warning,this%threshold,this%threshold_file,'warning',src,msg)
  end subroutine test_warning
  
  !@Test
  subroutine test_error(this)
    class(log_test), intent(inout) :: this
    character(len=10), parameter :: src = 'test_error'
    character(len=24), parameter :: msg = 'This is an error message'
    call master_logger%error(src, msg)
    call master_logger%destroy()
    call test_output(this%master_file,'error',src,msg)
    call this%threshold_log%error(src, msg)
    call this%threshold_log%destroy()
    call test_threshold(error,this%threshold,this%threshold_file,'error',src,msg)
  end subroutine test_error
  
  !@Test
  subroutine test_fatal(this)
    class(log_test), intent(inout) :: this
    character(len=10), parameter :: src = 'test_fatal'
    character(len=23), parameter :: msg = 'This is a fatal message'
    call master_logger%fatal(src, msg)
    call master_logger%destroy()
    call test_output(this%master_file,'fatal',src,msg)
    call this%threshold_log%fatal(src, msg)
    call this%threshold_log%destroy()
    call test_threshold(fatal,this%threshold,this%threshold_file,'fatal',src,msg)
  end subroutine test_fatal
  
  !@Test
  subroutine test_destroy(this)
    class(log_test), intent(inout) :: this
#line 175 "tests/logging_tests.pf"
  call assertTrue(this%nonmaster_log%is_open(),message='Open file claiming to be closed.', &
 & location=SourceLocation( &
 & 'logging_tests.pf', &
 & 175) )
  if (anyExceptions()) return
#line 176 "tests/logging_tests.pf"
    call this%nonmaster_log%destroy()
#line 177 "tests/logging_tests.pf"
  call assertFalse(this%nonmaster_log%is_open(),message='Closed file claiming to be open.', &
 & location=SourceLocation( &
 & 'logging_tests.pf', &
 & 177) )
  if (anyExceptions()) return
#line 178 "tests/logging_tests.pf"
  end subroutine test_destroy

  !@Test
  subroutine test_master(this)
    class(log_test), intent(inout) :: this
#line 183 "tests/logging_tests.pf"
  call assertTrue(master_logger%is_open(),message='Master logger not open', &
 & location=SourceLocation( &
 & 'logging_tests.pf', &
 & 183) )
  if (anyExceptions()) return
#line 184 "tests/logging_tests.pf"
  end subroutine test_master
  
  !@Test
  subroutine test_colours(this)
    class(log_test), intent(inout) :: this
    character :: answer
    write(*,*)
    write(*,*) 'The portion of the following messages surrounded by "<" and ">" should'
    write(*,*) 'be bold and have the colour which is named on the right.'
    associate(l => this%nonmaster_log)
      call l%debug('test_colours','This should be cyan')
      call l%trivia('test_colours','This should be blue')
      call l%info('test_colours','This should be green')
      call l%warning('test_colours','This should be yellow')
      call l%error('test_colours','This should be red')
      call l%fatal('test_colours','This should have a red background')
    end associate
    write(*,*) 'Type "y" if this is the case.'
    read(*,*) answer
    if (answer == 'Y') answer = 'y'
#line 204 "tests/logging_tests.pf"
  call assertEqual('y',answer,message='Incorrect colours used for messages.', &
 & location=SourceLocation( &
 & 'logging_tests.pf', &
 & 204) )
  if (anyExceptions()) return
#line 205 "tests/logging_tests.pf"
  end subroutine test_colours
  
end module logging_tests

module Wraplogging_tests
   use pFUnit_mod
   use logging_tests
   implicit none
   private

   public :: WrapUserTestCase
   public :: makeCustomTest
   type, extends(log_test) :: WrapUserTestCase
      procedure(userTestMethod), nopass, pointer :: testMethodPtr
   contains
      procedure :: runMethod
   end type WrapUserTestCase

   abstract interface
     subroutine userTestMethod(this)
        use logging_tests
        class (log_test), intent(inout) :: this
     end subroutine userTestMethod
   end interface

contains

   subroutine runMethod(this)
      class (WrapUserTestCase), intent(inout) :: this

      call this%testMethodPtr(this)
   end subroutine runMethod

   function makeCustomTest(methodName, testMethod) result(aTest)
#ifdef INTEL_13
      use pfunit_mod, only: testCase
#endif
      type (WrapUserTestCase) :: aTest
#ifdef INTEL_13
      target :: aTest
      class (WrapUserTestCase), pointer :: p
#endif
      character(len=*), intent(in) :: methodName
      procedure(userTestMethod) :: testMethod
      aTest%testMethodPtr => testMethod
#ifdef INTEL_13
      p => aTest
      call p%setName(methodName)
#else
      call aTest%setName(methodName)
#endif
   end function makeCustomTest

end module Wraplogging_tests

function logging_tests_suite() result(suite)
   use pFUnit_mod
   use logging_tests
   use Wraplogging_tests
   type (TestSuite) :: suite

   suite = newTestSuite('logging_tests_suite')

   call suite%addTest(makeCustomTest('test_debug', test_debug))

   call suite%addTest(makeCustomTest('test_trivia', test_trivia))

   call suite%addTest(makeCustomTest('test_info', test_info))

   call suite%addTest(makeCustomTest('test_warning', test_warning))

   call suite%addTest(makeCustomTest('test_error', test_error))

   call suite%addTest(makeCustomTest('test_fatal', test_fatal))

   call suite%addTest(makeCustomTest('test_destroy', test_destroy))

   call suite%addTest(makeCustomTest('test_master', test_master))

   call suite%addTest(makeCustomTest('test_colours', test_colours))


end function logging_tests_suite

