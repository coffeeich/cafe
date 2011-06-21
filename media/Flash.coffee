package "cafe.media"

  Flash: class Flash

    checkAlt: null

    # jQuery Tools 1.2.5 / Flashembed - New wave Flash embedding
    #
    # NO COPYRIGHTS OR LICENSES. DO WHAT YOU LIKE.
    #
    # http://flowplayer.org/tools/toolbox/flashembed.html
    #
    # Since : March 2008
    # Date  : Wed Sep 22 06:02:10 2010 +0000
    embed: `(function(){function f(a,b){if(b)for(var c in b)if(b.hasOwnProperty(c))a[c]=b[c];return a}function l(a,b){var c=[];for(var d in a)if(a.hasOwnProperty(d))c[d]=b(a[d]);return c}function m(a,b,c){if(e.isSupported(b.version))a.innerHTML=e.getHTML(b,c);else if(b.expressInstall&&e.isSupported([6,65]))a.innerHTML=e.getHTML(f(b,{src:b.expressInstall}),{MMredirectURL:location.href,MMplayerType:"PlugIn",MMdoctitle:document.title});else{if(!a.innerHTML.replace(/\s/g,"")){a.innerHTML="<h2>Flash version "+b.version+
  " or greater is required</h2><h3>"+(g[0]>0?"Your version is "+g:"You have no flash plugin installed")+"</h3>"+(a.tagName=="A"?"<p>Click here to download latest version</p>":"<p>Download latest version from <a href='"+k+"'>here</a></p>");if(a.tagName=="A")a.onclick=function(){location.href=k}}if(b.onFail){var d=b.onFail.call(this);if(typeof d=="string")a.innerHTML=d}}if(i)window[b.id]=document.getElementById(b.id);f(this,{getRoot:function(){return a},getOptions:function(){return b},getConf:function(){return c},
  getApi:function(){return a.firstChild}})}var i=document.all,k="http://www.adobe.com/go/getflashplayer",o=/(\d+)[^\d]+(\d+)[^\d]*(\d*)/,j={width:"100%",height:"100%",id:"_"+(""+Math.random()).slice(9),allowfullscreen:true,allowscriptaccess:"always",quality:"high",version:[3,0],onFail:null,expressInstall:null,w3c:false,cachebusting:false};window.attachEvent&&window.attachEvent("onbeforeunload",function(){__flash_unloadHandler=function(){};__flash_savedUnloadHandler=function(){}});
  var flashembed=function(a,b,c){if(typeof a=="string")a=document.getElementById(a.replace("#",""));if(a){if(typeof b=="string")b={src:b};return new m(a,f(f({},j),b),c)}};var e=f(flashembed,{conf:j,getVersion:function(){var a,b;try{b=navigator.plugins["Shockwave Flash"].description.slice(16)}catch(c){try{b=(a=new ActiveXObject("ShockwaveFlash.ShockwaveFlash.7"))&&a.GetVariable("$version")}catch(d){try{b=(a=new ActiveXObject("ShockwaveFlash.ShockwaveFlash.6"))&&a.GetVariable("$version")}catch(h){}}}return(b=
  o.exec(b))?[b[1],b[3]]:[0,0]},asString:function(a){if(a===null||a===undefined)return null;var b=typeof a;if(b=="object"&&a.push)b="array";switch(b){case "string":a=a.replace(new RegExp('(["\\\\])',"g"),"\\$1");a=a.replace(/^\s?(\d+\.?\d+)%/,"$1pct");return'"'+a+'"';case "array":return"["+l(a,function(d){return e.asString(d)}).join(",")+"]";case "function":return'"function()"';case "object":b=[];for(var c in a)a.hasOwnProperty(c)&&b.push('"'+c+'":'+e.asString(a[c]));return"{"+b.join(",")+"}"}return String(a).replace(/\s/g,
  " ").replace(/\'/g,'"')},getHTML:function(a,b){a=f({},a);var c='<object width="'+a.width+'" height="'+a.height+'" id="'+a.id+'" name="'+a.id+'"';if(a.cachebusting)a.src+=(a.src.indexOf("?")!=-1?"&":"?")+Math.random();c+=a.w3c||!i?' data="'+a.src+'" type="application/x-shockwave-flash"':' classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000"';c+=">";if(a.w3c||i)c+='<param name="movie" value="'+a.src+'" />';a.width=a.height=a.id=a.w3c=a.src=null;a.onFail=a.version=a.expressInstall=null;for(var d in a)if(a[d])c+=
  '<param name="'+d+'" value="'+a[d]+'" />';a="";if(b){for(var h in b)if(b[h]){d=b[h];a+=h+"="+(/function|object/.test(typeof d)?e.asString(d):d)+"&"}a=a.slice(0,-1);c+='<param name="flashvars" value=\''+a+"' />"}c+="</object>";return c},isSupported:function(a){return g[0]>a[0]||g[0]==a[0]&&g[1]>=a[1]}}),g=e.getVersion();return flashembed;})()`

    embedFlashObject: (node, params={}, flashvars={}) ->
      return @embed(node, params, flashvars) if {}.constructor is params.constructor

      return null unless sizzle = params.getSizzle?()

      params = {}
      fixes  = []

      for hidden in sizzle("[type='hidden']", node)
        {name, value} = hidden

        value = Number(value) if /^\d+$/.test(value)
        value = yes           if value in ["yes", "true",  true,  1]
        value = no            if value in ["no",  "false", false, 1]

        if /^flashvars:/.test(name)
          name = name.replace(/^flashvars:/, "")

          flashvars[name] = value
        else if /^fix:/.test(name)
          fixes.push(name.replace(/^fix:/, ""))
        else
          params[name] = value

      for name in fixes
        switch name
          when "wmode"
            if value is yes
              wmode = @fixWMode(params.wmode)
              if wmode is null
                delete params.wmode
              else
                params.wmode = wmode

      if alternative = params.alternative
        delete params.alternative

        if @checkAlt
          node.innerHTML = alternative

          return null

      return @embed(node, params, flashvars) 

    fixWMode: (wmode) ->
      return null   if @constructor.isFirefox3MinorLess6()
      return wmode

    checkAlternative: (check=yes) ->
      @checkAlt = check

    @getFlashVersion: () ->
      # ie
      try
        try
          # avoid fp6 minor version lookup issues
          # see: http://blog.deconcept.com/2006/01/11/getvariable-setvariable-crash-internet-explorer-flash-6/
          axo = new ActiveXObject('ShockwaveFlash.ShockwaveFlash.6')
          try 
            axo.AllowScriptAccess = 'always'
          catch ex
            return '6,0,0'

        return new ActiveXObject('ShockwaveFlash.ShockwaveFlash').GetVariable('$version').replace(/\D+/g, ',').match(/^,?(.+),?$/)[1]
      # other browsers
      catch ex
        try
          if navigator.mimeTypes["application/x-shockwave-flash"].enabledPlugin
            return (navigator.plugins["Shockwave Flash 2.0"] or navigator.plugins["Shockwave Flash"]).description.replace(/\D+/g, ",").match(/^,?(.+),?$/)[1]

      return '0,0,0'

    @isFirefox3MinorLess6: () ->
      agent = navigator.userAgent.toLowerCase()

      return no unless /gecko/.test(agent) and !/(compatible|webkit)/g.test(agent) and /firefox/.test(agent)

      ver = agent.split("firefox/").pop()

      [major, minor] = ver.split(".", 3)

      major = major | 0
      minor = minor | 0

      return major is 3 and minor < 6