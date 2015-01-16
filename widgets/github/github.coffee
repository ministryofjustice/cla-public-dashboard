delay = (ms, func) -> setTimeout func, ms

class Dashing.Github extends Dashing.Widget

  ready: ->
    # This is fired when the widget is done being rendered

  onData: (data) ->
    # Handle incoming data
    # You can access the html node of this widget with `@node`
    console.log(data)

    @onUpdate(1000)

  onUpdate: (duration) ->
    duration = duration || 200
    $(@node).addClass('s-updated')
    delay duration, => $(@node).removeClass('s-updated')
