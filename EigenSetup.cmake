
# Two ways:
  # - WITH_EIGEN_INSTALL=ON : use fetchcontent to download and install EIGEN as a cairn part
  # - User asks explicitely for a specific (already installed) version of EIGEN
  #   by providing EIGEN_ROOT on cmake command line.
  #   => find it and check the version

if(WITH_EIGEN_INSTALL)
  include(FetchContent)
  message(STATUS "EIGEN will be downloaded from gitlab repository and installed as a cairn component")

  set(FETCHCONTENT_QUIET OFF) # verbose mode for fetchcontent. Comment/uncomment according to your needs.
  
  set(EIGEN_Install ON) 
  FetchContent_Declare(eigen
    GIT_REPOSITORY    https://gitlab.com/libeigen/eigen.git
    GIT_TAG          e67c494cba7180066e73b9f6234d0b2129f1cdf5 #3.4.1 (3.4.0 ne fonctionne pas bien, on ne peut pas désactiver les tests)    
    #GIT_SHALLOW TRUE
    UPDATE_DISCONNECTED TRUE # Do not update git repo at each run
    LOG_CONFIGURE TRUE
    LOG_BUILD TRUE
    LOG_INSTALL TRUE
    )
  
  option(BUILD_TESTING OFF)
  option(EIGEN_BUILD_DOC OFF)
  option(EIGEN_BUILD_PKGCONFIG OFF)
  #option(EIGEN_BUILD_CMAKE_PACKAGE OFF)
  FetchContent_MakeAvailable(eigen)
        
  #set(EIGEN_DIR ${CMAKE_INSTALL_PREFIX} CACHE INTERNAL "")  
  
  #set(CMAKEPACKAGE_INSTALL_DIR
  #  "lib/cmake/eigen3"
  #   PATH "The directory relative to CMAKE_INSTALL_PREFIX where Eigen3Config.cmake is installed"
  #  )
  find_package(Eigen3 REQUIRED NO_MODULE)  
  message(STATUS "Built, installed and used Eigen in ${Eigen3_SOURCE_DIR}.")
else()
    find_package(Eigen3)
  
endif()
target_compile_definitions(${COMPONENT} PRIVATE -DEIGEN_MPL2_ONLY)
