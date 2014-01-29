# == Define: powershell
#
# Runs a PowerShell script.
#
define powershell(
  $content,
  $creates = undef,
  $file_cache_dir = params_lookup('file_cache_dir', 'global'),
) {
  $script_path = "${file_cache_dir}/powershell_${name}.ps1"

  file { $script_path:
    content => $content,
  }

  exec { "ps1-${name}":
    command => "cmd.exe /C powershell.exe -ExecutionPolicy Bypass -Command \"&\" '${script_path}'",
    creates => $creates,
    require => File[$script_path],
  }
}
