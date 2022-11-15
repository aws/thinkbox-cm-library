# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

cmake_policy(VERSION 3.7)

include( CMakeParseArguments )

# Split a path into its component directory names
function( frantic_split_path FILEPATH RESULT )
	string( REGEX MATCHALL "[^/\\\\]+" directories "${FILEPATH}" )
	set( ${RESULT} ${directories} PARENT_SCOPE )
endfunction()

# Add all of the source files matching `TYPEREGEX` into the specified source group `ROOTNAME`
# into a subfilter corresponding to its subdirectory. You can specify a common leading directory
# prefix that will _not_ be made into subfilters with the `DIRPREFIX` optional argument
# TODO: This might work better if we _only_ matched sources which match the `DIRPREFIX`, and left
# anything unmatched alone
function( frantic_auto_source_group SOURCEFILES ROOTNAME TYPEREGEX )
	cmake_parse_arguments( AUTOGRP "" "DIRPREFIX" "" "${ARGN}" )

	foreach( SOURCEFILE ${SOURCEFILES} )
		get_filename_component( FILENAME "${SOURCEFILE}" NAME )
		string( REGEX MATCH "${TYPEREGEX}" FOUND ${FILENAME} )

		if( FOUND )
			frantic_split_path( "${AUTOGRP_DIRPREFIX}" PREFIXDIRS )
			get_filename_component( FILENAME "${SOURCEFILE}" NAME )
			get_filename_component( FILEDIR "${SOURCEFILE}" DIRECTORY )
			frantic_split_path( "${FILEDIR}" directories )

			set( GROUPNAME "${ROOTNAME}" )

			if( directories )
				foreach( prefixDir ${PREFIXDIRS} )
					list( GET directories 0 srcDir )
					if( ${srcDir} STREQUAL "${prefixDir}" )
						list( REMOVE_AT directories 0 )
					else()
						break()
					endif()
				endforeach()
			endif()

			foreach( srcDir ${directories} )
				set( GROUPNAME "${GROUPNAME}\\${srcDir}" )
			endforeach()

			source_group( "${GROUPNAME}" FILES "${SOURCEFILE}" )
		endif()
	endforeach()

endfunction()

# Construct our usual MSVC filter structure
# Specify the root header and source directories with `HEADERDIR` and `SOURCEDIR` respectively
function( frantic_default_source_groups TARGETNAME )

    cmake_parse_arguments( SRCGRP "" "HEADERDIR;SOURCEDIR" "" "${ARGN}" )

    get_target_property( SOURCEFILES ${TARGETNAME} SOURCES )
    frantic_auto_source_group( "${SOURCEFILES}" "Header Files" ".*\\.(h|hh|hpp)$" DIRPREFIX "${SRCGRP_HEADERDIR}" )
    frantic_auto_source_group( "${SOURCEFILES}" "Source Files" ".*\\.(c|cc|cpp)$" DIRPREFIX "${SRCGRP_SOURCEDIR}" )
endfunction()

# Get the Mac OSX version as a simple string. For example, if you are on
# version 10.9.3, it will set the variable to "10.9.3"
function( frantic_get_osx_version OUT_MACOSX_VERSION )

	if( APPLE )
		# detect OS X version
		EXEC_PROGRAM( /usr/bin/sw_vers ARGS -productVersion OUTPUT_VARIABLE MACOSX_VERSION )

		if( "${MACOSX_VERSION}" STREQUAL "" )
			message( FATAL_ERROR "Could not determine OSX version." )
		endif()

		set( ${OUT_MACOSX_VERSION} ${MACOSX_VERSION} PARENT_SCOPE )
	else()
		message( FATAL_ERROR "Attempted to get the OSX version on a non-apple machine" )
	endif()

endfunction()

