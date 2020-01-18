##########################################################################
# "THE ANY BEVERAGE-WARE LICENSE" (Revision 42 - based on beer-ware
# license):
# <dev@layer128.net> wrote this file. As long as you retain this notice
# you can do whatever you want with this stuff. If we meet some day, and
# you think this stuff is worth it, you can buy me a be(ve)er(age) in
# return. (I don't like beer much.)
#
# Matthias Kleemann
##########################################################################

##########################################################################
# The toolchain requires some variables set.
#
# AVR_MCU (default: atmega8)
#     the type of AVR the application is built for
# AVR_L_FUSE (NO DEFAULT)
#     the LOW fuse value for the MCU used
# AVR_H_FUSE (NO DEFAULT)
#     the HIGH fuse value for the MCU used
# AVR_UPLOADTOOL (default: avrdude)
#     the application used to upload to the MCU
#     NOTE: The toolchain is currently quite specific about
#           the commands used, so it needs tweaking.
# AVR_UPLOADTOOL_PORT (default: usb)
#     the port used for the upload tool, e.g. usb
# AVR_PROGRAMMER (default: avrispmkII)
#     the programmer hardware used, e.g. avrispmkII
##########################################################################

set(DIR_OF_GENERIC_GCC_AVR_CMAKE ${CMAKE_CURRENT_LIST_DIR})

##########################################################################
# options
##########################################################################
option(WITH_MCU "Add the mCU type to the target file name." ON)

##########################################################################
# executables in use
##########################################################################
find_program(AVR_CC avr-gcc)
find_program(AVR_CXX avr-g++)
find_program(AVR_OBJCOPY avr-objcopy)
find_program(AVR_SIZE_TOOL avr-size)
find_program(AVR_OBJDUMP avr-objdump)

##########################################################################
# toolchain starts with defining mandatory variables
##########################################################################
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR avr)
set(CMAKE_C_COMPILER ${AVR_CC})
set(CMAKE_CXX_COMPILER ${AVR_CXX})


##########################################################################
# Identification
##########################################################################
set(AVR 1)

##########################################################################
# some necessary tools and variables for AVR builds, which may not
# defined yet
# - AVR_UPLOADTOOL
# - AVR_UPLOADTOOL_PORT
# - AVR_PROGRAMMER
# - AVR_MCU
# - AVR_SIZE_ARGS
##########################################################################

# default upload tool
if(NOT AVR_UPLOADTOOL)
    set(
            AVR_UPLOADTOOL avrdude
            CACHE STRING "Set default upload tool: avrdude"
    )
    find_program(AVR_UPLOADTOOL avrdude)
endif(NOT AVR_UPLOADTOOL)

# default upload tool port
if(NOT AVR_UPLOADTOOL_PORT)
    set(
            AVR_UPLOADTOOL_PORT usb
            CACHE STRING "Set default upload tool port: usb"
    )
endif(NOT AVR_UPLOADTOOL_PORT)

# default programmer (hardware)
if(NOT AVR_PROGRAMMER)
    set(
            AVR_PROGRAMMER avrispmkII
            CACHE STRING "Set default programmer hardware model: avrispmkII"
    )
endif(NOT AVR_PROGRAMMER)

# default MCU (chip)
if(NOT AVR_MCU)
    set(
            AVR_MCU atmega8
            CACHE STRING "Set default MCU: atmega8 (see 'avr-gcc --target-help' for valid values)"
    )
endif(NOT AVR_MCU)

#default avr-size args
if(NOT AVR_SIZE_ARGS)
    if(APPLE)
        set(AVR_SIZE_ARGS -B)
    else(APPLE)
        execute_process(COMMAND
                ${AVR_SIZE_TOOL} -C;--mcu=${AVR_MCU} somefile.out
                ERROR_VARIABLE avr_size_check_result)
        # Error should contain the file name => params are ok
        if(avr_size_check_result MATCHES ".*somefile\\.out.*")
            set(AVR_SIZE_ARGS -C;--mcu=${AVR_MCU})
        else(avr_size_check_result MATCHES ".*somefile\\.out.*")
            set(AVR_SIZE_ARGS -B)
        endif(avr_size_check_result MATCHES ".*somefile\\.out.*")
    endif(APPLE)
