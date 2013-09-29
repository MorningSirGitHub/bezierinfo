define (require) ->


  class _LazyLoad

    VERSION: '0.1'

    constructor: (_global) ->

      @isScrolling = false
      @global = _global
      get_this = @
      $(_global).scroll ->
        get_this.isScrolling = true

          
        #MathJax.Hub.queue.Suspend();
        #MathJax.Hub.queue.pending = 1  if MathJax

        clearTimeout $.data(this, "scrollTimer")
        $.data this, "scrollTimer", setTimeout(->
          


          # do something
          get_this.isScrolling = false


        , 350)


      get_this = @
      @defer _global, "MathJax", ->
        

        _defer = get_this.defer
        _MathJax = _global.MathJax
        # Wait for mathjax config to load
        _defer _MathJax, "Hub", ->
          _defer _MathJax.Hub, "config", ->
            _defer _MathJax.Hub.config, "lazytex2jax", (lazytex2jax)->
              _defer _MathJax.Hub.config, "skipStartupTypeset", (skipStartupTypeset)->
                if skipStartupTypeset
                  get_this['lazytex2jax'] = lazytex2jax
                  get_this.bootstrap()


    defer: (parent_obj, waitfor, method)->

      if parent_obj?[waitfor]?
        method(parent_obj[waitfor])
      else
        parent_obj.watch waitfor, (id, oldval, newval) ->
          method(parent_obj[waitfor])
          newval
      return

    escapeRegExp: (str) ->
      str.replace /[\-\[\]{}()*+?.,\\\^$|#\s]/g, "\\$&" #.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");



    bootstrap: () ->
      _ = require('lodash')
      $ = require('jquery')
      XRegExp = require('xregexp')
      get_this = @
      $ ->
        getTextNodesIn = (el) ->
          $(el).find(":not(iframe,script,img,canvas)").addBack().contents().filter ->
            @nodeType is 3

        #console.log $(getTextNodesIn('body')).size() + " text nodes"

        lazy_watch_queue = {}

        # precedence???
        _escapeRegExp = get_this.escapeRegExp
        _.each(get_this.lazytex2jax, (delimiter_pack, delimiter_pack_name) ->
          _.each(delimiter_pack, (delimiter, index) ->
            

            start_delimiter = _escapeRegExp(delimiter[0]);
            end_delimiter = _escapeRegExp(delimiter[1]);
            
            #console.log start_delimiter
            #console.log end_delimiter

            regex_string = start_delimiter+'(.*?)'+end_delimiter

            re = new XRegExp.cache(regex_string, "sg");



            $(getTextNodesIn('body')).each(()->
              a = $(this)
              text = a.text()
              if re.test(text)

                lazy_element = {}
                lazy_element.start_delimiter = delimiter[0]
                lazy_element.end_delimiter = delimiter[1]

                name = "#{delimiter_pack_name}-#{index}"
                lazy_watch_queue[name] = lazy_element

                replacementpattern = "<lazymathjax name=\"lazy-load-mathjax-stamp-#{name}\">$1</lazymathjax>"
                new_text = XRegExp.replace(text, re, replacementpattern)

                a.replaceWith(new_text)
              )
            )
          )
        
        get_this.watch_setup(lazy_watch_queue)

        return

    isElementInViewport_old: (el) ->
      top = el.offsetTop
      left = el.offsetLeft
      width = el.offsetWidth
      height = el.offsetHeight
      while el.offsetParent
        el = el.offsetParent
        top += el.offsetTop
        left += el.offsetLeft
      top >= @global.pageYOffset and left >= @global.pageXOffset and (top + height) <= (@global.pageYOffset + @global.innerHeight) and (left + width) <= (@global.pageXOffset + @global.innerWidth)
    
    isElementInViewport: (el) ->
      rect = el.getBoundingClientRect()
      return rect.top >= 0 and rect.left >= 0 and rect.bottom <= (window.innerHeight or document.documentElement.clientHeight) and rect.right <= (window.innerWidth or document.documentElement.clientWidth)

    watch_setup: (lazy_watch_queue)->
      $ = require('jquery')
      get_this = @
      @counter = 0
      $ ->
        _.each(lazy_watch_queue, (delimiter_to_watch, name) ->

          qq = $("lazymathjax[name='lazy-load-mathjax-stamp-#{name}']")
          
          if qq.size() > 0
            qq.lazyloadanything
              onLoad: (e, LLobj) ->
                $element = LLobj.$element
                defer = () ->

                  bool = get_this.isElementInViewport($element.get(0))

                  if not bool
                    LLobj.loaded = false
                    return
                    
                  
                  if not get_this.isScrolling and bool


                    bool = get_this.isElementInViewport($element.get(0))
                    if not bool
                      LLobj.loaded = false
                      return
                    

                    start_delimiter = delimiter_to_watch.start_delimiter
                    end_delimiter = delimiter_to_watch.end_delimiter

                    mathjax_input = $("<mathjax>").html(start_delimiter + $element.text() + end_delimiter)

                    anotherdefer = ()->

                      if get_this.counter < 5
                        get_this.counter++

                        QUEUE = MathJax.Hub.queue

                        END_STEP = ()->
                          $element.replaceWith(mathjax_input.get(0))
                          if get_this.counter > 0
                            get_this.counter--
                          $element.remove()

                        QUEUE.Push(["Typeset", MathJax.Hub, mathjax_input.get(0)],END_STEP)

                      else

                        setTimeout(()->
                            anotherdefer()
                          ,100)
                      return
                    anotherdefer()

                  else
                    
                    setTimeout(()->
                        defer()
                      ,500)
                  return
                defer()

                return


          )
        $.fn.lazyloadanything('load')
        # setTimeout(()->
        #   $.fn.lazyloadanything('load')
        # ,1000)


        # mathjax_input = $("<mathjax></mathjax>").html($(this).text())
        # $(this).replaceWith(mathjax_input.get(0))

        # QUEUE = MathJax.Hub.queue

        # HIDEBOX = ()->
        #   mathjax_input.hide()

        # SHOWBOX = ()->
        #   mathjax_input.show()

        # QUEUE.Push(HIDEBOX,["Typeset",MathJax.Hub,mathjax_input.get(0)],SHOWBOX)
        
        #console.log $(this).get(0)
        #MathJax.Hub.Queue ["Typeset", MathJax.Hub, red.get(0)]


        return
        
        


      return


  # Ensure mathjax lazyloading happens once
  class Singleton
    instance = null

    @get: (global) ->
      instance ?= new _LazyLoad(global)

      return




  return Singleton