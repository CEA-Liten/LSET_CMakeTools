# find CPLEX
include(FindPackageHandleStandardArgs)


set (CPLEX_INCLUDE_DIR 
   ${CPLEX_ROOT}/include/ilcplex
)

# Try to help find_package process (pkg-config ...)
#set_find_package_hints(NAME CPLEX MODULE cplex)

#find_path(CPLEX_INCLUDE_DIR NAMES cplex.h  
#  HINTS ${CPLEX_ROOT} #/include/ilcplex
#  NO_DEFAULT_PATH #${_CPLEX_INC_SEARCH_OPTS}
#  )
#message(STATUS "_CPLEX_INC_SEARCH_OPTS: ${_CPLEX_INC_SEARCH_OPTS}")
#message(STATUS "CPLEX_INCLUDE_DIR: ${CPLEX_INCLUDE_DIR}")

if(NOT CPLEX_LIBRARIES)    
    find_library(CPLEX_LIBRARIES NAMES cplex1290 cplex2010 cplex
    PATHS "${CPLEX_ROOT}/lib/x64_windows_vs2017/stat_mda" "${CPLEX_ROOT}/lib/x64_windows_msvc14/stat_mda" "${CPLEX_ROOT}/lib/x86-64_linux/static_pic"
    REQUIRED)
endif()



# -- Library setup --
find_package_handle_standard_args(CPLEX
  REQUIRED_VARS CPLEX_LIBRARIES CPLEX_INCLUDE_DIR)

if(CPLEX_FOUND)
  option(USE_CPLEX "Use CPLEX" ON)
  message(STATUS "Use CPLEX")
  if(NOT TARGET CPLEX::CPLEX)
    add_library(CPLEX::CPLEX IMPORTED INTERFACE)
    set_property(TARGET CPLEX::CPLEX PROPERTY INTERFACE_LINK_LIBRARIES ${CPLEX_LIBRARIES})    
    if(CPLEX_INCLUDE_DIR)
      set_target_properties(CPLEX::CPLEX PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${CPLEX_INCLUDE_DIR}")
    endif()
  endif()

endif()
