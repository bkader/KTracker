local a,b="CallbackHandler-1.0",5;local c=LibStub:NewLibrary(a,b)if not c then return end;local d={__index=function(e,f)e[f]={}return e[f]end}local g=table.concat;local assert,error,loadstring=assert,error,loadstring;local setmetatable,rawset,rawget=setmetatable,rawset,rawget;local next,select,pairs,type,tostring=next,select,pairs,type,tostring;local xpcall=xpcall;local function h(i)return geterrorhandler()(i)end;local function j(k)local l=[[
  local next, xpcall, eh = ...

  local method, ARGS
  local function call() method(ARGS) end

  local function dispatch(handlers, ...)
    local index
    index, method = next(handlers)
    if not method then return end
    local OLD_ARGS = ARGS
    ARGS = ...
    repeat
      xpcall(call, eh)
      index, method = next(handlers, index)
    until not method
    ARGS = OLD_ARGS
  end

  return dispatch
  ]]local m,n={},{}for o=1,k do m[o],n[o]="arg"..o,"old_arg"..o end;l=l:gsub("OLD_ARGS",g(n,", ")):gsub("ARGS",g(m,", "))return assert(loadstring(l,"safecall Dispatcher["..k.."]"))(next,xpcall,h)end;local p=setmetatable({},{__index=function(self,k)local q=j(k)rawset(self,k,q)return q end})function c:New(r,s,t,u,v,w)assert(not v and not w,"ACE-80: OnUsed/OnUnused are deprecated. Callbacks are now done to registry.OnUsed and registry.OnUnused")s=s or"RegisterCallback"t=t or"UnregisterCallback"if u==nil then u="UnregisterAllCallbacks"end;local x=setmetatable({},d)local y={recurse=0,events=x}function y:Fire(z,...)if not rawget(x,z)or not next(x[z])then return end;local A=y.recurse;y.recurse=A+1;p[select("#",...)+1](x[z],z,...)y.recurse=A;if y.insertQueue and A==0 then for z,B in pairs(y.insertQueue)do local C=not rawget(x,z)or not next(x[z])for self,D in pairs(B)do x[z][self]=D;if C and y.OnUsed then y.OnUsed(y,r,z)C=nil end end end;y.insertQueue=nil end end;r[s]=function(self,z,E,...)if type(z)~="string"then error("Usage: "..s.."(eventname, method[, arg]): 'eventname' - string expected.",2)end;E=E or z;local C=not rawget(x,z)or not next(x[z])if type(E)~="string"and type(E)~="function"then error("Usage: "..s..'("eventname", "methodname"): \'methodname\' - string or function expected.',2)end;local F;if type(E)=="string"then if type(self)~="table"then error("Usage: "..s..'("eventname", "methodname"): self was not a table?',2)elseif self==r then error("Usage: "..s..'("eventname", "methodname"): do not use Library:'..s.."(), use your own 'self'",2)elseif type(self[E])~="function"then error("Usage: "..s..'("eventname", "methodname"): \'methodname\' - method \''..tostring(E).."' not found on self.",2)end;if select("#",...)>=1 then local G=select(1,...)F=function(...)self[E](self,G,...)end else F=function(...)self[E](self,...)end end else if type(self)~="table"and type(self)~="string"then error("Usage: "..s..'(self or "addonId", eventname, method): \'self or addonId\': table or string expected.',2)end;if select("#",...)>=1 then local G=select(1,...)F=function(...)E(G,...)end else F=E end end;if x[z][self]or y.recurse<1 then x[z][self]=F;if y.OnUsed and C then y.OnUsed(y,r,z)end else y.insertQueue=y.insertQueue or setmetatable({},d)y.insertQueue[z][self]=F end end;r[t]=function(self,z)if not self or self==r then error("Usage: "..t.."(eventname): bad 'self'",2)end;if type(z)~="string"then error("Usage: "..t.."(eventname): 'eventname' - string expected.",2)end;if rawget(x,z)and x[z][self]then x[z][self]=nil;if y.OnUnused and not next(x[z])then y.OnUnused(y,r,z)end end;if y.insertQueue and rawget(y.insertQueue,z)and y.insertQueue[z][self]then y.insertQueue[z][self]=nil end end;if u then r[u]=function(...)if select("#",...)<1 then error("Usage: "..u..'([whatFor]): missing \'self\' or "addonId" to unregister events for.',2)end;if select("#",...)==1 and...==r then error("Usage: "..u..'([whatFor]): supply a meaningful \'self\' or "addonId"',2)end;for o=1,select("#",...)do local self=select(o,...)if y.insertQueue then for z,B in pairs(y.insertQueue)do if B[self]then B[self]=nil end end end;for z,B in pairs(x)do if B[self]then B[self]=nil;if y.OnUnused and not next(B)then y.OnUnused(y,r,z)end end end end end end;return y end
