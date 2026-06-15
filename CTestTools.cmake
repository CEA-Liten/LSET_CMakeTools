include(CMakeTools)

# =========================================================
#
# add tests
#  Usages:
#    add_tests(<SOURCE_DIR_TESTS>)
#    add_tests(<SOURCE_DIR_TESTS> DEPS <dep1;dep2 ...>)		add extra deps
#	 add_tests(<SOURCE_DIR_TESTS> DATA <DATA_DIR_TESTS>)	
# Full signature:
#	 add_tests(<SOURCE_DIR_TESTS> 
#			[QTESTS]			
#			[DATA <DATA_DIR_TESTS>]
#			[RESULTS <RESULTS_DIR_TESTS>]
#			[DEPS <dep1;dep2 ...>]
#			[EXTRA_DIR_SRC <dir1;dir2; ...>]
#			[EXTRA_RESOURCES <rc1; rc2; ...>]
#			[EXCLUDE_TESTS <tests1;tests2 ...>]
#	 )	
# =========================================================
function(add_tests SOURCE_DIR)
	set(options QTESTS)
	set(oneValueArgs DATA RESULTS)
	set(multiValueArgs DEPS EXTRA_DIR_SRC EXCLUDE_TESTS EXTRA_RESOURCES)
	cmake_parse_arguments(TEST "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

	set(TEST_NAME TEST_${COMPONENT})
	# prepare header file	
	if (EXISTS "${SOURCE_DIR}/${TEST_NAME}.in")
		configure_file(${SOURCE_DIR}/${TEST_NAME}.in ${SOURCE_DIR}/${TEST_NAME}.h @ONLY)
	endif()

	# --> Scan source directories and return a list of files
	# to be compiled.
	get_sources(${TEST_NAME}_EXTRA DIRS ${TEST_EXTRA_DIR_SRC})

	message("exclude tests: ${TEST_EXCLUDE_TESTS}")
	get_sources(${TEST_NAME} DIRS ${SOURCE_DIR} EXCLUDE ${TEST_EXCLUDE_TESTS})
	message("tests: ${${TEST_NAME}_SRCS}")
	
	# one file = one test
	foreach(src IN LISTS ${TEST_NAME}_SRCS)		
		get_filename_component(_unitTest ${src} NAME_WE)	
		if (${TEST_QTESTS})
			add_qtestUnit(${TEST_NAME}_${_unitTest} ${SOURCE_DIR} ${src} DEPS ${TEST_DEPS} EXTRA_SRCS ${${TEST_NAME}_EXTRA_SRCS} EXTRA_RESOURCES ${TEST_EXTRA_RESOURCES})
		else()
			add_testUnit(${TEST_NAME}_${_unitTest} ${SOURCE_DIR} ${src} DEPS ${TEST_DEPS} EXTRA_SRCS ${${TEST_NAME}_EXTRA_SRCS} EXTRA_DIR_SRC ${TEST_EXTRA_DIR_SRC})
		endif()
	endforeach()

endfunction()

function(add_testUnit TESTUNIT_NAME TESTUNIT_DIR TEST_SRC)
	set(multiValueArgs DEPS EXTRA_SRCS EXTRA_DIR_SRC ARGS)
	cmake_parse_arguments(TEST "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )
		
	if (NOT DEFINED TEST_EXTRA_SRCS)		
		get_sources(TEST_EXTRA DIRS ${TEST_EXTRA_DIR_SRC})		
	endif()
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
		$<BUILD_INTERFACE:${TESTUNIT_DIR}>)
	
	target_include_directories(${TESTUNIT_NAME} PRIVATE
		$<BUILD_INTERFACE:${TEST_EXTRA_DIR_SRC}>)
	if(MSVC)
		# problem with msvc, see  https://stackoverflow.com/questions/78598141/first-stdmutexlock-crashes-in-application-built-with-latest-visual-studio
		target_compile_definitions(${TESTUNIT_NAME} PRIVATE -D_DISABLE_CONSTEXPR_MUTEX_CONSTRUCTOR)
	endif()
	if (WITH_PRIVATEMODELS)
		target_compile_definitions(${TESTUNIT_NAME} PRIVATE -DPRIVATE_MODELS)
	endif()
	if (USE_CPLEX)
		target_compile_definitions(${TESTUNIT_NAME} PRIVATE -DUSE_CPLEX)
	endif()
	# coverage
	if(TEST_WITH_COVERAGE)
		if(CMAKE_COMPILER_IS_GNUCXX)
			include(CodeCoverage)
			append_coverage_compiler_flags_to_target(${TESTUNIT_NAME})
			#target_compile_options(${TESTUNIT_NAME} PRIVATE --coverage)
			#target_link_options(${TESTUNIT_NAME} PRIVATE --coverage)
			set(${TESTUNIT_NAME}_WITHCOVERAGE 1)			
		endif()
	endif()

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
	add_test(NAME ${TESTUNIT_NAME} COMMAND ${command} ${TEST_ARGS} WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
	set_property(TEST "${TESTUNIT_NAME}" PROPERTY LABELS TESTLABEL ${COMPONENT})

	if (${TESTUNIT_NAME}_WITHCOVERAGE)
		message("add test ${TESTUNIT_NAME} with tests coverage in ${CMAKE_CURRENT_BINARY_DIR}")
	else()
		message("add test ${TESTUNIT_NAME} in ${CMAKE_CURRENT_BINARY_DIR}")
	endif()

endfunction()

function(add_qtestUnit TESTUNIT_NAME TESTUNIT_DIR TEST_SRC)
	set(multiValueArgs DEPS EXTRA_SRCS EXTRA_RESOURCES)
	cmake_parse_arguments(TEST "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )
	
	message("${COMPONENT}_RESOURCES: ${TEST_EXTRA_RESOURCES}")
	add_executable(${TESTUNIT_NAME} ${TEST_SRC} ${TEST_EXTRA_SRCS} ${TEST_EXTRA_RESOURCES})
		
	# -- link with current component and its dependencies --
	# --> add include and links
	#target_link_libraries(${TESTUNIT_NAME} PRIVATE ${COMPONENT})
	foreach(dir IN LISTS ${COMPONENT}_DIRS)
		target_include_directories(${TESTUNIT_NAME} PRIVATE
		$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/${dir}>)
	endforeach()	

	# add include 'utils'	
	target_include_directories(${TESTUNIT_NAME} PRIVATE
		$<BUILD_INTERFACE:${TESTUNIT_DIR}>)
	
	target_include_directories(${TESTUNIT_NAME} PRIVATE
		$<BUILD_INTERFACE:${TEST_EXTRA_DIR_SRC}>)
	if(MSVC)
		# problem with msvc, see  https://stackoverflow.com/questions/78598141/first-stdmutexlock-crashes-in-application-built-with-latest-visual-studio
		target_compile_definitions(${TESTUNIT_NAME} PRIVATE -D_DISABLE_CONSTEXPR_MUTEX_CONSTRUCTOR)
	endif()

	# link with Qt Test
	set(COMPONENT_SAVE ${COMPONENT})
	set(COMPONENT ${TESTUNIT_NAME})
	find_package(Qt REQUIRED COMPONENTS Core Quick Gui Xml Widgets Location Positioning AxContainer Concurrent Test)		
	set(COMPONENT ${COMPONENT_SAVE})

	# Link with extra deps
	foreach(libtarget IN LISTS TEST_DEPS)		
		message("libtarget: ${libtarget}")
		target_link_libraries(${TESTUNIT_NAME} PRIVATE "${libtarget}")		
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


function(create_genericTest GENERICTEST_NAME TESTUNIT_DIR TEST_SRC)
	set(multiValueArgs DEPS EXTRA_SRCS EXTRA_DIR_SRC)
	cmake_parse_arguments(TEST "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )
		
	if (NOT DEFINED TEST_EXTRA_SRCS)		
		get_sources(TEST_EXTRA DIRS ${TEST_EXTRA_DIR_SRC})		
	endif()
	add_executable(${GENERICTEST_NAME} ${TEST_SRC} ${TEST_EXTRA_SRCS})
	# -- link with current component and its dependencies --
	# --> add include and links
	target_link_libraries(${GENERICTEST_NAME} PRIVATE ${COMPONENT})
	foreach(dir IN LISTS ${COMPONENT}_DIRS)
		target_include_directories(${GENERICTEST_NAME} PRIVATE
		$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/${dir}>)
	endforeach()	

	# add include 'utils'	
	target_include_directories(${GENERICTEST_NAME} PRIVATE
		$<BUILD_INTERFACE:${TESTUNIT_DIR}>)
	
	target_include_directories(${GENERICTEST_NAME} PRIVATE
		$<BUILD_INTERFACE:${TEST_EXTRA_DIR_SRC}>)
	if(MSVC)
		# problem with msvc, see  https://stackoverflow.com/questions/78598141/first-stdmutexlock-crashes-in-application-built-with-latest-visual-studio
		target_compile_definitions(${GENERICTEST_NAME} PRIVATE -D_DISABLE_CONSTEXPR_MUTEX_CONSTRUCTOR)
	endif()
	if (WITH_PRIVATEMODELS)
		target_compile_definitions(${GENERICTEST_NAME} PRIVATE -DPRIVATE_MODELS)
	endif()
	if (USE_CPLEX)
		target_compile_definitions(${GENERICTEST_NAME} PRIVATE -DUSE_CPLEX)
	endif()
	# coverage
	if(TEST_WITH_COVERAGE)
		if(CMAKE_COMPILER_IS_GNUCXX)
			include(CodeCoverage)
			append_coverage_compiler_flags_to_target(${GENERICTEST_NAME})					
		endif()
	endif()

	# Link with extra deps
	foreach(libtarget IN LISTS TEST_DEPS)				
		target_link_libraries(${GENERICTEST_NAME} PRIVATE "${libtarget}")		
	endforeach()
endfunction()


function(add_genericTestCase GENERICTEST_NAME TESTUNIT_NAME TESTUNIT_ARG)

	# -- set test command --
	set(command ${GENERICTEST_NAME})
	if(CMAKE_SYSTEM_NAME MATCHES Windows)
		set(command ${command}.exe)
	endif()
	# Add the test in the pipeline
	add_test(NAME ${TESTUNIT_NAME} COMMAND ${command} ${TESTUNIT_ARG} WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
	set_property(TEST "${TESTUNIT_NAME}" PROPERTY LABELS TESTLABEL ${COMPONENT})
	
	set_tests_properties(
		${TESTUNIT_NAME}
		PROPERTIES
		ENVIRONMENT_MODIFICATION "PATH=path_list_append:$<TARGET_FILE_DIR:${COMPONENT}>"
	)
	message("add test ${TESTUNIT_NAME}, ${TESTUNIT_ARG}")
	

endfunction()


function(add_genericTestSuite TESTSUITE_DIR TESTSUITE_NAME)
	# get json files
	collect_files(VAR _TEST_PROJECT_FILE DIRS ${TESTSUITE_DIR} EXTS "json")
	list(LENGTH _TEST_PROJECT_FILE _FILES_LEN)		
	# loop on json files
	foreach(_file_loc ${_TEST_PROJECT_FILE})
		get_filename_component(_file ${_file_loc} NAME_WE)
		set(TEST_NAME TESTNR_${COMPONENT}_${TESTSUITE_NAME})
		if (_FILES_LEN GREATER 1)
			set(TEST_NAME TESTNR_${COMPONENT}_${TESTSUITE_NAME}_${_file})
		endif()						
		add_genericTestCase(GenericTests ${TEST_NAME}
			--case:${TESTSUITE_DIR}/${_file}.json
		)
	endforeach()

	# loop on subdirectories	
	get_subdirectories(TESTCASE_DIRS ${TESTSUITE_DIR})	
	foreach(_tnr ${TESTCASE_DIRS})
		# directory must start with <func_>
		string(FIND ${_tnr} "func_" out)
		if("${out}" EQUAL 0)			
			add_genericTestSuite(${TESTSUITE_DIR}/${_tnr} ${TESTSUITE_NAME}_${_tnr})
		endif()		
	endforeach()

endfunction()

function(add_genericTests TESTS_SUBDIR)
	get_subdirectories(TEST_DIRS ${CAIRNTESTS_HOME}/${TESTS_SUBDIR})	
	# loop on subdirectories
	foreach(_tnr ${TEST_DIRS})
		add_genericTestSuite(${CAIRNTESTS_HOME}/${TESTS_SUBDIR}/${_tnr} ${_tnr})
	endforeach()
endfunction()