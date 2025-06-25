# find CLP
include(FindPackageHandleStandardArgs)


set (CLP_INCLUDE_DIR 
    ${COINOR_ROOT}/Cgl/src/
    ${COINOR_ROOT}/CoinUtils/src/
    ${COINOR_ROOT}/Osi/src/Osi/    
    ${COINOR_ROOT}/Clp/src/OsiClp
    ${COINOR_ROOT}/Clp/src/
)


if(NOT CLP_LIBRARIES)        
    set(CLP_LIBS
            libCgl libClp libCoinUtils libOsi libOsiClp
        )
    set(CLP_PATHLIBS ${COINOR_ROOT}/lib/${CMAKE_BUILD_TYPE})
    if ("${CMAKE_BUILD_TYPE}" STREQUAL "fullrelease")
        set(CLP_PATHLIBS ${COINOR_ROOT}/lib/release)
    elseif ("${CMAKE_BUILD_TYPE}" STREQUAL "fulldebug")
        set(CLP_PATHLIBS ${COINOR_ROOT}/lib/debug)
    endif()
    foreach(CLP_LIBRARY IN LISTS CLP_LIBS)                
        find_library(CLP_LIB ${CLP_LIBRARY}
            PATHS ${CLP_PATHLIBS}
            REQUIRED)            
        list(APPEND CLP_LIBRARIES ${CLP_LIB})
        unset(CLP_LIB CACHE)
    endforeach()      
endif()


# -- Library setup --
find_package_handle_standard_args(CLP
  REQUIRED_VARS CLP_LIBRARIES CLP_INCLUDE_DIR)

if(CLP_FOUND)
    option(USE_CLP "Use CLP" ON)  
    foreach(CLP_LIBRARY CLP_FULLLIBRARY IN ZIP_LISTS CLP_LIBS CLP_LIBRARIES)
                      
      if(CMAKE_SYSTEM_NAME MATCHES Windows)
        message("CLP:${CLP_LIBRARY}")
        add_library(${CLP_LIBRARY} SHARED IMPORTED) 
        set_property(TARGET ${CLP_LIBRARY} PROPERTY INTERFACE_LINK_LIBRARIES ${CLP_FULLLIBRARY})                        
        set_property(TARGET ${CLP_LIBRARY} PROPERTY IMPORTED_IMPLIB ${CLP_FULLLIBRARY})
        set_target_properties(${CLP_LIBRARY} PROPERTIES            
            OUTPUT_NAME "${CLP_LIBRARY}"
            IMPORTED_LOCATION "${COINOR_ROOT}/lib/${CMAKE_BUILD_TYPE}"   
            INTERFACE_INCLUDE_DIRECTORIES "${CLP_INCLUDE_DIR}"  
        )
       target_link_libraries(${COMPONENT} PUBLIC ${CLP_LIBRARY})
        install(FILES ${COINOR_ROOT}/lib/${CMAKE_BUILD_TYPE}/${CLP_LIBRARY}.dll
            DESTINATION ${CMAKE_INSTALL_BINDIR}            
            )
      else()
        set(CLP_LIBRARY lib${CLP_LIBRARY})
        message("CLP:${CLP_LIBRARY}")
        add_library(${CLP_LIBRARY} SHARED IMPORTED) 
        set_property(TARGET ${CLP_LIBRARY} PROPERTY INTERFACE_LINK_LIBRARIES ${CLP_FULLLIBRARY})                        
        set_property(TARGET ${CLP_LIBRARY} PROPERTY IMPORTED_IMPLIB ${CLP_FULLLIBRARY})
        set_target_properties(${CLP_LIBRARY} PROPERTIES            
            OUTPUT_NAME "${CLP_LIBRARY}"
            #IMPORTED_LOCATION "${COINOR_ROOT}/lib/${CMAKE_BUILD_TYPE}"   
            INTERFACE_INCLUDE_DIRECTORIES "${CLP_INCLUDE_DIR}"  
        )
       target_link_libraries(${COMPONENT} PUBLIC ${CLP_LIBRARY})
        install(FILES ${CLP_FULLLIBRARY} ${CLP_FULLLIBRARY}.1 ${CLP_FULLLIBRARY}.1.0 ${CLP_FULLLIBRARY}.1.0.0
            DESTINATION ${CMAKE_INSTALL_BINDIR}            
            )
      endif()
    endforeach()
endif()
