#!/usr/bin/env bash

dir="$(dirname "$(realpath "$0")")"
source "$dir/1-global_script.sh"

parent_dir="$(dirname "$dir")"
source "$parent_dir/interaction_fn.sh"

log_dir="$parent_dir/Logs"
log="$log_dir/others-$(date +%d-%m-%y).log"

# Install awww dependencies
awww_deps=(
	build-essential
	liblz4-dev
	libdrm-dev
	libgbm-dev
)

msg act "Checking swww dependencies..."
for packages in "${awww_deps[@]}"; do
  if ! dpkg -s "$packages" &> /dev/null; then
      sudo apt-get install -y "$packages" 2>&1 | tee -a "$log"
  fi
done

# installing awww
if ! command -v swww &> /dev/null; then
  msg act "Installing swww..."

  awww_tag="v0.11.2"
  awww_dir="$parent_dir/.cache/awww"

  # ensure cargo exists (install rustup if missing)
  if ! command -v cargo &> /dev/null; then
    msg act "Installing Rust (rustup)..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o rustup.sh
    sh rustup.sh -y 2>&1 | tee -a "$log"
    rm rustup.sh
  fi

  # load rust environment if available
  if [ -f "$HOME/.cargo/env" ]; then
    source "$HOME/.cargo/env"
  fi

  # ensure cargo bin is in PATH for this session
  export PATH="$HOME/.cargo/bin:$PATH"

  # final verification
  if ! command -v cargo &> /dev/null; then
    echo "[ ERROR ] cargo not found after rust setup!" | tee -a "$log"
    exit 1
  fi

  # ensure correct rust version
  rustup update 2>&1 | tee -a "$log"

  # clone correct version
  rm -rf "$awww_dir"
  git clone --branch "$awww_tag" --depth=1 https://codeberg.org/LGFae/awww.git "$awww_dir" \
    2>&1 | tee -a "$log"

  cd "$awww_dir" || exit 1

  # build
  cargo build --release 2>&1 | tee -a "$log" || {
    echo "[ ERROR ] swww build failed!" | tee -a "$log"
    exit 1
  }

  # install binaries
  sudo cp target/release/swww /usr/local/bin/
  sudo cp target/release/swww-daemon /usr/local/bin/

  # cleanup
  cd ~
  rm -rf "$awww_dir"

  # verify
  if command -v swww &> /dev/null; then
    msg dn "swww was installed successfully..."
    printf "[ DONE ] - swww was installed successfully...\n" | tee -a "$log" &> /dev/null
  else
    msg err "swww failed to install..."
    printf "[ ERROR ] - swww installation failed!\n" | tee -a "$log" &> /dev/null
  fi

else
  msg dn "swww is already installed..."
fi