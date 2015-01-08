class Dashing.JenkinsBuild extends Dashing.Widget
  _initBar: ->
    $(@node).find('.bar').each ->
      r = $(this).attr('r')
      offset = Math.PI * (r * 2) + 1
      $(this).css({
        transition: 'none',
        strokeDasharray: Math.ceil(offset),
        strokeDashoffset: Math.ceil(offset)
      })

  _fillBar: (val) ->
    progressBar = $(@node).find('.bar')
    r = progressBar.attr('r')
    c = Math.PI * (r * 2)

    val = 0   if val < 0
    val = 100 if val > 100

    offset = ((100 - val) / 100) * c + 1;

    progressBar.css({
      transition: 'stroke-dashoffset 800ms',
      strokeDashoffset: Math.ceil(offset)
    })

  ready: ->
    @_initBar()

  onData: (data) ->
    console.log(data)
    @_fillBar(data.value)
