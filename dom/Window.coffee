package "cafe.dom",

Window: class Window

  @getViewPortSize: () ->
    myWidth = 0
    myHeight = 0

    if typeof window.innerWidth is 'number'
      #Non-IE
      myWidth  = window.innerWidth
      myHeight = window.innerHeight
    else if (doc = document.documentElement) and (doc.clientWidth or doc.clientHeight)
      #IE 6+ in 'standards compliant mode'
      myWidth  = doc.clientWidth
      myHeight = doc.clientHeight
      doc = null
    else if (body = document.body) and (body.clientWidth or body.clientHeight)
      #IE 4 compatible
      myWidth  = body.clientWidth
      myHeight = body.clientHeight

    return {
      width : myWidth
      height: myHeight
    }

  @getScrollOffsets: () ->
    scrOfX = 0
    scrOfY = 0

    if typeof window.pageYOffset is 'number'
      #Netscape compliant
      scrOfY = window.pageYOffset
      scrOfX = window.pageXOffset
    else if (body = document.body) and (body.scrollLeft or body.scrollTop)
      #DOM compliant
      scrOfY = body.scrollTop
      scrOfX = body.scrollLeft
      body = null
    else if (doc = document.documentElement) and (doc.scrollLeft or doc.scrollTop)
      #IE6 standards compliant mode
      scrOfY = doc.scrollTop
      scrOfX = doc.scrollLeft
      doc = null

    return {
      x: scrOfX
      y: scrOfY
    }

  @smoothScrollingOffset: (node, restrictions) ->
    fullHeight = document.documentElement.scrollHeight
    fullWidth = document.documentElement.scrollWidth

    blockHeight = node.offsetHeight
    blockWidth  = node.offsetWidth

    viewPortSize = @getViewPortSize()

    kH = 1 + (viewPortSize.height - blockHeight) / fullHeight
    kW = 1 + (viewPortSize.width  - blockWidth)  / fullWidth

    #console.log "kH, kW (", kH, ", ", kW, ")"

    scrollOffsets = @getScrollOffsets()

    topOffset    = restrictions.top or 0
    bottomOffset = fullHeight - blockHeight - restrictions.bottom or 0

    leftOffset  = restrictions.left or 0
    rightOffset = fullWidth - blockWidth - restrictions.right or 0

    top = scrollOffsets.y * kH

    top = topOffset    if top < topOffset
    top = bottomOffset if bottomOffset < top

    left = scrollOffsets.x * kW

    left = leftOffset  if left < leftOffset
    left = rightOffset if rightOffset < left

    #console.log "left, top (", left, ", ", top, ")"

    return {
      x: left
      y: top
    }
