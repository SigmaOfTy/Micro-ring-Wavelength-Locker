#*****************************************************************************************
# Vivado (TM) v2025.1 (64-bit)
#
# rebuild_project.tcl: Tcl script for re-creating project 'MicroringWavelengthLocker'
#
#*****************************************************************************************

# Set the reference directory for source file relative paths (by default the value is script directory path)
set origin_dir "."

# Use origin directory path location variable, if specified in the tcl shell
if { [info exists ::origin_dir_loc] } {
  set origin_dir $::origin_dir_loc
}

# Set the project name
set _xil_proj_name_ "MicroringWavelengthLocker"

# Use project name variable, if specified in the tcl shell
if { [info exists ::user_project_name] } {
  set _xil_proj_name_ $::user_project_name
}

variable script_file
set script_file "rebuild_project.tcl"

# Help information for this script
proc print_help {} {
  variable script_file
  puts "\nDescription:"
  puts "Recreate a Vivado project from this script."
  puts "Syntax:"
  puts "$script_file"
  puts "$script_file -tclargs \[--origin_dir <path>\]"
  puts "$script_file -tclargs \[--project_name <name>\]"
  puts "$script_file -tclargs \[--help\]\n"
  exit 0
}

if { $::argc > 0 } {
  for {set i 0} {$i < $::argc} {incr i} {
    set option [string trim [lindex $::argv $i]]
    switch -regexp -- $option {
      "--origin_dir"   { incr i; set origin_dir [lindex $::argv $i] }
      "--project_name" { incr i; set _xil_proj_name_ [lindex $::argv $i] }
      "--help"         { print_help }
      default {
        if { [regexp {^-} $option] } {
          puts "ERROR: Unknown option '$option' specified.\n"
          return 1
        }
      }
    }
  }
}

# Check file required for this script exists
proc checkRequiredFiles { origin_dir} {
  set status true
  set files [list \
 "[file normalize "$origin_dir/src/dac_sdm_driver.v"]"\
 "[file normalize "$origin_dir/src/interpolation_filter.v/fir_stage1.v"]"\
 "[file normalize "$origin_dir/src/interpolation_filter.v/fir_stage2.v"]"\
 "[file normalize "$origin_dir/src/interpolation_filter.v/interpolation_top.v"]"\
 "[file normalize "$origin_dir/src/sigma_delata/sdm_cifb_3rd_4bit.v"]"\
 "[file normalize "$origin_dir/src/FPGA_TOP_DAC.v"]"\
 "[file normalize "$origin_dir/src/FPGA_top.v"]"\
 "[file normalize "$origin_dir/src/interpolation_filter.v/fpga_verification_top.v"]"\
 "[file normalize "$origin_dir/src/system_top.v"]"\
 "[file normalize "$origin_dir/src/interpolation_filter.v/repeat_16x.v"]"\
 "[file normalize "$origin_dir/src/data_sin/din_fixed.coe"]"\
 "[file normalize "$origin_dir/src/ip/blk_mem_gen_0/blk_mem_gen_0.xci"]"\
 "[file normalize "$origin_dir/src/ip/ila_0/ila_0.xci"]"\
 "[file normalize "$origin_dir/src/ip/clk_wiz_0/clk_wiz_0.xci"]"\
 "[file normalize "$origin_dir/src/xdc/phy.xdc"]"\
  ]
  foreach ifile $files {
    if { ![file isfile $ifile] } {
      puts " Could not find remote file $ifile "
      set status false
    }
  }

  return $status
}

# Check for paths and files needed for project creation
set validate_required 1
if { $validate_required } {
  if { [checkRequiredFiles $origin_dir] } {
    puts "Tcl file $script_file is valid. All files required for project creation is accesable. "
  } else {
    puts "Tcl file $script_file is not valid. Not all files required for project creation is accesable. "
    return
  }
}

