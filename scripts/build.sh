#!/bin/bash

rm -rf ./dist

GLEAM_VERSION=$(gleam --version | awk '{print $2}')

gleam build

bun build --compile --outfile=./dist/radio_cli ./build/dev/javascript/radio_cli/gleam@@private_main_v$GLEAM_VERSION.mjs
