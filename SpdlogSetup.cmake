
# Two ways:
  # - WITH_SPDLOG_INSTALL=ON : use fetchcontent to download and install SPDLOG as a cairn part
  # - User asks explicitely for a specific (already installed) version of spdlog
  #   by providing spdlog_DIR on cmake command line.
  #   => find it and check the version 
set(SPDLOG_IS_INSTALLED OFF)
if (DEFINED spdlog_DIR)    
    if (EXISTS ${spdlog_DIR})
        set(SPDLOG_IS_INSTALLED ON)
    endif()
endif()

if(WITH_spdlog_INSTALL OR (NOT SPDLOG_IS_INSTALLED))
  include(FetchContent)  

  set(FETCHCONTENT_QUIET OFF) # verbose mode for fetchcontent. Comment/uncomment according to your needs.  
  option(SPDLOG_MASTER_PROJECT "SPDLOG_MASTER_PROJECT" ON)  
  set(SPDLOG_GIT_REPOSITORY https://github.com/gabime/spdlog) 
  set(SPDLOG_GIT_TAG  v1.16.0)

  if (DEPS_INSTALL AND EXISTS ${DEPS_ROOT})
      message(STATUS "spdlog will be used from path ${DEPS_ROOT} and installed as a cairn component")  
      FetchContent_Declare(spdlog
        PREFIX ${DEPS_ROOT}
        SOURCE_DIR ${DEPS_ROOT}/spdlog-src
        BINARY_DIR ${DEPS_ROOT}/${CMAKE_BUILD_TYPE}/spdlog-build  
        SUBBUILD_DIR ${DEPS_ROOT}/${CMAKE_BUILD_TYPE}/spdlog-subbuild  
        GIT_REPOSITORY    ${SPDLOG_GIT_REPOSITORY}
        GIT_TAG     ${SPDLOG_GIT_TAG}
        GIT_SHALLOW TRUE
        UPDATE_DISCONNECTED TRUE # Do not update git repo at each run
        LOG_CONFIGURE TRUE
        LOG_BUILD TRUE
        LOG_INSTALL TRUE
        ) 
        install(CODE "execute_process(COMMAND \"${CMAKE_COMMAND}\"
            --install ${DEPS_ROOT}/${CMAKE_BUILD_TYPE}/spdlog-build 
            --prefix ${DEPS_ROOT}/bin/${CMAKE_BUILD_TYPE})")
  else()
      message(STATUS "spdlog will be downloaded from github repository and installed as a cairn component")
      FetchContent_Declare(spdlog
        GIT_REPOSITORY    ${SPDLOG_GIT_REPOSITORY}
        GIT_TAG     ${SPDLOG_GIT_TAG}
        GIT_SHALLOW TRUE
        UPDATE_DISCONNECTED TRUE # Do not update git repo at each run
        LOG_CONFIGURE TRUE
        LOG_BUILD TRUE
        LOG_INSTALL TRUE
        ) 
  endif()
  
  if(MSVC)
    # problem with msvc, see  https://stackoverflow.com/questions/78598141/first-stdmutexlock-crashes-in-application-built-with-latest-visual-studio
    add_compile_options(-D_DISABLE_CONSTEXPR_MUTEX_CONSTRUCTOR)
  endif()
  option(BUILD_TESTING OFF)
  FetchContent_MakeAvailable(spdlog)
  
  set(SPDLOG_VERSION 1.16.0 CACHE INTERNAL "spdlog version") 
  set(SPDLOG_DIR ${CMAKE_INSTALL_PREFIX} CACHE INTERNAL "") 
  message(STATUS "Built, installed and used spdlog, version ${SPDLOG_VERSION} in ${SPDLOG_DIR}.")
  
else()
  find_package(spdlog REQUIRED)  
  message(STATUS "spdlog_FOUND: ${spdlog_FOUND}") 

endif()

