

((window) ->

  requirejs.config
    #enforceDefine: true
    urlArgs: 'bust=' + (new Date()).getTime()
    paths:
      'jquery': 'jquery-1.10.2.min'
      'lodash': 'lodash.compat.min'
      'xregexp': 'xregexp-all-min'
      'async': 'async'

    shim:

      jquery:
        exports: '$'

      lodash:
        exports: '_'

      'jquery-lazyloadanything': 
        deps: ['jquery']


      'isOnScreen': 
        deps: ['jquery']

      "app":
        deps: ['jquery', 'lodash', 'xregexp', 'jquery-lazyloadanything', 'isOnScreen']
        exports: "_LazyLoad"


  require ["app"], (_LazyLoad)->
    _LazyLoad.get(window)
    return
  

  
  

  return
  # see: https://github.com/shichuan/javascript-patterns/blob/master/general-patterns/access-to-global-object.html
  #)(if typeof window is "undefined" then this else window)
)(window or (1
eval
)("this"))