endif(NOT AVR_SIZE_ARGS)

# prepare base flags for upload tool
set(AVR_UPLOADTOOL_BASE_OPTIONS "-p ${AVR_MCU} -c ${AVR_PROGRAMMER} -V")

# use AVR_UPLOADTOOL_BAUDRATE as baudrate for upload tool (if defined)
if(AVR_UPLOADTOOL_BAUDRATE)
    set(AVR_UPLOADTOOL_BASE_OPTIONS "${AVR_UPLOADTOOL_BASE_OPTIONS} -b ${AVR_UPLOADTOOL_BAUDRATE}")
endif()

##########################################################################
# check build types:
# - Debug
# - Release
# - RelWithDebInfo
#
# Release is chosen, because of some optimized functions in the
# AVR toolchain, e.g. _delay_ms().
##########################################################################
if(NOT ((CMAKE_BUILD_TYPE MATCHES Release) OR
(CMAKE_BUILD_TYPE MATCHES RelWithDebInfo) OR
(CMAKE_BUILD_TYPE MATCHES Debug) OR
(CMAKE_BUILD_TYPE MATCHES MinSizeRel)))
    set(
            CMAKE_BUILD_TYPE Release
            CACHE STRING "Choose cmake build type: Debug Release RelWithDebInfo MinSizeRel"
            FORCE
    )
endif(NOT ((CMAKE_BUILD_TYPE MATCHES Release) OR
(CMAKE_BUILD_TYPE MATCHES RelWithDebInfo) OR
(CMAKE_BUILD_TYPE MATCHES Debug) OR
(CMAKE_BUILD_TYPE MATCHES MinSizeRel)))



##########################################################################

# Useful for cross compiling, skips automatic compiler tests.
set(CMAKE_TRY_COMPILE_TARGET_TYPE "STATIC_LIBRARY")
##########################################################################
# some cmake cross-compile necessities
##########################################################################
if(DEFINED ENV{AVR_FIND_ROOT_PATH})
    set(CMAKE_FIND_ROOT_PATH $ENV{AVR_FIND_ROOT_PATH})
else(DEFINED ENV{AVR_FIND_ROOT_PATH})
    if(EXISTS "/opt/local/avr")
        set(CMAKE_FIND_ROOT_PATH "/opt/local/avr")
    elseif(EXISTS "/usr/avr")
        set(CMAKE_FIND_ROOT_PATH "/usr/avr")
    elseif(EXISTS "/usr/lib/avr")
        set(CMAKE_FIND_ROOT_PATH "/usr/lib/avr")
    elseif(EXISTS "/usr/local/CrossPack-AVR")
        set(CMAKE_FIND_ROOT_PATH "/usr/local/CrossPack-AVR")
    else(EXISTS "/opt/local/avr")
        message(FATAL_ERROR "Please set AVR_FIND_ROOT_PATH in your environment.")
    endif(EXISTS "/opt/local/avr")
endif(DEFINED ENV{AVR_FIND_ROOT_PATH})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
# not added automatically, since CMAKE_SYSTEM_NAME is "generic"
set(CMAKE_SYSTEM_INCLUDE_PATH "${CMAKE_FIND_ROOT_PATH}/include")
set(CMAKE_SYSTEM_LIBRARY_PATH "${CMAKE_FIND_ROOT_PATH}/lib")

if(NOT IS_DIRECTORY "${CMAKE_SYSTEM_INCLUDE_PATH}" OR NOT EXISTS "${CMAKE_SYSTEM_INCLUDE_PATH}/avr/eeprom.h")
    message(FATAL_ERROR "Could not find required avr header files in: ${CMAKE_SYSTEM_INCLUDE_PATH}. Did you install arv-libc?")
