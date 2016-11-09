#!/bin/bash

# Local scripts always pass in the VAGRANT_DIR as the first parameter.
# Other arguments are passed through from $2.

ARGS=(${@})

VAGRANT_DIR=${ARGS[0]}
OTHER_ARGS=(${ARGS[@]:1})

echo "${OTHER_ARGS[@]}"
