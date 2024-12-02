#!/usr/bin/env bash

# Enable strict mode for Bash
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

# Discover target triple (e.g. "aarch64-unknown-linux-gnu")
target="$(rustc -vV | awk '/host/ { print $2 }')"

rustc_dummy=$(
  cat <<EOF
#!/usr/bin/env bash
echo "This is a dummy file to trick rustup into thinking this is a sysroot"
echo 'Run "x.py build --stage 1 library/std" to create a real sysroot you can use with rustup'
EOF
)

for D in rust*; do
  if [ -d "$D" ]; then
    pushd "$D"

    stages=(stage1 stage2)

    for stage in "${stages[@]}"; do
      directory="build/${target}/${stage}"

      if [ ! -d "$directory" ]; then
        mkdir -p "${directory}/lib"
        mkdir -p "${directory}/bin"
        echo "$rustc_dummy" >> "${directory}/bin/rustc"
        chmod +x "${directory}/bin/rustc"
      fi

      rustup toolchain link "${D}_${stage}" "$directory"
    done

    popd
  fi
done
