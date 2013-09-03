define launchd(
  $content,
  $file_name=$title,
  $type='daemon',
) {
  $plist_path = $type ? {
    'agent'  => "/Library/LaunchAgents",
    'daemon' => "/Library/LaunchDaemons",
    default  => fail("Must set a proper type: daemon or agent."),
  }

  file { "${plist_path}/${file_name}.plist":
    ensure  => present,
    content => $content,
    owner   => "root",
    group   => "wheel",
    mode    => "0644",
  }
}
