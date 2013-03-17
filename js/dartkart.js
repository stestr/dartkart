function detectExecutionEnvironment() {
  var jsinfo = document.getElementById('info-javascript');
  var dartinfo = document.getElementById('info-dart');
  if (navigator.webkitStartDart) {
    // we are in Dartium 
    jsinfo.style.display = 'none';
    dartinfo.style.display='block'; 
  } else {
    jsinfo.style.display = 'block';
    dartinfo.style.display='none';
  }
}
