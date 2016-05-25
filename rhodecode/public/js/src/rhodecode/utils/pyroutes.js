// # Copyright (C) 2010-2016  RhodeCode GmbH
// #
// # This program is free software: you can redistribute it and/or modify
// # it under the terms of the GNU Affero General Public License, version 3
// # (only), as published by the Free Software Foundation.
// #
// # This program is distributed in the hope that it will be useful,
// # but WITHOUT ANY WARRANTY; without even the implied warranty of
// # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// # GNU General Public License for more details.
// #
// # You should have received a copy of the GNU Affero General Public License
// # along with this program.  If not, see <http://www.gnu.org/licenses/>.
// #
// # This program is dual-licensed. If you wish to learn more about the
// # RhodeCode Enterprise Edition, including its added features, Support services,
// # and proprietary license terms, please see https://rhodecode.com/licenses/

/**
* Object holding the registered pyroutes.
* Routes will be registered with the generated script
* rhodecode/public/js/rhodecode/base/pyroutes.js
*/
var PROUTES_MAP = {};

/**
* PyRoutesJS
*
* Usage pyroutes.url('mark_error_fixed',{"error_id":error_id}) // /mark_error_fixed/<error_id>
*/
var pyroutes = (function() {
  // access global map defined in special file pyroutes
  var matchlist = PROUTES_MAP;
  var sprintf = (function() {
    function get_type(variable) {
      return Object.prototype.toString.call(variable).slice(8, -1).toLowerCase();
    }
    function str_repeat(input, multiplier) {
      for (var output = []; multiplier > 0; output[--multiplier] = input) {
          /* do nothing */
      }
      return output.join('');
    }
    var str_format = function() {
      if (!str_format.cache.hasOwnProperty(arguments[0])) {
          str_format.cache[arguments[0]] = str_format.parse(arguments[0]);
      }
      return str_format.format.call(null, str_format.cache[arguments[0]], arguments);
    };
  
    str_format.format = function(parse_tree, argv) {
      var cursor = 1,
                   tree_length = parse_tree.length,
                   node_type = '',
                   arg,
                   output = [],
                   i, k,
                   match,
                   pad,
                   pad_character,
                   pad_length;
      for (i = 0; i < tree_length; i++) {
        node_type = get_type(parse_tree[i]);
        if (node_type === 'string') {
            output.push(parse_tree[i]);
        }
        else if (node_type === 'array') {
          match = parse_tree[i]; // convenience purposes only
          if (match[2]) { // keyword argument
              arg = argv[cursor];
              for (k = 0; k < match[2].length; k++) {
                  if (!arg.hasOwnProperty(match[2][k])) {
                      throw(sprintf('[sprintf] property "%s" does not exist', match[2][k]));
                  }
                  arg = arg[match[2][k]];
              }
          }
          else if (match[1]) { // positional argument (explicit)
              arg = argv[match[1]];
          }
          else { // positional argument (implicit)
              arg = argv[cursor++];
          }
      
          if (/[^s]/.test(match[8]) && (get_type(arg) !== 'number')) {
              throw(sprintf('[sprintf] expecting number but found %s', get_type(arg)));
          }
          switch (match[8]) {
              case 'b': arg = arg.toString(2); break;
              case 'c': arg = String.fromCharCode(arg); break;
              case 'd': arg = parseInt(arg, 10); break;
              case 'e': arg = match[7] ? arg.toExponential(match[7]) : arg.toExponential(); break;
              case 'f': arg = match[7] ? parseFloat(arg).toFixed(match[7]) : parseFloat(arg); break;
              case 'o': arg = arg.toString(8); break;
              case 's': arg = ((arg = String(arg)) && match[7] ? arg.substring(0, match[7]) : arg);
                break;
              case 'u': arg = Math.abs(arg); break;
              case 'x': arg = arg.toString(16); break;
              case 'X': arg = arg.toString(16).toUpperCase(); break;
          }
          arg = (/[def]/.test(match[8]) && match[3] && arg >= 0 ? '+'+ arg : arg);
          pad_character =
              match[4] ? match[4] === '0' ? '0' : match[4].charAt(1) : ' ';
          pad_length = match[6] - String(arg).length;
          pad = match[6] ? str_repeat(pad_character, pad_length) : '';
          output.push(match[5] ? arg + pad : pad + arg);
        }
      }
      return output.join('');
    };
  
    str_format.cache = {};
  
    str_format.parse = function(fmt) {
    var _fmt = fmt, match = [], parse_tree = [], arg_names = 0;
    while (_fmt) {
      if ((match = /^[^\x25]+/.exec(_fmt)) !== null) {
          parse_tree.push(match[0]);
      }
      else if ((match = /^\x25{2}/.exec(_fmt)) !== null) {
          parse_tree.push('%');
      }
      else if (
          (match = /^\x25(?:([1-9]\d*)\$|\(([^\)]+)\))?(\+)?(0|'[^$])?(-)?(\d+)?(?:\.(\d+))?([b-fosuxX])/.exec(_fmt)) !== null) {
        if (match[2]) {
          arg_names |= 1;
          var field_list = [], replacement_field = match[2], field_match = [];
          if ((field_match = /^([a-z_][a-z_\d]*)/i.exec(replacement_field)) !== null) {
            field_list.push(field_match[1]);
            while ((replacement_field = replacement_field.substring(field_match[0].length)) !== '') {
              if ((field_match = /^\.([a-z_][a-z_\d]*)/i.exec(replacement_field)) !== null) {
                field_list.push(field_match[1]);
              }
              else if ((field_match = /^\[(\d+)\]/.exec(replacement_field)) !== null) {
                field_list.push(field_match[1]);
              }
              else {
                throw('[sprintf] huh?');
              }
            }
          }
          else {
              throw('[sprintf] huh?');
          }
          match[2] = field_list;
        }
        else {
            arg_names |= 2;
        }
        if (arg_names === 3) {
            throw('[sprintf] mixing positional and named placeholders is not (yet) supported');
        }
        parse_tree.push(match);
      }
      else {
          throw('[sprintf] huh?');
      }
      _fmt = _fmt.substring(match[0].length);
    }
    return parse_tree;
    };
    return str_format;
  })();
  
  var vsprintf = function(fmt, argv) {
    argv.unshift(fmt);
    return sprintf.apply(null, argv);
  };
  return {
    'url': function(route_name, params) {
      var result = route_name;
      if (typeof(params) !== 'object'){
          params = {};
      }
      if (matchlist.hasOwnProperty(route_name)) {
          var route = matchlist[route_name];
        // param substitution
        for(var i=0; i < route[1].length; i++) {
            var param_name = route[1][i];
            if (!params.hasOwnProperty(param_name))
                throw new Error(
                    'parameter '+ 
                    param_name + 
                    ' is missing in route"' + 
                    route_name + '" generation');
        }
        result = sprintf(route[0], params);
  
        var ret = [];
        // extra params => GET
        for (var param in params){
            if (route[1].indexOf(param) === -1){
                ret.push(encodeURIComponent(param) + "=" + 
                encodeURIComponent(params[param]));
            }
        }
        var _parts = ret.join("&");
        if(_parts){
            result = result +'?'+ _parts;
        }
        if(APPLICATION_URL) {
            result = APPLICATION_URL + result;
        }
      }
  
      return result;
    },
    'register': function(route_name, route_tmpl, req_params) {
      if (typeof(req_params) !== 'object') {
        req_params = [];
      }
      // fix escape
      route_tmpl = unescape(route_tmpl);
      keys = [];
      for(var i=0; i < req_params.length; i++) {
        keys.push(req_params[i]);
      }
      matchlist[route_name] = [
      route_tmpl,
      keys
      ];
    },
    '_routes': function(){
        return matchlist;
    }
  };
})();
