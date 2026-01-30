
# Two ways:
  # - WITH_EIGEN_INSTALL=ON : use fetchcontent to download and install EIGEN as a cairn part
  # - User asks explicitely for a specific (already installed) version of EIGEN
  #   by providing Eigen3_DIR on cmake command line.
  #   => find it and check the version
set(IS_INSTALLED OFF)
if (DEFINED eigen_DIR)
    if (EXISTS ${eigen_DIR})
        set(IS_INSTALLED ON)
    endif()
endif()

if(WITH_eigen_INSTALL OR (NOT IS_INSTALLED))
  include(FetchContent)

  set(FETCHCONTENT_QUIET OFF) # verbose mode for fetchcontent. Comment/uncomment according to your needs.
  set(EIGEN_Install ON) 
  set(EIGEN_GIT_REPOSITORY https://gitlab.com/libeigen/eigen.git) 
  set(EIGEN_GIT_TAG e67c494cba7180066e73b9f6234d0b2129f1cdf5) #3.4.1 (3.4.0 ne fonctionne pas bien, on ne peut pas désactiver les tests)    ) 

  if (DEPS_INSTALL AND EXISTS ${DEPS_ROOT})
      message(STATUS "EIGEN will be used from path ${DEPS_ROOT} and installed as a cairn component")  
      FetchContent_Declare(eigen
        PREFIX ${DEPS_ROOT}
        SOURCE_DIR ${DEPS_ROOT}/eigen-src
        BINARY_DIR ${DEPS_ROOT}/${CMAKE_BUILD_TYPE}/eigen-build  
        SUBBUILD_DIR ${DEPS_ROOT}/${CMAKE_BUILD_TYPE}/eigen-subbuild  
        GIT_REPOSITORY    ${EIGEN_GIT_REPOSITORY}
        GIT_TAG     ${EIGEN_GIT_TAG}
        #GIT_SHALLOW TRUE
        UPDATE_DISCONNECTED TRUE # Do not update git repo at each run
        LOG_CONFIGURE TRUE
        LOG_BUILD TRUE
        LOG_INSTALL TRUE
        ) 
        install(CODE "execute_process(COMMAND \"${CMAKE_COMMAND}\"
            --install ${DEPS_ROOT}/${CMAKE_BUILD_TYPE}/eigen-build 
            --prefix ${DEPS_ROOT}/bin/${CMAKE_BUILD_TYPE})")
  else()
      message(STATUS "EIGEN will be downloaded from gitlab repository and installed as a cairn component")
      FetchContent_Declare(eigen
        GIT_REPOSITORY    ${EIGEN_GIT_REPOSITORY}
        GIT_TAG     ${EIGEN_GIT_TAG}
        #GIT_SHALLOW TRUE
        UPDATE_DISCONNECTED TRUE # Do not update git repo at each run
        LOG_CONFIGURE TRUE
        LOG_BUILD TRUE
        LOG_INSTALL TRUE
        ) 
  endif()
  
  option(BUILD_TESTING OFF)
  option(EIGEN_BUILD_DOC OFF)
  option(EIGEN_BUILD_PKGCONFIG OFF)
  #option(EIGEN_BUILD_CMAKE_PACKAGE OFF)
  FetchContent_MakeAvailable(eigen)
  #set(Eigen3_DIR eigen_DIR)
  find_package(Eigen3 REQUIRED NO_MODULE)  
  message(STATUS "Built, installed and used Eigen in ${Eigen3_SOURCE_DIR}.")
else()
    set(Eigen3_DIR eigen_DIR)
    find_package(Eigen3)
    message(STATUS "eigen_FOUND: ${Eigen3_FOUND}") 
endif()
target_compile_definitions(${COMPONENT} PRIVATE -DEIGEN_MPL2_ONLY)
