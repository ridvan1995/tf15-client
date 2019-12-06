#!/bin/sh

if echo "$HOME" | grep "com.termux"; then
	echo "-- Configuring for termux"
	export JAVAC=ecj
	export JAVA=true # /bin/true does nothing but returns success
	export JAR=true
	export JAVADOC=true
	TERMUX_ARG="--termux"
	TOOLCHAIN=host
else
	echo "-- Configuring for Android SDK/NDK"
fi

if [ -z "$ARCHS" ]; then
	ARCHS="armeabi-v7a x86"
fi

if [ -z "$API" ]; then
	API=9
fi
ROOT="$PWD" # compile.sh must be run from root of android project sources

if [ -z "$1" ]; then
	BUILD_TYPE=debug
else
	BUILD_TYPE=$1
fi

rm -rf android/build

build_native_project()
{
	prj=tf15-client
	shift
	arch=$1
	shift

	out="$ROOT/build-$prj/$arch"

	mkdir -p $out
	if [ -L "$prj-sl" ]; then
		cd $prj-sl # need to change directory, as waf doesn't work well with symlinks(used in development purposes)
	else
		cd $prj
	fi
	./waf -o "$out" configure -T $BUILD_TYPE --android="$arch,$TOOLCHAIN,$API" $* build || die "$out"
	./waf install --destdir=$ROOT/android/build/ --strip
	cd $ROOT # obviously, we can't ../ from symlink directory, so change to our root directory
}

for i in $ARCHS; do
	build_native_project "." "$i" $ENGINE_FLAGS
done

./waf -t android configure -T $BUILD_TYPE $TERMUX_ARG|| exit 1
./waf -t android build -v || exit 1

cp android/build/tf15-client-signed.apk tf15-client.apk