# Applies some common platform definitions that (I think) we end up using in all our projects
function( frantic_common_platform_setup TARGETNAME )

	if( WIN32 )
		# _USE_MATH_DEFINES : enable math #define symbols, such as M_PI
		# _UNICODE : Set the default character set as UTF-16
		# _CRT_SECURE_NO_WARNINGS : Disable warnings about using 'insecure' C-runtime methods
		target_compile_definitions( ${TARGETNAME} PRIVATE _USE_MATH_DEFINES _UNICODE _CRT_SECURE_NO_WARNINGS )

		# Use multi-core compilation
		set_target_properties( ${TARGETNAME} PROPERTIES COMPILE_FLAGS "/MP" )

		# Enable link-time code generation on release builds
		set_target_properties( ${TARGETNAME} PROPERTIES STATIC_LIBRARY_FLAGS_RELEASE "/LTCG" )
		set_target_properties( ${TARGETNAME} PROPERTIES STATIC_LIBRARY_FLAGS_RELWITHDEBINFO "/LTCG" )

	elseif( APPLE )
		frantic_get_osx_version( MACOSX_VERSION )

		target_compile_definitions( ${TARGETNAME} PRIVATE OSMac_=1 )

		set_target_properties( ${TARGETNAME} PROPERTIES COMPILE_FLAGS "-arch x86_64 -arch i386" )

		if( ${MACOSX_VERSION} VERSION_LESS "10.9" OR XCODE_VERSION VERSION_LESS "6.2" )
			option( USE_CXX11 "Use C++11" OFF )
			option( USE_LIBCXX "Use clang's libc++" OFF )
		else()
			option( USE_CXX11 "Use C++11" ON )
			option( USE_LIBCXX "Use clang's libc++" ON )
		endif()
		if(USE_LIBCXX)
			set_target_properties( ${TARGETNAME} PROPERTIES COMPILE_FLAGS "-stdlib=libc++")
			#Workaround for a bug in libc++ on OS X 10.8
			target_compile_definitions( ${TARGETNAME} PRIVATE BOOST_NO_CXX11_NUMERIC_LIMITS )
		endif()

	elseif( "${CMAKE_SYSTEM}" MATCHES "Linux" )
		option( USE_CXX11 "Use C++11" OFF)
		target_compile_definitions( ${TARGETNAME} PRIVATE LINUX=1 )
		target_compile_definitions( ${TARGETNAME} PRIVATE BOOST_FILESYSTEM_VERSION=3 )

		# Is this used anymore? This should probably be configured from the environment instead
		if( FORCE32 )
			MESSAGE( "Forcing 32-bit build" )
			set_target_properties( ${TARGETNAME} PROPERTIES COMPILE_FLAGS "-m32" )
		endif()

	else()
		message( FATAL_ERROR "Platform ${CMAKE_SYSTEM} not supported" )
	endif()

	if( UNIX )
		target_compile_definitions( ${TARGETNAME} PRIVATE _BOOL REQUIRE_IOSTREAM )
		set_target_properties( ${TARGETNAME} PROPERTIES POSITION_INDEPENDENT_CODE TRUE )
		set_target_properties( ${TARGETNAME} PROPERTIES COMPILE_FLAGS "-pthread" )

		if( USE_CXX11 )
			# Enable C++11 features, disable errors (for Eigen library in FranticDev)
			set_target_properties( ${TARGETNAME} PROPERTIES COMPILE_FLAGS "-std=c++11 -Wno-c++11-narrowing -Wno-reserved-user-defined-literal" )
		endif()
	endif()

endfunction()

# Link to Mac's Core libraries
function( frantic_link_apple_core_libraries TARGETNAME )

	if(APPLE)
		find_library( CORE_FOUNDATION CoreFoundation )
		find_library( CORE_TEXT CoreText)
		find_library( CORE_SERVICES CoreServices )
		target_link_libraries( ${TARGETNAME} ${CORE_FOUNDATION} ${CORE_TEXT} ${CORE_SERVICES} )
	endif()

endfunction()
