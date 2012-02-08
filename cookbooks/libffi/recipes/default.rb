# Compile libffi
util_autotools "libffi" do
  file "libffi-3.0.10.tar.gz"
end

# Move libffi headers. libffi installs its headers in a
# really strange place, so we move them into the standard
# location.
execute "libffi-headers-move" do
  command "mv #{embedded_dir}/lib/libffi-*/include/* #{embedded_dir}/include"
end
