$ = require('jquery')
sightglass = require('sightglass')
rivets = require('rivets')

Utils = require('./utils.coffee')

class ProgressBar
  @extension:
    name: 'ProgressBar'
    type: 'progress'

  constructor: (@app) ->
    return unless @app.theme.progressBarElement.length

    @elem = @app.theme.progressBarElement
    @player = @app.player
    @media = @app.player.media

    @render()
    @findElements()
    @bindEvents()
    @hideBuffering()

  showBuffering: () ->
    @bufferingElement.show()

  hideBuffering: () ->
    @bufferingElement.hide()

  switchTimeDisplay: =>
    @timeMode = if @timeMode == 'countup'
      'countdown'
    else
      'countup'

    @updateTime()

  updateBarWidths: () =>
    @updatePlayed()
    @updateLoaded()

  updateTime: (time) =>
    currentTime = time || @media.currentTime
    time = if @timeMode == 'countup'
      prefix = ''
      currentTime
    else
      prefix = '-'
      @player.duration - currentTime

    time = 0 if isNaN(time)
    timeString = Utils.secondsToHHMMSS(time)
    @timeElement.text(prefix + timeString)

    @updatePlayed()

    return timeString

  updateLoaded: (buffered) =>
    return unless @media.seekable.length

    newWidth = @media.seekable.end(@media.seekable.length - 1) * @timeRailFactor()
    @loadedElement.css('margin-left', 0).width(newWidth)

  #private

  context: () ->
    {}

  render: () ->
    html = $(@template)
    rivets.bind(html, @context)
    @elem.replaceWith(html)
    @elem = html

  template:
    """
    <div class="progress-bar">
      <div class="progress-bar-time-played" title="Switch display mode">00:00:00</div>
      <div class="progress-bar-rail">
        <span class="progress-bar-loaded"></span>
        <span class="progress-bar-buffering"></span>
        <span class="progress-bar-played"></span>
      </div>
    </div>
    """

  findElements: () ->
    @timeElement = @elem.find('.progress-bar-time-played')
    @railElement = @elem.find('.progress-bar-rail')
    @playedElement = @elem.find('.progress-bar-played')
    @loadedElement = @elem.find('.progress-bar-loaded')
    @bufferingElement = @elem.find('.progress-bar-buffering')

  triggerLoading: =>
    @updateLoaded()
    @showBuffering()

  triggerPlaying: =>
    @updateLoaded()
    @hideBuffering()

  triggerLoaded: =>
    @updateLoaded()
    @hideBuffering()

  handleLetgo: (event) =>
    $(@app.elem).off('mousemove')
    $(@app.elem).off('mouseup')
    $(@app.elem).off('mouseleave')
    $(@app.elem).off('touchmove')
    $(@app.elem).off('touchend')
    @handleDrop(event)

  handlePickup: (event) =>
    $(@app.elem).on 'mousemove', @handleDrag
    $(@app.elem).on 'mouseup', @handleLetgo
    $(@app.elem).on 'mouseleave', @handleLetgo
    $(@app.elem).on 'touchmove', @handleDrag
    $(@app.elem).on 'touchend', @handleLetgo

  bindEvents: () ->
    @timeElement.click => @switchTimeDisplay()

    $(@media).on('timeupdate', @updateTime)
      .on('play', @triggerPlaying)
      .on('playing', @triggerPlaying)
      .on('waiting', @triggerLoading)
      .on('loadeddata', @triggerLoaded)
      .on('progress', @updateLoaded)

    # drag&drop on time rail
    @elem.on 'mousedown', @handlePickup
    @elem.on 'touchstart', @handlePickup

  jumpToPosition: (position) =>
    if @player.duration
      pixelPerSecond = @player.duration/@barWidth()
      newTime = pixelPerSecond * position
      unless newTime == @media.currentTime
        @player.setCurrentTime(newTime)

  handleDrag: (event) =>
    position = Utils.calculateCursorPosition(event, @elem[0])
    if position <= @barWidth()
      @playedElement.width(position + 'px')

  handleDrop: (event) =>
    position = Utils.calculateCursorPosition(event, @elem[0])
    @jumpToPosition(position)

  barWidth: => @railElement.width()

  timeRailFactor: =>
    @barWidth()/@player.duration

  updatePlayed: () =>
    newWidth = @media.currentTime * @timeRailFactor()
    @playedElement.width(newWidth)

module.exports = ProgressBar
