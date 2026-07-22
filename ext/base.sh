dot_wezterm() {
	link $DOT_DIR_R/wezterm/config.lua $HOME/.wezterm.lua
}

dot_tmux() {
	link $DOT_DIR_R/tmux.conf $HOME/.tmux.conf
}

dot_git() {
	install() {
		git config --global include.path $DOT_DIR_R/gitconfig
		git config --global core.excludesFile $DOT_DIR/gitignore.global
	}
}

dot_chruby() {
	# https://github.com/postmodern/chruby
	local ver=0.3.9
	check() {
		which chruby-exec
	}
	eval "install() {
		cd $INSTALL_DIR
		wget -O chruby-$ver.tar.gz https://github.com/postmodern/chruby/archive/v$ver.tar.gz
		tar -xzvf chruby-$ver.tar.gz
		cd chruby-$ver/
		sudo make install
	}"
}

dot_ruby_install() {
	# https://github.com/postmodern/ruby-install
	local ver=0.10.2

	check() {
		command -v ruby-install
	}
	eval "install() {
		cd $INSTALL_DIR
		wget https://github.com/postmodern/ruby-install/releases/download/v$ver/ruby-install-$ver.tar.gz
		tar -xzvf ruby-install-$ver.tar.gz
		cd ruby-install-$ver/
		sudo make install
	}"
}

dot_starship() {
	# https://starship.rs/
	install() {
		curl -sS https://starship.rs/install.sh | BIN_DIR=$BIN_DIR sh
	}
}

dot_bat() {
	check() {
		if [[ "$OSTYPE" == "linux-gnu"* ]]; then
			which batcat
		else
			which bat
		fi
	}
}

dot_ag() {
	install() {
		if [[ "$OSTYPE" == "linux-gnu"* ]]; then
			$PKGMAN_INSTALL silversearcher-ag
		else
			$PKGMAN_INSTALL the_silver_searcher
		fi
	}
}

dot_rg() {
	install() {
		$PKGMAN_INSTALL ripgrep
	}
}

dot_vimrc() {
	link $DOT_DIR_R/vimrc $HOME/.vimrc
	install() {
		ln -s $DOT_DIR_R/vimrc $HOME/.vimrc
		# https://github.com/junegunn/vim-plug
		curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
			https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
		vim +PlugInstall +qall
		git config --global core.editor vim
	}
}

dot_fzf() {
	# https://github.com/junegunn/fzf
	check() {
		exist ~/.fzf/bin/fzf
	}
	install() {
		git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
		~/.fzf/install
	}
}
