include(CMakeTools)

# =========================================================
#
# add tests
#  Usages:
#    add_tests(<SOURCE_DIR_TESTS>)
#    add_tests(<SOURCE_DIR_TESTS> DEPS <dep1;dep2 ...>)		add extra deps
#	 add_tests(<SOURCE_DIR_TESTS> DATA <DATA_DIR_TESTS>)	
# =========================================================
function(add_tests SOURCE_DIR)

	set(oneValueArgs DATA RESULTS)
	set(multiValueArgs DEPS EXTRA_DIR_SRC EXCLUDE_TESTS)
	cmake_parse_arguments(TEST "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

	set(TEST_NAME TEST_${COMPONENT})
	# prepare header file	
	if (EXISTS "${SOURCE_DIR}/${TEST_NAME}.in")
		configure_file(${SOURCE_DIR}/${TEST_NAME}.in ${SOURCE_DIR}/${TEST_NAME}.h @ONLY)
	endif()

	# --> Scan source directories and return a list of files
	# to be compiled.
	get_sources(${TEST_NAME}_EXTRA DIRS ${TEST_EXTRA_DIR_SRC})

	message("no test: ${TEST_EXCLUDE_TESTS}")
	get_sources(${TEST_NAME} DIRS ${SOURCE_DIR} EXCLUDE ${TEST_EXCLUDE_TESTS})
	message("tests: ${${TEST_NAME}_SRCS}")
	
	# one file = one test
	foreach(src IN LISTS ${TEST_NAME}_SRCS)		
		get_filename_component(_unitTest ${src} NAME_WE)		
		add_testUnit(${TEST_NAME}_${_unitTest} ${src} DEPS ${TEST_DEPS} EXTRA_SRCS ${${TEST_NAME}_EXTRA_SRCS})
	endforeach()

endfunction()

function(add_testUnit TESTUNIT_NAME TEST_SRC)
	set(multiValueArgs DEPS EXTRA_SRCS)
	cmake_parse_arguments(TEST "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )
	
	message("TEST_SRC : ${TEST_SRC}")
	message("EXTRA_DIR_SRC : ${TEST_EXTRA_DIR_SRC}")
	add_executable(${TESTUNIT_NAME} ${TEST_SRC} ${TEST_EXTRA_SRCS})
	# -- link with current component and its dependencies --
	# --> add include and links
	target_link_libraries(${TESTUNIT_NAME} PRIVATE ${COMPONENT})
	foreach(dir IN LISTS ${COMPONENT}_DIRS)
		target_include_directories(${TESTUNIT_NAME} PRIVATE
		$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/${dir}>)
	endforeach()	

	# add include 'utils'	
	target_include_directories(${TESTUNIT_NAME} PRIVATE
		$<BUILD_INTERFACE:${TEST_EXTRA_DIR_SRC}>)
	

	# Link with extra deps
	foreach(libtarget IN LISTS TEST_DEPS)		
		if ("${libtarget}" STREQUAL "Qt5")
			find_package(Qt REQUIRED Core)
			target_link_libraries(${TESTUNIT_NAME} PRIVATE ${QT_${UPPERPACKAGE}_TARGET})
		else()
			target_link_libraries(${TESTUNIT_NAME} PRIVATE "${libtarget}")
		endif()

	endforeach()

	# -- set test command --
	set(command ${TESTUNIT_NAME})
	if(CMAKE_SYSTEM_NAME MATCHES Windows)
		set(command ${command}.exe)
	endif()
	# Add the test in the pipeline
	add_test(NAME ${TESTUNIT_NAME} COMMAND ${command} WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
	set_property(TEST "${TESTUNIT_NAME}" PROPERTY LABELS TESTLABEL ${COMPONENT})
	message("add test ${TESTUNIT_NAME} in  ${CMAKE_CURRENT_BINARY_DIR}")
endfunction()

