#!/bin/sh

printf "\n--------------- $1 - $2 -------------\n"

if [ $# -lt 4 ]; then
	echo "$0 directory fetch-url push-url (upstream-url|-) (checkout-branch|-) (upstream-branch|-)"
	exit 1
fi

prop=build/prop.`basename $1`

# fetch url / push url might differ, commonly fetch by https, push by ssh
echo "export fetch_url=$2" > $prop
echo "export git_repo=${2##*/}" > $prop
echo "export push_url=$3" >> $prop

if [ "$4" != "-" ]; then
	echo "export upstream_url=$4" >> $prop
else
	echo "export upstream_url=" >> $prop
fi

if [ "$5" != "-" ]; then
	echo "export checkout_branch=$5" >> $prop
else
	echo "export checkout_branch=" >> $prop
fi

if [ "$6" != "-" ]; then
	echo "export upstream_full_branch=$6" >> $prop
	echo "export upstream_branch=${6##*/}" >> $prop
else
	echo "export upstream_full_branch=" >> $prop
	echo "export upstream_branch=" >> $prop
fi

# For CI, allow shallow fetching, its a bit faster
if [ "$7" = "shallow" ]; then
	git clone --depth=1 $2 $1
	exit
fi

git clone --no-checkout $2 $1

# set the upstream to push changes back
git --git-dir=$1/.git remote set-url --push origin $3

# optionally set an upstream repository
if [ "$4" != "-" ]; then
	git --git-dir=$1/.git remote add upstream $4
fi

# optionally checkout a branch
if [ "$5" != "-" ]; then
	git --git-dir=$1/.git --work-tree=$1 checkout "$5"
fi

# Set the checkout branch as default upstream branch
#
# Switching to OE point venus is based on can be done with:
# ./repos branch -u 'origin/$upstream_branch'
#
git --git-dir=$1/.git --work-tree=$1 branch -u "origin/$5"

echo "Set git config log.follow=true, to handle all the recipe renames"
git --git-dir=$1/.git --work-tree=$1 config log.follow true
