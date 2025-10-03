

local DataToCode do
	local DataToCode_request, DataToCode_source = pcall(function()
		return game:GetService("HttpService"):GetAsync("https://raw.githubusercontent.com/78n/Roblox/refs/heads/main/Lua/Libraries/DataToCode/DataToCode.luau")
	end)
	assert(DataToCode_request, "An error occured when retrieving the DataToCode source (try saving as a plugin): "..DataToCode_source)

	local CompiledDataToCode = loadstring(DataToCode_source, "DataToCode")
	DataToCode = CompiledDataToCode()
end

local Location = game:GetService("HttpService"):GenerateGUID(false)
local ScriptEditor = game:GetService("ScriptEditorService")
local shared = shared
shared[Location] = DataToCode

function DataToCode.output(tbl)
	shared[Location] = nil
	local Serialized = DataToCode.Convert(tbl, true)
	local DisplayScript = Instance.new("LocalScript", game)
	DisplayScript.Name = "Dumped_"..math.floor(os.clock())

	ScriptEditor:UpdateSourceAsync(DisplayScript, function()
		return Serialized
	end)

	ScriptEditor:OpenScriptDocumentAsync(DisplayScript)
end

local setfenv, error, loadstring, type, info = setfenv, error, loadstring, type, debug.info -- localizing so it doesnt retrieve it from the enviornment
local CClosures = {}

local function newcclosure(func)
	CClosures[func] = "C"

	return func
end

local function islclosure(func)
	return info(func, "l") ~= -1
end

local env = getfenv()

env.setfenv = newcclosure(function(func, ...)
	if type(func) == "function" then -- This is how they check if a function is a CClosure
		error("'setfenv' cannot change environment of given object")
	end

	return setfenv(func, ...)
end)

env.debug = (function()
	local newdebug = table.clone(debug) -- They retrieve it weird

	newdebug.getinfo = newcclosure(function(func) -- Encrypted only checks the 'what'
		return {
			what = CClosures[func] or islclosure(func) and "Lua" or "C"
		}
	end)

	return newdebug
end)()

