
# Two ways:
  # - WITH_HIGHS_INSTALL=ON : use fetchcontent to download and install HIGHS as a cairn part
  # - User asks explicitely for a specific (already installed) version of Highs
  #   by providing HIGHS_ROOT on cmake command line.
  #   => find it and check the version
set(IS_INSTALLED OFF)
if (DEFINED highs_DIR)
    if (EXISTS ${highs_DIR})
        set(IS_INSTALLED ON)
    endif()
endif()

if(WITH_highs_INSTALL OR (NOT IS_INSTALLED))
  include(FetchContent)  

  set(FETCHCONTENT_QUIET OFF) # verbose mode for fetchcontent. Comment/uncomment according to your needs.    
  set(HIGHS_GIT_REPOSITORY https://github.com/ERGO-Code/HiGHS) 
  set(HIGHS_GIT_TAG  v1.8.0)
  
  if (DEPS_INSTALL AND EXISTS ${DEPS_ROOT})
      message(STATUS "HiGHS will be used from path ${DEPS_ROOT} and installed as a cairn component")  
      FetchContent_Declare(highs
        PREFIX ${DEPS_ROOT}
        SOURCE_DIR ${DEPS_ROOT}/highs-src
        BINARY_DIR ${DEPS_ROOT}/${CMAKE_BUILD_TYPE}/highs-build  
        SUBBUILD_DIR ${DEPS_ROOT}/${CMAKE_BUILD_TYPE}/highs-subbuild  
        GIT_REPOSITORY    ${HIGHS_GIT_REPOSITORY}
        GIT_TAG     ${HIGHS_GIT_TAG}
        GIT_SHALLOW TRUE
        UPDATE_DISCONNECTED TRUE # Do not update git repo at each run
        LOG_CONFIGURE TRUE
        LOG_BUILD TRUE
        LOG_INSTALL TRUE
        ) 
        install(CODE "execute_process(COMMAND \"${CMAKE_COMMAND}\"
            --install ${DEPS_ROOT}/${CMAKE_BUILD_TYPE}/highs-build 
            --prefix ${DEPS_ROOT}/bin/${CMAKE_BUILD_TYPE})")
  else()
      message(STATUS "HiGHS will be downloaded from github repository and installed as a cairn component")
      FetchContent_Declare(highs
        GIT_REPOSITORY    ${HIGHS_GIT_REPOSITORY}
        GIT_TAG     ${HIGHS_GIT_TAG}
        GIT_SHALLOW TRUE
        UPDATE_DISCONNECTED TRUE # Do not update git repo at each run
        LOG_CONFIGURE TRUE
        LOG_BUILD TRUE
        LOG_INSTALL TRUE
        )         
  endif()

  set(BUILD_TESTING OFF)
  set(BUILD_EXAMPLES OFF)  
  set(BUILD_DOTNET OFF)
  set(USE_DOTNET_STD_21 OFF)
  FetchContent_MakeAvailable(highs)
      
  #set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
  set(HIGHS_VERSION 1.8.0 CACHE INTERNAL "Highs version") 
  set(HIGHS_DIR ${CMAKE_INSTALL_PREFIX} CACHE INTERNAL "") 
  message(STATUS "Built, installed and used highs, version ${HIGHS_VERSION} in ${HIGHS_DIR}.")
  message(STATUS "highs_FOUND: ${highs_FOUND}") 

else()        
    find_package(highs REQUIRED CONFIG)  
    message(STATUS "highs_FOUND: ${highs_FOUND}") 
endif()

