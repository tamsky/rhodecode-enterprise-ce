# Nix environment for the community edition
#
# This shall be as lean as possible, just producing the Enterprise
# derivation. For advanced tweaks to pimp up the development environment we use
# "shell.nix" so that it does not have to clutter this file.

{ pkgs ? (import <nixpkgs> {})
, pythonPackages ? "python27Packages"
, pythonExternalOverrides ? self: super: {}
, doCheck ? true
}:

let pkgs_ = pkgs; in

let
  pkgs = pkgs_.overridePackages (self: super: {
    # Override subversion derivation to
    #  - activate python bindings
    #  - set version to 1.8
    subversion = super.subversion18.override {
       httpSupport = true;
       pythonBindings = true;
       python = self.python27Packages.python;
    };
  });

  inherit (pkgs.lib) fix extends;

  basePythonPackages = with builtins; if isAttrs pythonPackages
    then pythonPackages
    else getAttr pythonPackages pkgs;

  elem = builtins.elem;
  basename = path: with pkgs.lib; last (splitString "/" path);
  startsWith = prefix: full: let
    actualPrefix = builtins.substring 0 (builtins.stringLength prefix) full;
  in actualPrefix == prefix;

  src-filter = path: type: with pkgs.lib;
    let
      ext = last (splitString "." path);
    in
      !elem (basename path) [
        ".git" ".hg" "__pycache__" ".eggs"
        "bower_components" "node_modules"
        "build" "data" "tmp"] &&
      !elem ext ["egg-info" "pyc"] &&
      !startsWith "result" path;

  sources = pkgs.config.rc.sources or {};
  rhodecode-enterprise-ce-src = builtins.filterSource src-filter ./.;

  nodeEnv = import ./pkgs/node-default.nix {
    inherit pkgs;
  };
  nodeDependencies = nodeEnv.shell.nodeDependencies;

  bowerComponents = pkgs.buildBowerComponents {
    name = "enterprise-ce-bower-components";
    generated = ./pkgs/bower-packages.nix;
    src = rhodecode-enterprise-ce-src;
  };

  pythonGeneratedPackages = self: basePythonPackages.override (a: {
    inherit self;
  })
  // (scopedImport {
    self = self;
    super = basePythonPackages;
    inherit pkgs;
    inherit (pkgs) fetchurl fetchgit;
  } ./pkgs/python-packages.nix);

  pythonOverrides = import ./pkgs/python-packages-overrides.nix {
    inherit
      basePythonPackages
      pkgs;
  };

  pythonLocalOverrides = self: super: {
    rhodecode-enterprise-ce =
      let
        version = builtins.readFile ./rhodecode/VERSION;
        linkNodeAndBowerPackages = ''
          echo "Link node packages"
          rm -fr node_modules
          mkdir node_modules

          # johbo: Linking individual packages allows us to run "npm install"
          # inside of a shell to try things out. Re-entering the shell will
          # restore a clean environment.
          ln -s ${nodeDependencies}/lib/node_modules/* node_modules/

          echo "DONE: Link node packages"

          echo "Link bower packages"
          rm -fr bower_components
          mkdir bower_components

          ln -s ${bowerComponents}/bower_components/* bower_components/
          echo "DONE: Link bower packages"
        '';
      in super.rhodecode-enterprise-ce.override (attrs: {

      inherit
        doCheck
        version;
      name = "rhodecode-enterprise-ce-${version}";
      releaseName = "RhodeCodeEnterpriseCE-${version}";
      src = rhodecode-enterprise-ce-src;

      buildInputs =
        attrs.buildInputs ++
        (with self; [
          pkgs.nodePackages.bower
          pkgs.nodePackages.grunt-cli
          pkgs.subversion
          pytest-catchlog
          rhodecode-testdata
        ]);

      propagatedBuildInputs = attrs.propagatedBuildInputs ++ (with self; [
        rhodecode-tools
      ]);

      # TODO: johbo: Make a nicer way to expose the parts. Maybe
      # pkgs/default.nix?
      passthru = {
        inherit
          bowerComponents
          linkNodeAndBowerPackages
          myPythonPackagesUnfix
          pythonLocalOverrides;
        pythonPackages = self;

        # johbo: Legacy support for the EE build mechanisms
        linkNodeModules = linkNodeAndBowerPackages;
      };

      LC_ALL = "en_US.UTF-8";
      LOCALE_ARCHIVE =
        if pkgs.stdenv ? glibc
        then "${pkgs.glibcLocales}/lib/locale/locale-archive"
        else "";

      # Somewhat snappier setup of the development environment
      # TODO: move into shell.nix
      # TODO: think of supporting a stable path again, so that multiple shells
      #       can share it.
      shellHook = ''
        tmp_path=$(mktemp -d)
        export PATH="$tmp_path/bin:$PATH"
        export PYTHONPATH="$tmp_path/${self.python.sitePackages}:$PYTHONPATH"
        mkdir -p $tmp_path/${self.python.sitePackages}
        python setup.py develop --prefix $tmp_path --allow-hosts ""
      '' + linkNodeAndBowerPackages;

      preCheck = ''
        export PATH="$out/bin:$PATH"
      '';

      postCheck = ''
        rm -rf $out/lib/${self.python.libPrefix}/site-packages/pytest_pylons
        rm -rf $out/lib/${self.python.libPrefix}/site-packages/rhodecode/tests
      '';

      preBuild = linkNodeAndBowerPackages + ''
        grunt
        rm -fr node_modules
      '';

      postInstall = ''
        # python based programs need to be wrapped
        ln -s ${self.supervisor}/bin/supervisor* $out/bin/
        ln -s ${self.gunicorn}/bin/gunicorn $out/bin/
        ln -s ${self.PasteScript}/bin/paster $out/bin/
        ln -s ${self.channelstream}/bin/channelstream $out/bin/
        ln -s ${self.pyramid}/bin/* $out/bin/  #*/

        # rhodecode-tools
        # TODO: johbo: re-think this. Do the tools import anything from enterprise?
        ln -s ${self.rhodecode-tools}/bin/rhodecode-* $out/bin/

        # note that condition should be restricted when adding further tools
        for file in $out/bin/*; do  #*/
          wrapProgram $file \
              --prefix PYTHONPATH : $PYTHONPATH \
              --prefix PATH : $PATH \
              --set PYTHONHASHSEED random
        done

        mkdir $out/etc
        cp configs/production.ini $out/etc

        echo "Writing meta information for rccontrol to nix-support/rccontrol"
        mkdir -p $out/nix-support/rccontrol
        cp -v rhodecode/VERSION $out/nix-support/rccontrol/version
        echo "DONE: Meta information for rccontrol written"

        # TODO: johbo: Make part of ac-tests
        if [ ! -f rhodecode/public/js/scripts.js ]; then
          echo "Missing scripts.js"
          exit 1
        fi
        if [ ! -f rhodecode/public/css/style.css ]; then
          echo "Missing style.css"
          exit 1
        fi
      '';

    });

    rhodecode-testdata = import "${rhodecode-testdata-src}/default.nix" {
    inherit
      doCheck
      pkgs
      pythonPackages;
    };

  };

  rhodecode-testdata-src = sources.rhodecode-testdata or (
    pkgs.fetchhg {
      url = "https://code.rhodecode.com/upstream/rc_testdata";
      rev = "v0.8.0";
      sha256 = "0hy1ba134rq2f9si85yx7j4qhc9ky0hjzdk553s3q026i7km809m";
  });

  # Apply all overrides and fix the final package set
  myPythonPackagesUnfix =
    (extends pythonExternalOverrides
    (extends pythonLocalOverrides
    (extends pythonOverrides
             pythonGeneratedPackages)));
  myPythonPackages = (fix myPythonPackagesUnfix);

in myPythonPackages.rhodecode-enterprise-ce
