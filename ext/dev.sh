dot_cargo() {
	default=true
	# https://rust-lang.org/tools/install/
	install() {
		curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
		source $HOME/.cargo/env
	}
}

dot_bun() {
	default=true
	# https://bun.com/docs/installation
	install() {
		curl -fsSL https://bun.com/install | bash
		export PATH="$HOME/.bun/bin:$PATH"
	}
}

dot_uv() {
	default=true
	# https://docs.astral.sh/uv/getting-started/installation/
	install() {
		curl -LsSf https://astral.sh/uv/install.sh | sh
		source $HOME/.local/bin/env
	}
}
