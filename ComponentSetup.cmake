include(CMakeTools)
include(GNUInstallDirs)

#====================================================================
#
# Define and setup build process for a target for the current component
# 
# Usage:
#
# create_component(COMPONENT)
#
# The following variables must be properly set before any call to this function
# - <COMPONENT>_DIRS : list of directories (path relative to CMAKE_SOURCE_DIR)
#    that contain source files.
# - <COMPONENT>_EXCLUDE_SRCS : list of files to exclude from build process
# - <COMPONENT>_RESOURCES : list of qrc files
# - <COMPONENT>_RESOURCES_DIR :  of directories (path relative to CMAKE_SOURCE_DIR)
#    that contain resource files (icon, image, configuration, ...).

#   for this component.
#
# This function:
#   creates a target <component> from all sources files in <component>_DIRS
#   excluding files from <component>_EXCLUDE_SRCS
#
function(create_component COMPONENT)

  # --- Collect source files from given directories ---

  # --> Scan source directories and return a list of files to be compiled.  
  get_sources(${COMPONENT} DIRS ${${COMPONENT}_DIRS} EXCLUDE ${${COMPONENT}_EXCLUDE_SRCS} INCLUDESRCS  ${${COMPONENT}_INCLUDE_SRCS})
  
  # --> Scan resource directories and return a list of files to be included in target => ${COMPONENT}_INSTALLRESOURCES 
  get_resources(${COMPONENT} DIRS ${${COMPONENT}_RESOURCES_DIR})

  # Create the library
  if(BUILD_EXE)
    add_executable(${COMPONENT} ${${COMPONENT}_SRCS} ${${COMPONENT}_RESOURCES})
  elseif(BUILD_PYBIND)  
    pybind11_add_module(${COMPONENT} SHARED ${${COMPONENT}_SRCS})
  elseif(BUILD_SHARED_LIBS)
    add_library(${COMPONENT} SHARED ${${COMPONENT}_SRCS} ${${COMPONENT}_RESOURCES})
  else()
    add_library(${COMPONENT} STATIC ${${COMPONENT}_SRCS})
    set_property(TARGET ${COMPONENT} PROPERTY POSITION_INDEPENDENT_CODE ON)
  endif()

  # Set compiler options
  string(TOUPPER ${COMPONENT} UPPERCOMPONENT)
  target_compile_definitions(${COMPONENT} PRIVATE -D${UPPERCOMPONENT}_LIBRARY)

  # reminder : WARNINGS_LEVEL=0 -> no warnings, =1, developers mininmal set of warnings,
  # =2 : strict mode, warnings to errors.
  apply_compiler_options(${COMPONENT} DIAGNOSTICS_LEVEL ${WARNINGS_LEVEL})
  
  # Append component source dirs to include directories
  # (Private : only to build current component).
  foreach(dir IN LISTS ${COMPONENT}_DIRS)
    target_include_directories(${COMPONENT} PRIVATE
      $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/${dir}>)
  endforeach()
  foreach(dir IN LISTS ${COMPONENT}_EXTRA_INCLUDE_DIRECTORIES)
    target_include_directories(${COMPONENT} PRIVATE
      $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/${dir}>)
  endforeach()

  # Add current component include dirs that should be propagated through
  # interface, in build tree.
  # WARNING : includes for install interface are handled later
  # in component install, and may be different.
  foreach(dir IN LISTS ${COMPONENT}_INTERFACE_INCLUDE_DIRECTORIES)
    target_include_directories(${COMPONENT} INTERFACE
      $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/${dir}>)
     
    message("-- Include dir for ${COMPONENT},  ${CMAKE_CURRENT_SOURCE_DIR}/${dir}")
  endforeach()

  if (${COMPONENT}_TRANSLATION)
    find_package(Qt REQUIRED Core LinguistTools)   
    FILE(GLOB ${COMPONENT}_TS_FILES "${${COMPONENT}_TRANSLATION}/*.ts")     
    qt_add_translation(${COMPONENT}_QM_FILES  ${${COMPONENT}_TS_FILES})    

    message("-- Create translations for ${COMPONENT}, ${${COMPONENT}_TS_FILES}")
    message("Qt5_LRELEASE_EXECUTABLE: ${Qt5_LRELEASE_EXECUTABLE} ")
        
    set(${COMPONENT}_TRANSLATIONS_FILES ${${COMPONENT}_QM_FILES} PARENT_SCOPE)
  endif()
      
  set_target_properties(${COMPONENT} PROPERTIES
    OUTPUT_NAME "${COMPONENT}"
    VERSION "${PROJECT_SOVERSION}"  
    SOVERSION "${PROJECT_SOVERSION_MAJOR}"
    RESOURCE "${${COMPONENT}_INSTALLRESOURCES}"
    #POSITION_INDEPENDENT_CODE ON
    #INTERFACE_POSITION_INDEPENDENT_CODE ON
    #INTERFACE_${PROJECT_NAME}_MAJOR_VERSION ${PROJECT_VERSION_MAJOR}
    #COMPATIBLE_INTERFACE_STRING ${PROJECT_NAME}_MAJOR_VERSION      
  )
   
