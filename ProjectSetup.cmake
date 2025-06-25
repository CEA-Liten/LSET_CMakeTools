#Set main parameters for the cmake project
#-- -- -- -- - CMake project internal variables -- -- -- -- -
include(ProjectVersion)
set(${PROJECT_NAME}_VERSION ${MAJOR_VERSION}.${MINOR_VERSION}.${PATCH_VERSION})

include(FetchContent)

#-- Set include directories that are required by ALL components
#and only those !
#Other includes must be specified to individual targets only.
#Current binary dir, for generated headers.Only at build time !
include_directories($<BUILD_INTERFACE:${CMAKE_BINARY_DIR}>)

#Save date / time into BUILD_TIMESTAMP var
string(TIMESTAMP BUILD_TIMESTAMP)



