@import "cafe/Deferred"
@import "cafe/Event"
@import "cafe/event/Observable"

~stylesheet "cafe/jet/content-assist/default", "all"

# @author Sergey Chikuyonok (serge.che@gmail.com)
# @link http://chikuyonok.ru
Utils =

  # Проверяет, есть ли класс у элемента
  #
  # @param Element elem
  # @param String className
  # @return Boolean
  hasClass: (elem, className) ->
    return no unless cl = elem.className

    return " #{cl} ".indexOf(" #{className} ") >= 0

   # Добавляет класс элементу
   #
   # @param Element elem
   # @param String className
  addClass: (elem, className) ->
    array = className.trim?().split(/\s+/g) or []

    classes = (cl for cl in array when not @hasClass(elem, cl))

    if classes.length
      elem.className += " " + classes.join(" ")

  # Удаляет класс у элемента
  #
  # @param Element elem
  # @param String className
  removeClass: (elem, className) ->
    names = className.trim?().split(/\s+/g) or []

    return false if names.length is 0

    remove = (array, removable) -> (cl for cl in array when cl isnt removable).join(" ")

    array = elem.className.trim().split(/\s+/g) or []

    classes = ""

    if names.length > 1
      classes += " " + remove(array, name) for name in names
    else
      classes += remove(array, className)

    elem.className = classes

  # Removes element's content
  # @param Element elem
  emptyElement: (elem) ->
    elem.removeChild(child) while child = elem.firstChild

  # Sanitazes string for size measurement
  # @param String str
  # @return String
  sanitizeString: (str) ->
    xml_chars =
      "<" : "&lt;"
      ">" : "&gt;"
      "&" : "&amp;"

    str = str.replace(/[<>&]/g, (str) -> xml_chars[str] )

    unless @hasPreWrap?
      # different browser use different newlines, so we have to figure out
      # native browser newline and sanitize incoming text with it
      tx = document.createElement('textarea')
      tx.value = '\n'
      @hasPreWrap = ! tx.currentStyle # pre-wrap in IE is not the same as in other browsers
      tx = null

    return str if @hasPreWrap

    breaker = if navigator.userAgent.toLowerCase().indexOf('msie 6') is -1 then String.fromCharCode(8203) else "&shy;"

    return str.replace(/\s/g, "&nbsp;" + breaker);

  # Split text into lines. Set <code>removeEmpty</code> to true to filter
  # empty lines
  # @param {String} text
  # @param {Boolean} [removeEmpty]
  # @return {Array}
  splitByLines: (text, removeEmpty) ->
    return [] unless text.replace(/:?/, "")

    # IE fails to split string by regexp,
    # need to normalize newlines first
    # Also, Mozilla's Rhiho JS engine has a wierd newline bug
    lines = text
      .replace(/\r\n/g, '\n')
      .replace(/\n\r/g, '\n')
      .split('\n')

    return lines unless removeEmpty

    return (line for line in lines when line.trim())

  # Creates new element with given class name
  # @param String name Element's name
  # @param String class_name Element's class name
  # @return Element
  createElement: (name, class_name) ->
    elem = document.createElement(name)
    elem.className = class_name if class_name

    return elem

  toCamelCase: (str) ->
    return str.replace(/\-(\w)/g, (str, ch) -> ch.toUpperCase() )

  # Set CSS propesties for element
  # @param Element elem
  # @param Object params
  setCSS: (elem, params) ->
    return unless elem

    props = []
    num_props = {'line-height': 1, 'z-index': 1, opacity: 1}

    for p, value of params
      name = p.replace(/([A-Z])/g, '-$1').toLowerCase()

      value += "px" if typeof value is "number" and name not of num_props

      props.push(name + ":" + value);

    elem.style.cssText += ";" + props.join(";");

  # Returns value of CSS property <b>name</b> of element <b>elem</b>
  # @author John Resig (http://ejohn.org)
  # @param Element elem
  # @param String|Array name
  # @return String|Object
  getCSS: (elem, name, force_computed) ->
    result = {}
    is_array = name instanceof Array

    use_w3c = document.defaultView && document.defaultView.getComputedStyle
    rnumpx = /^-?\d+(?:px)?$/i
    rnum = /^-?\d(?:\.\d+)?/
    rsuf = /\d$/

    _name = if is_array then name else [name]

    for n in _name
      name_camel = Utils.toCamelCase(n);

      # If the property exists in style[], then it's been set
      # recently (and is current)
      if not force_computed and elem.style[name_camel]
        result[n] = result[name_camel] = elem.style[name_camel]
      # Or the W3C's method, if it exists
      else if use_w3c
        cs = window.getComputedStyle(elem, "") unless cs

        result[n] = result[name_camel] = cs and cs.getPropertyValue(n)
      else if elem.currentStyle
        ret   = elem.currentStyle[n] or elem.currentStyle[name_camel]
        style = elem.style or elem

        # From the awesome hack by Dean Edwards
        # http://erik.eae.net/archives/2007/07/27/18.54.15/#comment-102291

        # If we're not dealing with a regular pixel number
        # but a number that has a weird ending, we need to convert it to pixels
        if not rnumpx.test(ret) and rnum.test(ret)
          # Remember the original values
          left = style.left
          rsLeft = elem.runtimeStyle.left

          # Put in the new values to get a computed value out
          elem.runtimeStyle.left = elem.currentStyle.left
          suffix = if rsuf.test(ret) then "em" else ""
          style.left = if name_camel is "fontSize" then "1em" else (ret + suffix or 0)
          ret = style.pixelLeft + "px"

          # Revert the changed values
          style.left = left
          elem.runtimeStyle.left = rsLeft

        result[n] = result[name_camel] = ret

    return result if is_array

    return result[Utils.toCamelCase(name)];