env.loadstring = newcclosure(function(code : string, chunkname : string, ...)
	if type(code) == "string" then
		local Start,End,Pattern,Constants = code:find("([%a_][%w_]*%([%a_][%w_]*%((.)%)%))")

		if Constants then
			local Start, End, Reassign, Variable, full, Constants = code:find("([^%s]([%a_][%w_]*)[%s]*=[%s]*)([%a_][%w_]*%([%a_][%w_]*%((.)%)%)).-return %2%(%.%.%.%)")

			if not Start then
				Start, End, Reassign, Variable, full, Constants = code:find("(([%a_][%w_]*)[%s]*=[%s]*)([%a_][%w_]*%([%a_][%w_]*%((.)%)%)).-return %2%(%.%.%.%)") -- very lazy fix and I'm sorry :)
			end

			code = code:sub(1, Start-1+#Reassign)..`(shared["{Location}"].output({Constants}) or function() end)`..code:sub(Start+#full+3)
		end
	end

	return loadstring(code, chunkname, ...)
end);

([[This file was protected with MoonSec V3]]):gsub('.+', (function(a) _ImZaWHQvOSld = a; end)); return(function(c,...)local f;local h;local r;local o;local t;local d;local e=24915;local n=0;local l={};while n<836 do n=n+1;while n<0x31f and e%0xc7a<0x63d do n=n+1 e=(e+161)%40519 local a=n+e if(e%0x271e)<0x138f then e=(e*0x225)%0x3b2e while n<0x280 and e%0x1fac<0xfd6 do n=n+1 e=(e*1020)%3436 local d=n+e if(e%0x16d8)>=0xb6c then e=(e*0x1ab)%0x3668 local e=26257 if not l[e]then l[e]=0x1 t=getfenv and getfenv();end elseif e%2~=0 then e=(e*0x1e2)%0xb8e8 local e=76504 if not l[e]then l[e]=0x1 end else e=(e-0x1fc)%0x3eb6 n=n+1 local e=59590 if not l[e]then l[e]=0x1 t=(not t)and _ENV or t;end end end elseif e%2~=0 then e=(e-0x3b2)%0x591 while n<0x2b0 and e%0x3574<0x1aba do n=n+1 e=(e+50)%42698 local f=n+e if(e%0x4b24)<0x2592 then e=(e*0x1ad)%0xa542 local e=72244 if not l[e]then l[e]=0x1 o={};end elseif e%2~=0 then e=(e-0x16)%0xa292 local e=50036 if not l[e]then l[e]=0x1 d=function(d)local e=0x01 local function l(n)e=e+n return d:sub(e-n,e-0x01)end while true do local n=l(0x01)if(n=="\5")then break end local e=r.byte(l(0x01))local e=l(e)if n=="\2"then e=o.lgTSxyOU(e)elseif n=="\3"then e=e~="\0"elseif n=="\6"then t[e]=function(n,e)return c(8,nil,c,e,n)end elseif n=="\4"then e=t[e]elseif n=="\0"then e=t[e][l(r.byte(l(0x01)))];end local n=l(0x08)o[n]=e end end end else e=(e-0x8b)%0x5d37 n=n+1 local e=17290 if not l[e]then l[e]=0x1 r=string;end end end else e=(e-0x24e)%0xbe30 n=n+1 while n<0x106 and e%0x1736<0xb9b do n=n+1 e=(e-573)%34324 local t=n+e if(e%0x1f52)>=0xfa9 then e=(e+0x203)%0x64b6 local e=64899 if not l[e]then l[e]=0x1 f="\4\8\116\111\110\117\109\98\101\114\108\103\84\83\120\121\79\85\0\6\115\116\114\105\110\103\4\99\104\97\114\104\110\117\101\90\83\69\109\0\6\115\116\114\105\110\103\3\115\117\98\81\105\115\122\100\80\107\97\0\6\115\116\114\105\110\103\4\98\121\116\101\72\97\79\76\116\77\110\103\0\5\116\97\98\108\101\6\99\111\110\99\97\116\85\86\71\119\120\110\112\82\0\5\116\97\98\108\101\6\105\110\115\101\114\116\81\110\122\118\117\88\68\112\5";end elseif e%2~=0 then e=(e-0x353)%0x92b3 local e=39453 if not l[e]then l[e]=0x1 h=tonumber;end else e=(e+0x378)%0xac7f n=n+1 local e=66718 if not l[e]then l[e]=0x1 end end end end end e=(e+705)%43621 end d(f);local n={};for e=0x0,0xff do local l=o.hnueZSEm(e);n[e]=l;n[l]=e;end local function u(e)return n[e];end local r=(function(a,d)local f,l=0x01,0x10 local n={{},{},{}}local t=-0x01 local e=0x01 local r=a while true do n[0x03][o.QiszdPka(d,e,(function()e=f+e return e-0x01 end)())]=(function()t=t+0x01 return t end)()if t==(0x0f)then t=""l=0x000 break end end local t=#d while e<t+0x01 do n[0x02][l]=o.QiszdPka(d,e,(function()e=f+e return e-0x01 end)())l=l+0x01 if l%0x02==0x00 then l=0x00 o.QnzvuXDp(n[0x01],(u((((n[0x03][n[0x02][0x00]]or 0x00)*0x10)+(n[0x03][n[0x02][0x01]]or 0x00)+r)%0x100)));r=a+r;end end return o.UVGwxnpR(n[0x01])end);d(r(91,"_,TpKdBOo)uz2 E0uu"));d(r(3,"}_w0bje(:-1pxIvEEIXQe1e:e0j(j-bEv-bejbb-b-wpb(bb_Ew00(+v_0xwx w:_:_0_p_:_j_v_e_bZEvEEE>e-w-0EpE1vvEyE0vjxevPvjvwv(1xx-ebe(I_xEx1pvxMpej_pe1(p(101j(E1(:r(b:I:v(0-vwww0:-(1:1(p_j(-evex(x(_b:b(e(bw0be_0wbxv1vEj0bwbvbb0-bjwE0Ew-w(wvwbUpw_EIEEw_wjvI=E1:1:EblDEpX-r_f_pEIXvpxIv0x1pxI:Ij(j(wvwx-xvIexv10pE1x1bp:p(:Ib-bj(1:v-j(I:x:e(_:p-jw1wp-b:x:I:p:e(1(x(w:_jjjjbeex0EbIe1EPEwjvb:bebIb0v_bIb0bw0%wE0bSxr(900e_ww(wpDjpwp__I_0_wtVEEDbv:Q:EwIbEIx-I1vw:w:Cv:v(IpIIvMx0xxI_pjIjx_11xIjjjbpv1Ip_1(1wpQ(x:v-w1e(::0eIe(w_ww::(-:-(1_b(w(j(j(w(wjEjwj_0Ej0b0010_v1"));local e=(-2426+(function()local d,n=0,1;(function(l,e,n)n(l(l,n and e,e)and l(e and n,n,l),e(e,e,e),e(n,e,e))end)(function(t,e,l)if d>205 then return l end d=d+1 n=(n+840)%39352 if(n%472)<236 then n=(n-724)%34638 return e(t(e,t,e),e(l,l,t),t(l,e,l))else return e end return t end,function(t,l,e)if d>265 then return l end d=d+1 n=(n+229)%21532 if(n%512)<=256 then n=(n*101)%4530 return l else return e(t(t,l,t)and e(e,t,t and l),e(e,e,t)and t(l,e,e),l(e,l and e,l))end return e(t(e,t,t),l(e,l,e),e(e and l,e and e,l and t))end,function(t,e,l)if d>472 then return t end d=d+1 n=(n+670)%14114 if(n%750)<375 then n=(n*658)%20007 return l(l(l,l,e),e(e,l,t and e),e(e,e,t))else return e end return e end)return n;end)())local u=o.RubGsBVa or o.FDCyXpwT;local ne=(getfenv)or(function()return _ENV end);local t=2;local ee=1;local d=3;local a=4;local function g(j,...)local f=r(e,";uFt9/J8br %jU!OOOOR!b!4U%!rjbjv%bOUu8)OgJ!t!U!tU8jtUjUFju%! O%tb<rrbjb98U8!9r89JjJF!%!9UbUwjbF8uruU?U t Fr2bbbA!9UOjrj9j%j9%  r Jr8F%FUubuh,b/O9u/U9F9uFOuburtJS8ftu9^9r%%Nbbb=8bUbUjU9jbjtbFJOJ8 Qbrrtbj8/J!8rFJ/u/b/_d8FFpr6%u%Duu8U/UO%OO !u!O8tbOJ1/b/)rj b u t9bbJbu8jJUF1JO/u/%+39b9Ft8t9uUutuj_/Oj%3OO!r!jUbbb Uj8%O%JrtrUrt9b8J9%uteO0:ObOQtZ/99j9Q*OF/Fj%B b 3rbr>rJb(8b8+Jb8J/b/f9b9utbtNFbtFu u?nbL}OrOH!b!h! UOjbj_%b%9 b =rb%JbUbs8b8nJ!J)/r/v9!9Ttjt%FbFxubuJ0bhuObOyOu!6UbU1jrj:%b%R% %urbrhbbbt8b8:Jb8FJb/o9r9Xt txFbF)tbFrebcuObOu!b!8Ub!FUOj&%%%Y U Wrbr(bbr*8b8uJbJt/b/g9b9Wt!tYFbF}ubuTT paObBU!b!DUbUujbju%b%D j grbr<brbL8b8V");local n=0;o.lxstrUhr(function()o.oGfVQhjC()n=n+1 end)local function e(l,e)if e then return n end;n=l+n;end local l,n,b=c(0,c,e,f,o.HaOLtMng);local function r()local n,l=o.HaOLtMng(f,e(1,3),e(5,6)+2);e(2);return(l*256)+n;end;local s=true;local s=0 local function k()local t=n();local e=n();local d=1;local t=(l(e,1,20)*(2^32))+t;local n=l(e,21,31);local e=((-1)^l(e,32));if(n==0)then if(t==s)then return e*0;else n=1;d=0;end;elseif(n==2047)then return(t==0)and(e*(1/0))or(e*(0/0));end;return o.JLoMBrFc(e,n-1023)*(d+(t/(2^52)));end;local _=n;local function p(n)local l;if(not n)then n=_();if(n==0)then return'';end;end;l=o.QiszdPka(f,e(1,3),e(5,6)+n-1);e(n)local e=""for n=(1+s),#l do e=e..o.QiszdPka(l,n,n)end return e;end;local s=#o.yPSGpFWw(h('\49.\48'))~=1 local e=n;local function m(...)return{...},o.CX_vKYFC('#',...)end local function g()local c={};local u={};local e={};local h={u,c,nil,e};local e=n()local f={}for t=1,e do local l=b();local e;if(l==1)then e=(b()~=#{});elseif(l==0)then local n=k();if s and o.EpLC_cKy(o.yPSGpFWw(n),'.(\48+)$')then n=o.bXZKbUOI(n);end e=n;elseif(l==3)then e=p();end;f[t]=e;end;h[3]=b();for e=1,n()do c[e-(#{1})]=g();end;for h=1,n()do local e=b();if(l(e,1,1)==0)then local o=l(e,2,3);local c=l(e,4,6);local e={r(),r(),nil,nil};if(o==0)then e[d]=r();e[a]=r();elseif(o==#{1})then e[d]=n();elseif(o==j[2])then e[d]=n()-(2^16)elseif(o==j[3])then e[d]=n()-(2^16)e[a]=r();end;if(l(c,1,1)==1)then e[t]=f[e[t]]end if(l(c,2,2)==1)then e[d]=f[e[d]]end if(l(c,3,3)==1)then e[a]=f[e[a]]end u[h]=e;end end;return h;end;local function y(l,e,n)local t=e;local t=n;return h(o.EpLC_cKy(o.EpLC_cKy(({o.lxstrUhr(l)})[2],e),n))end local function z(p,e,b)local function y(...)local r,y,s,g,j,l,f,_,h,k,z,n;local e=0;while-1<e do if 3>e then if e<=0 then r=c(6,18,1,85,p);y=c(6,57,2,4,p);else if-2<=e then for n=39,74 do if 1~=e then l=-41;f=-1;break;end;s=c(6,26,3,35,p);j=m g=0;break;end;else l=-41;f=-1;end end else if e>=5 then if 3<=e then for l=14,94 do if 5<e then e=-2;break;end;n=c(7);break;end;else n=c(7);end else if 0<=e then for n=17,83 do if e>3 then k=o.CX_vKYFC('#',...)-1;z={};break;end;_={};h={...};break;end;else _={};h={...};end end end e=e+1;end;for e=0,k do if(e>=s)then _[e-s]=h[e+1];else n[e]=h[e+1];end;end;local e=k-s+1 local e;local o;local function c(...)while true do end end while true do if l<-40 then l=l+42 end e=r[l];o=e[ee];if 12<=o then if o<=17 then if 14>=o then if 13>o then local o,f,r,c,a;local l=0;while l>-1 do if l>=3 then if l>4 then if l==5 then n(a,c);else l=-2;end else if 3==l then c=o[r];else a=o[f];end end else if l>0 then if 2==l then r=d;else f=t;end else o=e;end end l=l+1 end else if 12~=o then repeat if o<14 then l=e[d];break;end;local e=e[t]n[e]=n[e](u(n,e+1,f))until true;else l=e[d];end end else if o<=15 then n[e[t]]=(e[d]~=0);else if o~=17 then local o,h,_,s,c;n[e[t]]=b[e[d]];l=l+1;e=r[l];o=e[t];h=n[e[d]];n[o+1]=h;n[o]=h[e[a]];l=l+1;e=r[l];n(e[t],e[d]);l=l+1;e=r[l];o=e[t]_,s=j(n[o](u(n,o+1,e[d])))f=s+o-1 c=0;for e=o,f do c=c+1;n[e]=_[c];end;l=l+1;e=r[l];o=e[t]n[o]=n[o](u(n,o+1,f))l=l+1;e=r[l];n[e[t]]();l=l+1;e=r[l];do return end;else n[e[t]]=b[e[d]];end end end else if 21>o then if 19<=o then if o==19 then local l=e[t]local t,e=j(n[l](u(n,l+1,e[d])))f=e+l-1 local e=0;for l=l,f do e=e+1;n[l]=t[e];end;else local l=e[t]local t,e=j(n[l](u(n,l+1,e[d])))f=e+l-1 local e=0;for l=l,f do e=e+1;n[l]=t[e];end;end else n[e[t]]=b[e[d]];end else if o>21 then if o>21 then repeat if 22<o then n[e[t]]();break;end;for o=0,3 do if 1<o then if-2<=o then for f=23,94 do if o<3 then n[e[t]]=b[e[d]];l=l+1;e=r[l];break;end;if(n[e[t]]~=e[a])then l=l+1;else l=e[d];end;break;end;else n[e[t]]=b[e[d]];l=l+1;e=r[l];end else if-1<=o then for f=17,59 do if o~=1 then n[e[t]]=(e[d]~=0);l=l+1;e=r[l];break;end;b[e[d]]=n[e[t]];l=l+1;e=r[l];break;end;else n[e[t]]=(e[d]~=0);l=l+1;e=r[l];end end end until true;else n[e[t]]();end else n[e[t]]=(e[d]~=0);end end end else if 5>=o then if 3>o then if o<=0 then local a,o,c,r,f;local l=0;while l>-1 do if l>=3 then if 5<=l then if 4<=l then repeat if 5~=l then l=-2;break;end;n(f,r);until true;else n(f,r);end else if 3==l then r=a[c];else f=a[o];end end else if 1>l then a=e;else if-1~=l then for e=41,88 do if l~=1 then c=d;break;end;o=t;break;end;else o=t;end end end l=l+1 end else if-1~=o then repeat if 2>o then if(n[e[t]]~=e[a])then l=l+1;else l=e[d];end;break;end;local t=e[t];local l=n[e[d]];n[t+1]=l;n[t]=l[e[a]];until true;else local t=e[t];local l=n[e[d]];n[t+1]=l;n[t]=l[e[a]];end end else if 4<=o then if o==4 then b[e[d]]=n[e[t]];else do return end;end else if(n[e[t]]~=e[a])then l=l+1;else l=e[d];end;end end else if o<9 then if 6<o then if 8>o then local e=e[t]n[e]=n[e](u(n,e+1,f))else b[e[d]]=n[e[t]];end else n[e[t]]();end else if o<10 then do return end;else if 10<o then l=e[d];else local t=e[t];local l=n[e[d]];n[t+1]=l;n[t]=l[e[a]];end end end end end l=1+l;end;end;return y end;local d=0xff;local c={};local f=(1);local t='';(function(n)local l=n local r=0x00 local e=0x00 l={(function(a)if r>0x28 then return a end r=r+1 e=(e+0xb7b-a)%0x49 return(e%0x03==0x2 and(function(l)if not n[l]then e=e+0x01 n[l]=(0xe1);end return true end)'SKETJ'and l[0x2](0x25c+a))or(e%0x03==0x0 and(function(l)if not n[l]then e=e+0x01 n[l]=(0x18);t={t..'\58 a',t};c[f]=g();f=f+((not o.UttRYpJR)and 1 or 0);t[1]='\58'..t[1];d[2]=0xff;end return true end)'Uozuk'and l[0x3](a+0x178))or(e%0x03==0x1 and(function(l)if not n[l]then e=e+0x01 n[l]=(0xc2);end return true end)'lfEQM'and l[0x1](a+0x2a9))or a end),(function(t)if r>0x2b then return t end r=r+1 e=(e+0xa93-t)%0x46 return(e%0x03==0x1 and(function(l)if not n[l]then e=e+0x01 n[l]=(0xe8);end return true end)'PfOMZ'and l[0x2](0x296+t))or(e%0x03==0x2 and(function(l)if not n[l]then e=e+0x01 n[l]=(0xbf);end return true end)'ODWcx'and l[0x3](t+0x1f7))or(e%0x03==0x0 and(function(l)if not n[l]then e=e+0x01 n[l]=(0x26);end return true end)'cInqq'and l[0x1](t+0x1ce))or t end),(function(o)if r>0x23 then return o end r=r+1 e=(e+0x950-o)%0x49 return(e%0x03==0x2 and(function(l)if not n[l]then e=e+0x01 n[l]=(0xa0);t='\37';d={function()d()end};t=t..'\100\43';end return true end)'AjmUg'and l[0x1](0x7d+o))or(e%0x03==0x0 and(function(l)if not n[l]then e=e+0x01 n[l]=(0x96);c[f]=ne();f=f+d;end return true end)'xoPuy'and l[0x2](o+0x338))or(e%0x03==0x1 and(function(l)if not n[l]then e=e+0x01 n[l]=(0xf4);d[2]=(d[2]*(y(function()c()end,u(t))-y(d[1],u(t))))+1;c[f]={};d=d[2];f=f+d;end return true end)'dEmlY'and l[0x3](o+0x150))or o end)}l[0x3](0x16ef)end){};local e=z(u(c));return e(...);end return g((function()local n={}local e=0x01;local l;if o.UttRYpJR then l=o.UttRYpJR(g)else l=''end if o.EpLC_cKy(l,o.iMjrrzBb)then e=e+0;else e=e+1;end n[e]=0x02;n[n[e]+0x01]=0x03;return n;end)(),...)end)((function(e,n,l,t,d,o)local o;if 3>=e then if e>1 then if 3~=e then do return 16777216,65536,256 end;else do return n(1),n(4,d,t,l,n),n(5,d,t,l)end;end else if e==0 then do return n(1),n(4,d,t,l,n),n(5,d,t,l)end;else do return function(l,e,n)if n then local e=(l/2^(e-1))%2^((n-1)-(e-1)+1);return e-e%1;else local e=2^(e-1);return(l%(e+e)>=e)and 1 or 0;end;end;end;end end else if 5<e then if e>=7 then if e>=5 then for n=32,74 do if e~=8 then do return setmetatable({},{['__\99\97\108\108']=function(e,d,t,l,n)if n then return e[n]elseif l then return e else e[d]=t end end})end break;end;do return l(e,nil,l);end break;end;else do return setmetatable({},{['__\99\97\108\108']=function(e,l,t,d,n)if n then return e[n]elseif d then return e else e[l]=t end end})end end else do return d[l]end;end else if 3~=e then repeat if 5~=e then local e=t;local t,d,f=d(2);do return function()local r,o,n,l=n(l,e(e,e),e(e,e)+3);e(4);return(l*t)+(n*d)+(o*f)+r;end;end;break;end;local e=t;do return function()local n=n(l,e(e,e),e(e,e));e(1);return n;end;end;until true;else local e=t;local d,o,t=d(2);do return function()local n,l,f,r=n(l,e(e,e),e(e,e)+3);e(4);return(r*d)+(f*o)+(l*t)+n;end;end;end end end end),...)