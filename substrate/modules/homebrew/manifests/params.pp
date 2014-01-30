# == Class: homebrew::params
#
# This is a parameter farm for homebrew.
#
class homebrew::params {
  $user = $param_homebrew_user

  if !$test {
    if $user == '' {
      fail("You must set a homebrew user.")
    }
  }
}
