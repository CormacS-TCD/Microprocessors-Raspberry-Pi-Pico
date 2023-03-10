# Specify the name of the executable.
add_executable(test_lab05)

# Specify the source files to be compiled.
target_sources(test_lab05 PRIVATE test_lab05.c test_lab05.S)

# Pull in commonly used features.
target_link_libraries(test_lab05 PRIVATE pico_stdlib)

# Create map/bin/hex file etc.
pico_add_extra_outputs(test_lab05)

# Add the URL via pico_set_program_url.
apps_auto_set_url(test_lab05)