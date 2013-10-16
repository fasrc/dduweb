#!/usr/bin/env bash

# Copyright (c) 2013
# Harvard FAS Research Computing
# John Brunelle <john_brunelle@harvard.edu>
# All right reserved.

set -e

helpstr="\
NAME
	install_dduweb.sh - configure a host to use dduweb

SYNOPSIS
	install_dduweb.sh --component web|ddurund --web-user USER --admin-group GROUP

DESCRIPTION
	This should be run as root.

OPTIONS
	--component web|ddurund
		The dduweb system involves two components which may or may not be on 
		the same host.  Use this option to specify which component to setup.
	
	--web-user USER
		The username of the account under which the web server runs.
	
	--admin-group GROUP
		The group that should own directories which are not world-readable.
	
	--pretend
		Print the commands to the screen instead of actually running them.

	-h, --help
		Print this help.

REQUIREMENTS
	n/a

BUGS/TODO
	n/a

AUTHOR
	Copyright (c) 2013
	Harvard FAS Research Computing
	John Brunelle <john_brunelle@harvard.edu>
	All rights reserved.
"

component=''
web_user=''
admin_group=''
prefix=''

args=$(getopt -n "$(basename "$0")" -l component:,web-user:,admin-group:,pretend,help -o h -- "$@")
if [ $? -ne 0 ]; then
	exit 65  #(getopt will have written the error message)
fi
eval set -- "$args"
while [ ! -z "$1" ]; do
	case "$1" in
		--component)
			component="$2"
			if [ "$component" != 'web' -a "$component" != 'ddurund' ]; then
				echo "*** ERROR *** invalid component [$component]" >&2
				exit 1
			fi
			shift
			;;
		--web-user)
			web_user="$2"
			shift
			;;
		--admin-group)
			admin_group="$2"
			shift
			;;
		
		--pretend)
			prefix='echo'
			shift
			;;

		-h | --help)
			echo -n "$helpstr"
			exit 0
			;;
		--) 
			shift
			break
			;;
	esac
	shift
done

if [ -z "$component" ]; then
	echo "*** ERROR *** must specify --component" >&2
	exit 1
fi
if [ "$component" = 'web' ]; then
	if [ -z "$web_user" ]; then
		echo "*** ERROR *** must specify --web-user" >&2
		exit 1
	fi
	if [ -z "$admin_group" ]; then
		echo "*** ERROR *** must specify --admin_group" >&2
		exit 1
	fi
fi

if ! $pretend && [ "$(id -u)"!=0 ]; then
	echo "*** ERROR *** this script should be run as root"
fi

dduweb_root="$(dirname $(readlink -e "$0"))"

set -u


#---


if [ "$component" = 'web' ]; then
	#(stuff that could go in either I choose to put in web)

	#--- adjust ownership, permissions, etc.

	$prefix chown "$web_user:$admin_group" "$dduweb_root"/log
	$prefix chmod 770                      "$dduweb_root"/log

	$prefix install -o "$web_user" -g "$admin_group" -m 660 /dev/null "$dduweb_root"/log/web.log
	
	$prefix chown "$web_user:$admin_group" "$dduweb_root"/web/data
	$prefix chmod 775                      "$dduweb_root"/web/data


	#--- symlink apache config

	$prefix ln -s "$dduweb_root"/misc/dduweb.conf /etc/httpd/conf.d/dduweb.conf


	#--- install philesight

	$prefix cd "$dduweb_root"/sw
	$prefix wget http://zevv.nl/play/code/philesight/philesight-20120427.tgz
	$prefix tar xzvf "$(basename $_)"
	$prefix ln -s "$(basename $_ .tgz)" philesight
fi

if [ "$component" = 'ddurund' ]; then
	#--- symlink init script

	$prefix ln -s "$dduweb_root"/misc/ddurund.init_script /etc/init.d/ddurund
fi