# Stores and revalidetes text line heights. The problem of getting line
# height is that a single line could be spanned across multiple lines.
# It this case we can't use <code>line-height</code> CSS property, we
# need to calculate real line height
# @class
#
class LineCacher
  measurer: null
  width   : null
  lines   : null

  # @param Element measurer
  constructor: (@measurer)->
    @width = @measurer.clientWidth

    @reset()

  # Returns line position in pixels in passed text
  # @param Number line_num Line index (starting from 0) to get offset
  # @param String text
  #
  # @return Number Offset in pixels
  getLineOffset: (line_num, text) ->
    return 0 unless line_num

    m = @measurer
    force_recalc = m.clientWidth isnt @width
    lines = Utils.splitByLines(text)
    affected_params = Utils.getCSS(m, ['padding-top', 'padding-bottom'])
    affected_size = parseFloat(affected_params['padding-top']) + parseFloat(affected_params['padding-bottom'])
    total_height = 0

    for i in [0 ... Math.min(lines.length, line_num)]
      line = lines[i]

      if force_recalc or not @lines[i] or @lines[i].text isnt line
        m.innerHTML = Utils.sanitizeString(line or '&nbsp;')

        @lines[i] =
          text  : line
          height: m.offsetHeight - affected_size

      total_height += @lines[i].height

    @width = m.clientWidth

    return total_height

  # Reset lines cache
  reset: () ->
    @lines = []


class TextViewer extends Observable

  # @param Element textarea
  constructor: (@textarea) ->
    @textarea.setAttribute("autocomplete", "off")

    @_measurer = @createMeasurer(@textarea)

    @updateMeasurerSize()

    @line_cacher = new LineCacher(@_measurer)

    @modifiedEventPrevented = false

    last_length = -1
    last_value  = null;

    # watch for content modification
    # if we think it was modified, we'll send special "modify" event
    Event.add(@textarea, 'paste change keyup', (evt) =>
      setTimeout(
        =>
          try
            return if @modifiedEventPrevented

            val = @textarea.value

            if val.length isnt last_length or val isnt last_value
              @notifyListeners('modify')

              last_length = val.length
              last_value  = val
          finally
            @modifiedEventPrevented = no
        10
      )
    )

    Event.add(window, 'focus resize', (evt) => @updateMeasurerSize() )

  reset: () ->
    @textarea.value = ""

    Event.dispatch(@textarea, "change")

TextViewer.prototype[name] = method for name, method of `{
  /**
   * Creates text measurer for textarea
   * @param {Element} textarea
   * @return Element
   */
  createMeasurer: function(textarea) {
    var measurer = Utils.createElement('div', 'cafe-jet-content-assist-measurer'),
      /**
       * textarea element properties that should be copied to measurer
       * on order to correctly calculate popup position
       */
      copy_props = ('font-family,font-size,line-height,text-indent,' +
              'padding-top,padding-right,padding-bottom,padding-left,' +
              'border-left-width,border-right-width,border-left-style,border-right-style').split(','),
      css_props = Utils.getCSS(textarea, copy_props);

    // copy properties
    for (var i = 0; i < copy_props.length; i++) {
      var prop = copy_props[i];
      measurer.style[Utils.toCamelCase(prop)] = css_props[prop];
    }

    if (textarea.parentNode.nodeName == "P") {
      textarea.parentNode.parentNode.appendChild(measurer);
    } else {
      textarea.parentNode.appendChild(measurer);
    }

    return measurer;
  },

  preventModifiedEvent: function() {
    this.modifiedEventPrevented = true;
  },
  /**
   * Returns current selection range of textarea
   */
  getSelectionRange: function() {
    if ('selectionStart' in this.textarea) { // W3C's DOM
      return {
        start: this.textarea.selectionStart,
        end: this.textarea.selectionEnd
      };
    } else if (document.selection) { // IE
      this.textarea.focus();

      var range = document.selection.createRange();

      if (range === null) {
        return {
          start: 0,
          end: this.getContent().length
        };
      }

      var re = this.textarea.createTextRange();
      var rc = re.duplicate();
      re.moveToBookmark(range.getBookmark());
      rc.setEndPoint('EndToStart', re);

      return {
        start: rc.text.length,
        end: rc.text.length + range.text.length
      };
    } else {
      return null;
    }
  },

  /**
   * Set selection range for textarea
   * @param {Number} start
   * @param {Number} [end]
   */
  setSelectionRange: function(start, end) {
    if (typeof(end) == 'undefined')
      end = start;

    var target = this.textarea;

    // W3C's DOM
    if ('setSelectionRange' in target) {
      target.setSelectionRange(start, end);
    } else if ('createTextRange' in target) {
      var t = target.createTextRange();

      t.collapse(true);

      // IE has an issue with handling newlines while creating selection,
      // so we need to adjust start and end indexes
//        var delta = Utils.splitByLines(getContent().substring(0, start)).length - 1;
//        end -= delta + Utils.splitByLines(getContent().substring(start, end)).length - 1;
//        start -= delta;

      t.moveStart('character', start);
      t.moveEnd('character', end - start);
      t.select();
    }
  },

  /**
   * Returns current caret position
   * @return {Number|null}
   */
  getCaretPos: function() {
    var selection = this.getSelectionRange();
    return selection ? selection.start : null;
  },

  /**
   * Set current caret position
   * @param {Number} pos
   */
  setCaretPos: function(pos) {
    this.setSelectionRange(pos);
  },

  /**
   * Get textare content
   * @return {String}
   */
  getContent: function() {
    return this.textarea.value;
  },

  /**
   * Update measurer size
   */
  updateMeasurerSize: function() {
    var af_props = Utils.getCSS(this.getElement(), ['padding-left', 'padding-right', 'border-left-width', 'border-right-width']),
      offset = parseInt(af_props['padding-left'])
        + parseInt(af_props['padding-right'])
        + parseInt(af_props['border-left-width'])
        + parseInt(af_props['border-right-width']);

    this._measurer.style.width = (this.textarea.clientWidth - offset) + 'px';
  },

  /**
   * Find start and end index of text line for <code>from</code> index
   * @param {String} text
   * @param {Number} from
   */
  findNewlineBounds: function(text, from) {
    var len = text.length,
      start = 0,
      end = len - 1;

    // search left
    for (var i = from - 1; i > 0; i--) {
      var ch = text.charAt(i);
      if (ch == '\n' || ch == '\r') {
        start = i + 1;
        break;
      }
    }
    // search right
    for (var j = from; j < len; j++) {
      var ch = text.charAt(j);
      if (ch == '\n' || ch == '\r') {
        end = j;
        break;
      }
    }

    return {start: start, end: end};
  },

  /**
   * Returns character pixel position relative to textarea element
   * @param {Number} offset Character index
   * @returns object with <code>x</code> and <code>y</code> properties
   */
  getCharacterCoords: function(offset) {
    var content = this.getContent(),
      line_bounds = this.findNewlineBounds(content, offset);

    this._measurer.innerHTML = Utils.sanitizeString(content.substring(line_bounds.start, offset)) + '<i>' + (this.getChar(offset) || '.') + '</i>';
    /** @type {Element} */
    var beacon = this._measurer.getElementsByTagName('i')[0],
      beacon_pos = {x: beacon.offsetLeft, y: beacon.offsetTop};

    // find out current line index
    var cur_line = Utils.splitByLines(content.substring(0, line_bounds.start)).length;
    cur_line = Math.max(0, cur_line - 1);
    var line_offset = this.line_cacher.getLineOffset(cur_line, content);

    Utils.emptyElement(this._measurer);

    return {
      x: beacon_pos.x,
      y: beacon_pos.y + line_offset
    };
  },

  /**
   * Returns absolute (relative to first offsetParent of textarea) character
   * coordinates. You can use it to position popup element
   * @param {Number} offset Character index
   * @returns object with <code>x</code> and <code>y</code> properties
   */
  getAbsoluteCharacterCoords: function(offset) {
    var pos = this.getCharacterCoords(offset);
    return {
      x: this.textarea.offsetLeft + pos.x - this.textarea.scrollLeft,
      y: this.textarea.offsetTop + pos.y - this.textarea.scrollTop
    };
  },

  /**
   * Returns character at offset
   * @param {Number} offset
   * @return {String}
   */
  getChar: function(offset) {
    return this.getContent().charAt(offset);
  },

  /**
   * @return {Element}
   */
  getElement: function() {
    return this.textarea;
  },

  /**
   * Replaces text substring with new value
   * @param {String} text
   * @param {Number} start
   * @param {Number} end
   */
  replaceText: function(text, start, end) {
    var has_start = (typeof start != 'undefined'),
      has_end = (typeof end != 'undefined'),
      content = this.getContent();

    if (!has_start && !has_end) {
      start = 0;
      end = content.length;
    } else if (!has_end) {
      end = start;
    }

    this.textarea.value = content.substring(0, start) + text + content.substring(end);
  },

  addEvent: function(type, fn){
    var items = type.split(/\s+/),
      elem = this.getElement();

    for (var i = 0, il = items.length; i < il; i++) {
      if (items[i].toLowerCase() == 'modify') {
        this.addListener('modify', fn);
      } else {
        Event.add(elem, type, fn);
      }
    }
  },

  removeEvent: function(type, fn) {
    var items = type.split(/\s+/),
      elem = this.getElement();

    for (var i = 0, il = items.length; i < il; i++) {
      if (items[i].toLowerCase() == 'modify') {
        this.removeListener('modify', fn);
      } else {
        Event.remove(elem, type, fn);
      }
    }
  }
}`

