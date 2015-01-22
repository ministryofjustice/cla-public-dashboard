# dashing.js is located in the dashing framework
# It includes jquery & batman for you.
#= require dashing.js

#= require_directory .
#= require_tree ../../widgets

# console.log("Yeah! The dashboard has started!")

Dashing.on 'ready', ->
  Dashing.widget_margins ||= [10, 10]
  Dashing.widget_base_dimensions ||= [458, 510]
  Dashing.numColumns ||= 4

  contentWidth = (Dashing.widget_base_dimensions[0] + Dashing.widget_margins[0] * 2) * Dashing.numColumns

  Batman.setImmediate ->
    $('.gridster').width(contentWidth)
    $('.gridster ul:first').gridster
      widget_margins: Dashing.widget_margins
      widget_base_dimensions: Dashing.widget_base_dimensions
      avoid_overlapped_widgets: !Dashing.customGridsterLayout
      draggable:
        stop: Dashing.showGridsterInstructions
        start: -> Dashing.currentWidgetPositions = Dashing.getWidgetPositions()

  Batman.mixin Batman.Filters,
    formatDescription: (desc) ->
      closeInd = desc.indexOf("</a>")
      anchor = desc.slice(0, closeInd + 4)
      $aObj = $(anchor)
      $aObj.text() + " " + $aObj.attr("title")

    getIcon: (result) ->
      cl = "fa fa-"
      switch result
        when "success"
          cl += "thumbs-up"
        when "failure"
          cl += "thumbs-down"
        when "building"
          cl += "spinner fa-spin"
        when "aborted"
          cl += "close"
        when "warning"
          cl += "exclamation-triangle"
        when "up"
          cl += "arrow-circle-up"
        when "down"
          cl += "arrow-circle-down"
        else
          cl += "question"
      cl

    formatTime: (timestamp) ->
      moment(timestamp).fromNow()

    getAuthor: (actions) ->
      return actions[0].parameters[2].value
