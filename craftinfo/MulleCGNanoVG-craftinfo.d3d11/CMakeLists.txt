cmake_minimum_required( VERSION 3.15...99.99)

project( MulleCGNanoVG-craftinfo NONE)

file( GLOB DEFINITION_DIRS
   definition*
)

if( DEFINITION_DIRS)
   foreach( DIR ${DEFINITION_DIRS} )
      install( DIRECTORY "${DIR}" DESTINATION "share/mulle-craft/MulleCGNanoVG"
               USE_SOURCE_PERMISSIONS
               PATTERN "*._DS_Store" EXCLUDE
      )
   endforeach()
else()
   message( FATAL_ERROR "Empty craftinfo")
endif()
