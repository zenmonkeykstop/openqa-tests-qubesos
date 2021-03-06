# The Qubes OS Project, https://www.qubes-os.org/
#
# Copyright (C) 2019 Marek Marczykowski-Górecki <marmarek@invisiblethingslab.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

use base "installedtest";
use strict;
use testapi;
use networking;

sub run {
    my ($self) = @_;

    select_console('x11');
    assert_screen "desktop";
    x11_start_program('xterm');
    curl_via_netvm;

    foreach (split / /, get_var("UPDATE_TEMPLATES")) {
        my $action = "upgrade";
        if (script_run("rpm -q qubes-template-$_") != 0) {
            $action = "install";
        }
        script_run("qvm-features -D $_ fixups-installed");
        assert_script_run("sudo qubes-dom0-update --clean --enablerepo=qubes-*templates* --action=$action -y qubes-template-$_", timeout => 1500);
        $self->save_and_upload_log("rpm -q qubes-template-$_", "template-$_-version.txt");
    }

    # restart only sys-whonix - for potential whonixcheck run
    # other system VMs will be restarted later anyway (whole system restart)
    if (get_var("UPDATE_TEMPLATES") =~ /whonix-gw/) {
        assert_script_run("qvm-shutdown --wait sys-whonix", timeout => 90);
        assert_script_run("qvm-start sys-whonix", timeout => 90);
    }

    type_string("exit\n");
}

1;

# vim: set sw=4 et:
