define (require) ->


  class _LazyLoad

    VERSION: '0.1'

    constructor: (window) ->

      @window = window

      # Watch MathJax

      get_this = @
      _watch = get_this.watchproperty
      _watch window, "MathJax", ()->
        
        _MathJax = window.MathJax

        # Watch MathJax.Hub.config
        _watch _MathJax, "Hub", ()->
          _watch _MathJax.Hub, "config", ()->

            # Watch MathJax.Hub.config.lazytex2jax
            # Required for lazyloading
            _watch _MathJax.Hub.config, "lazytex2jax", (lazytex2jax)->
              
              # skipStartupTypeset is required for lazyloading
              _watch _MathJax.Hub.config, "skipStartupTypeset", (skipStartupTypeset)->
                if skipStartupTypeset is true
                  get_this['lazytex2jax'] = lazytex2jax

                  _ = require('lodash')
                  _.defer((f, _this)->
                      f.call(_this)

                    , get_this.bootstrap, get_this )
                  return
                  

      async = require('async')
      return

    bootstrap: () ->
      _ = require('lodash')
      $ = require('jquery')
      XRegExp = require('xregexp')

      get_this = @
      @stopRender = false
      _stopRender = @stopRender
      $ ->

        # Convert all mathjax to lazy
        #####

        # Credit: http://stackoverflow.com/questions/298750/how-do-i-select-text-nodes-with-jquery
        getTextNodesIn = (el) ->
          $(el).find(":not(iframe,script,img,canvas)").addBack().contents().filter ->
            @nodeType is 3

        _escapeRegExp = get_this.escapeRegExp

        lazy_watch_queue = {}

        # Check precedence of $$ over $
        _.each(get_this.lazytex2jax, (delimiter_pack, delimiter_pack_name) ->
          _.each(delimiter_pack, (delimiter, index) ->

            start_delimiter = _escapeRegExp(delimiter[0])
            end_delimiter = _escapeRegExp(delimiter[1])

            regex_string = start_delimiter+'(.*?)'+end_delimiter

            re = new XRegExp.cache(regex_string, "sg");

            $(getTextNodesIn('body')).each(()->
              $this = $(this)
              $text = $this.text()
              if re.test($text)

                lazy_element = {}
                lazy_element.start_delimiter = delimiter[0]
                lazy_element.end_delimiter = delimiter[1]
                name = "#{delimiter_pack_name}-#{index}"
                lazy_element.selector = "lazymathjax[name='lazy-load-mathjax-stamp-#{name}']"

                lazy_watch_queue[name] = lazy_element

                replacementpattern = "<lazymathjax name=\"lazy-load-mathjax-stamp-#{name}\">$1</lazymathjax>"
                new_text = XRegExp.replace($text, re, replacementpattern)

                $this.replaceWith(new_text)
              return
              )
            return
            )
          return
          )

        # Watch lazy mathjax
        #####



        # mini plugin
        # should be a separate amd module
        #$.fn.inViewport = (options)->

        get_this.init_renderMathJax()

        $(get_this.window).on("scroll.lmjx resize.lmjx", ()->

          _stopRender = true

          clearTimeout $.data(this, "lmjxeventTimer")
          $.data this, "lmjxeventTimer", setTimeout(->
            
            # End step of scroll and/or resize event

            _stopRender = false

            _isElementInViewport = get_this.isElementInViewport
            _.each(lazy_watch_queue, (delimiter_to_watch, name) ->

              $elems = $(delimiter_to_watch.selector)
              
              if ($elems.size() > 0)
                _renderMathJax = get_this.renderMathJax

                $elems.each(()->
                  
                  if(_stopRender is false and _isElementInViewport($(this).get(0)) is true)
                    # console.log $(this).get(0) is this
                    #_renderMathJax(this)
                    render_package = 
                      elem: this,
                      start_delimiter: delimiter_to_watch.start_delimiter,
                      end_delimiter: delimiter_to_watch.end_delimiter


                    _renderMathJax.call(get_this, render_package)

                  )
              )     

            # _.defer((f, _this)->
            #     f.call(_this)
            #   , trigger, get_this )

            # do something
            #console.log "something happened and stopped!"


          , 500)
          )

        $(get_this.window).trigger('scroll.lmjx')

      return

    init_renderMathJax: ()->
      async = require('async')
      _ = require('lodash')

      if(!@queue?)
        worker = (_work, callback)->
          _f = _work['f']
          _this = _work['_this']
          _args = _work['_args'] or [] # an array
          _args.push(callback)

          _.defer((f, _this, _args)->
              f.apply(_this,_args)
            , _f, _this, _args )

        @queue = async.queue(worker, 5)

      if(!@MathJaxQueue? )
        @MathJaxQueue = @window.MathJax.Hub.queue

      return

    renderMathJax: (render_package)->

      _queue = @queue
      $ = require('jquery')

      render_process = (render_package, callback) ->

        if @isElementInViewport(render_package.elem) is false
          return callback(true)

        if @stopRender is true
          return callback(true)

        $element = $(render_package.elem)
        start_delimiter = render_package.start_delimiter
        end_delimiter = render_package.end_delimiter

        $newelement = $("<mathjax>").html(start_delimiter + $element.text() + end_delimiter)
        $element.replaceWith($newelement.get(0))
        $element.remove()

        QUEUE = @MathJaxQueue

        some_callback = ()->
          return callback()

        QUEUE.Push(["Typeset", MathJax.Hub, $newelement.get(0), callback])

        return
      
      # Object
      work_package =
        f: render_process,
        _this: @
        _args: [render_package]
      
      # Queue render work
      _queue.push(work_package, (cancelled)->
        #console.log "done!"
        )
      #if(_queue.length() <= 20)



      return

    # Watch property of parent_obj, and execute callback whenever it changed.
    # callback is called with parent_obj[property] as input

    # credit: http://stackoverflow.com/questions/1029241/javascript-object-watch-for-all-browsers
    watchproperty: (parent_obj, property, callback)->

      if parent_obj?[property]?
        callback(parent_obj[property])
      else
        parent_obj.watch property, (id, oldval, newval) ->
          callback(parent_obj[property])
          return newval
      return

    # Credit: http://stackoverflow.com/questions/123999/how-to-tell-if-a-dom-element-is-visible-in-the-current-viewport
    isElementInViewport: (el) ->
      rect = el.getBoundingClientRect()
      docEl = document.documentElement
      vWidth = @window.innerWidth or docEl.clientWidth
      vHeight = @window.innerHeight or docEl.clientHeight
      efp = (x, y) ->
        document.elementFromPoint x, y

      contains = (if "contains" of el then "contains" else "compareDocumentPosition")
      has = (if contains is "contains" then 1 else 0x10)
      
      # Return false if it's not in the viewport
      return false  if rect.right < 0 or rect.bottom < 0 or rect.left > vWidth or rect.top > vHeight
      
      # Return true if any of its four corners are visible
      (eap = efp(rect.left, rect.top)) is el or el[contains](eap) is has or (eap = efp(rect.right, rect.top)) is el or el[contains](eap) is has or (eap = efp(rect.right, rect.bottom)) is el or el[contains](eap) is has or (eap = efp(rect.left, rect.bottom)) is el or el[contains](eap) is has

    isElementInViewport_old: (el) ->
      rect = el.getBoundingClientRect()
      return rect.top >= 0 and rect.left >= 0 and rect.bottom <= (@window.innerHeight or document.documentElement.clientHeight) and rect.right <= (@window.innerWidth or document.documentElement.clientWidth)


    escapeRegExp: (str) ->
      str.replace /[\-\[\]{}()*+?.,\\\^$|#\s]/g, "\\$&" #.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");


  # Ensure mathjax lazyloading happens once
  class Singleton
    instance = null

    @get: (window) ->
      instance ?= new _LazyLoad(window)
      return

  return Singleton