# A content assist processor proposes completions and computes context
# information for a particular character offset. This interface is similar to
# Eclipse's IContentAssistProcessor
#
# @author Sergey Chikuyonok (serge.che@gmail.com)
# @link http://chikuyonok.ru
# @require TextViewer
# @require CompletitionProposal
class ContentAssistProcessor

  onCancelCallbacks: null
  generator: null

  constructor: (words) ->
    @onCancelCallbacks = {}

    @setWords(words)          if words instanceof Array and words.length > 0
    @setWordsProvider(words)  if typeof words is "function"

    @setProposalHTMLGenerator = (@generator) ->

`
ContentAssistProcessor.prototype = {
  charMode: "clearWords",

  notAllowedChars: {
    clearWords : /[\s\*\.,:@\!\?\#%\^\$\(\)\{\}\[\]=\+<>'"«»\\\/]/,
    clearPhrase: /[\*\.,:@\!\?\#%\^\$\(\)\{\}\[\]=\+<>'"«»\\\/]/,
    allSymbols : null
  },

  /**
   * Returns a list of completion proposals based on the specified location
   * within the document that corresponds to the current cursor position
   * within the text viewer.
   *
   * @param {TextViewer} viewer The viewer whose document is used to compute
   * the proposals
   *
   * @param {Number} offset An offset within the document for which
   * completions should be computed
   *
   * @return CompletitionProposal[]
   */
  computeCompletionProposals: function(viewer, offset, id) {
    var cur_offset = offset - 1,
      cur_word = '',
      cur_char = '';

    // search for word prefix
    while (cur_offset >= 0 && this.isAllowedChar(cur_char = viewer.getChar(cur_offset))) {
      cur_word = cur_char + cur_word;
      cur_offset--;
    }

    // search for right word's bound
    var right_bound = offset;
    while (right_bound < 1000 && this.isAllowedChar(viewer.getChar(right_bound))) {
      right_bound++;
    }

    return Deferred.processing(
      __bind(function() {
        return this.suggestWords(cur_word, id);
      }, this),
      __bind(function(suggestions) {
        var proposals = null;
        if (suggestions.length) {
          proposals = [];

          for (var i = 0, il = suggestions.length; i < il; i++) {
            var s = suggestions[i];
            var proposal = this.completitionProposalFactory(cur_word, s, offset - cur_word.length, right_bound - cur_offset - 1, offset - cur_word.length + s.toString().length);
            proposals.push(proposal);
          }
        }

        return proposals;
      }, this)
    );
  },

  /**
   * @param {String} str The actual string to be inserted into the document
   * @param {Number} offset The offset of the text to be replaced
   * @param {Number} length The length of the text to be replaced
   * @param {Number} cursor The position of the cursor following the insert
   * @return {CompletionProposal}
   */
  completitionProposalFactory: function(cur_word, str, offset, length, cursor) {
    var proposal = new CompletionProposal(cur_word, str, offset, length, cursor);

    if (this.generator) {
      proposal.setHTMLGenerator(this.generator);
    }

    return proposal;
  },

  /**
   * Returns the characters which when entered by the user should
   * automatically trigger the presentation of possible completions.
   * @private Doesn't work yet
   * @return {String}
   */
  getActivationChars: function() {
    return 'abcdefghijklmnopqrstuvwxyz!@$';
  },

  /**
   * Check if passed character is allowed for word bounds
   * @param {String} ch
   * @return {Boolean}
   */
  isAllowedChar: function(ch) {
    ch = String(ch);
    if (!ch) return false;

    var re_ch = this.notAllowedChars[this.charMode];
    return re_ch === null || ! re_ch.test(ch);
  },

  setCharMode: function(mode) {
    this.charMode = mode;
  },

  setWordsProvider: function(wordsProvider) {
    this.words = wordsProvider;
  },
  setWords: function(words) {
    // index words by first letter for faster search
    var _w = {};
    for (var i = 0, il = words.length; i < il; i++) {
      var ch = words[i].toString().charAt(0);
      if (!(ch in _w))
        _w[ch] = [];

      _w[ch].push(words[i]);
    }


    this.words = _w;
  },

  cancelReceiveData: function(id) {
    if (id in this.onCancelCallbacks) {
      this.onCancelCallbacks[id].call(null);
    }
  },

  /**
   * Returs suggested code assist proposals for prefix
   * @param {String} prefix Word prefix
   * @return {Array}
   */
  suggestWords: function(prefix, id) {
    prefix = String(prefix);

    if (prefix && this.words) {
      return Deferred.processing(
        typeof this.words === "function" ?
          __bind(function() {
            return Deferred.processing(
              __bind(function() {
                return this.words({
                  onCancel: __bind(function(callback) {
                    if (typeof callback == "function") {
                      this.onCancelCallbacks[id] = callback;
                    }
                  }, this),
                  getWord: function() {
                    return prefix;
                  }
                });
              }, this)

            ).addErrorback(
              function(result) {
                console.log(result);
              }
            ).addCallback(
              __bind(function(result) {
                if (! (result instanceof Array)) {
                  result = [];
                }

                return result;
              }, this)
            );
          }, this)
        : this.words instanceof Object ?
          __bind(function() {
            var result = [];
            var first_ch = prefix.charAt(0);
            if (first_ch in this.words) {
              var words = this.words[first_ch];
              for (var i = 0, il = words.length; i < il; i++) {
                var word = words[i].toString();
                if (word.indexOf(prefix) === 0) {
                  result.push(word);
                }
              }
            }

            return result;
          }, this)
        :
          function() {
            return [];
          },
        function(result) {
          var prefix_len = prefix.length;
          var result2 = [];
          for (var i = 0, il = result.length; i < il; i++) {
            var word = result[i];
            if (word.toString().length > prefix_len) {
              result2.push(word);
            }
          }

          return result2;
        }
      )

    }

    return [];
  }

}
`