endif(NOT IS_DIRECTORY "${CMAKE_SYSTEM_INCLUDE_PATH}" OR NOT EXISTS "${CMAKE_SYSTEM_INCLUDE_PATH}/avr/eeprom.h")

# Default compiler options
add_definitions("-DF_CPU=${MCU_SPEED}")

##########################################################################
# target file name add-on
##########################################################################
if(WITH_MCU)
    set(MCU_TYPE_FOR_FILENAME "-${AVR_MCU}")
else(WITH_MCU)
    set(MCU_TYPE_FOR_FILENAME "")
endif(WITH_MCU)


##########################################################################
# Fuses
##########################################################################

set(uploadscript_in "uploadscript.sh.in")
# Set MCU_FUSES_SIZE = <number of fuse bytes for this mcu>
execute_process(COMMAND
        sh "-c" "echo '#include <avr/io.h>' | ${AVR_CC} -I${CMAKE_SYSTEM_INCLUDE_PATH} -mmcu=${AVR_MCU} - -E -dM | grep FUSE_MEMORY_SIZE | sed 's=#define FUSE_MEMORY_SIZE =='"
        OUTPUT_VARIABLE MCU_FUSES_SIZE OUTPUT_STRIP_TRAILING_WHITESPACE)

if(NOT (MCU_FUSES_SIZE MATCHES 2) AND (NOT (MCU_FUSES_SIZE MATCHES 3)))
    message(FATAL_ERROR "Detected fuses size ${MCU_FUSES_SIZE} is not supported.")
endif(NOT (MCU_FUSES_SIZE MATCHES 2) AND (NOT (MCU_FUSES_SIZE MATCHES 3)))


