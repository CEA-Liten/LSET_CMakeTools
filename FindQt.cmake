
# default qt package
if (NOT Qt_FIND_COMPONENTS)
    set(Qt_FIND_COMPONENTS Core)    
endif()

# find qt package
# if cmake failed to find Qt5Core configuration file, set path manually:    
foreach(package ${Qt_FIND_COMPONENTS})
    message("-- Qt package for ${COMPONENT},  ${package}")
    find_package(Qt5 COMPONENTS ${package} REQUIRED)
    string(TOUPPER ${package} UPPERPACKAGE)
    set(QT_${UPPERPACKAGE}_TARGET Qt5::${package})
    
    if ("${package}" STREQUAL "LinguistTools" )
    else()
        target_link_libraries(${COMPONENT} PRIVATE ${QT_${UPPERPACKAGE}_TARGET})
    endif()
endforeach()
    
# instruct CMake to run moc automatically when needed.
#set(CMAKE_AUTOMOC ON)
set_property(TARGET ${COMPONENT} PROPERTY AUTOMOC ON)
