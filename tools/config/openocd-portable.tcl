# Resolve nested configuration imports only from the bundled scripts directory.
set _dt_scripts [file normalize [file join [file dirname [info script]] .. xpack-openocd openocd scripts]]
set _dt_scripts [string map {\\ /} $_dt_scripts]
proc find {filename} {
    global _dt_scripts
    set path [file normalize [file join $_dt_scripts $filename]]
    set path [string map {\\ /} $path]
    if {[string first [string tolower "$_dt_scripts/"] [string tolower $path]] != 0} {
        error "OpenOCD dependency outside bundled scripts: $filename"
    }
    if {![file isfile $path]} {
        error "Missing bundled OpenOCD script: $filename"
    }
    return $path
}
