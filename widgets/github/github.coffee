class Dashing.Github extends Dashing.Widget

  ready: ->
    # This is fired when the widget is done being rendered

  onData: (data) ->
    # Handle incoming data
    # You can access the html node of this widget with `@node`
    console.log(data)
    $(@node).fadeOut().fadeIn()
