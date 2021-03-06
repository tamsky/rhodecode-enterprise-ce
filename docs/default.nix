{ system ? builtins.currentSystem
}:

let

  pkgs = import <nixpkgs> { inherit system; };

  inherit (pkgs) fetchurl;

  buildPythonPackage = pkgs.python27Packages.buildPythonPackage;
  python = pkgs.python27Packages.python;


  alabaster = buildPythonPackage {
    name = "alabaster-0.7.11";
    doCheck = false;
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/3f/46/9346ea429931d80244ab7f11c4fce83671df0b7ae5a60247a2b588592c46/alabaster-0.7.11.tar.gz";
      sha256 = "1mvm69xsn5xf1jc45kdq1mn0yq0pfn54mv2jcww4s1vwqx6iyfxn";
    };
  };
  babel = buildPythonPackage {
    name = "babel-2.6.0";
    doCheck = false;
    propagatedBuildInputs = [
      pytz
    ];
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/be/cc/9c981b249a455fa0c76338966325fc70b7265521bad641bf2932f77712f4/Babel-2.6.0.tar.gz";
      sha256 = "08rxmbx2s4irp0w0gmn498vns5xy0fagm0fg33xa772jiks51flc";
    };
  };
  certifi = buildPythonPackage {
    name = "certifi-2018.8.24";
    doCheck = false;
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/e1/0f/f8d5e939184547b3bdc6128551b831a62832713aa98c2ccdf8c47ecc7f17/certifi-2018.8.24.tar.gz";
      sha256 = "0f0nhrj9mlrf79iway4578wrsgmjh0fmacl9zv8zjckdy7b90rip";
    };
  };
  chardet = buildPythonPackage {
    name = "chardet-3.0.4";
    doCheck = false;
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/fc/bb/a5768c230f9ddb03acc9ef3f0d4a3cf93462473795d18e9535498c8f929d/chardet-3.0.4.tar.gz";
      sha256 = "1bpalpia6r5x1kknbk11p1fzph56fmmnp405ds8icksd3knr5aw4";
    };
  };
  docutils = buildPythonPackage {
    name = "docutils-0.14";
    doCheck = false;
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/84/f4/5771e41fdf52aabebbadecc9381d11dea0fa34e4759b4071244fa094804c/docutils-0.14.tar.gz";
      sha256 = "0x22fs3pdmr42kvz6c654756wja305qv6cx1zbhwlagvxgr4xrji";
    };
  };
  idna = buildPythonPackage {
    name = "idna-2.7";
    doCheck = false;
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/65/c4/80f97e9c9628f3cac9b98bfca0402ede54e0563b56482e3e6e45c43c4935/idna-2.7.tar.gz";
      sha256 = "05jam7d31767dr12x0rbvvs8lxnpb1mhdb2zdlfxgh83z6k3hjk8";
    };
  };
  imagesize = buildPythonPackage {
    name = "imagesize-1.1.0";
    doCheck = false;
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/41/f5/3cf63735d54aa9974e544aa25858d8f9670ac5b4da51020bbfc6aaade741/imagesize-1.1.0.tar.gz";
      sha256 = "1dg3wn7qpwmhgqc0r9na2ding1wif9q5spz3j9zn2riwphc2k0zk";
    };
  };
  jinja2 = buildPythonPackage {
    name = "jinja2-2.9.6";
    doCheck = false;
    propagatedBuildInputs = [
      markupsafe
    ];
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/90/61/f820ff0076a2599dd39406dcb858ecb239438c02ce706c8e91131ab9c7f1/Jinja2-2.9.6.tar.gz";
      sha256 = "1zzrkywhziqffrzks14kzixz7nd4yh2vc0fb04a68vfd2ai03anx";
    };
  };
  markupsafe = buildPythonPackage {
    name = "markupsafe-1.0";
    doCheck = false;
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/4d/de/32d741db316d8fdb7680822dd37001ef7a448255de9699ab4bfcbdf4172b/MarkupSafe-1.0.tar.gz";
      sha256 = "0rdn1s8x9ni7ss8rfiacj7x1085lx8mh2zdwqslnw8xc3l4nkgm6";
    };
  };
  packaging = buildPythonPackage {
    name = "packaging-17.1";
    doCheck = false;
    propagatedBuildInputs = [
      pyparsing
      six
    ];
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/77/32/439f47be99809c12ef2da8b60a2c47987786d2c6c9205549dd6ef95df8bd/packaging-17.1.tar.gz";
      sha256 = "0nrpayk8kij1zm9sjnk38ldz3a6705ggvw8ljylqbrb4vmqbf6gh";
    };
  };
  pygments = buildPythonPackage {
    name = "pygments-2.2.0";
    doCheck = false;
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/71/2a/2e4e77803a8bd6408a2903340ac498cb0a2181811af7c9ec92cb70b0308a/Pygments-2.2.0.tar.gz";
      sha256 = "1k78qdvir1yb1c634nkv6rbga8wv4289xarghmsbbvzhvr311bnv";
    };
  };
  pyparsing = buildPythonPackage {
    name = "pyparsing-2.2.0";
    doCheck = false;
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/3c/ec/a94f8cf7274ea60b5413df054f82a8980523efd712ec55a59e7c3357cf7c/pyparsing-2.2.0.tar.gz";
      sha256 = "016b9gh606aa44sq92jslm89bg874ia0yyiyb643fa6dgbsbqch8";
    };
  };
  pytz = buildPythonPackage {
    name = "pytz-2018.4";
    doCheck = false;
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/10/76/52efda4ef98e7544321fd8d5d512e11739c1df18b0649551aeccfb1c8376/pytz-2018.4.tar.gz";
      sha256 = "0jgpqx3kk2rhv81j1izjxvmx8d0x7hzs1857pgqnixic5wq2ar60";
    };
  };
  requests = buildPythonPackage {
    name = "requests-2.19.1";
    doCheck = false;
    propagatedBuildInputs = [
      chardet
      idna
      urllib3
      certifi
    ];
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/54/1f/782a5734931ddf2e1494e4cd615a51ff98e1879cbe9eecbdfeaf09aa75e9/requests-2.19.1.tar.gz";
      sha256 = "0snf8xxdzsgh1x2zv3vilvbrv9jbpmnfagzzb1rjmmvflckdh8pc";
    };
  };
  six = buildPythonPackage {
    name = "six-1.11.0";
    doCheck = false;
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/16/d8/bc6316cf98419719bd59c91742194c111b6f2e85abac88e496adefaf7afe/six-1.11.0.tar.gz";
      sha256 = "1scqzwc51c875z23phj48gircqjgnn3af8zy2izjwmnlxrxsgs3h";
    };
  };
  snowballstemmer = buildPythonPackage {
    name = "snowballstemmer-1.2.1";
    doCheck = false;
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/20/6b/d2a7cb176d4d664d94a6debf52cd8dbae1f7203c8e42426daa077051d59c/snowballstemmer-1.2.1.tar.gz";
      sha256 = "0a0idq4y5frv7qsg2x62jd7rd272749xk4x99misf5rcifk2d7wi";
    };
  };
  sphinx = buildPythonPackage {
    name = "sphinx-1.7.8";
    doCheck = false;
    propagatedBuildInputs = [
      six
      jinja2
      pygments
      docutils
      snowballstemmer
      babel
      alabaster
      imagesize
      requests
      setuptools
      packaging
      sphinxcontrib-websupport
      typing
    ];
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/ac/54/4ef326d0c654da1ed91341a7a1f43efc18a8c770ddd2b8e45df97cb79d82/Sphinx-1.7.8.tar.gz";
      sha256 = "1ryz0w4c31930f1br2sjwrxwx9cmsy7cqdb0d81g98n9bj250w50";
    };
  };
  sphinx-rtd-theme = buildPythonPackage {
    name = "sphinx-rtd-theme-0.4.1";
    doCheck = false;
    propagatedBuildInputs = [
      sphinx
    ];
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/f2/b0/a1933d792b806118ddbca6699f2e2c844d9b1b16e84a89d7effd5cd2a800/sphinx_rtd_theme-0.4.1.tar.gz";
      sha256 = "1xkyqam8dzbjaymdyvkiif85m4y3jf8crdiwlgcfp8gqcj57aj9v";
    };
  };
  sphinxcontrib-websupport = buildPythonPackage {
    name = "sphinxcontrib-websupport-1.1.0";
    doCheck = false;
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/07/7a/e74b06dce85555ffee33e1d6b7381314169ebf7e31b62c18fcb2815626b7/sphinxcontrib-websupport-1.1.0.tar.gz";
      sha256 = "1ff3ix76xi1y6m99qxhaq5161ix9swwzydilvdya07mgbcvpzr4x";
    };
  };
  typing = buildPythonPackage {
    name = "typing-3.6.6";
    doCheck = false;
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/bf/9b/2bf84e841575b633d8d91ad923e198a415e3901f228715524689495b4317/typing-3.6.6.tar.gz";
      sha256 = "0ba9acs4awx15bf9v3nrs781msbd2nx826906nj6fqks2bvca9s0";
    };
  };
  urllib3 = buildPythonPackage {
    name = "urllib3-1.23";
    doCheck = false;
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/3c/d2/dc5471622bd200db1cd9319e02e71bc655e9ea27b8e0ce65fc69de0dac15/urllib3-1.23.tar.gz";
      sha256 = "1bvbd35q3zdcd7gsv38fwpizy7p06dr0154g5gfybrvnbvhwb2m6";
    };
  };

  # Avoid that setuptools is replaced, this leads to trouble
  # with buildPythonPackage.
  setuptools = pkgs.python27Packages.setuptools;

in python.buildEnv.override {
  inherit python;
  extraLibs = [
    sphinx
    sphinx-rtd-theme
  ];
}