##########################################################################
# add_avr_executable
# - IN_VAR: EXECUTABLE_NAME
#
# Creates targets and dependencies for AVR toolchain, building an
# executable. Calls add_executable with ELF file as target name, so
# any link dependencies need to be using that target, e.g. for
# target_link_libraries(<EXECUTABLE_NAME>-${AVR_MCU}.elf ...).
##########################################################################
function(add_avr_executable EXECUTABLE_NAME)

   if(NOT ARGN)
      message(FATAL_ERROR "No source files given for ${EXECUTABLE_NAME}.")
   endif(NOT ARGN)

   # set file names
   set(elf_file ${EXECUTABLE_NAME}${MCU_TYPE_FOR_FILENAME}.elf)
   set(hex_file ${EXECUTABLE_NAME}${MCU_TYPE_FOR_FILENAME}.hex)
   set(lst_file ${EXECUTABLE_NAME}${MCU_TYPE_FOR_FILENAME}.lst)
   set(map_file ${EXECUTABLE_NAME}${MCU_TYPE_FOR_FILENAME}.map)
   set(fuses_file ${EXECUTABLE_NAME}${MCU_TYPE_FOR_FILENAME}-fuses.bin)
   set(lfuse_file ${EXECUTABLE_NAME}${MCU_TYPE_FOR_FILENAME}-lfuse.bin)
   set(hfuse_file ${EXECUTABLE_NAME}${MCU_TYPE_FOR_FILENAME}-hfuse.bin)
   if(MCU_FUSES_SIZE GREATER 2)
     set(efuse_file ${EXECUTABLE_NAME}${MCU_TYPE_FOR_FILENAME}-efuse.bin)
   endif(MCU_FUSES_SIZE GREATER 2)
   set(uploadscript_file ${EXECUTABLE_NAME}${MCU_TYPE_FOR_FILENAME}-upload.sh)
   set(eeprom_image ${EXECUTABLE_NAME}${MCU_TYPE_FOR_FILENAME}-eeprom.hex)

   # elf file
   add_executable(${elf_file} EXCLUDE_FROM_ALL ${ARGN})

   set_target_properties(
      ${elf_file}
      PROPERTIES
         COMPILE_FLAGS "-mmcu=${AVR_MCU}"
         LINK_FLAGS "-mmcu=${AVR_MCU} -Wl,--gc-sections -mrelax -Wl,-Map,${map_file}"
   )

   add_custom_command(
      OUTPUT ${hex_file}
      COMMAND
         ${AVR_OBJCOPY} -j .text -j .data -O ihex ${elf_file} ${hex_file}
      COMMAND
         ${AVR_SIZE_TOOL} ${AVR_SIZE_ARGS} ${elf_file}
      DEPENDS ${elf_file}
   )

   add_custom_command(
      OUTPUT ${lst_file}
      COMMAND
         ${AVR_OBJDUMP} -d ${elf_file} > ${lst_file}
      DEPENDS ${elf_file}
   )

   # eeprom
   add_custom_command(
      OUTPUT ${eeprom_image}
      COMMAND
         ${AVR_OBJCOPY} -j .eeprom --set-section-flags=.eeprom=alloc,load
            --change-section-lma .eeprom=0 --no-change-warnings
            -O ihex ${elf_file} ${eeprom_image}
      DEPENDS ${elf_file}
   )

   add_custom_command(
      OUTPUT ${fuses_file}
      COMMAND
         ${AVR_OBJCOPY} --only-section .fuse -O binary ${elf_file} ${fuses_file}
      DEPENDS ${elf_file}
   )

   add_custom_target(
           ${EXECUTABLE_NAME}
           ALL
           DEPENDS ${hex_file} ${lst_file} ${eeprom_image}
   )

   add_custom_command(
      OUTPUT ${lfuse_file}
      COMMAND
         dd skip=0 count=1 bs=1 if=${fuses_file} of=${lfuse_file}
      DEPENDS ${fuses_file}
   )
   add_custom_target(${EXECUTABLE_NAME}-lfuse DEPENDS ${lfuse_file})
   add_dependencies(${EXECUTABLE_NAME} ${EXECUTABLE_NAME}-lfuse)
   add_custom_command(
      OUTPUT ${hfuse_file}
      COMMAND
         dd skip=1 count=1 bs=1 if=${fuses_file} of=${hfuse_file}
      DEPENDS ${fuses_file}
   )
   add_custom_target(${EXECUTABLE_NAME}-hfuse DEPENDS ${hfuse_file})
   add_dependencies(${EXECUTABLE_NAME} ${EXECUTABLE_NAME}-hfuse)
   if(MCU_FUSES_SIZE GREATER 2)
       add_custom_command(
          OUTPUT ${efuse_file}
          COMMAND
             dd skip=2 count=1 bs=1 if=${fuses_file} of=${efuse_file}
          DEPENDS ${fuses_file}
       )
       add_custom_target(${EXECUTABLE_NAME}-efuse DEPENDS ${efuse_file})
       add_dependencies(${EXECUTABLE_NAME} ${EXECUTABLE_NAME}-efuse)
   endif(MCU_FUSES_SIZE GREATER 2)

   set_target_properties(
      ${EXECUTABLE_NAME}
      PROPERTIES
         OUTPUT_NAME "${elf_file}"
   )

   # clean
   get_directory_property(clean_files ADDITIONAL_MAKE_CLEAN_FILES)
   set_directory_properties(
      PROPERTIES
         ADDITIONAL_MAKE_CLEAN_FILES "${map_file}"
   )

   # upload - with avrdude
   set(command_upload_flash "${AVR_UPLOADTOOL} ${AVR_UPLOADTOOL_BASE_OPTIONS} ${AVR_UPLOADTOOL_OPTIONS} \
           -U flash:w:${hex_file} \
           -P ${AVR_UPLOADTOOL_PORT}")
   add_custom_target(
      upload_${EXECUTABLE_NAME}
      sh -c "${command_upload_flash}"
      DEPENDS ${hex_file}
      COMMENT "Uploading ${hex_file} to ${AVR_MCU} using ${AVR_PROGRAMMER}"
   )

   # upload eeprom only - with avrdude
   # see also bug http://savannah.nongnu.org/bugs/?40142
   set(command_upload_eeprom "${AVR_UPLOADTOOL} ${AVR_UPLOADTOOL_BASE_OPTIONS} ${AVR_UPLOADTOOL_OPTIONS} \
           -U eeprom:w:${eeprom_image} \
           -P ${AVR_UPLOADTOOL_PORT}")
   add_custom_target(
      upload_${EXECUTABLE_NAME}_eeprom
      sh -c "${command_upload_eeprom}"
      DEPENDS ${eeprom_image}
      COMMENT "Uploading ${eeprom_image} to ${AVR_MCU} using ${AVR_PROGRAMMER}"
   )

   if (MCU_FUSES_SIZE GREATER 2)
       set(command_upload_fuses
               "${AVR_UPLOADTOOL} ${AVR_UPLOADTOOL_BASE_OPTIONS} ${AVR_UPLOADTOOL_OPTIONS} -P ${AVR_UPLOADTOOL_PORT} \
               -U hfuse:w:${hfuse_file}:r -U lfuse:w:${lfuse_file}:r -U efuse:w:${efuse_file}:r")
       set(command_upload_fuses_deps ${hfuse_file} ${lfuse_file} ${efuse_file})
   else (MCU_FUSES_SIZE GREATER 2)
       set(command_upload_fuses
               "${AVR_UPLOADTOOL} ${AVR_UPLOADTOOL_BASE_OPTIONS} ${AVR_UPLOADTOOL_OPTIONS} -P ${AVR_UPLOADTOOL_PORT} \
               -U hfuse:w:${hfuse_file}:r -U lfuse:w:${lfuse_file}:r")
       set(command_upload_fuses_deps ${hfuse_file} ${lfuse_file})
   endif (MCU_FUSES_SIZE GREATER 2)

   add_custom_target(
      upload_${EXECUTABLE_NAME}_fuses
      sh -c "${command_upload_fuses}"
      DEPENDS ${command_upload_fuses_deps}
      COMMENT "Setting fuses for ${AVR_MCU} using ${AVR_PROGRAMMER}"
   )

   # disassemble
   add_custom_target(
      disassemble_${EXECUTABLE_NAME}
      ${AVR_OBJDUMP} -h -S ${elf_file} > ${EXECUTABLE_NAME}.lst
      DEPENDS ${elf_file}
   )

   configure_file(${DIR_OF_GENERIC_GCC_AVR_CMAKE}/uploadscript.sh.in ${uploadscript_file})

