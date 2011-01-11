# only markup:
#
# ~cup "path/to/cap/file"
#   context:
#     title : "Foo"
#     path  : "/zig"
#
# document fragment:
#
# document.body.appendChild ~cup ! "path/to/cap/file"
#   context:
#     title : "Foo"
#     path  : "/zig"
__htmlCup = (fragment, html) ->

  return html unless fragment

  div = document.createElement("div")
  div.innerHTML = html

  fragment = document.createDocumentFragment()
  fragment.appendChild(node) while node = div.firstChild

  return fragment
