String.prototype.startsWith = function(prefix){
  return this.indexOf(prefix, 0) != -1;
}

String.prototype.endsWith = function(suffix){
  return this.indexOf(suffix, this.length - suffix.length) != -1;
}

