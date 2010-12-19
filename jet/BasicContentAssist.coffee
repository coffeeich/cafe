@import "cafe/Deferred"

@stylesheet "cafe/jet/content-assist/style", "all"

`
/**
 * @author Sergey Chikuyonok (serge.che@gmail.com)
 * @link http://chikuyonok.ru
 */
var tx_utils = {

  /**
   * Вспомогательная функция, которая пробегается по всем элементам массива
   * <code>ar</code> и выполняет на каждом элементе его элементе функцию
   * <code>fn</code>. <code>this</code> внутри этой функции указывает на
   * элемент массива
   *
   * @param {Array}
   *            ar Массив, по которому нужно пробежаться
   * @param {Function}
   *            fn Функция, которую нужно выполнить на каждом элементе массива
   * @param {Boolean}
   *            forward Перебирать значения от начала массива (п умолчанию: с
   *            конца)
   */
  walkArray: function(ar, fn, forward) {
    if (forward) {
      for (var i = 0, len = ar.length; i < len; i++)
        if (fn.call(ar[i], i, ar[i]) === false)
          break;
    } else {
      for (var i = ar.length - 1; i >= 0; i--)
        if (fn.call(ar[i], i, ar[i]) === false)
          break;
    }
  },

  trim: function(text) {
    return (text || '').replace(/^(\s|\u00A0)+|(\s|\u00A0)+$/g, '');
  },

  /**
   * Проверяет, есть ли класс у элемента
   *
   * @param {Element} elem
   * @param {String} class_name
   * @return {Boolean}
   */
  hasClass: function(elem, class_name) {
    class_name = ' ' + class_name + ' ';
    var _cl = elem.className;
    return _cl && (' ' + _cl + ' ').indexOf(class_name) >= 0;
  },

  toggleClass: function(elem, class_name) {
    if (this.hasClass(elem, class_name))
      this.removeClass(elem, class_name);
    else
      this.addClass(elem, class_name);
  },

  /**
   * Добавляет класс элементу
   *
   * @param {Element} elem
   * @param {String} class_name
   */
  addClass: function(elem, class_name) {
    var classes = [],
      that = this;

    this.walkArray(class_name.split(/\s+/g), function(i, n) {
      if (n && !that.hasClass(elem, n))
        classes.push(n);
    });

    if (classes.length)
      elem.className += (elem.className ? ' ' : '') + classes.join(' ');
  },

  /**
   * Удаляет класс у элемента
   *
   * @param {Element} elem
   * @param {String} class_name
   */
  removeClass: function(elem, class_name) {
    var elem_class = elem.className || '';
    this.walkArray(class_name.split(/\s+/g), function(i, n) {
      elem_class = elem_class.replace(new RegExp('\\b' + n + '\\b'), '');
    });

    elem.className = this.trim(elem_class);
  },

  /**
   * Removes element's content
   * @param {Element} elem
   */
  emptyElement: function(elem) {
    while (elem.firstChild)
      elem.removeChild(elem.firstChild);
  },

  /**
   * Add event listener to element
   * @param {Element} elem
   * @param {String} type
   * @param {Function} fn
   */
  addEvent: function(elem, type, fn) {
    var items = type.split(/\s+/);
    for (var i = 0; i < items.length; i++) {
      if (elem.addEventListener)
        elem.addEventListener(items[i], fn, false);
      else if (elem.attachEvent)
        elem.attachEvent('on' + items[i], fn);
    }
  },

  /**
   * Removes event listener from element
   * @param {Element} elem
   * @param {String} type
   * @param {Function} fn
   */
  removeEvent: function(elem, type, fn) {
    var items = type.split(/\s+/);
    for (var i = 0; i < items.length; i++) {
      if (elem.removeEventListener)
        elem.removeEventListener(items[i], fn, false);
      else if (elem.detachEvent)
        elem.detachEvent('on' + items[i], fn);
    }
  },

  /**
   * Normalizes event for IE, making it look like a W3C event
   */
  normalizeEvent: function(evt) {
    if (!evt || !evt.target) {
      evt = window.event;
      evt.target = evt.srcElement;
      evt.stopPropagation = function(){
        this.cancelBubble = true;
      };

      evt.preventDefault = function(){
        this.returnValue = false;
      };
    }

    return evt;
  },

  /**
   * Creates new element with given class name
   * @param {String} name Element's name
   * @param {String} class_name Element's class name
   * @return {Element}
   */
  createElement: function(name, class_name) {
    var elem = document.createElement(name);
    if (class_name)
      elem.className = class_name;

    return elem;
  },

  /**
   * Set CSS propesties for element
   * @param {Element} elem
   * @param {Object} params
   */
  setCSS: function(elem, params) {
    if (!elem)
      return;

    var props = [],
      num_props = {'line-height': 1, 'z-index': 1, opacity: 1};

    for (var p in params) if (params.hasOwnProperty(p)) {
      var name = p.replace(/([A-Z])/g, '-$1').toLowerCase(),
        value = params[p];
      props.push(name + ':' + ((typeof(value) == 'number' && !(name in num_props)) ? value + 'px' : value));
    }

    elem.style.cssText += ';' + props.join(';');
  }
};

/**
 * @author     Matthew Foster
 * @date    June 6th 2007
 * @purpose    To have a base class to extend subclasses from to inherit event dispatching functionality.
 * @procedure  Use a hash of event "types" that will contain an array of functions to execute.  The logic is if any function explicitally returns false the chain will halt execution.
 */

function EventDispatcher() {};

EventDispatcher.prototype = {
  buildListenerChain : function(){
    if(!this.listenerChain)
      this.listenerChain = {};
    if(!this.onlyOnceChain)
      this.onlyOnceChain = {};
  },

  /**
   * Добавляет слушатель события
   * @param {String} type Название события
   * @param {Function} listener Слушатель
   * @param {Boolean} only_once Подписаться на событие только один раз
   */
  addEventListener : function(type, listener, only_once){
    if(!listener instanceof Function)
      throw new Error("Listener isn't a function" );

    this.buildListenerChain();

    var chain = only_once ? this.onlyOnceChain : this.listenerChain;
    type = typeof(type) == 'string' ? type.split(' ') : type;
    for (var i = 0; i < type.length; i++) {
      if(!chain[type[i]])
        chain[type[i]] = [listener];
      else
        chain[type[i]].push(listener);
    }

  },

  /**
   * Проверяет, есть ли у такого события слушатели
   * @param {String} type Название события
   * @return {Boolean}
   */
  hasEventListener : function(type){
    return (typeof this.listenerChain[type] != "undefined" || typeof this.onlyOnceChain[type] != "undefined");
  },

  /**
   * Удаляет слушатель события
   * @param {String} type Название события
   * @param {Function} listener Слушатель, который нужно удалить
   */
  removeEventListener : function(type, listener){
    if(!this.hasEventListener(type))
      return false;

    var chains = [this.listenerChain, this.onlyOnceChain];
    for (var i = 0; i < chains.length; i++) {
      /** @type Array */
      var lst = chains[i][type];

      for(var j = 0; j < lst.length; j++)
        if(lst[j] == listener)
          lst.splice(j, 1);
    }

    return true;
  },

  /**
   * Инициирует событие
   * @param {String} type Название события
   * @param {Object} [args] Дополнительные данные, которые нужно передать слушателю
   * @return {Boolean}
   */
  dispatchEvent : function(type, args){
    this.buildListenerChain();

    if(!this.hasEventListener(type))
      return false;

    var chains = [this.listenerChain, this.onlyOnceChain],
      evt = new CustomEvent(type, this, args);
    for (var j = 0; j < chains.length; j++) {
      /** @type Array */
      var lst = chains[j][type];
      if (lst)
        for(var i = 0, il = lst.length; i < il; i++)
          lst[i](evt);
    }

    if (this.onlyOnceChain[type])
      delete this.onlyOnceChain[type];

    return true;
  }
};

/**
 * Произвольное событие. Создается в EventDispatcher и отправляется всем слушателям
 * @constructor
 * @param {String} type Тип события
 * @param {Object} target Объект, который инициировал событие
 * @param {Object} [data] Дополнительные данные
 */
function CustomEvent(type, target, data){
  this.type = type;
  this.target = target;
  if (typeof(data) != 'undefined') {
    this.data = data;
  }
}

/**
 * Wrapper for textarea (or any other) element for convenient text manipulation
 * @class
 * @author Sergey Chikuyonok (serge.che@gmail.com)
 * @link http://chikuyonok.ru
 *
 * @include "EventDispatcher.js"
 */
// different browser use different newlines, so we have to figure out
// native browser newline and sanitize incoming text with it
var tx = document.createElement('textarea');
tx.value = '\n';
var newline_char = tx.value;
var has_pre_wrap = !tx.currentStyle; // pre-wrap in IE is not the same as in other browsers
tx = null;

var use_w3c = document.defaultView && document.defaultView.getComputedStyle,
  /**
   * textarea element properties that should be copied to measurer
   * on order to correctly calculate popup position
   */
  copy_props = ('font-family,font-size,line-height,text-indent,' +
          'padding-top,padding-right,padding-bottom,padding-left,' +
          'border-left-width,border-right-width,border-left-style,border-right-style').split(','),
  xml_chars = {
    '<' : '&lt;',
    '>' : '&gt;',
    '&' : '&amp;'
  },
  ua = navigator.userAgent.toLowerCase(),
  line_breaker = ua.indexOf('msie 6') === -1 ? String.fromCharCode(8203) : '&shy;';

/**
 * Find start and end index of text line for <code>from</code> index
 * @param {String} text
 * @param {Number} from
 */
function findNewlineBounds(text, from) {
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
}

/**
 * Sanitazes string for size measurement
 * @param {String} str
 * @return {String}
 */
function sanitizeString(str) {
  str = str.replace(/[<>&]/g, function(str) {
    return xml_chars[str];
  });
  return has_pre_wrap ? str : str.replace(/\s/g, '&nbsp;' + line_breaker);
}

/**
 * Split text into lines. Set <code>remove_empty</code> to true to filter
 * empty lines
 * @param {String} text
 * @param {Boolean} [remove_empty]
 * @return {Array}
 */
function splitByLines(text, remove_empty) {
  // IE fails to split string by regexp,
  // need to normalize newlines first
  // Also, Mozilla's Rhiho JS engine has a wierd newline bug
  var lines = (text || '')
    .replace(/\r\n/g, '\n')
    .replace(/\n\r/g, '\n')
    .split('\n');

  if (remove_empty) {
    for (var i = lines.length; i >= 0; i--) {
      if (!trim(lines[i]))
        lines.splice(i, 1);
    }
  }

  return lines;
}

/**
 * Returns line number (0-based) for character position in text
 * @param {String} text
 * @param {Number} pos
 */
function getLineNumber(text, pos) {
  var lines = text.split(newline_char),
    total_len = 0,
    nl_len = newline_char.length;

  for (var i = 0, il = lines.length; i < il; i++) {
    total_len += lines[i].length;
    if (i < il - 1)
      total_len += nl_len;

    if (pos < total_len)
      return i;
  }

  return -1;
}

/**
 * Creates new element with class
 * @param {String} name Element's name
 * @param {String} class_name Element's class
 * @return {Element}
 */
function createElement(name, class_name) {
  var elem = document.createElement(name);
  if (class_name)
    elem.className = class_name;

  return elem;
}

function toCamelCase(str) {
  return str.replace(/\-(\w)/g, function(str, p1) {
    return p1.toUpperCase();
  });
}

/**
 * Returns value of CSS property <b>name</b> of element <b>elem</b>
 * @author John Resig (http://ejohn.org)
 * @param {Element} elem
 * @param {String|Array} name
 * @return {String|Object}
 */
function getCSS(elem, name, force_computed) {
  var cs, result = {}, n, name_camel, is_array = name instanceof Array;

  var rnumpx = /^-?\d+(?:px)?$/i,
    rnum = /^-?\d(?:\.\d+)?/,
    rsuf = /\d$/,
    ret,
    suffix;

  var _name = is_array ? name : [name];
  for (var i = 0, il = _name.length; i < il; i++) {
    n = _name[i];
    name_camel = toCamelCase(n);

    // If the property exists in style[], then it's been set
    // recently (and is current)
    if (!force_computed && elem.style[name_camel]) {
      result[n] = result[name_camel] = elem.style[name_camel];
    }
    // Or the W3C's method, if it exists
    else if (use_w3c) {
      if (!cs)
        cs = window.getComputedStyle(elem, "");
      result[n] = result[name_camel] = cs && cs.getPropertyValue(n);
    } else if ( elem.currentStyle ) {
      ret = elem.currentStyle[n] || elem.currentStyle[name_camel];
      var style = elem.style || elem;

      // From the awesome hack by Dean Edwards
      // http://erik.eae.net/archives/2007/07/27/18.54.15/#comment-102291

      // If we're not dealing with a regular pixel number
      // but a number that has a weird ending, we need to convert it to pixels
      if ( !rnumpx.test( ret ) && rnum.test( ret ) ) {
        // Remember the original values
        var left = style.left, rsLeft = elem.runtimeStyle.left;

        // Put in the new values to get a computed value out
        elem.runtimeStyle.left = elem.currentStyle.left;
        suffix = rsuf.test(ret) ? 'em' : '';
        style.left = name_camel === "fontSize" ? "1em" : (ret + suffix || 0);
        ret = style.pixelLeft + "px";

        // Revert the changed values
        style.left = left;
        elem.runtimeStyle.left = rsLeft;
      }

      result[n] = result[name_camel] = ret;
    }
  }

  return is_array ? result : result[toCamelCase(name)];
}

/**
 * Sets new CSS propery values for element
 * @param {Element} elem
 * @param {Object} params
 */
function setCSS(elem, params) {
  if (!elem)
    return;

  var props = [],
    num_props = {'line-height': 1, 'z-index': 1, opacity: 1};

  for (var p in params) if (params.hasOwnProperty(p)) {
    var name = p.replace(/([A-Z])/g, '-$1').toLowerCase(),
      value = params[p];
    props.push(name + ':' + ((typeof(value) == 'number' && !(name in num_props)) ? value + 'px' : value));
  }

  elem.style.cssText += ';' + props.join(';');
}

/**
 * Creates text measurer for textarea
 * @param {Element} textarea
 * @return Element
 */
function createMeasurer(textarea) {
  var measurer = createElement('div', 'cafe-jet-content-assist-measurer'),
    css_props = getCSS(textarea, copy_props);

  // copy properties
  for (var i = 0; i < copy_props.length; i++) {
    var prop = copy_props[i];
    measurer.style[toCamelCase(prop)] = css_props[prop];
  }

  textarea.parentNode.appendChild(measurer);
  return measurer;
}

/**
 * Stores and revalidetes text line heights. The problem of getting line
 * height is that a single line could be spanned across multiple lines.
 * It this case we can't use <code>line-height</code> CSS property, we
 * need to calculate real line height
 * @class
 *
 * @param {Element} measurer
 */
function LineCacher(measurer) {
  this.measurer = measurer;
  this.width = measurer.clientWidth;
  this.lines = [];
}

LineCacher.prototype = {
  /**
   * Returns line position in pixels in passed text
   * @param {Number} line_num Line index (starting from 0) to get offset
   * @param {String} text
   *
   * @return {Number} Offset in pixels
   */
  getLineOffset: function(line_num, text) {
    if (!line_num)
      return 0;

    var m = this.measurer,
      force_recalc = m.clientWidth != this.width,
      lines = splitByLines(text),
      affected_params = getCSS(m, ['padding-top', 'padding-bottom']),
      affected_size = parseFloat(affected_params['padding-top']) + parseFloat(affected_params['padding-bottom']),
      line,
      total_height = 0;

    for (var i = 0, il = Math.min(lines.length, line_num); i < il; i++) {
      line = lines[i];
      if (force_recalc || !this.lines[i] || this.lines[i].text !== line) {
        m.innerHTML = sanitizeString(line || '&nbsp;');
        this.lines[i] = {
          text: line,
          height: m.offsetHeight - affected_size
        };
      }

      total_height += this.lines[i].height;
    }

    this.width = m.clientWidth;
    return total_height;
  },

  /**
   * Reset lines cache
   */
  reset: function() {
    this.lines = [];
  }
};


/**
 * Object constructor
 * @class
 * @param {Element} textarea
 */
function TextViewer(textarea) {
  this.textarea = textarea;
  this._measurer = createMeasurer(textarea);
  this.updateMeasurerSize();
  this.dispatcher = new EventDispatcher();
  this.line_cacher = new LineCacher(this._measurer);

  this.modifiedEventPrevented = false;

  var last_length = -1,
    last_value = null;

  // watch for content modification
  // if we think it was modified, we'll send special "modify" event
  tx_utils.addEvent(textarea, 'input paste change keyup', __bind(function(/* Event */ evt) {
    try {
      if (this.modifiedEventPrevented) {
        return;
      }

      var val = textarea.value;

      if (val.length != last_length || val !== last_value) {
        this.dispatcher.dispatchEvent('modify');
        last_length = val.length;
        last_value = val;
      }
    } finally {
      this.modifiedEventPrevented = false;
    }
  }, this));

  tx_utils.addEvent(window, 'focus resize', __bind(function(/* Event */ evt) {
    this.updateMeasurerSize();
  }, this));
};

TextViewer.prototype = {
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
//        var delta = zen_coding.splitByLines(getContent().substring(0, start)).length - 1;
//        end -= delta + zen_coding.splitByLines(getContent().substring(start, end)).length - 1;
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
    var af_props = getCSS(this.getElement(), ['padding-left', 'padding-right', 'border-left-width', 'border-right-width']),
      offset = parseInt(af_props['padding-left'])
        + parseInt(af_props['padding-right'])
        + parseInt(af_props['border-left-width'])
        + parseInt(af_props['border-right-width']);

    this._measurer.style.width = (this.textarea.clientWidth - offset) + 'px';
  },

  /**
   * Returns character pixel position relative to textarea element
   * @param {Number} offset Character index
   * @returns object with <code>x</code> and <code>y</code> properties
   */
  getCharacterCoords: function(offset) {
    var content = this.getContent(),
      line_bounds = findNewlineBounds(content, offset);

    this._measurer.innerHTML = sanitizeString(content.substring(line_bounds.start, offset)) + '<i>' + (this.getChar(offset) || '.') + '</i>';
    /** @type {Element} */
    var beacon = this._measurer.getElementsByTagName('i')[0],
      beacon_pos = {x: beacon.offsetLeft, y: beacon.offsetTop};

    // find out current line index
    var cur_line = splitByLines(content.substring(0, line_bounds.start)).length;
    cur_line = Math.max(0, cur_line - 1);
    var line_offset = this.line_cacher.getLineOffset(cur_line, content);

    tx_utils.emptyElement(this._measurer);

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
        this.dispatcher.addEventListener('modify', fn);
      } else {
        tx_utils.addEvent(elem, type, fn);
      }
    }
  },

  removeEvent: function(type, fn) {
    var items = type.split(/\s+/),
      elem = this.getElement();

    for (var i = 0, il = items.length; i < il; i++) {
      if (items[i].toLowerCase() == 'modify') {
        this.dispatcher.removeEventListener('modify', fn);
      } else {
        tx_utils.removeEvent(elem, type, fn);
      }
    }
  }
};

/**
 * A content assist processor proposes completions and computes context
 * information for a particular character offset. This interface is similar to
 * Eclipse's IContentAssistProcessor
 * @class
 * @author Sergey Chikuyonok (serge.che@gmail.com)
 * @link http://chikuyonok.ru
 *
 * @include "TextViewer.js"
 * @include "CompletitionProposal.js"
 */
function ContentAssistProcessor(words) {
  this.onCancelCallbacks = {};

  if (words instanceof Array && words.length > 0) {
    this.setWords(words);
  }

  if (typeof words === "function") {
    this.setWordsProvider(words);
  }
}

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
            var proposal = this.completitionProposalFactory(cur_word, s, offset - cur_word.length, right_bound - cur_offset - 1, offset - cur_word.length + s.length);
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
    return new CompletionProposal(cur_word, str, offset, length, cursor);
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
            if (word.length > prefix_len) {
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

/**
 * Completition proposal
 * @author Sergey Chikuyonok (serge.che@gmail.com)
 * @link http://chikuyonok.ru
 *
 * @param {String} str The actual string to be inserted into the document
 * @param {Number} offset The offset of the text to be replaced
 * @param {Number} length The length of the text to be replaced
 * @param {Number} cursor The position of the cursor following the insert
 * relative to <code>offset</code>
 *
 * @include "TextViewer.js"
 */
function CompletionProposal(cur_word, str, offset, length, cursor, additional_info) {
  this.cur_word = cur_word;
  this.str = str;
  this.offset = offset;
  this.len = length;
  this.cursor = cursor;
  this.additional_info = additional_info || '';
}

CompletionProposal.prototype = {
  /**
   * Returns the string to be displayed in the list of completion proposals.
   * @return {String}
   */
  getDisplayString: function() {
    return this.toString();
  },

  /**
   * Returns proposal's additional info which will be shown when proposal
   * is selected
   * @return {String}
   */
  getAdditionalInfo: function() {
    return this.additional_info;
  },

  /**
   * Inserts the proposed completion into the given document
   * @param {TextViewer} viewer
   */
  apply: function(viewer) {
    viewer.preventModifiedEvent();
    viewer.replaceText(this.toString(), this.offset, this.offset + this.len);
    viewer.setCaretPos(this.cursor);
  },

  toString: function() {
    return this.str.toString();
  },

  /**
   * Create DOM node for proposal
   * @return Object
   */
  toHtml: function() {
    var word = this.cur_word;

    var displayString = this.getDisplayString().substr(word.length);

    var proposal = document.createElement('div');
    proposal.className = 'cafe-jet-content-assist-proposal';

    var cur_word = document.createElement('span');
    cur_word.appendChild( document.createTextNode(word) );

    proposal.appendChild( cur_word );
    proposal.appendChild( document.createTextNode(displayString) );

    return proposal;
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
  BasicContentAssist: class BasicContentAssist

    viewer        : null
    processor     : null
    content_assist: null

    constructor: (textarea, words, options) ->
      @viewer         = new TextViewer(textarea)
      @processor      = new ContentAssistProcessor(words)
      @content_assist = new ContentAssist(@viewer, @processor, options)

    setCharMode: (mode) ->
      @processor.setCharMode(mode) if mode in [BasicContentAssist.USE_ALL_SYMBOLS, BasicContentAssist.USE_CLEAR_PHRASE, BasicContentAssist.USE_CLEAR_WORDS]

    @USE_ALL_SYMBOLS : "allSymbols"
    @USE_CLEAR_WORDS : "clearWords"
    @USE_CLEAR_PHRASE: "clearPhrase"

  ContentAssist: ContentAssist = ( ->
    ContentAssist = null

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
       * @include "tx_utils.js"
       */
      ContentAssist = function(viewer, processor, options) {
        this.viewer = viewer;
        this.options = {
          visible_items: 10
        };

        this.fetchingCompletionId = null;
        this.fetchingCompletionProposals = {};

        this.setProcessor(processor);
        this.setOptions(options);

        // create content assist popup
        this.popup = tx_utils.createElement('div', 'cafe-jet-content-assist-popup');
        this.popup_content = tx_utils.createElement('div', 'cafe-jet-content-assist-popup-content');
        this.additional_info = tx_utils.createElement('div', 'cafe-jet-content-assist-additional-info');

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
          evt = tx_utils.normalizeEvent(evt);
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
        tx_utils.addEvent(popup_content, 'mouseover', function(/* Event */ evt) {
          if (that.is_hover_locked)
            return;

          evt = tx_utils.normalizeEvent(evt);
          var target = that.searchProposal(evt.target);

          if (target) {
            var ix = that.findProposalIx(target);
            if (ix != -1)
              that.selectProposal(ix, true);
          }
        });

        // delegate click event: apply proposal
        tx_utils.addEvent(popup_content, 'click', function(/* Event */ evt) {
          evt = tx_utils.normalizeEvent(evt);
          var target = that.searchProposal(evt.target);
          if (target) {
            var ix = that.findProposalIx(target);
            if (ix != -1) {
              that.applyProposal(ix);
              that.hidePopup();
            }
          }
        });

        tx_utils.addEvent(popup_content, 'mousedown', function(/* Event */ evt) {
          evt = tx_utils.normalizeEvent(evt);
          evt.preventDefault();
          evt.stopPropagation();
          dont_hide = true;
          return false;
        });

        tx_utils.addEvent(document, 'mousedown', function(/* Event */ evt) {
          that.stopFetchingCompletionProposals();

          that.hidePopup();
        });

        tx_utils.addEvent(this.additional_info, 'scroll', function(/* Event */ evt) {
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
            if (tx_utils.hasClass(elem, 'cafe-jet-content-assist-proposal'))
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
          }
        },

        showPopup: function(x, y) {
          this.popup.style.display = 'block';
          this.popup.style.top = y + 'px';
          this.popup.style.width = '';

          // make some adjustments so popup won't appear outside the TextViewer box
          var elem = this.viewer.getElement();
          x = Math.min(elem.offsetLeft + elem.offsetWidth - this.popup.offsetWidth, x);
          this.popup.style.left = x + 'px';

          this.popup.style.width = this.popup_content.offsetWidth + 'px';

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
          tx_utils.removeClass(this.viewer.getElement(), 'cafe-jet-content-assist-viewer-processing');

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

            this.hidePopup();

            this.fetchingCompletionId = id;

            this.fetchingCompletionProposals[id] = true;

            Deferred.processing(
              __bind(function() {
                tx_utils.addClass(this.viewer.getElement(), 'cafe-jet-content-assist-viewer-processing');
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
                  tx_utils.emptyElement(this.popup_content);

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
                    tx_utils.addClass(this.popup, 'cafe-jet-content-assist-popup-overflow');
                  else
                    tx_utils.removeClass(this.popup, 'cafe-jet-content-assist-popup-overflow');

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
            tx_utils.removeClass(elem, 'cafe-jet-content-assist-additional-info-left');
            tx_utils.setCSS(elem, {
              display: 'block',
              top: proposal_elem.offsetTop - this.popup_content.scrollTop
            });

            // make sure that additional info window is not outside TextViewer's bounds
            var viewer = this.viewer.getElement();
            if (elem.offsetLeft + elem.offsetWidth + this.popup.offsetLeft > viewer.offsetLeft + viewer.offsetWidth) {
              tx_utils.addClass(elem, 'cafe-jet-content-assist-additional-info-left');
            }
          }
        },

        /**
         * Hide additional info window
         */
        hideAdditionalInfo: function() {
          tx_utils.setCSS(this.additional_info, {display: 'none'});
        },

        /**
         * Select proposal in popup window
         * @param {Number} ix Proposal index (0-based)
         * @param {boolean} [no_scroll] Don't scroll proposal into view
         */
        selectProposal: function(ix, no_scroll) {
          if (this.popup_content.childNodes[this.selected_proposal])
            tx_utils.removeClass(this.popup_content.childNodes[this.selected_proposal], this.selected_class);

          if (this.popup_content.childNodes[ix]) {
            var proposal = this.popup_content.childNodes[ix];
            tx_utils.addClass(proposal, this.selected_class);

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

    return ContentAssist )()