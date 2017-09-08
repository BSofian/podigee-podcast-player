IframeResizer = require('./iframe_resizer.coffee')

class Iframe
  constructor: (@elem)->
    @id = Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1)
    config = @elem.dataset.configuration
    @configuration = if typeof config == 'string'
      window[config] || {json_config: config}
    else
      config

    @configuration.parentLocationHash = window.location.hash
    @configuration.embedCode = @elem.outerHTML

    @url = "#{@origin()}/podigee-podcast-player.html?id=#{@id}&iframeMode=script"

    @buildIframe()
    @setupListeners()
    @replaceElem()
    @injectConfiguration() if @configuration

  origin: () ->
    scriptSrc = @elem.src
    unless window.location.protocol.match(/^https/)
      scriptSrc = scriptSrc.replace(/^https/, 'http')
    scriptSrc.match(/(^.*\/)/)[0].replace(/javascripts\/$/, '').replace(/\/$/, '')

  buildIframe: ->
    @iframe = document.createElement('iframe')
    @iframe.id = @id
    @iframe.scrolling = 'no'
    @iframe.src = @url
    @iframe.style.border = '0'
    @iframe.style.overflowY = 'hidden'
    @iframe.style.transition = 'height 100ms linear'
    @iframe.width = "100%"
    @iframe

  setupListeners: ->
    IframeResizer.listen('resizePlayer', @iframe)

  replaceElem: ->
    @iframe.className += @elem.className
    @elem.parentNode.replaceChild(@iframe, @elem)

  injectConfiguration: ->
    window.addEventListener 'message', ((event) =>
      try
        eventData = JSON.parse(event.data || event.originalEvent.data)
      catch
        return
      return unless eventData.id == @iframe.id
      return unless eventData.listenTo == 'sendConfig'

      config = if @configuration.constructor == String
        @configuration
      else
        JSON.stringify(@configuration)
      @iframe.contentWindow.postMessage(config, '*')
    ), false

class Embed
  constructor: ->
    players = []
    elems = document.querySelectorAll('script.podigee-podcast-player')

    return if elems.length == 0

    for elem in elems
      players.push(new Iframe(elem))

    window.podigeePodcastPlayers = players

new Embed()
