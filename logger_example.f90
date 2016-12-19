program logging_example
  use logger_mod, only: logger_init, logger => master_logger

  ! Initialise the logger prior to use
  call logger_init('outputfile.log')

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
  