endfunction()


#====================================================================
#
# Function to define and setup install process for a target for the current component
# 
# Usage:
#
# component_install_setup(<COMPONENT>)
#
#
# This function 
#   creates a target <component> from all sources files in <component>_DIRS
#   excluding files from <component>_EXCLUDE_SRCS
#
function(component_install_setup COMPONENT)
  
  set(oneValueArgs DESTINATION INCLUDE LIBDIR)
  cmake_parse_arguments(runtime "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

  if("${runtime_DESTINATION}" STREQUAL "")
    set(runtime_DESTINATION ${CMAKE_INSTALL_BINDIR})
  else()
    set(runtime_DESTINATION ${CMAKE_INSTALL_BINDIR}/${runtime_DESTINATION})
  endif()
  if("${runtime_LIBDIR}" STREQUAL "")
    set(runtime_LIBDIR ${CMAKE_INSTALL_LIBDIR})
  endif()
  if("${runtime_INCLUDE}" STREQUAL "")
    set(runtime_INCLUDE ${PROJECT_NAME}/${COMPONENT})
  endif()
  
  # libraries
  if(CMAKE_SYSTEM_NAME MATCHES Windows)
      install(TARGETS ${COMPONENT}
        EXPORT ${PROJECT_NAME}Targets
        RUNTIME DESTINATION ${runtime_DESTINATION}    
        INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${runtime_INCLUDE}
        ARCHIVE DESTINATION ${runtime_LIBDIR}
        LIBRARY DESTINATION ${runtime_LIBDIR}    
        PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${runtime_INCLUDE}
        RESOURCE DESTINATION resources
      )

  else()
      install(TARGETS ${COMPONENT}
        EXPORT ${PROJECT_NAME}Targets
        RUNTIME DESTINATION ${runtime_DESTINATION}    
        INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${runtime_INCLUDE}
        ARCHIVE DESTINATION ${runtime_LIBDIR}
        LIBRARY DESTINATION ${runtime_DESTINATION}    
        PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${runtime_INCLUDE}
        RESOURCE DESTINATION resources
        )
  endif()


  
  #target_include_directories(${COMPONENT} INTERFACE
  #  $<INSTALL_INTERFACE:include>)

  # Setup the list of all headers to be installed.
  foreach(dir IN LISTS ${COMPONENT}_INSTALL_INTERFACE_INCLUDE_DIRECTORIES)

    file(GLOB _headers CONFIGURE_DEPENDS
      LIST_DIRECTORIES false ${_FILE} ${dir}/*.h ${dir}/*.hpp)
    list(APPEND _all_headers ${_headers})
      
  endforeach()

  if(_all_headers)
    # Do not install files listed in ${COMPONENT}_HDRS_EXCLUDE
    foreach(_file IN LISTS ${COMPONENT}_HDRS_EXCLUDE)
      list(REMOVE_ITEM _all_headers "${CMAKE_CURRENT_SOURCE_DIR}/${_file}")
    endforeach()
    # install files collected in _all_headers
    install(
      FILES ${_all_headers}
      DESTINATION include/${runtime_INCLUDE}
      )
    
    # Add include dirs in target interface 
    target_include_directories(${COMPONENT} INTERFACE
      $<INSTALL_INTERFACE:include/${runtime_INCLUDE}>)

  endif()

  if(${COMPONENT}_EXTRA_FILES)
     install(
      FILES ${${COMPONENT}_EXTRA_FILES}
      DESTINATION ${runtime_DESTINATION}
      )
  endif()

  # TODO: !!!probl�mes dans la g�n�ration des qm
  #if(${COMPONENT}_TRANSLATION)
  #   message("-- Install translations for ${COMPONENT}, ${${COMPONENT}_TRANSLATIONS_FILES}")
  #   install(
  #    FILES ${${COMPONENT}_TRANSLATIONS_FILES}
  #    DESTINATION ${runtime_DESTINATION}/translations
  #    )
  #endif()
  
  
  #set(${COMPONENT}_DEPS_FILES file(GET_RUNTIME_DEPENDENCIES))
  #install(RUNTIME_DEPENDENCY_SET ${COMPONENT}_DEPS_FILES )


  # Set installed_targets list (for <project>-config.cmake file)
  list(APPEND installed_targets ${COMPONENT})
  list(REMOVE_DUPLICATES installed_targets)
  set(installed_targets ${installed_targets}
    CACHE INTERNAL "List of all exported components (targets).")
  


  #install(CODE  [[file(GET_RUNTIME_DEPENDENCIES) ]])
endfunction()


function(component_get_install COMPONENT)

  set(oneValueArgs DESTINATION MODULE )
  cmake_parse_arguments(install "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

  if(NOT ${COMPONENT}_LIBRARIES)           
        foreach(${COMPONENT}_LIBRARY IN LISTS ${COMPONENT}_LIBS)                
            find_library(${COMPONENT}_LIB ${${COMPONENT}_LIBRARY}
                PATHS ${install_DESTINATION}/lib
                REQUIRED)            
            list(APPEND ${COMPONENT}_LIBRARIES ${${COMPONENT}_LIB})       
            unset(${COMPONENT}_LIB CACHE)
        endforeach()      
    endif()

    find_package_handle_standard_args(${COMPONENT}
      REQUIRED_VARS ${COMPONENT}_LIBRARIES ${COMPONENT}_INCLUDE_DIR)

    if(${COMPONENT}_FOUND)
      option(USE_${COMPONENT} "Use ${COMPONENT}" ON)    
        foreach(${COMPONENT}_LIBRARY ${COMPONENT}_FULLLIBRARY IN ZIP_LISTS ${COMPONENT}_LIBS ${COMPONENT}_LIBRARIES)      
            add_library(${${COMPONENT}_LIBRARY} SHARED IMPORTED) 
            set_property(TARGET ${${COMPONENT}_LIBRARY} PROPERTY INTERFACE_LINK_LIBRARIES ${${COMPONENT}_FULLLIBRARY})                        
            set_property(TARGET ${${COMPONENT}_LIBRARY} PROPERTY IMPORTED_IMPLIB ${${COMPONENT}_FULLLIBRARY})
            set_target_properties(${${COMPONENT}_LIBRARY} PROPERTIES            
                OUTPUT_NAME "${${COMPONENT}_LIBRARY}"
                IMPORTED_LOCATION "${install_DESTINATION}/lib"   
                INTERFACE_INCLUDE_DIRECTORIES "${${COMPONENT}_INCLUDE_DIR}"  
            )
           target_link_libraries(${install_MODULE} PUBLIC ${${COMPONENT}_LIBRARY})
       
        endforeach()

  
    endif()

endfunction()



#====================================================================
#
# Define and setup build & install process for a target for each models in directory MODELS
#   One model = one cpp file
# 
# Usage:
#
# create_model(MODELS)
#
# The following variables must be properly set before any call to this function
# - MODELS_SFX : string, define a suffixe of the target
#
function(create_model MODELS)
    
    get_sources(${MODELS} DIRS ${MODELS})
    
    foreach(_FILEMODEL IN LISTS ${MODELS}_SRCS) 
        get_filename_component(_NAMEMODEL ${_FILEMODEL} NAME_WLE)               
        get_filename_component(COMPONENT_DIR ${_FILEMODEL} DIRECTORY)
        
        set(COMPONENT ${_NAMEMODEL}${MODELS_SFX})
        message("\n-- Set up for ${PROJECT_NAME}_${COMPONENT} library ...")
        message("\n--dir ${CMAKE_CURRENT_SOURCE_DIR}/${COMPONENT_DIR}")
      
        add_library(${COMPONENT} SHARED ${_FILEMODEL})
        
        target_compile_definitions(${COMPONENT} PRIVATE -DMODELS_LIBRARY)
		apply_compiler_options(${COMPONENT} DIAGNOSTICS_LEVEL ${WARNINGS_LEVEL})
		
         target_include_directories(${COMPONENT} PRIVATE
          $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>)
        target_include_directories(${COMPONENT} PRIVATE
          $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/${COMPONENT_DIR}>)

        target_include_directories(${COMPONENT} INTERFACE
          $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>)
        target_include_directories(${COMPONENT} INTERFACE
          $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/${COMPONENT_DIR}>)
		message("-- Include dir for ${COMPONENT},  ${CMAKE_CURRENT_SOURCE_DIR}/${COMPONENT_DIR}")
   
        set_target_properties(${COMPONENT} PROPERTIES
            OUTPUT_NAME "${COMPONENT}"
            VERSION "${PROJECT_SOVERSION}"  
            SOVERSION "${PROJECT_SOVERSION_MAJOR}"        
        )

        include(EigenSetup)
        include(SpdlogSetup)        
        find_package(Cairn REQUIRED CairnCore CairnModelInterface )
                
        target_link_libraries(${COMPONENT} PRIVATE mipmodeler::MIPModeler)
        target_link_libraries(${COMPONENT} PRIVATE mipmodeler::ModelerInterface)
        target_link_libraries(${COMPONENT} PRIVATE mipmodeler::MIPSolver)
        target_link_libraries(${COMPONENT} PRIVATE Eigen3::Eigen)
        target_link_libraries(${COMPONENT} PRIVATE spdlog::spdlog)

        if (${_NAMEMODEL}_LINKEDMODELS)                     
            foreach(_MODEL_LINK IN LISTS ${_NAMEMODEL}_LINKEDMODELS)
                set(CAIRNMODEL_LINK ${_MODEL_LINK}${MODELS_SFX}) 
                message("-- link ${CAIRNMODEL_LINK}") 
                target_link_libraries(${COMPONENT} PRIVATE CairnModels::${CAIRNMODEL_LINK})    
            endforeach()            
        endif()

      # ---- Installation ----
        set(${COMPONENT}_INSTALL_INTERFACE_INCLUDE_DIRECTORIES
            ${MODELS} # All .h are installed
        )
        component_install_setup(${COMPONENT} INCLUDE  ${PROJECT_NAME}/models)


        list(APPEND list_models ${COMPONENT})

        
    endforeach() 
    list(REMOVE_DUPLICATES list_models)
    set(list_models ${list_models}
    CACHE INTERNAL "List of all models")

endfunction()

#====================================================================
#
#
# create_models(MODELS_DIRS)
#
# 
#
function(create_models MODELS_DIRS)
 
     foreach(_DIRMODELS IN LISTS ${MODELS_DIRS} )
        create_model(${_DIRMODELS})
     endforeach() 

endfunction()


