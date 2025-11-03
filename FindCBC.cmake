# find CBC
include(FindPackageHandleStandardArgs)


set (CBC_INCLUDE_DIR 
    ${COINOR_ROOT}/Cgl/src/
    ${COINOR_ROOT}/CoinUtils/src/
    ${COINOR_ROOT}/Osi/src/Osi/
    ${COINOR_ROOT}/Cbc/src/
    ${COINOR_ROOT}/Clp/src/OsiClp
    ${COINOR_ROOT}/Clp/src/
)


if(NOT CBC_LIBRARIES)        
    set(CBC_LIBS
        libCbc libCbcSolver libCgl libClp libCoinUtils libOsi libOsiCbc  libOsiClp
    )    
    set(CBC_PATHLIBS ${COINOR_ROOT}/lib/${CMAKE_BUILD_TYPE})
    if ("${CMAKE_BUILD_TYPE}" STREQUAL "fullrelease")
        set(CBC_PATHLIBS ${COINOR_ROOT}/lib/release)
    elseif ("${CMAKE_BUILD_TYPE}" STREQUAL "fulldebug")
        set(CBC_PATHLIBS ${COINOR_ROOT}/lib/debug)
    endif()
    foreach(CBC_LIBRARY IN LISTS CBC_LIBS)                
        find_library(CBC_LIB ${CBC_LIBRARY}
            PATHS ${CBC_PATHLIBS}
            REQUIRED)            
        list(APPEND CBC_LIBRARIES ${CBC_LIB})       
        unset(CBC_LIB CACHE)
    endforeach()      
endif()


# -- Library setup --
find_package_handle_standard_args(CBC
  REQUIRED_VARS CBC_LIBRARIES CBC_INCLUDE_DIR)

if(CBC_FOUND)
  option(USE_CBC "Use CBC" ON)    
  
    foreach(CBC_LIBRARY CBC_FULLLIBRARY IN ZIP_LISTS CBC_LIBS CBC_LIBRARIES)
                      
      if(CMAKE_SYSTEM_NAME MATCHES Windows)
        message("CBC:${CBC_LIBRARY}")
        add_library(${CBC_LIBRARY} SHARED IMPORTED) 
        set_property(TARGET ${CBC_LIBRARY} PROPERTY INTERFACE_LINK_LIBRARIES ${CBC_FULLLIBRARY})                        
        set_property(TARGET ${CBC_LIBRARY} PROPERTY IMPORTED_IMPLIB ${CBC_FULLLIBRARY})
        set_target_properties(${CBC_LIBRARY} PROPERTIES            
            OUTPUT_NAME "${CBC_LIBRARY}"
            IMPORTED_LOCATION "${COINOR_ROOT}/lib/${CMAKE_BUILD_TYPE}"   
            INTERFACE_INCLUDE_DIRECTORIES "${CBC_INCLUDE_DIR}"  
        )
       target_link_libraries(${COMPONENT} PUBLIC ${CBC_LIBRARY})
        install(FILES ${COINOR_ROOT}/lib/${CMAKE_BUILD_TYPE}/${CBC_LIBRARY}.dll
            DESTINATION ${CMAKE_INSTALL_BINDIR}            
            )
      else()
        set(CBC_LIBRARY lib${CBC_LIBRARY})
        message("CBC:${CBC_LIBRARY}")
        add_library(${CBC_LIBRARY} SHARED IMPORTED) 
        set_property(TARGET ${CBC_LIBRARY} PROPERTY INTERFACE_LINK_LIBRARIES ${CBC_FULLLIBRARY})                        
        set_property(TARGET ${CBC_LIBRARY} PROPERTY IMPORTED_IMPLIB ${CBC_FULLLIBRARY})
        set_target_properties(${CBC_LIBRARY} PROPERTIES            
            OUTPUT_NAME "${CBC_LIBRARY}"
            IMPORTED_LOCATION "${COINOR_ROOT}/lib/${CMAKE_BUILD_TYPE}"   
            INTERFACE_INCLUDE_DIRECTORIES "${CBC_INCLUDE_DIR}"  
        )
       target_link_libraries(${COMPONENT} PUBLIC ${CBC_LIBRARY})
        install(FILES ${CBC_FULLLIBRARY} ${CBC_FULLLIBRARY}.1 ${CBC_FULLLIBRARY}.1.0 ${CBC_FULLLIBRARY}.1.0.0 
            DESTINATION ${CMAKE_INSTALL_BINDIR}            
            )
      endif()
    endforeach()

    
   


  #target_link_libraries(${COMPONENT} PUBLIC CBC::CBC)
  
endif()