# Completition proposal
# @author Sergey Chikuyonok (serge.che@gmail.com)
# @link http://chikuyonok.ru
#
# @require class TextViewer
class CompletionProposal

  word: null
  str: null
  offset: null
  len: null
  cursor: null
  info: null
  generator: null

  # @param {String} str The actual string to be inserted into the document
  # @param {Number} offset The offset of the text to be replaced
  # @param {Number} length The length of the text to be replaced
  # @param {Number} cursor The position of the cursor following the insert
  # relative to <code>offset</code>
  constructor: (@word, @str, @offset, @len, @cursor, @info="") ->
    @setHTMLGenerator (word, proposal) =>
      fragment = document.createDocumentFragment()

      curWord = document.createElement("span")
      curWord.appendChild( document.createTextNode(word) )

      fragment.appendChild( curWord )
      fragment.appendChild( document.createTextNode(proposal.substr(word.length)) )

      return fragment

  getSource: () -> @str

  # Returns proposal's additional info which will be shown when proposal
  # is selected
  # @return String
  getAdditionalInfo: () -> @info

  # Inserts the proposed completion into the given document
  # @param TextViewer viewer
  apply: (viewer) ->
    viewer.preventModifiedEvent()
    viewer.replaceText(@toString(), @offset, @offset + @len)
    viewer.setCaretPos(@cursor)

  toString: () -> @str.toString()

  setHTMLGenerator: (@generator) ->
    @generator = null unless typeof @generator is "function"

  # Create DOM node for proposal
  # @return Object
  toHtml: () ->
    word = @word

    proposal = document.createElement('div')
    proposal.className = 'cafe-jet-content-assist-proposal'

    if node = @generator(word, @toString(), @str.valueOf())
      proposal.appendChild(if typeof node is "string" then document.createTextNode(node) else node)

    return proposal

