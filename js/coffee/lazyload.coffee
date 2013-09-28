

((global) ->

  requirejs.config
    #enforceDefine: true
    urlArgs: 'bust=' + (new Date()).getTime()
    paths:
      'jquery': 'jquery-1.10.2.min'
      'underscore': 'underscore-min'
      'xregexp': 'xregexp-all-min'

    shim:

      jquery:
        exports: '$'

      underscore:
        exports: '_'

      'jquery-lazyloadanything': 
        deps: ['jquery']


      'isOnScreen': 
        deps: ['jquery']

      "app":
        deps: ['jquery', 'underscore', 'xregexp', 'jquery-lazyloadanything', 'isOnScreen']
        exports: "_LazyLoad"


  require ["app"], (_LazyLoad)->
      $ = require('jquery')
      $ ->
        _LazyLoad.get(global)
      return
  

  
  

  return
  # see: https://github.com/shichuan/javascript-patterns/blob/master/general-patterns/access-to-global-object.html
  #)(if typeof window is "undefined" then this else window)
)(this or (1
eval_
)("this"))



