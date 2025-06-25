#
# Some convenience macros
#

function(collect_files)

  set(oneValueArgs VAR) # output variable name
  set(multiValueArgs DIRS EXTS)
  cmake_parse_arguments(collect "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )
  # Scan all dirs and check all exts ...

  foreach(DIR IN LISTS collect_DIRS)
    foreach(_EXT IN LISTS collect_EXTS)
      file(GLOB FILES_LIST
        RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} CONFIGURE_DEPENDS
        ${DIR}/*.${_EXT})
      if(FILES_LIST)
	list(APPEND COLLECTION ${FILES_LIST})
      endif()
    endforeach()
  endforeach()
  if(COLLECTION)
    list(LENGTH COLLECTION _FILES_LEN)
    if (_FILES_LEN GREATER 1)
      list(REMOVE_DUPLICATES COLLECTION)
    endif()
  endif()
  set(${collect_VAR} ${COLLECTION} PARENT_SCOPE)

endfunction()

# Collect source files.
#
# Usage:
#
# get_sources(<COMPONENT> DIRS <dirs list> EXCLUDE <files list>)
#
# Result : set (parent scope) <COMPONENT>_SRCS with files in
# dir1, dir2 matching standard extension for C,C++ and Fortran.
# Do not include files listed after EXCLUDE option.
#
# Remarks:
# - dir1, dir2 ... are relative to CMAKE_CURRENT_SOURCE_DIR
#
function(get_sources COMPONENT)

  set(multiValueArgs DIRS EXCLUDE INCLUDESRCS)
  cmake_parse_arguments(source "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

  # Get list of extensions to be taken into account
  foreach(_EXT
      ${CMAKE_CXX_SOURCE_FILE_EXTENSIONS}
      ${CMAKE_C_SOURCE_FILE_EXTENSIONS}
      ${CMAKE_Fortran_SOURCE_FILE_EXTENSIONS})
    list(APPEND SRC_EXTS ${_EXT})
  endforeach()
  list(REMOVE_DUPLICATES SRC_EXTS)

  collect_files(VAR SOURCES_FILES DIRS ${source_DIRS} EXTS ${SRC_EXTS})

  # Add extra src files  
    foreach(_SRC IN LISTS source_INCLUDESRCS)
        list(APPEND SOURCES_FILES ${_SRC})
        message("-- Include extra source for ${COMPONENT} : ${_SRC}")
    endforeach()
  
  # Check if some sources are to be excluded from build
  foreach(_FILE IN LISTS source_EXCLUDE)
    list(REMOVE_ITEM SOURCES_FILES ${_FILE})
  endforeach()

  set(${COMPONENT}_SRCS ${SOURCES_FILES} PARENT_SCOPE)

endfunction()



# Try to provide some hints for a find_package call.
#
# Usage:
#
# set_find_package_hints(NAME <name> MODULE <mod>)
#
#
# Result : set (parent scope) _<NAME>_SEARCH_OPTS and _<NAME>_INC_SEARCH_OPTS
# that can be used in find_path (INC_SEARCH) and find_library calls.
#
# These variables are filled either with <NAME>_ROOT value if set
# or using pkg-config information, if available.
#
# See examples of use in FindCPPUNIT.cmake or FindSuperLU.cmake.
#
function(set_find_package_hints)
  set(oneValueArgs NAME MODULE)

  cmake_parse_arguments(pkg "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

  if(${pkg_NAME}_ROOT)
    set(_${pkg_NAME}_SEARCH_OPTS
      HINTS ${${pkg_NAME}_ROOT} NO_DEFAULT_PATH PARENT_SCOPE)
    set(_${pkg_NAME}_INC_SEARCH_OPTS
      HINTS ${${pkg_NAME}_ROOT} NO_DEFAULT_PATH PARENT_SCOPE)
  else()
    # Try pkgconfig
    find_package(PkgConfig QUIET)
    pkg_check_modules(PKGC_${pkg_NAME} ${pkg_MODULE} QUIET)
    if(PKGC_${pkg_NAME}_FOUND)
      set(_${pkg_NAME}_INC_SEARCH_OPTS "HINTS ${PKGC_${pkg_NAME}_INCLUDE_DIRS}"
        PARENT_SCOPE)
    endif()
    set(_${pkg_NAME}_SEARCH_OPTS
      HINTS ${PKGC_${pkg_NAME}_LIBRARY_DIRS} ENV LD_LIBRARY_PATH ENV DYLD_LIBRARY_PATH
      PARENT_SCOPE)
  endif()

endfunction()

# ------------------------------------
# Get the list of subdirectories
# of a given dir
# Useful only in examples ...
# ------------------------------------
macro(get_subdirectories result current_dir)
  file(GLOB subdirs RELATIVE ${current_dir} ${current_dir}/*)
  set(dirs "")
  foreach(_dir ${subdirs})
    if(IS_DIRECTORY ${current_dir}/${_dir})
      list(APPEND dirs ${_dir})
    endif()
  endforeach()
  set(${result} ${dirs})
endmacro()


# Apply compiler options onto a given target
#
# Depends on the diagnostics level required.
#
# Usage :
#
#     apply_compiler_options(numerics DIAGNOSTICS_LEVEL ${WARNINGS_LEVEL})
#
# * This function must be called inside create_siconos_component function.
# * WARNINGS_LEVEL is 0 by default and set by user in siconos config file
# (-DUSER_OPTIONS_FILE=configfile.cmake)
# * to be more specific on a given target, use target_compile_... functions
#   Check in externals/CMakeLists.txt for an example.
#
function(apply_compiler_options COMPONENT)
  set(oneValueArgs DIAGNOSTICS_LEVEL)
  cmake_parse_arguments(COMP "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

  unset(COMP_OPTIONS)   # C and C++ options. Append options there by default.

  # -- Compiler options common to all setups --

  # Warn about types with virtual methods where code quality would be improved if the type were declared with the C++11 final specifier, or, if possible, declared in an anonymous namespace.
  #list(APPEND COMP_OPTIONS "-Wsuggest-final-types"). GNU/CXX ONLY. ## NOTE FP : too many warnings, activate this later
  # list(APPEND COMP_OPTIONS
  #   $<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CXX_COMPILER_ID:GNU>>:-Wsuggest-final-types>)
  # Warn about virtual methods where code quality would be improved if the method were declared with the C++11 final specifier, or, if possible, its type were declared in an anonymous namespace or with the final specifier. GNU/CXX ONLY. ## NOTE FP : too many warnings, activate this later
  # list(APPEND COMP_OPTIONS
  #   $<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CXX_COMPILER_ID:GNU>>:-Wsuggest-final-methods>)
  # Warn when a literal ‘0’ is used as null pointer constant.
  #list(APPEND COMP_OPTIONS $<$<COMPILE_LANGUAGE:CXX>:-Wzero-as-null-pointer-constant>)
  if(WITH_SERIALIZATION)
    list(APPEND COMP_OPTIONS -ftemplate-depth=1024)
  endif(WITH_SERIALIZATION)
  # Intel specific
  list(APPEND COMP_OPTIONS $<$<CXX_COMPILER_ID:Intel>:"-diag-disable 654">)
  list(APPEND COMP_OPTIONS $<$<CXX_COMPILER_ID:Intel>:"-D__aligned__=ignored">)
  # LLVM Static analyser ? Where do we ask to set this LLVM_ANALYSE ?
  if(LLVM_ANALYSE)
    target_compile_options(${COMPONENT} PRIVATE "-emit-llvm")
  endif()
  # Clang++ specific
  list(APPEND COMP_OPTIONS
    $<$<OR:$<CXX_COMPILER_ID:Clang>,$<CXX_COMPILER_ID:AppleClang>>:-Wno-string-plus-int>)

  # -- Dev mode options --
  if(COMP_DIAGNOSTICS_LEVEL GREATER 0)
    # -- options working with both C and C++ --
    # and for all compilers.
    # ! tested only with clang and gnu
    # - Activates  all the warnings about constructions
    # details: https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html
    list(APPEND COMP_OPTIONS -Wall)
    # - enables some extra warning flags that are not enabled by -Wall
    list(APPEND COMP_OPTIONS -Wextra)
    ## TMP ?? deactivate warning for unused parameters in C/CXX
    list(APPEND COMP_OPTIONS -Wno-unused-parameter)
    # This option controls warnings when a function is used before being declared.
    list(APPEND COMP_OPTIONS $<$<COMPILE_LANGUAGE:C>:-Werror=implicit-function-declaration>)
    # - Warn when variables are not initialized.
    # Warning: this may lead to many false warnings.
    # See for instance https://gcc.gnu.org/wiki/Better_Uninitialized_Warnings
    # --> activated by Wall
    #  list(APPEND COMP_OPTIONS "-Wuninitialized")
    # warn/error when a switch statement has an index of boolean type and the case values are outside the range of a boolean type
    list(APPEND COMP_OPTIONS -Werror=switch-bool)
    # Warn about logical not used on the left hand side operand of a comparison
    list(APPEND COMP_OPTIONS -Werror=logical-not-parentheses)
    # warn when the sizeof operator is applied to a parameter that is declared as an array in a function definition. This warning is enabled by default for C and C++ programs
    list(APPEND COMP_OPTIONS -Werror=sizeof-array-argument)
    # Warn about boolean expression compared with an integer value different from true/false
    # GNU ONLY, C/CXX
    list(APPEND COMP_OPTIONS
      $<$<OR:$<C_COMPILER_ID:GNU>,$<CXX_COMPILER_ID:GNU>>:-Werror=bool-compare>)
    # This option is only active when -ftree-vrp is active (default for -O2 and above). It warns about subscripts to arrays that are always out of bounds.
    list(APPEND COMP_OPTIONS -Werror=array-bounds)
    # Warn if a comparison is always true or always false due to the limited range of the data type
    list(APPEND COMP_OPTIONS -Werror=type-limits)
    # warn when there is a conversion between pointers that have incompatible types.
    list(APPEND COMP_OPTIONS $<$<COMPILE_LANGUAGE:C>:-Werror=incompatible-pointer-types>)
    # Warn if a global function is defined without a previous prototype declaration.
    list(APPEND COMP_OPTIONS $<$<COMPILE_LANGUAGE:C>:-Werror=missing-prototypes>)
    # Warn whenever a function is defined with a return type that defaults to int.
    list(APPEND COMP_OPTIONS -Werror=return-type)
    # warns about cases where the compiler optimizes based on the assumption that signed overflow does not occur.
    # !! this warning depends on the optimization level. Check doc.
    list(APPEND COMP_OPTIONS -Wstrict-overflow=4)
    # warns about code that might break the strict aliasing rules that the compiler is using for optimization.
    list(APPEND COMP_OPTIONS -Werror=strict-aliasing)
    # Warn about trampolines generated for pointers to nested functions.
    # GNU ONLY, C/CXX
    list(APPEND COMP_OPTIONS
      $<$<OR:$<C_COMPILER_ID:GNU>,$<CXX_COMPILER_ID:GNU>>:-Werror=trampolines>)
    # warnings from casts to pointer type of an integer of a different size
    list(APPEND COMP_OPTIONS -Werror=int-to-pointer-cast)
    #  warnings from casts from a pointer to an integer type of a different size.
    list(APPEND COMP_OPTIONS $<$<COMPILE_LANGUAGE:C>:-Werror=pointer-to-int-cast>)
    # Warn if a global function is defined without a previous declaration.
    list(APPEND COMP_OPTIONS -Werror=missing-declarations)
    # Check calls to printf and scanf, etc., to make sure that the arguments supplied have types appropriate to the format string specified
    list(APPEND COMP_OPTIONS -Wformat=2)
    # warn about uses of format functions that represent possible security problems.
    list(APPEND COMP_OPTIONS -Werror=format-security)
    # Warn when a function declaration hides virtual functions from a base class
    list(APPEND COMP_OPTIONS $<$<COMPILE_LANGUAGE:CXX>:-Werror=overloaded-virtual>)
    # Warn when a class has virtual functions and an accessible non-virtual destructor itself
    list(APPEND COMP_OPTIONS  $<$<COMPILE_LANGUAGE:CXX>:-Werror=non-virtual-dtor>)
    # Clang specific, C/C++
    # Error when option does not exist ...
    list(APPEND COMP_OPTIONS
      $<$<OR:$<C_COMPILER_ID:Clang>,$<C_COMPILER_ID:AppleClang>,$<CXX_COMPILER_ID:Clang>,$<CXX_COMPILER_ID:AppleClang>>:-Werror=unknown-warning-option>)
    list(APPEND COMP_OPTIONS
      $<$<OR:$<C_COMPILER_ID:Clang>,$<C_COMPILER_ID:AppleClang>,$<CXX_COMPILER_ID:Clang>,$<CXX_COMPILER_ID:AppleClang>>:-Werror=unreachable-code>)
  endif()

  # More diagnostics ...
  if(COMP_DIAGNOSTICS_LEVEL EQUAL 2)
    # implicit conversions that may alter a value
    list(APPEND COMP_OPTIONS -Wconversion)

    # Gives a warning whenever the base standard (see -Wpedantic) requires a diagnostic,
    list(APPEND COMP_OPTIONS -pedantic)

    # Warn if a function is declared or defined without specifying the argument types.
    list(APPEND COMP_OPTIONS -Wstrict-prototypes)

  elseif(COMP_DIAGNOSTICS_LEVEL EQUAL 3)
    # -- Paranoid mode  options --
    # Warnings = errors
     # Gives a warning whenever the base standard (see -Wpedantic) requires a diagnostic,
    list(APPEND COMP_OPTIONS -Werror=pedantic)

    # implicit conversions that may alter a value
    list(APPEND COMP_OPTIONS -Werror=conversion)

    # Warn if a function is declared or defined without specifying the argument types.
    list(APPEND COMP_OPTIONS -Werror=strict-prototypes)
  endif()
 
  # --- Apply options to the current target ---
  if(COMP_OPTIONS)
    target_compile_options(${COMPONENT}
      PRIVATE
      $<$<OR:$<COMPILE_LANGUAGE:CXX>,$<COMPILE_LANGUAGE:C>>:${COMP_OPTIONS}>)
  endif()
endfunction()


macro(msys_to_win_path MsysPath ResultingPath)
  string(REGEX REPLACE "/" "\\\\" ${ResultingPath} "${MsysPath}")  
endmacro()