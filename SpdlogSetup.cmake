
# Two ways:
  # - WITH_SPDLOG_INSTALL=ON : use fetchcontent to download and install SPDLOG as a persee part
  # - User asks explicitely for a specific (already installed) version of Highs
  #   by providing SPDLOG_ROOT on cmake command line.
  #   => find it and check the version

if(WITH_SPDLOG_INSTALL)
  include(FetchContent)
  message(STATUS "spdlog will be downloaded from github repository and installed as a cairn component")

  set(FETCHCONTENT_QUIET ON) # verbose mode for fetchcontent. Comment/uncomment according to your needs.
  
  set(SPDLOG_Install ON) 
  FetchContent_Declare(spdlog
    GIT_REPOSITORY    https://github.com/gabime/spdlog
    GIT_TAG          v1.15.3
    GIT_SHALLOW TRUE
    UPDATE_DISCONNECTED TRUE # Do not update git repo at each run
    LOG_CONFIGURE TRUE
    LOG_BUILD TRUE
    LOG_INSTALL TRUE
    )
  
  option(BUILD_TESTING OFF)
  FetchContent_MakeAvailable(spdlog)
      
  set(SPDLOG_VERSION 1.15.3 CACHE INTERNAL "spdlog version") 
  set(SPDLOG_DIR ${CMAKE_INSTALL_PREFIX} CACHE INTERNAL "") 
  message(STATUS "Built, installed and used spdlog, version ${SPDLOG_VERSION} in ${SPDLOG_DIR}.")
  
elseif(SPDLOG_ROOT)  
  set(SPDLOG_DIR ${SPDLOG_ROOT}/${CMAKE_BUILD_TYPE}/lib/cmake/spdlog)
  find_package(SPDLOG REQUIRED)  
endif()