`
/**
 * Content assist provider for TextViewer
 * @class
 * @param {TextViewer} viewer
 * @param {ContentAssistProcessor} processor
 * @param {Object} [options]
 *
 * @include "ContentAssistProcessor.js"
 * @include "CompletionProposal.js"
 * @include "TextViewer.js"
 * @include "Utils.js"
 */
var ContentAssist = function(viewer, processor, options) {
  this.viewer = viewer;
  this.options = {
    visible_items: 10
  };

  this.fetchingCompletionId = null;
  this.fetchingCompletionProposals = {};

  this.setProcessor(processor);
  this.setOptions(options);

  // create content assist popup
  this.popup = Utils.createElement('div', 'cafe-jet-content-assist-popup');
  this.popup_content = Utils.createElement('div', 'cafe-jet-content-assist-popup-content');
  this.additional_info = Utils.createElement('div', 'cafe-jet-content-assist-additional-info');

  this.popup.appendChild(this.popup_content);
  this.popup.appendChild(this.additional_info);

  viewer.getElement().parentNode.appendChild(this.popup);

  /** @type {ContentAssistProcessor} */
  this.processor = null;
  this.is_visible = false;
  this.last_proposals = [];
  this.is_hover_locked = false,
  this.hover_lock_timeout = null;
  this.selected_class = 'cafe-jet-content-assist-proposal-selected';

  /** Currently selected proposal's index */
  this.selected_proposal = 0;

  if (processor)
    this.setProcessor(processor);

  var popup = this.popup,
    popup_content = this.popup_content,
    that = this;

  this.hidePopup();

  viewer.addEvent('modify', function(/* Event */ evt) {
    that.showContentAssist();
  });

  var is_opera = !!window.opera,
    is_mac = /mac\s+os/i.test(navigator.userAgent),
    is_opera_mac = is_opera && is_mac;

  function stopEvent(evt) {
    if (evt.preventDefault)
      evt.preventDefault();
    else
      evt.returnValue = false;
  }

  viewer.addEvent(is_opera ? 'keypress' : 'keydown', function(/* Event */ evt) {

    if (that.is_visible) {
      switch (evt.keyCode) {
        case 38: //up
          that.selectProposal(Math.max(that.selected_proposal - 1, 0));
          that.lockHover();
          evt.preventDefault();
          break;
        case 40: //down
          that.selectProposal(Math.min(that.selected_proposal + 1, popup_content.childNodes.length - 1));
          that.lockHover();
          evt.preventDefault();
          break;
        case 13: //enter
          that.applyProposal(that.selected_proposal);
          that.hidePopup();
          evt.preventDefault();
          break;
        case 27: // escape
          that.hidePopup();
          evt.preventDefault();
          break;
      }
    } else if (evt.keyCode == 32 && (evt.ctrlKey && !is_opera_mac || evt.metaKey && is_opera_mac || evt.altKey)) { // ctrl+space or alt+space
      // explicitly show content assist
      that.showContentAssist();

      evt.preventDefault();
    }
  });

  var dont_hide = false;

  viewer.addEvent('blur', function() {
    // use delayed execution in to handle popup click event correctly
    that.hide_timeout = setTimeout(function() {
      if (!dont_hide) {
        that.stopFetchingCompletionProposals();
        that.hidePopup();
      }
      dont_hide = false;
    }, 200);
  });

  // delegate hover event: hilight proposal
  Event.add(popup_content, 'mouseover', function(/* Event */ evt) {
    if (that.is_hover_locked)
      return;


    var target = that.searchProposal(evt.target);

    if (target) {
      var ix = that.findProposalIx(target);
      if (ix != -1)
        that.selectProposal(ix, true);
    }
  });

  // delegate click event: apply proposal
  Event.add(popup_content, 'click', function(/* Event */ evt) {

    var target = that.searchProposal(evt.target);
    if (target) {
      var ix = that.findProposalIx(target);
      if (ix != -1) {
        that.applyProposal(ix);
        that.hidePopup();
      }
    }
  });

  Event.add(popup_content, 'mousedown', function(/* Event */ evt) {

    evt.preventDefault();
    evt.stopPropagation();
    dont_hide = true;
    return false;
  });

  Event.add(document, 'mousedown', function(/* Event */ evt) {
    that.stopFetchingCompletionProposals();

    that.hidePopup();
  });

  Event.add(this.additional_info, 'scroll', function(/* Event */ evt) {
    that.hideAdditionalInfo();
  });
};

ContentAssist.prototype = {
  /**
   * @param {ContentAssistProcessor} processor
   */
  setProcessor: function(processor) {
    this.processor = processor;
  },

  /**
   * Set new content assist popup options
   * @param {Object} opt
   */
  setOptions: function(opt) {
    if (opt) {
      for (var p in this.options) if (this.options.hasOwnProperty(p)) {
        if (p in opt)
          this.options[p] = opt[p];
      }
    }
  },

  /**
   * Search for proposal element traversing up to the tree
   * @param {Element} elem
   * @return {Element}
   */
  searchProposal: function(elem) {
    do {
      if (Utils.hasClass(elem, 'cafe-jet-content-assist-proposal'))
        break;
    } while (elem = elem.parentNode);

    return elem;
  },

  /**
   * Search for proposal's element index in parent
   * @param {Element} proposal
   * @return {Number}
   */
  findProposalIx: function(proposal) {
    var result = -1,
      props = proposal.parentNode.childNodes;

    for (var i = 0, il = props.length; i < il; i++) {
      if (props[i] == proposal) {
        result = i;
        break;
      }
    }

    return result;
  },

  applyProposal: function(ix) {
    if (this.popup_content.childNodes[ix]) {
      this.last_proposals[ix].apply(this.viewer);
      this.onApplyProposal();
    }
  },

  showPopup: function(x, y) {
    this.popup.style.display = 'block';
    this.popup.style.top = y + 'px';
    this.popup.style.width = '';

    // this need to measure size of content
    this.popup_content.style.position = "absolute";

    // make some adjustments so popup won't appear outside the TextViewer box
    var elem = this.viewer.getElement();
    x = Math.min(elem.offsetLeft + elem.offsetWidth - this.popup.offsetWidth, x);
    this.popup.style.left = x + 'px';

    this.popup.style.width = this.popup_content.offsetWidth + 'px';
    this.popup_content.style.position = "";

    this.is_visible = true;
    this.lockHover();
  },

  hidePopup: function() {
    this.popup.style.display = 'none';
    this.hideAdditionalInfo();
    this.is_visible = false;
  },

  /**
   * Temporary lock popup hover events.
   * Hover lock is used to prevent accident mouseover event callback when
   * mouse cursor is over popup window and user traverses between proposals
   * with arrow keys
   */
  lockHover: function() {
    if (this.hover_lock_timeout)
      clearTimeout(this.hover_lock_timeout);

    this.is_hover_locked = true;
    var that = this;
    this.hover_lock_timeout = setTimeout(function() {
      that.is_hover_locked = false;
    }, 100);
  },

  stopFetchingCompletionProposals: function() {
    Utils.removeClass(this.viewer.getElement(), 'cafe-jet-content-assist-viewer-processing');

    var id = this.fetchingCompletionId;
    this.fetchingCompletionId = null;

    if (id) {
      this.processor.cancelReceiveData(id)

      delete this.fetchingCompletionProposals[id];
    } else {
      this.fetchingCompletionProposals = {};
    }
  },

  /**
   * Calculate content assist proposals and show popup
   */
  showContentAssist: function() {
    if (this.processor) {
      var timeout = 0;

      if (this.fetchingCompletionId in this.fetchingCompletionProposals) {
        this.stopFetchingCompletionProposals();
      }

      var id = new Date().getTime();

      this.fetchingCompletionId = id;

      this.fetchingCompletionProposals[id] = true;

      Deferred.processing(
        __bind(function() {
          Utils.addClass(this.viewer.getElement(), 'cafe-jet-content-assist-viewer-processing');
        }, this),

        __bind(function() {
          return this.processor.computeCompletionProposals(this.viewer, this.viewer.getCaretPos(), id);
        }, this),

        __bind(function(proposals) {

          if (! (id in this.fetchingCompletionProposals)) {
            return;
          }

          if (proposals) {
            var last_offset = 0,
              popup_height = 0,
              total_height = 0;

            // temporary show popup element for height calculations
            this.popup.style.display = 'block';
            Utils.emptyElement(this.popup_content);

            for (var i = 0, il = proposals.length; i < il; i++) {
              var proposal_elem = proposals[i].toHtml();
              this.popup_content.appendChild(proposal_elem);
              last_offset = proposals[i].offset;

              if (this.options.visible_items > 0 && i < this.options.visible_items) {
                popup_height += proposal_elem.offsetHeight;
              }

              total_height += proposal_elem.offsetHeight;
            }

            if (total_height > popup_height)
              Utils.addClass(this.popup, 'cafe-jet-content-assist-popup-overflow');
            else
              Utils.removeClass(this.popup, 'cafe-jet-content-assist-popup-overflow');

            var coords = this.viewer.getAbsoluteCharacterCoords(last_offset);
            this.showPopup(coords.x, coords.y);
            this.popup_content.style.height = popup_height ? popup_height + 'px' : 'auto';
            this.last_proposals = proposals;

            this.selected_proposal = 0;
            this.selectProposal(this.selected_proposal);
          } else {
            this.hidePopup();
          }

          if (this.fetchingCompletionId === id) {
            this.fetchingCompletionId = null;
          }

          this.stopFetchingCompletionProposals();
        }, this)
      );
    }
  },

  /**
   * Shows additional info for given proposal
   * @private
   * @param {Number} ix
   */
  showAdditionalInfo: function(ix) {
    /** @type {CompletionProposal} */
    var proposal = this.last_proposals[ix];
    if (proposal && proposal.getAdditionalInfo()) {
      var proposal_elem = this.popup_content.childNodes[ix],
        elem = this.additional_info;

      elem.innerHTML = proposal.getAdditionalInfo();
      Utils.removeClass(elem, 'cafe-jet-content-assist-additional-info-left');
      Utils.setCSS(elem, {
        display: 'block',
        top: proposal_elem.offsetTop - this.popup_content.scrollTop
      });

      // make sure that additional info window is not outside TextViewer's bounds
      var viewer = this.viewer.getElement();
      if (elem.offsetLeft + elem.offsetWidth + this.popup.offsetLeft > viewer.offsetLeft + viewer.offsetWidth) {
        Utils.addClass(elem, 'cafe-jet-content-assist-additional-info-left');
      }
    }
  },

  /**
   * Hide additional info window
   */
  hideAdditionalInfo: function() {
    Utils.setCSS(this.additional_info, {display: 'none'});
  },

  /**
   * Select proposal in popup window
   * @param {Number} ix Proposal index (0-based)
   * @param {boolean} [no_scroll] Don't scroll proposal into view
   */
  selectProposal: function(ix, no_scroll) {
    if (this.popup_content.childNodes[this.selected_proposal])
      Utils.removeClass(this.popup_content.childNodes[this.selected_proposal], this.selected_class);

    if (this.popup_content.childNodes[ix]) {
      var proposal = this.popup_content.childNodes[ix];
      Utils.addClass(proposal, this.selected_class);

      if (!no_scroll) {
        // make sure that selected proposal is visible
        var proposal_top = proposal.offsetTop,
          proposal_height = proposal.offsetHeight,
          popup_scroll = this.popup_content.scrollTop,
          popup_height = this.popup_content.offsetHeight;

        if (proposal_top < popup_scroll) {
          this.popup_content.scrollTop = proposal_top;
        } else if (proposal_top + proposal_height > popup_scroll + popup_height) {
          this.popup_content.scrollTop = proposal_top + proposal_height - popup_height;
        }
      }

      this.showAdditionalInfo(ix);
    }

    this.selected_proposal = ix;
  }
}`

