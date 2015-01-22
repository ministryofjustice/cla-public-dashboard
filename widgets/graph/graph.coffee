class Dashing.Graph extends Dashing.Widget

  @accessor 'current', ->
    return @get('displayedValue') if @get('displayedValue')
    points = @get('points')
    if points
      points[points.length - 1].y

  ready: ->
    @graph = new Rickshaw.Graph(
      element: $(@node).find('.content')[0]
      renderer: @get("graphtype")
      stroke: true
      preserve: true
      series: [
        {
          data: @get('points')
        }
      ]
    )

    x_axis = new Rickshaw.Graph.Axis.Time(graph: @graph)
    y_axis = new Rickshaw.Graph.Axis.Y(
      graph: @graph
      tickFormat: Rickshaw.Fixtures.Number.formatKMBT
    )
    @graph.render()

  onData: (data) ->
    console.log(data)
    if @graph
      @graph.series[0].data = data.points
      @graph.update()
