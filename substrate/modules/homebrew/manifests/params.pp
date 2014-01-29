# == Class: homebrew::params
#
# This is a parameter farm for homebrew.
#
class homebrew::params {
  $user = params_lookup('user')

  if !$test {
    if $user == '' {
      fail("You must set a homebrew user.")
    }
  }
}