package "cafe.jet"

  # Basic content assist provides words proposal based on dictionary
  # @class
  # @param {Element} textarea Textarea element where you need to show content assist
  # @param {Array} words Proposals (strings)
  # @param {Object} [options] Options for <code>ContentAssist</code> object
  #
  # @author Sergey Chikuyonok (serge.che@gmail.com)
  # @link http://chikuyonok.ru
  BasicContentAssist: class BasicContentAssist extends Observable

    viewer        : null
    processor     : null
    content_assist: null

    constructor: (textarea, words, options) ->
      @viewer         = new TextViewer(textarea)
      @processor      = new ContentAssistProcessor(words)
      @content_assist = new ContentAssist(@viewer, @processor, options)

      @content_assist.onApplyProposal = () =>
        @notifyListeners("select")

    getSelectedProposal: () ->
      ix = @content_assist.selected_proposal

      return @content_assist.last_proposals[ix] if @content_assist.popup_content.childNodes[ix]

      return null

    setProposalHTMLGenerator: (generator) ->
      @processor.setProposalHTMLGenerator(generator)

    setCharMode: (mode) ->
      @processor.setCharMode(mode) if mode in [BasicContentAssist.USE_ALL_SYMBOLS, BasicContentAssist.USE_CLEAR_PHRASE, BasicContentAssist.USE_CLEAR_WORDS]

    @USE_ALL_SYMBOLS : "allSymbols"
    @USE_CLEAR_WORDS : "clearWords"
    @USE_CLEAR_PHRASE: "clearPhrase"
