#!/usr/bin/env bash

function key_exit() {
    echo "Press any key to exit."
    read
    exit $1
}

# Collect the directories and files to remove
my_files=""
my_files="$my_files /Applications/vagrant"
my_files="$my_files /usr/bin/vagrant"

# Print the files that will be removed
echo "The following files and directories will be removed:"
for file in $my_files; do
    echo "    $file"
done

echo ""
echo "Do you wish to uninstall Vagrant (Yes/No)?"
read my_answer
if [ "$my_answer" != "Yes" ]; then
    echo "Aborting install. (answer: ${my_answer})"
    key_exit 2
fi

echo "The uninstallation process requires administrative privileges"
echo "because some of the installed files cannot be removed by a"
echo "normal user. You may be prompted for your password now..."
echo ""

/usr/bin/sudo -p "Please enter %u's password:" /bin/rm -Rf $my_files
exit_status=$?

if [ "$exit_status" -ne 0 ]; then
    echo "An error coccurred during the uninstall process. (exit: ${exit_status})"
    echo ""
    echo "The uninstall failed. Try again."
    key_exit 1
fi

echo "Successfully uninstalled Vagrant."
echo "Done."
key_exit 0