# Create project
# ----------------------------------------------------------------------------------
# 修改点：确保创建 project 文件夹，并将工程指定生成在该目录下
file mkdir ./project
create_project ${_xil_proj_name_} ./project -part xc7z020clg400-2 -force
# ----------------------------------------------------------------------------------

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Set project properties
set obj [current_project]
set_property -name "default_lib" -value "xil_defaultlib" -objects $obj
set_property -name "enable_resource_estimation" -value "0" -objects $obj
set_property -name "enable_vhdl_2008" -value "1" -objects $obj
set_property -name "ip_cache_permissions" -value "read write" -objects $obj
set_property -name "ip_output_repo" -value "$proj_dir/${_xil_proj_name_}.cache/ip" -objects $obj
set_property -name "mem.enable_memory_map_generation" -value "1" -objects $obj
set_property -name "part" -value "xc7z020clg400-2" -objects $obj
set_property -name "revised_directory_structure" -value "1" -objects $obj
set_property -name "sim.central_dir" -value "$proj_dir/${_xil_proj_name_}.ip_user_files" -objects $obj
set_property -name "sim.ip.auto_export_scripts" -value "1" -objects $obj
set_property -name "simulator_language" -value "Mixed" -objects $obj
set_property -name "sim_compile_state" -value "1" -objects $obj
set_property -name "use_inline_hdl_ip" -value "1" -objects $obj
set_property -name "xpm_libraries" -value "XPM_CDC XPM_MEMORY" -objects $obj

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Set 'sources_1' fileset object
set obj [get_filesets sources_1]
# ----------------------------------------------------------------------------------
# 修改点：使用相对路径 $origin_dir/src/...
set files [list \
 [file normalize "${origin_dir}/src/dac_sdm_driver.v"] \
 [file normalize "${origin_dir}/src/interpolation_filter.v/fir_stage1.v"] \
 [file normalize "${origin_dir}/src/interpolation_filter.v/fir_stage2.v"] \
 [file normalize "${origin_dir}/src/interpolation_filter.v/interpolation_top.v"] \
 [file normalize "${origin_dir}/src/sigma_delata/sdm_cifb_3rd_4bit.v"] \
 [file normalize "${origin_dir}/src/FPGA_TOP_DAC.v"] \
 [file normalize "${origin_dir}/src/FPGA_top.v"] \
 [file normalize "${origin_dir}/src/interpolation_filter.v/fpga_verification_top.v"] \
 [file normalize "${origin_dir}/src/system_top.v"] \
 [file normalize "${origin_dir}/src/interpolation_filter.v/repeat_16x.v"] \
 [file normalize "${origin_dir}/src/data_sin/din_fixed.coe"] \
]
# ----------------------------------------------------------------------------------
add_files -norecurse -fileset $obj $files

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "dataflow_viewer_settings" -value "min_width=16" -objects $obj
set_property -name "top" -value "FPGA_TOP_DAC" -objects $obj
set_property -name "top_auto_set" -value "0" -objects $obj

# Add IP Cores
set obj [get_filesets sources_1]
set files [list \
 [file normalize "${origin_dir}/src/ip/blk_mem_gen_0/blk_mem_gen_0.xci"] \
]
add_files -norecurse -fileset $obj $files

set obj [get_filesets sources_1]
set files [list \
 [file normalize "${origin_dir}/src/ip/ila_0/ila_0.xci"] \
]
add_files -norecurse -fileset $obj $files

set obj [get_filesets sources_1]
set files [list \
 [file normalize "${origin_dir}/src/ip/clk_wiz_0/clk_wiz_0.xci"] \
]
add_files -norecurse -fileset $obj $files

# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

# Set 'constrs_1' fileset object
set obj [get_filesets constrs_1]

# Add/Import constrs file and set constrs file properties
set file "[file normalize "$origin_dir/src/xdc/phy.xdc"]"
set file_added [add_files -norecurse -fileset $obj [list $file]]
set file "$origin_dir/src/xdc/phy.xdc"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
set_property -name "file_type" -value "XDC" -objects $file_obj

# Set 'constrs_1' fileset properties
set obj [get_filesets constrs_1]
set_property -name "target_part" -value "xc7z020clg400-2" -objects $obj

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

# Set 'sim_1' fileset properties
set obj [get_filesets sim_1]
set_property -name "sim_wrapper_top" -value "1" -objects $obj
set_property -name "top" -value "FPGA_TOP_DAC" -objects $obj
set_property -name "top_lib" -value "xil_defaultlib" -objects $obj

# Create 'utils_1' fileset (if not found)
if {[string equal [get_filesets -quiet utils_1] ""]} {
  create_fileset -utils_utils_1
}
# 注意：已删除对旧 DCP 文件的引用，因为 gitignore 忽略了 project 目录，队友不会有那个文件

# Create 'synth_1' run (if not found)
if {[string equal [get_runs -quiet synth_1] ""]} {
    create_run -name synth_1 -part xc7z020clg400-2 -flow {Vivado Synthesis 2025} -strategy "Vivado Synthesis Defaults" -report_strategy {No Reports} -constrset constrs_1
} else {
  set_property strategy "Vivado Synthesis Defaults" [get_runs synth_1]
  set_property flow "Vivado Synthesis 2025" [get_runs synth_1]
}
set obj [get_runs synth_1]
set_property set_report_strategy_name 1 $obj
set_property report_strategy {Vivado Synthesis Default Reports} $obj
set_property set_report_strategy_name 0 $obj

# set the current synth run
current_run -synthesis [get_runs synth_1]

# Create 'impl_1' run (if not found)
if {[string equal [get_runs -quiet impl_1] ""]} {
    create_run -name impl_1 -part xc7z020clg400-2 -flow {Vivado Implementation 2025} -strategy "Vivado Implementation Defaults" -report_strategy {No Reports} -constrset constrs_1 -parent_run synth_1
} else {
  set_property strategy "Vivado Implementation Defaults" [get_runs impl_1]
  set_property flow "Vivado Implementation 2025" [get_runs impl_1]
}
set obj [get_runs impl_1]
set_property set_report_strategy_name 1 $obj
set_property report_strategy {Vivado Implementation Default Reports} $obj
set_property set_report_strategy_name 0 $obj

# set the current impl run
current_run -implementation [get_runs impl_1]

puts "INFO: Project created:${_xil_proj_name_} in ./project directory"
