# find GAMS
include(FindPackageHandleStandardArgs)

set (GAMS_INCLUDE_DIR 
    ${GAMS_ROOT}/apifiles/C++/api    
)

if(NOT GAMS_LIBRARIES)
  find_library(GAMS_LIBRARIES NAMES gamscpp 
    PATHS ${GAMS_ROOT}/apifiles/C++/lib/vs2019 REQUIRED)  
endif()

find_package_handle_standard_args(GAMS REQUIRED_VARS GAMS_LIBRARIES GAMS_INCLUDE_DIR)

if(GAMS_FOUND)  
  option(USE_GAMS "Use GAMS" ON)
  if(NOT TARGET GAMS::GAMS)
    add_library(GAMS::GAMS IMPORTED INTERFACE)
    set_property(TARGET GAMS::GAMS PROPERTY INTERFACE_LINK_LIBRARIES ${GAMS_LIBRARIES})
    if(GAMS_INCLUDE_DIR)
      set_target_properties(GAMS::GAMS PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${GAMS_INCLUDE_DIR}")
    endif()
  endif()      
  target_link_libraries(${COMPONENT} PRIVATE GAMS::GAMS)
endif()