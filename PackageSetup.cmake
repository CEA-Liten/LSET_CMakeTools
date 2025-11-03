
set(installed_targets ${installed_targets}
  CACHE INTERNAL "List of installed libraries for the project.")


set(ConfigPackageFile ${CMAKE_CURRENT_SOURCE_DIR}/cmake/${PROJECT_NAME}-config.cmake.in)
message("-- ConfigPackageFile: ${ConfigPackageFile}")
if (NOT EXISTS "${ConfigPackageFile}")
	set(ConfigPackageFile ${CMAKE_SOURCE_DIR}/cmake/${PROJECT_NAME}-config.cmake.in)
	message("-- ConfigPackageFile: ${ConfigPackageFile}")
	if (NOT EXISTS "${ConfigPackageFile}")
		message("-- ConfigPackageFile, list: ${CMAKE_MODULE_PATH}")
		foreach (dir IN LISTS CMAKE_MODULE_PATH)
			message("-- ConfigPackageFile, dir: ${dir}")
			if (EXISTS "${dir}/${PROJECT_NAME}-config.cmake.in")
				set(ConfigPackageFile ${dir}/${PROJECT_NAME}-config.cmake.in)
				break()
		endif()
		endforeach()
	endif()
endif()

message("-- ConfigPackageFile: ${ConfigPackageFile}")
set(ConfigPackageLocation  ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME})
# ===== Package configuration file ====
# https://cmake.org/cmake/help/latest/manual/cmake-packages.7.html#creating-packages
# 
include(CMakePackageConfigHelpers)

# Generate ${PROJECT_NAME}-config-version.cmake file.
# Configure <export_config_name>ConfigVersion.cmake common to build and install tree
set(config_version_file ${PROJECT_BINARY_DIR}/${PROJECT_NAME}-config-version.cmake)
write_basic_package_version_file(
  ${config_version_file}
  VERSION ${MAJOR_VERSION}.${MINOR_VERSION}.${PATCH_VERSION}
  COMPATIBILITY ExactVersion
  )

#------------------------------------------------------------------------------
# Export '<PROJECT_NAME>Targets.cmake' for a build tree
export(  
  EXPORT ${PROJECT_NAME}Targets
  FILE "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Targets.cmake"
  NAMESPACE ${PROJECT_NAME}:: 
  )

# Configure '<PROJECT_NAME>Config.cmake' for a build tree
set(build_config ${CMAKE_BINARY_DIR}/${PROJECT_NAME}-config.cmake)
configure_package_config_file(
  ${ConfigPackageFile}
  ${build_config}
  INSTALL_DESTINATION "${PROJECT_BINARY_DIR}"
  )

#------------------------------------------------------------------------------
# Export '<export_config_name>Targets.cmake' for an install tree
#set(CMAKE_INSTALL_PREFIX "\${CMAKE_CURRENT_LIST_DIR}")
install(
  EXPORT ${PROJECT_NAME}Targets
  FILE ${PROJECT_NAME}Targets.cmake
  NAMESPACE ${PROJECT_NAME}:: 
  DESTINATION ${ConfigPackageLocation}
  )

set(install_config ${PROJECT_BINARY_DIR}/CMakeFiles/${PROJECT_NAME}-config.cmake)
configure_package_config_file(
  ${ConfigPackageFile}
  ${install_config}
  INSTALL_DESTINATION ${ConfigPackageLocation}  
  )

# Install config files
install(
  FILES ${config_version_file} ${install_config}
  DESTINATION "${ConfigPackageLocation}"
  )



#set(CMAKE_INSTALL_PREFIX "\${CMAKE_CURRENT_LIST_DIR}")
