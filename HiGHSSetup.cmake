
# Two ways:
  # - WITH_HIGHS_INSTALL=ON : use fetchcontent to download and install HIGHS as a persee part
  # - User asks explicitely for a specific (already installed) version of Highs
  #   by providing HIGHS_ROOT on cmake command line.
  #   => find it and check the version

if(WITH_HIGHS_INSTALL)
  include(FetchContent)
  message(STATUS "HiGHS will be downloaded from github repository and installed as a persee component")

  set(FETCHCONTENT_QUIET OFF) # verbose mode for fetchcontent. Comment/uncomment according to your needs.
  
  set(HIGHS_Install ON) 
  FetchContent_Declare(highs
    GIT_REPOSITORY    https://github.com/ERGO-Code/HiGHS
    GIT_TAG          v1.8.0 
    GIT_SHALLOW TRUE
    UPDATE_DISCONNECTED TRUE # Do not update git repo at each run
    LOG_CONFIGURE TRUE
    LOG_BUILD TRUE
    LOG_INSTALL TRUE
    )
  
  set(BUILD_TESTING OFF)
  set(BUILD_EXAMPLES OFF)  
  set(BUILD_DOTNET OFF)
  set(USE_DOTNET_STD_21 OFF)
  FetchContent_MakeAvailable(highs)
      
  set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
  set(HIGHS_VERSION 1.8.0 CACHE INTERNAL "Highs version") 
  set(HIGHS_DIR ${CMAKE_INSTALL_PREFIX} CACHE INTERNAL "") 
  message(STATUS "Built, installed and used highs, version ${HIGHS_VERSION} in ${HIGHS_DIR}.")
  
elseif(HIGHS_ROOT)  
  set(HIGHS_DIR ${HIGHS_ROOT}/${CMAKE_BUILD_TYPE}/lib/cmake/highs)
  find_package(HIGHS REQUIRED)  
endif()

