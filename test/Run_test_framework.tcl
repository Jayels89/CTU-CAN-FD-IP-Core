################################################################################
## 
## CAN with Flexible Data-Rate IP Core 
## 
## Copyright (C) 2017 Ondrej Ille <ondrej.ille@gmail.com>
## 
## Project advisor: Jiri Novak <jnovak@fel.cvut.cz>
## Department of Measurement         (http://meas.fel.cvut.cz/)
## Faculty of Electrical Engineering (http://www.fel.cvut.cz)
## Czech Technical University        (http://www.cvut.cz/)
## 
## Permission is hereby granted, free of charge, to any person obtaining a copy 
## of this VHDL component and associated documentation files (the "Component"), 
## to deal in the Component without restriction, including without limitation 
## the rights to use, copy, modify, merge, publish, distribute, sublicense, 
## and/or sell copies of the Component, and to permit persons to whom the 
## Component is furnished to do so, subject to the following conditions:
## 
## The above copyright notice and this permission notice shall be included in 
## all copies or substantial portions of the Component.
## 
## THE COMPONENT IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
## FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
## AUTHORS OR COPYRIGHTHOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
## LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
## FROM, OUT OF OR IN CONNECTION WITH THE COMPONENT OR THE USE OR OTHER DEALINGS 
## IN THE COMPONENT.
## 
## The CAN protocol is developed by Robert Bosch GmbH and protected by patents. 
## Anybody who wants to implement this IP core on silicon has to obtain a CAN 
## protocol license from Bosch.
## 
################################################################################

################################################################################
## Description:
## 			CAN FD IP Core testbench TCL framework for automatic 
##			test execution
##
################################################################################

puts "----------------------------------"
puts "--Starting CANTest TCL framework--"
puts "----------------------------------"

#Check if environment variables are existing
quietly set exist_var [info exist ITERATIONS]

# IP Core standalone relative location
quietly set BASE_DIR "../"
quietly set BASE_TEST "../test"

# Test platform relative location
#quietly set BASE_DIR "../../../CAN_FD_IP_Core/"
#quietly set BASE_TEST "../../../CAN_FD_IP_Core/test"

# Create the environment if not yet existant
if { $exist_var == 0 } {
	puts "Enviroment variables not found -> Setting up environment"
	puts ""
	do [file join $BASE_TEST set_env.tcl]
}

#Include the library functions
source [file join $BASE_TEST lib/test_lib.tcl]

puts ""
puts "Welcome in CAN FD IP Core TCL test framework"
puts "use: 'help' command to obtain list of available commands"
puts ""

quietly set FRAMEWORK_QUIT false

# Test parser loop
while { $FRAMEWORK_QUIT == false } {
	set arg1 ""
	set arg2 ""
	set arg3 ""
	set arg4 ""
	set arg5 ""
	scan [gets stdin] "%s %s %s %s %s" arg1 arg2 arg3 arg4 arg5
	
	if { $arg1 == "exit" } {
		quietly set FRAMEWORK_QUIT true
	} elseif { $arg1 == "help" } {
		print_help
	} elseif { $arg1 == "test" } {
		if { $arg2 == "unit" } {
			if { $arg3 == "all" } {
				exec_all_TCL_from_path [file join $BASE_TEST unit ]
			} else {
				exec_TCL_from_path [file join $BASE_TEST unit $arg3]
			}
		} elseif { $arg2 == "sanity" } {
			if { $arg3 == "run" } {	
				run_sanity
			} elseif { $arg3 == "start" } {
				
				quietly set SILENT_SANITY "false"
				if { $arg4 == "silent" } {
					quietly set SILENT_SANITY "true" 
				}
				start_sanity
			} else {
				puts "Unknown command! Type: 'help' to obtain list of commands!"
			}	
		} elseif { $arg2 == "feature" } {
			if { $arg3 == "start" } {	
				start_feature_FIFO
			} elseif { $arg3 == "run" } {
				run_feature_FIFO
			} elseif { $arg3 == "print_config" } {
				show_feature_FIFO
			} else {
				puts "Unknown command! Type: 'help' to obtain list of commands!"
			}
		} else {
			puts "Unknown command! Type: 'help' to obtain list of commands!"
		}
	} else {
	  puts "Unknown command! Type: 'help' to obtain list of commands!"
	}
}
