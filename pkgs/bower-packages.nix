{ fetchbower, buildEnv }:
buildEnv { name = "bower-env"; ignoreCollisions = true; paths = [
  (fetchbower "webcomponentsjs" "0.7.22" "^0.7.22" "178h9j8jq9wi5845f5pxhhhqw6x022nzmpzm4di8fgsdl1f6nr5d")
  (fetchbower "polymer" "Polymer/polymer#1.6.1" "Polymer/polymer#^1.6.1" "09mm0jgk457gvwqlc155swch7gjr6fs3g7spnvhi6vh5b6518540")
  (fetchbower "paper-button" "PolymerElements/paper-button#1.0.13" "PolymerElements/paper-button#^1.0.13" "0i3y153nqk06pn0gk282vyybnl3g1w3w41d5i9z659cgn27g3fvm")
  (fetchbower "paper-spinner" "PolymerElements/paper-spinner#1.2.0" "PolymerElements/paper-spinner#^1.2.0" "1av1m6y81jw3hjhz1yqy3rwcgxarjzl58ldfn4q6sn51pgzngfqb")
  (fetchbower "paper-tooltip" "PolymerElements/paper-tooltip#1.1.3" "PolymerElements/paper-tooltip#^1.1.2" "0vmrm1n8k9sk9nvqy03q177axy22pia6i3j1gxbk72j3pqiqvg6k")
  (fetchbower "paper-toast" "PolymerElements/paper-toast#1.3.0" "PolymerElements/paper-toast#^1.3.0" "0x9rqxsks5455s8pk4aikpp99ijdn6kxr9gvhwh99nbcqdzcxq1m")
  (fetchbower "paper-toggle-button" "PolymerElements/paper-toggle-button#1.2.0" "PolymerElements/paper-toggle-button#^1.2.0" "0mphcng3ngspbpg4jjn0mb91nvr4xc1phq3qswib15h6sfww1b2w")
  (fetchbower "iron-ajax" "PolymerElements/iron-ajax#1.4.4" "PolymerElements/iron-ajax#^1.4.4" "0jpi7ik3zljw8yh2ccc85r26lcpzmkc2nl1kn6fqdx57zkzk9v5b")
  (fetchbower "iron-autogrow-textarea" "PolymerElements/iron-autogrow-textarea#1.0.13" "PolymerElements/iron-autogrow-textarea#^1.0.13" "0zwhpl97vii1s8k0lgain8i9dnw29b0mxc5ixdscx9las13n2lqq")
  (fetchbower "iron-a11y-keys" "PolymerElements/iron-a11y-keys#1.0.6" "PolymerElements/iron-a11y-keys#^1.0.6" "1xz3mgghfcxixq28sdb654iaxj4nyi1bzcwf77ydkms6fviqs9mv")
  (fetchbower "iron-flex-layout" "PolymerElements/iron-flex-layout#1.3.1" "PolymerElements/iron-flex-layout#^1.0.0" "0nswv3ih3bhflgcd2wjfmddqswzgqxb2xbq65jk9w3rkj26hplbl")
  (fetchbower "paper-behaviors" "PolymerElements/paper-behaviors#1.0.12" "PolymerElements/paper-behaviors#^1.0.0" "012bqk97awgz55cn7rm9g7cckrdhkqhls3zvp8l6nd4rdwcrdzq8")
  (fetchbower "paper-material" "PolymerElements/paper-material#1.0.6" "PolymerElements/paper-material#^1.0.0" "0rljmknfdbm5aabvx9pk77754zckj3l127c3mvnmwkpkkr353xnh")
  (fetchbower "paper-styles" "PolymerElements/paper-styles#1.1.4" "PolymerElements/paper-styles#^1.0.0" "0j8vg74xrcxlni8i93dsab3y80f34kk30lv4yblqpkp9c3nrilf7")
  (fetchbower "neon-animation" "PolymerElements/neon-animation#1.2.4" "PolymerElements/neon-animation#^1.0.0" "16mz9i2n5w0k5j8d6gha23cnbdgm5syz3fawyh89gdbq97bi2q5j")
  (fetchbower "iron-a11y-announcer" "PolymerElements/iron-a11y-announcer#1.0.5" "PolymerElements/iron-a11y-announcer#^1.0.0" "0n7c7j1pwk3835s7s2jd9125wdcsqf216yi5gj07wn5s8h8p7m9d")
  (fetchbower "iron-overlay-behavior" "PolymerElements/iron-overlay-behavior#1.8.6" "PolymerElements/iron-overlay-behavior#^1.0.9" "14brn9gz6qqskarg3fxk91xs7vg02vgcsz9a9743kidxr0l0413m")
  (fetchbower "iron-fit-behavior" "PolymerElements/iron-fit-behavior#1.2.5" "PolymerElements/iron-fit-behavior#^1.1.0" "1msnlh8lp1xg6v4h6dkjwj9kzac5q5q208ayla3x9hi483ki6rlf")
  (fetchbower "iron-checked-element-behavior" "PolymerElements/iron-checked-element-behavior#1.0.5" "PolymerElements/iron-checked-element-behavior#^1.0.0" "0l0yy4ah454s8bzfv076s8by7h67zy9ni6xb932qwyhx8br6c1m7")
  (fetchbower "promise-polyfill" "polymerlabs/promise-polyfill#1.0.1" "polymerlabs/promise-polyfill#^1.0.0" "045bj2caav3famr5hhxgs1dx7n08r4s46mlzwb313vdy17is38xb")
  (fetchbower "iron-behaviors" "PolymerElements/iron-behaviors#1.0.17" "PolymerElements/iron-behaviors#^1.0.0" "021qvkmbk32jrrmmphpmwgby4bzi5jyf47rh1bxmq2ip07ly4bpr")
  (fetchbower "iron-validatable-behavior" "PolymerElements/iron-validatable-behavior#1.1.1" "PolymerElements/iron-validatable-behavior#^1.0.0" "1yhxlvywhw2klbbgm3f3cmanxfxggagph4ii635zv0c13707wslv")
  (fetchbower "iron-form-element-behavior" "PolymerElements/iron-form-element-behavior#1.0.6" "PolymerElements/iron-form-element-behavior#^1.0.0" "0rdhxivgkdhhz2yadgdbjfc70l555p3y83vjh8rfj5hr0asyn6q1")
  (fetchbower "iron-a11y-keys-behavior" "polymerelements/iron-a11y-keys-behavior#1.1.9" "polymerelements/iron-a11y-keys-behavior#^1.0.0" "1imm4gc84qizihhbyhfa8lwjh3myhj837f79i5m04xjgwrjmkaf6")
  (fetchbower "paper-ripple" "PolymerElements/paper-ripple#1.0.8" "PolymerElements/paper-ripple#^1.0.0" "0r9sq8ik7wwrw0qb82c3rw0c030ljwd3s466c9y4qbcrsbvfjnns")
  (fetchbower "font-roboto" "PolymerElements/font-roboto#1.0.1" "PolymerElements/font-roboto#^1.0.1" "02jz43r0wkyr3yp7rq2rc08l5cwnsgca9fr54sr4rhsnl7cjpxrj")
  (fetchbower "iron-meta" "PolymerElements/iron-meta#1.1.2" "PolymerElements/iron-meta#^1.0.0" "1wl4dx8fnsknw9z9xi8bpc4cy9x70c11x4zxwxnj73hf3smifppl")
  (fetchbower "iron-resizable-behavior" "PolymerElements/iron-resizable-behavior#1.0.5" "PolymerElements/iron-resizable-behavior#^1.0.0" "1fd5zmbr2hax42vmcasncvk7lzi38fmb1kyii26nn8pnnjak7zkn")
  (fetchbower "iron-selector" "PolymerElements/iron-selector#1.5.2" "PolymerElements/iron-selector#^1.0.0" "1ajv46llqzvahm5g6g75w7nfyjcslp53ji0wm96l2k94j87spv3r")
  (fetchbower "web-animations-js" "web-animations/web-animations-js#2.2.2" "web-animations/web-animations-js#^2.2.0" "1izfvm3l67vwys0bqbhidi9rqziw2f8wv289386sc6jsxzgkzhga")
]; }
