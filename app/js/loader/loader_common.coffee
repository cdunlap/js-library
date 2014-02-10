###@license
Factlink JavaScript library - https://factlink.com
Copyright (c) 2014 Factlink Team

Copyright for the annotator subcomponent:

Copyright 2012 Aron Carroll, Rufus Pollock, and Nick Stenning.

Permission is hereby granted, free of charge, to any person obtaining
a  copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
  distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Copyright for the jQuery subcomponent:

Copyright 2013 jQuery Foundation and other contributors
http://jquery.com/

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
  distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
###



factlink_loader_start_timestamp = new Date().getTime()


jslib_jail_code = __INLINE_JS_PLACEHOLDER__
style_code = __INLINE_CSS_PLACEHOLDER__
frame_style_code = __INLINE_FRAME_CSS_PLACEHOLDER__

do ->
  unsupported_browser = document.documentMode < 9
  return if unsupported_browser
  if window.FACTLINK_LOADED
    console.error 'FACTLINK already loaded!'
    return
  window.FACTLINK_LOADED = true

  window.FACTLINK = {}

  # Create proxy object that stores all calls
  # proxies calls from external content page to the js-library "jail" iframe's "FactlinkJailRoot"..
  methods = 'on,triggerClick,highlightAdditionalFactlinks,loadedBookmarklet,scrollTo,openFactlinkModal,initializeFactlinkButton,proxyLoaded'.split(',')

  storedMethodCalls = []

  storedMethodFactory = (name) ->
    -> storedMethodCalls.push(name: name, arguments: arguments) && undefined

  for name in methods
    window.FACTLINK[name] =
      if unsupported_browser
        ->
      else
        storedMethodFactory name

  mkEl = (name, id, content) ->
    el = document.createElement(name)
    id && el.id = id
    content && el.appendChild(content)
    el

  whenHasBody = ->
    # Add styles
    style_tag = mkEl 'style', null, document.createTextNode(style_code)
    document.getElementsByTagName('head')[0].appendChild style_tag

    #### Create iframe so jslib's namespace (window) doesn't collide with any content window.
    jslib_jail_iframe = mkEl 'iframe', 'factlink_jail_iframe'
    jslib_jail_iframe.style.display = 'none';
    document.body.appendChild(jslib_jail_iframe)

    load_time_before_jail = new Date().getTime()

    jail_window = jslib_jail_iframe.contentWindow
    jail_window.FrameCss = frame_style_code

    #### Load iframe with script tag
    jslib_jail_doc = jail_window.document

    jslib_jail_doc.open()
    jslib_jail_doc.write '<!DOCTYPE html><title></title>'
    jslib_jail_doc.close()

    script_tag = jslib_jail_doc.createElement 'script'
    script_tag.appendChild(jslib_jail_doc.createTextNode(jslib_jail_code))
    jslib_jail_doc.documentElement.appendChild(script_tag)

    root = jslib_jail_iframe.contentWindow.FactlinkJailRoot
    $ = jslib_jail_iframe.contentWindow.$
    root.perf.add_existing_timing_event 'factlink_loader_start', factlink_loader_start_timestamp
    root.perf.add_existing_timing_event 'before_jail', load_time_before_jail
    root.perf.add_timing_event 'after_jail'

    root.jail_ready_promise.resolve()

    root.core_loaded_promise.then ->

      #called from jail-iframe when core iframe is ready.
      for name in methods
        do (name) ->
          # don't return the value, as we can't do that when storing calls
          window.FACTLINK[name] = ->
            root[name](arguments...)
            return

      for methodCall in storedMethodCalls
        window.FACTLINK[methodCall.name](methodCall.arguments...)
      storedMethodCalls = undefined
      root.perf.add_timing_event 'FACTLINK_queue_emptied'


  tryToInit = (i) -> ->
    if document.body
      whenHasBody()
    else
      if localStorage?['debug'] then console.log('skipped init attempt ' + i)
      setTimeout tryToInit(i+1), i

  tryToInit(1)()

