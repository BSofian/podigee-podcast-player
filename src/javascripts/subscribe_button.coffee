class SubscribeButton
  @open: (@app) ->
    data = JSON.stringify({
      listenTo: 'subscribeButtonTrigger',
      detail : {
        title: @app.podcast.title,
        subtitle: @app.podcast.subtitle,
        cover: @app.episode.coverUrl,
        feeds: [
          {url: @app.podcast.feed.feedUrl, "type": "audio", "format": "mp3"}
        ]
      }
    })
    window.parent.postMessage(data, '*')

module.exports = SubscribeButton