endfunction(add_avr_executable)


##########################################################################
# add_avr_library
# - IN_VAR: LIBRARY_NAME
#
# Calls add_library with an optionally concatenated name
# <LIBRARY_NAME>${MCU_TYPE_FOR_FILENAME}.
# This needs to be used for linking against the library, e.g. calling
# target_link_libraries(...).
##########################################################################
function(add_avr_library LIBRARY_NAME)
    if(NOT ARGN)
        message(FATAL_ERROR "No source files given for ${LIBRARY_NAME}.")
    endif(NOT ARGN)

    set(lib_file ${LIBRARY_NAME}${MCU_TYPE_FOR_FILENAME})

    add_library(${lib_file} STATIC ${ARGN})

    set_target_properties(
            ${lib_file}
            PROPERTIES
            COMPILE_FLAGS "-mmcu=${AVR_MCU}"
            OUTPUT_NAME "${lib_file}"
    )

    if(NOT TARGET ${LIBRARY_NAME})
        add_custom_target(
                ${LIBRARY_NAME}
                ALL
                DEPENDS ${lib_file}
        )

        set_target_properties(
                ${LIBRARY_NAME}
                PROPERTIES
                OUTPUT_NAME "${lib_file}"
        )
    endif(NOT TARGET ${LIBRARY_NAME})

endfunction(add_avr_library)

