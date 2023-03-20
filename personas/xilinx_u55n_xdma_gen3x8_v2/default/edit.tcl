set bd [lindex $argv 0]
set script_path [file dirname [file normalize [info script]]]
set project_path [file normalize ${script_path}/../../../]

create_project -in_memory -part xcu55n-fsvh2892-2L-e
set_property source_mgmt_mode All [current_project]

set_property IP_REPO_PATHS ${project_path}/ [current_fileset]
update_ip_catalog -rebuild

proc commit {} {
    validate_bd_design
    save_bd_design
    set bd [current_bd_design]
    puts "Writing to: $::script_path/${bd}.bd"
    file copy -force ./${bd}/${bd}.bd $::script_path/
}

file mkdir ./user/
file copy ${script_path}/user.bd ./user/user.bd
read_bd ./user/user.bd

start_gui
