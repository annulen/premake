#!/bin/bash
sudo add-apt-repository --yes "ppa:codegear/release"
sudo apt-get update
sudo apt-get --yes install premake4
premake4 gmake
premake4 embed
make config=debug
tests/test
make config=release