##########################################################################
# avr_target_link_libraries
# - IN_VAR: EXECUTABLE_TARGET
# - ARGN  : targets and files to link to
#
# Calls target_link_libraries with AVR target names (concatenation,
# extensions and so on.
##########################################################################
function(avr_target_link_libraries EXECUTABLE_TARGET)
   if(NOT ARGN)
      message(FATAL_ERROR "Nothing to link to ${EXECUTABLE_TARGET}.")
   endif(NOT ARGN)

   get_target_property(TARGET_LIST ${EXECUTABLE_TARGET} OUTPUT_NAME)

   foreach(TGT ${ARGN})
      if(TARGET ${TGT})
         get_target_property(ARG_NAME ${TGT} OUTPUT_NAME)
         list(APPEND NON_TARGET_LIST ${ARG_NAME})
      else(TARGET ${TGT})
         list(APPEND NON_TARGET_LIST ${TGT})
      endif(TARGET ${TGT})
   endforeach(TGT ${ARGN})

   target_link_libraries(${TARGET_LIST} ${NON_TARGET_LIST})
endfunction(avr_target_link_libraries EXECUTABLE_TARGET)

##########################################################################
# avr_target_include_directories
#
# Calls target_include_directories with AVR target names
##########################################################################

function(avr_target_include_directories EXECUTABLE_TARGET)
    if(NOT ARGN)
        message(FATAL_ERROR "No include directories to add to ${EXECUTABLE_TARGET}.")
    endif()

    get_target_property(TARGET_LIST ${EXECUTABLE_TARGET} OUTPUT_NAME)
    set(extra_args ${ARGN})

    target_include_directories(${TARGET_LIST} ${extra_args})
endfunction()

##########################################################################
# avr_target_compile_definitions
#
# Calls target_compile_definitions with AVR target names
##########################################################################

function(avr_target_compile_definitions EXECUTABLE_TARGET)
    if(NOT ARGN)
        message(FATAL_ERROR "No compile definitions to add to ${EXECUTABLE_TARGET}.")
    endif()

    get_target_property(TARGET_LIST ${EXECUTABLE_TARGET} OUTPUT_NAME)
    set(extra_args ${ARGN})

   target_compile_definitions(${TARGET_LIST} ${extra_args})
endfunction()

function(avr_generate_fixed_targets)
   # get status
   add_custom_target(
      get_status
      ${AVR_UPLOADTOOL} ${AVR_UPLOADTOOL_BASE_OPTIONS} -P ${AVR_UPLOADTOOL_PORT} -n -v
      COMMENT "Get status from ${AVR_MCU}"
   )
   
   # get fuses
   add_custom_target(
      get_fuses
      ${AVR_UPLOADTOOL} ${AVR_UPLOADTOOL_BASE_OPTIONS} -P ${AVR_UPLOADTOOL_PORT} -n
         -U lfuse:r:-:b
         -U hfuse:r:-:b
      COMMENT "Get fuses from ${AVR_MCU}"
   )
   
   # set fuses
   add_custom_target(
      set_fuses
      ${AVR_UPLOADTOOL} ${AVR_UPLOADTOOL_BASE_OPTIONS} -P ${AVR_UPLOADTOOL_PORT}
         -U lfuse:w:${AVR_L_FUSE}:m
         -U hfuse:w:${AVR_H_FUSE}:m
         COMMENT "Setup: High Fuse: ${AVR_H_FUSE} Low Fuse: ${AVR_L_FUSE}"
   )
   
   # get oscillator calibration
   add_custom_target(
      get_calibration
         ${AVR_UPLOADTOOL} ${AVR_UPLOADTOOL_BASE_OPTIONS} -P ${AVR_UPLOADTOOL_PORT}
         -U calibration:r:${AVR_MCU}_calib.tmp:r
         COMMENT "Write calibration status of internal oscillator to ${AVR_MCU}_calib.tmp."
   )
   
   # set oscillator calibration
   add_custom_target(
      set_calibration
      ${AVR_UPLOADTOOL} ${AVR_UPLOADTOOL_BASE_OPTIONS} -P ${AVR_UPLOADTOOL_PORT}
         -U calibration:w:${AVR_MCU}_calib.hex
         COMMENT "Program calibration status of internal oscillator from ${AVR_MCU}_calib.hex."
   )
endfunction()

